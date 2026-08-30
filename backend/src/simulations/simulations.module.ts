import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { WorkloadRecord } from './entities/workload-record.entity';
import { SimulationsController } from './simulations.controller';
import { SimulationsService } from './simulations.service';

@Module({
  imports: [TypeOrmModule.forFeature([WorkloadRecord])],
  controllers: [SimulationsController],
  providers: [SimulationsService],
})
export class SimulationsModule {}