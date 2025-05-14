import { Entity, PrimaryGeneratedColumn, Column, OneToMany } from 'typeorm';
import { Trip } from '../../trips/entities/trip.entity';

@Entity()
export class Supplier {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column()
  city: string;

  @Column()
  address: string;

  @Column('text')
  contactPerson: string; // JSON as text

  @Column('text')
  bankDetails: string; // JSON as text

  @Column()
  gstNumber: string;

  @OneToMany(() => Trip, trip => trip.supplier)
  trips: Trip[];
} 