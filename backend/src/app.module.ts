import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { SimulationsModule } from './simulations/simulations.module';
import { SimulationReportsModule } from './simulation-reports/simulation-reports.module';
import { readFileSync } from 'fs';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: process.env.DB_HOST,
      port: Number(process.env.DB_PORT) || 5432,
      username: process.env.DB_USERNAME,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_DATABASE,
      ssl: {
         rejectUnauthorized: true,
         ca: readFileSync(process.env.DB_SSL_CA!, 'utf8'),
      },
      autoLoadEntities: true,
      synchronize: true,
    }),
    SimulationsModule,
    SimulationReportsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}