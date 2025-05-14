import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToMany, JoinColumn } from 'typeorm';
import { Supplier } from '../../suppliers/entities/supplier.entity';
import { Trip } from '../../trips/entities/trip.entity';

@Entity()
export class Vehicle {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  registrationNumber: string;

  @Column()
  supplierId: string;

  @ManyToOne(() => Supplier)
  @JoinColumn({ name: 'supplierId' })
  supplier: Supplier;

  @Column()
  supplierName: string;

  @Column()
  vehicleType: string;

  @Column()
  vehicleSize: string;

  @Column()
  vehicleCapacity: string;

  @Column()
  axleType: string;

  @Column()
  driverName: string;

  @Column()
  driverPhone: string;

  @Column()
  insuranceExpiry: string;

  @OneToMany(() => Trip, trip => trip.vehicle)
  trips: Trip[];
} 