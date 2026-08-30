import { Test, TestingModule } from '@nestjs/testing';
import { SimulationReportsController } from './simulation-reports.controller';

describe('SimulationReportsController', () => {
  let controller: SimulationReportsController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [SimulationReportsController],
    }).compile();

    controller = module.get<SimulationReportsController>(SimulationReportsController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
