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
  const records: Partial<WorkloadRecord>[] = [];

  for (let i = 0; i < 1000; i++) {
    records.push({
      payload: 'Database workload record ${i}',
      createdAt: new Date(),
    });
  }

  await this.workloadRepository.insert(records);

  const results = await this.workloadRepository.find({
    take: 1000,
    order: {
      id: 'DESC',
    },
  });

  return {
    message: 'Database workload completed',
    inserted: records.length,
    queried: results.length,
  };
} 
}