import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('workload_records')
export class WorkloadRecord {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  payload: string;

  @Column({ type: 'timestamp' })
  createdAt: Date;
}