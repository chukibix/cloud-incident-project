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

  cpuStress(durationSeconds = 10) {
    const end = Date.now() + durationSeconds * 1000;

    let result = 0;

    while (Date.now() < end) {
      for (let i = 0; i < 100000; i++) {
        result += Math.sqrt(i) * Math.random();
      }
    }

    return {
      message: 'CPU workload completed',
      durationSeconds,
      result,
    };
  }

  //workload stree to table
async databaseWorkload() {
  // 1. Target "Free Storage" & "Swap"
  // Create a 50KB string of junk data to eat up disk space rapidly
  const massivePayload = 'X'.repeat(50000); 
  
  const records = Array.from({ length: 100 }, (_, i) => ({
    payload: `Heavy Record ${i} - ${massivePayload}`,
    createdAt: new Date(),
  }));

  // Promise.all opens multiple concurrent connections instead of 1 efficient bulk insert
  await Promise.all(
    records.map(record => this.workloadRepository.save(record))
  );

  // 2. Target "RDS CPU Usage" & "Swap"
  // ORDER BY RANDOM() is notoriously expensive. It forces PostgreSQL to 
  // load data into memory (and swap) to perform the randomized sort.
  await this.workloadRepository.query(
    'SELECT id FROM workload_records ORDER BY RANDOM() LIMIT 500;'
  );

  return {
    message: 'Database hammered: High IOPS and CPU load generated',
    inserted: records.length,
  };
}
}