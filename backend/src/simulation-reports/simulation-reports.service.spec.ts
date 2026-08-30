import { Test, TestingModule } from '@nestjs/testing';
import { SimulationReportsService } from './simulation-reports.service';

describe('SimulationReportsService', () => {
  let service: SimulationReportsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [SimulationReportsService],
    }).compile();

    service = module.get<SimulationReportsService>(SimulationReportsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
