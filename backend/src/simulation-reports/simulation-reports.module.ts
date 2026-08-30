import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SimulationReport } from './entities/simulation-report.entity';
import { SimulationReportsController } from './simulation-reports.controller';
import { SimulationReportsService } from './simulation-reports.service';

@Module({
  imports: [TypeOrmModule.forFeature([SimulationReport])],
  controllers: [SimulationReportsController],
  providers: [SimulationReportsService],
})
export class SimulationReportsModule {}