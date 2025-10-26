
import React from 'react';

export enum MaterialType {
  STEEL = 'Steel',
  ALUMINUM = 'Aluminum',
  COPPER = 'Copper',
  BRASS = 'Brass',
  LEAD = 'Lead',
  STAINLESS_STEEL = 'Stainless Steel',
  OTHER = 'Other',
  UNKNOWN = 'Unknown'
}

export interface EstimationResult {
  material: MaterialType;
  weight: number;
  pricePerLb: number;
  totalValue: number;
}

export interface ChatMessage {
  role: 'user' | 'model';
  text: string;
}

export interface PickupDetails {
  address?: string;
  container_size?: string;
  special_instructions?: string;
  requested_date?: string;
}

export interface PickupFormData {
  name: string;
  phone: string;
  notes: string;
}

export interface Service {
  title: string;
  description: string;
  icon: React.ReactNode;
  action?: () => void;
  isActionable: boolean;
}
