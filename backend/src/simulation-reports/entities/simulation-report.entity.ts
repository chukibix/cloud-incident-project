import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('simulation_reports')
export class SimulationReport {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  engineerName: string;

  @Column()
  testType: string;

  @Column('text')
  description: string;

  @Column({ type: 'timestamp' })
  startedAt: Date;

  @Column({ type: 'timestamp', nullable: true })
  endedAt: Date | null;

  @Column()
  durationSeconds: number;

  @Column()
  requestsGenerated: number;

  @Column()
  successfulRequests: number;

  @Column()
  failedRequests: number;

  @Column()
  averageLatencyMs: number;

  @Column()
  p95LatencyMs: number;

  @Column()
  p99LatencyMs: number;

  @Column()
  result: string;

  @Column('text', { nullable: true })
  notes: string | null;
}
