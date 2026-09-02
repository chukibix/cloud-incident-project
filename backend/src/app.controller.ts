import { Controller, Get } from '@nestjs/common';
import { AppService } from './app.service';
import { Response } from 'express';
import { join } from 'path';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  getHomePage(@Res() res: Response) {
    return res.sendFile(join(process.cwd(), 'public/index.html'));
  }
}
