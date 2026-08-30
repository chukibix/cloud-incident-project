import { Controller, Get, Post } from '@nestjs/common';
import { SimulationReportsService } from './simulation-reports.service';

@Controller('simulation-reports')
export class SimulationReportsController {
  constructor(
    private readonly simulationReportsService: SimulationReportsService,
  ) {}

  @Post()
  createReport() {
    return this.simulationReportsService.createReport();
  }

  @Get()
  getReports() {
    return this.simulationReportsService.getReports();
  }
}