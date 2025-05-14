import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, CreateDateColumn, UpdateDateColumn } from 'typeorm';
import { Client } from '../../clients/entities/client.entity';
import { Supplier } from '../../suppliers/entities/supplier.entity';
import { Vehicle } from '../../vehicles/entities/vehicle.entity';

@Entity()
export class Trip {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  orderNumber: string;

  @Column('simple-array')
  lrNumbers: string[];

  @Column({ nullable: true })
  clientId: string;

  @ManyToOne(() => Client, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'clientId' })
  client: Client;

  @Column()
  clientName: string;

  @Column()
  clientAddress: string;

  @Column()
  clientAddressType: string;

  @Column()
  clientCity: string;

  @Column()
  destinationAddress: string;

  @Column()
  destinationCity: string;

  @Column()
  destinationAddressType: string;

  @Column({ nullable: true })
  supplierId: string;

  @ManyToOne(() => Supplier, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'supplierId' })
  supplier: Supplier;

  @Column()
  supplierName: string;

  @Column({ nullable: true })
  vehicleId: string;

  @ManyToOne(() => Vehicle, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'vehicleId' })
  vehicle: Vehicle;

  @Column()
  vehicleNumber: string;

  @Column({ nullable: true })
  driverName: string;

  @Column({ nullable: true })
  driverPhone: string;

  @Column()
  vehicleType: string;

  @Column()
  vehicleSize: string;

  @Column()
  vehicleCapacity: string;

  @Column()
  axleType: string;

  @Column('text')
  materials: string;

  @Column()
  pickupDate: string;

  @Column()
  pickupTime: string;

  @Column('float', { precision: 10, scale: 2 })
  clientFreight: number;

  @Column('float', { precision: 10, scale: 2 })
  supplierFreight: number;

  @Column('float', { precision: 5, scale: 2 })
  advancePercentage: number;

  @Column('float', { precision: 10, scale: 2 })
  advanceSupplierFreight: number;

  @Column('float', { precision: 10, scale: 2 })
  balanceSupplierFreight: number;

  @Column('text', { nullable: true })
  documents: string;

  @Column('text')
  fieldOps: string;

  @Column({ default: false })
  gsmTracking: boolean;

  @Column()
  status: string;

  @Column()
  advancePaymentStatus: string;

  @Column()
  balancePaymentStatus: string;

  @Column({ default: false })
  podUploaded?: boolean;

  @Column('text', { nullable: true })
  additionalCharges: string;

  @Column('text', { nullable: true })
  deductionCharges: string;

  @Column('float', { precision: 10, scale: 2, nullable: true })
  lrCharges: number;

  @Column('float', { precision: 10, scale: 2, nullable: true })
  platformFees: number;

  @Column({ nullable: true })
  utrNumber: string;

  @Column({ nullable: true })
  paymentMethod: string;

  @Column({ nullable: true })
  ifscCode: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
} 