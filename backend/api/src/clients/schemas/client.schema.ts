import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type ClientDocument = Client & Document;

// Contact Person Schema
@Schema({ _id: false })
export class ContactPerson {
  @Prop({ required: true })
  name: string;

  @Prop({ required: true })
  phone: string;

  @Prop({ required: true })
  email: string;

  @Prop()
  designation?: string;
}

const ContactPersonSchema = SchemaFactory.createForClass(ContactPerson);

@Schema({ timestamps: true })
export class Client {
  @Prop({ required: true, unique: true })
  id: string;

  @Prop({ required: true })
  name: string;

  @Prop({ required: true })
  address: string;

  @Prop({ required: true })
  city: string;

  @Prop({ required: true })
  addressType: string;

  @Prop({ required: true })
  invoicingType: string;

  @Prop()
  gstNumber: string;

  @Prop({ required: true })
  panNumber: string;

  @Prop()
  msmeNumber?: string;

  @Prop({ default: true })
  isActive: boolean;

  // Structured contact information
  @Prop({ type: ContactPersonSchema, required: true })
  logisticsPOC: ContactPerson;

  @Prop({ type: ContactPersonSchema, required: true })
  financePOC: ContactPerson;

  @Prop({ type: ContactPersonSchema, required: true })
  salesRepresentative: ContactPerson;

  // Legacy flat contact fields for backward compatibility
  @Prop()
  logisticsName: string;

  @Prop()
  logisticsPhone: string;

  @Prop()
  logisticsEmail: string;

  @Prop()
  financeName: string;

  @Prop()
  financePhone: string;

  @Prop()
  financeEmail: string;

  @Prop()
  salesRepName: string;

  @Prop()
  salesRepDesignation: string;

  @Prop()
  salesRepPhone: string;

  @Prop()
  salesRepEmail: string;

  // Documents with enhanced metadata
  @Prop({ type: [Object], default: [] })
  documents: {
    type: string;
    url: string;
    filename: string;
    originalName: string;
    mimeType: string;
    size: number;
    uploadedAt: Date;
    isVerified: boolean;
    verifiedAt?: Date;
    verifiedBy?: string;
    number?: string;
    year?: number;
  }[];

  @Prop({ default: 'Active' })
  status: string;
}

export const ClientSchema = SchemaFactory.createForClass(Client); 