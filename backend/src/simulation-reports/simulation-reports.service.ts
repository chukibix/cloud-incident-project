import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SimulationReport } from './entities/simulation-report.entity';

@Injectable()
export class SimulationReportsService {
  constructor(
    @InjectRepository(SimulationReport)
    private readonly reportRepository: Repository<SimulationReport>,
  ) {}

  async createReport() {
    const report = this.reportRepository.create({
      engineerName: 'Younes',
      testType: 'TRAFFIC',
      description: 'Testing API under increased traffic',
      startedAt: new Date(),
      endedAt: new Date(),
      durationSeconds: 60,
      requestsGenerated: 5400,
      successfulRequests: 5380,
      failedRequests: 20,
      averageLatencyMs: 185,
      p95LatencyMs: 420,
      p99LatencyMs: 870,
      result: 'SUCCESS',
      notes: 'Application remained stable',
    });

    return this.reportRepository.save(report);
  }
  async getReports() {
  return this.reportRepository.find({
    order: {
      startedAt: 'DESC',
    },
  });
}
}