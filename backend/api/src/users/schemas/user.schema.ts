import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type UserDocument = User & Document;

@Schema({ timestamps: true })
export class User {
  @Prop({ required: true, unique: true })
  email: string;

  @Prop({ required: true, select: false })
  password: string;

  @Prop({ required: true })
  name: string;

  @Prop({ 
    required: true, 
    enum: ['admin', 'manager', 'operator', 'user'],
    default: 'user'
  })
  role: string;

  @Prop({ default: true })
  isActive: boolean;

  @Prop()
  lastLogin: Date;

  @Prop()
  phone: string;

  @Prop()
  avatar: string;

  @Prop({ type: Object })
  preferences: Record<string, any>;

  @Prop({ type: [String] })
  permissions: string[];
}

export const UserSchema = SchemaFactory.createForClass(User); 