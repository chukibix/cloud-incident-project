import {
  HttpException,
  HttpStatus,
  Injectable,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { WorkloadRecord } from './entities/workload-record.entity';

@Injectable()
export class SimulationsService {
  constructor(
    @InjectRepository(WorkloadRecord)
    private readonly workloadRepository: Repository<WorkloadRecord>,
  ) {
  }
  healthCheck() {
    return {
      status: 'healthy',
      message: 'Application is running normally',
    };
  }

  async slowEndpoint() {
    await new Promise((resolve) => setTimeout(resolve, 2000));

    return {
      message: 'Slow endpoint completed',
      delay: '2000ms',
    };
  }

  errorSimulation() {
    throw new HttpException(
      'Simulated internal server error',
      HttpStatus.INTERNAL_SERVER_ERROR,
    );
  }

async generateTraffic() {
  const requests = 1000;
  const start = Date.now();

  const results = await Promise.all(
    Array.from({ length: requests }, () =>
      fetch('http://localhost:3000/simulations/health'),
    ),
  );

  const successfulRequests = results.filter(
    (response) => response.ok,
  ).length;

  const failedRequests = requests - successfulRequests;

  return {
    message: 'Traffic workload completed',
    requestsGenerated: requests,
    successfulRequests,
    failedRequests,
    durationMs: Date.now() - start,
  };
}

async cpuStress(durationSeconds = 5) {
    const end = Date.now() + durationSeconds * 1000;
    let result = 0;

    while (Date.now() < end) {
      for (let i = 0; i < 100000; i++) {
        result += Math.sqrt(i) * Math.random();
      }
      // Yield control back to the event loop so it can handle HTTP responses and health checks
      await new Promise((resolve) => setImmediate(resolve));
    }

    return {
      message: 'CPU workload completed',
      durationSeconds,
      result,
    };
  }

  //workload stree to table
async databaseWorkload() {
  // 1. Shift the generation burden to PostgreSQL
  // Node.js sends a tiny 100-byte text string over a single connection.
  // PostgreSQL handles the memory allocation, string repetition, and bulk insert.
  await this.workloadRepository.query(`
    INSERT INTO workload_records (payload, "createdAt")
    SELECT repeat('X', 50000), NOW()
    FROM generate_series(1, 100);
  `);

  // 2. Target "RDS CPU Usage" & "Swap"
  // The DB still has to run the expensive random sort in memory.
  await this.workloadRepository.query(
    'SELECT id FROM workload_records ORDER BY RANDOM() LIMIT 500;'
  );

  return {
    message: 'Database hammered: Node.js bypassed, RDS took the full hit',
  };
}
}