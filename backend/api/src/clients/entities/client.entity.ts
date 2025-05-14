import { Entity, PrimaryGeneratedColumn, Column, OneToMany } from 'typeorm';
import { Trip } from '../../trips/entities/trip.entity';

@Entity()
export class Client {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column()
  city: string;

  @Column()
  address: string;

  @Column()
  addressType: string;

  @Column()
  gstNumber: string;

  @Column()
  panNumber: string;

  @Column('text')
  logisticsPOC: string; // JSON as text

  @Column('text')
  financePOC: string; // JSON as text

  @Column()
  invoicingType: string;

  @Column('text')
  salesRep: string; // JSON as text

  @OneToMany(() => Trip, trip => trip.client)
  trips: Trip[];
} 