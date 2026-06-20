/**
 * Tipos y enums compartidos entre backend (NestJS) y frontends (web/mobile).
 * Espejan los enums del schema Prisma para evitar duplicar literales en el front
 * sin obligarlo a importar @prisma/client.
 *
 * Mantener sincronizado con apps/api/prisma/schema.prisma.
 */

export const UserRole = {
  CUSTOMER: 'CUSTOMER',
  BUSINESS_OWNER: 'BUSINESS_OWNER',
  BUSINESS_STAFF: 'BUSINESS_STAFF',
  RIDER: 'RIDER',
  ATS_ADMIN: 'ATS_ADMIN',
  SUPER_ADMIN: 'SUPER_ADMIN',
} as const;
export type UserRole = (typeof UserRole)[keyof typeof UserRole];

export const OrderStatus = {
  PENDING_PAYMENT: 'PENDING_PAYMENT',
  ACCEPTED: 'ACCEPTED',
  IN_PREPARATION: 'IN_PREPARATION',
  READY_FOR_PICKUP: 'READY_FOR_PICKUP',
  AT_RESTAURANT: 'AT_RESTAURANT',
  PICKED_UP: 'PICKED_UP',
  ON_THE_WAY: 'ON_THE_WAY',
  DELIVERED: 'DELIVERED',
  CANCELLED: 'CANCELLED',
} as const;
export type OrderStatus = (typeof OrderStatus)[keyof typeof OrderStatus];

export const FulfillmentType = {
  DELIVERY: 'DELIVERY',
  PICKUP: 'PICKUP',
} as const;
export type FulfillmentType =
  (typeof FulfillmentType)[keyof typeof FulfillmentType];

export const PaymentMethod = {
  MERCADOPAGO: 'MERCADOPAGO',
  CASH: 'CASH',
} as const;
export type PaymentMethod = (typeof PaymentMethod)[keyof typeof PaymentMethod];

export const PaymentStatus = {
  PENDING: 'PENDING',
  AUTHORIZED: 'AUTHORIZED',
  PAID: 'PAID',
  FAILED: 'FAILED',
  REFUNDED: 'REFUNDED',
  CANCELLED: 'CANCELLED',
} as const;
export type PaymentStatus = (typeof PaymentStatus)[keyof typeof PaymentStatus];

export const RiderStatus = {
  OFFLINE: 'OFFLINE',
  AVAILABLE: 'AVAILABLE',
  BUSY: 'BUSY',
} as const;
export type RiderStatus = (typeof RiderStatus)[keyof typeof RiderStatus];

export const DeliveryStatus = {
  PENDING_ASSIGNMENT: 'PENDING_ASSIGNMENT',
  ASSIGNED: 'ASSIGNED',
  ACCEPTED_BY_RIDER: 'ACCEPTED_BY_RIDER',
  AT_RESTAURANT: 'AT_RESTAURANT',
  PICKED_UP: 'PICKED_UP',
  ON_THE_WAY: 'ON_THE_WAY',
  DELIVERED: 'DELIVERED',
  CANCELLED: 'CANCELLED',
} as const;
export type DeliveryStatus =
  (typeof DeliveryStatus)[keyof typeof DeliveryStatus];

export const SubscriptionStatus = {
  TRIAL: 'TRIAL',
  ACTIVE: 'ACTIVE',
  PAST_DUE: 'PAST_DUE',
  CANCELLED: 'CANCELLED',
} as const;
export type SubscriptionStatus =
  (typeof SubscriptionStatus)[keyof typeof SubscriptionStatus];

export const SubscriptionProvider = {
  MANUAL: 'MANUAL',
  MERCADOPAGO: 'MERCADOPAGO',
} as const;
export type SubscriptionProvider =
  (typeof SubscriptionProvider)[keyof typeof SubscriptionProvider];

export const SubscriptionPlan = {
  FREE: 'FREE',
  PRO: 'PRO',
  PREMIUM: 'PREMIUM',
} as const;
export type SubscriptionPlan =
  (typeof SubscriptionPlan)[keyof typeof SubscriptionPlan];

/** Localidades de cobertura inicial (Maldonado, UY). */
export const COVERAGE_ZONES = [
  'Maldonado',
  'San Carlos',
  'Punta del Este',
  'Punta Ballena',
  'La Barra',
  'Piriápolis',
  'Balneario Buenos Aires',
  'Pan de Azúcar',
] as const;
export type CoverageZone = (typeof COVERAGE_ZONES)[number];
