import { Controller, Get, Post } from '@nestjs/common';
import { SimulationsService } from './simulations.service';

@Controller('simulations')
export class SimulationsController {
  constructor(private readonly simulationsService: SimulationsService) {}

  @Get('health')
  healthCheck() {
    return this.simulationsService.healthCheck();
  }

  @Post('slow')
  slowEndpoint() {
    return this.simulationsService.slowEndpoint();
  }

  @Post('errors')
  errorSimulation() {
    return this.simulationsService.errorSimulation();
  }

  @Post('traffic')
  startTraffic() {
    return this.simulationsService.generateTraffic();
  }

  @Post('cpu')
  cpuStress() {
    return this.simulationsService.cpuStress();
  }
  
  @Post('database')
  databaseWorkload() {
    return this.simulationsService.databaseWorkload();
}
}