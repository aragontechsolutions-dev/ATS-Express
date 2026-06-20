# Arquitectura — ATS-Express (Sistema de Delivery Híbrido)

> **Etapa 0 — Documento de arquitectura.**
> Monolito modular en NestJS, multi-tenancy "bridge model", Supabase (Postgres + RLS + Realtime).
> Autor del proyecto: Osmel — Aragon Tech Solutions (ATS), Maldonado, Uruguay.

---

## 1. Visión general

Un único backend NestJS (monolito modular) expone una sola API que consumen
**cuatro frontends**: web de pedido del cliente, app móvil del cliente, app del
rider, y los paneles web (negocio + admin ATS). La diferenciación entre negocios
con flota propia y el marketplace de ATS se hace **a nivel de datos**
(`operationMode` + `businessId`), no de infraestructura separada.

```mermaid
graph TB
  subgraph Clientes["Frontends"]
    WebCli["Web Cliente<br/>(React + Vite)"]
    AppCli["App Cliente<br/>(RN + Expo)"]
    AppRider["App Rider<br/>(RN + Expo)"]
    PanelNeg["Panel Negocio<br/>(React + Vite)"]
    PanelATS["Admin ATS<br/>(React + Vite)"]
  end

  subgraph Backend["Backend — NestJS (monolito modular) @ Render"]
    API["API REST"]
    Modulos["Módulos de dominio"]
  end

  subgraph Supabase["Supabase"]
    PG[("Postgres + RLS")]
    Realtime["Realtime"]
    Auth["Auth"]
    Storage["Storage"]
  end

  subgraph Externos["Servicios externos"]
    MP["MercadoPago<br/>Checkout API"]
    Mapbox["Mapbox"]
    WA["WhatsApp API<br/>(reuso ATS)"]
    Cron["cron-job.org<br/>(keep-alive)"]
  end

  WebCli & AppCli & AppRider & PanelNeg & PanelATS --> API
  API --> Modulos
  Modulos -->|"Prisma (service role,<br/>bypassa RLS)"| PG
  Modulos --> MP
  Modulos --> WA
  Modulos --> Storage

  AppRider & AppCli & WebCli & PanelNeg & PanelATS -.->|"Realtime / RLS<br/>(tracking en vivo)"| Realtime
  Realtime -.-> PG
  AppCli & AppRider -.-> Auth
  AppRider & WebCli --> Mapbox
  Cron -->|"GET /health c/10min"| API
```

**Frontera de seguridad (multi-tenancy):**
- **Primaria:** NestJS. El backend se conecta con el **service role** de Supabase
  (bypassa RLS) y aísla por `businessId` mediante guards/policies de aplicación.
- **Defensa en profundidad:** RLS en Postgres (deny-all) + policies finas solo en
  las tablas que el front lee directo por Realtime (`orders`, `deliveries`,
  `rider_locations`). Ver `apps/api/prisma/rls/policies.sql`.

---

## 2. Módulos del monolito

Cada módulo vive en su propia carpeta con límites claros, para poder extraerlo a
un servicio independiente si el proyecto escala, sin reescribir la lógica.

```mermaid
graph TD
  Auth["Auth<br/><i>login/registro multi-rol</i>"]
  Business["Business (Tenant)<br/><i>operationMode, zona, suscripción, horarios</i>"]
  Catalog["Catalog<br/><i>menú, productos, variantes, modificadores</i>"]
  Orders["Orders (OMS)<br/><i>ciclo de vida + SAGA de checkout</i>"]
  Dispatch["Dispatch<br/><i>asignación de rider según operationMode</i>"]
  Riders["Riders<br/><i>propios (businessId) o pool ATS (null)</i>"]
  Tracking["Geolocation / Tracking<br/><i>ubicación en vivo, ETA</i>"]
  Payments["Payments<br/><i>MercadoPago + efectivo/contraentrega</i>"]
  Notifications["Notifications<br/><i>push, WhatsApp, email</i>"]
  AdminPanel["Admin Panel (ATS)<br/><i>negocios, suscripciones, riders ATS, zonas</i>"]
  BusinessPanel["Business Panel<br/><i>recepción de pedidos, menú, reportes</i>"]
  Reports["Reports / Analytics<br/><i>(etapa posterior)</i>"]

  Auth --> Business
  Auth --> Riders
  Business --> Catalog
  Catalog --> Orders
  Orders --> Payments
  Orders --> Dispatch
  Dispatch --> Riders
  Dispatch --> Tracking
  Orders --> Notifications
  Dispatch --> Notifications
  Tracking --> Riders
  AdminPanel --> Business
  AdminPanel --> Riders
  BusinessPanel --> Orders
  BusinessPanel --> Catalog
  Reports --> Orders

  classDef nucleo fill:#1f6feb,color:#fff,stroke:#1f6feb;
  classDef futuro fill:#30363d,color:#8b949e,stroke:#30363d;
  class Orders,Business,Catalog nucleo;
  class Reports futuro;
```

| Módulo | Responsabilidad | MVP |
|---|---|---|
| **Auth** | Login/registro multi-rol (un rol por usuario) | Supabase Auth + tabla `Profile` |
| **Business** | Alta de negocios, `operationMode`, zona, suscripción, horarios | ✅ núcleo |
| **Catalog** | Menú: productos, categorías, variantes, modificadores, stock | ✅ |
| **Orders (OMS)** | Ciclo de vida del pedido, estados, SAGA de checkout | ✅ núcleo |
| **Dispatch** | Asignación de rider según `operationMode` | Manual en MVP |
| **Riders** | Riders propios o de ATS | ✅ |
| **Tracking** | Ubicación en vivo, ETA | Supabase Realtime |
| **Payments** | MercadoPago + efectivo/contraentrega | ✅ |
| **Notifications** | Push, WhatsApp, email | Etapa 4 |
| **Admin Panel (ATS)** | Negocios afiliados, suscripciones, riders ATS, zonas | Etapa 3 |
| **Business Panel** | Recepción de pedidos, menú, reportes | ✅ |
| **Reports** | Métricas de pedidos, ventas, performance | Etapa posterior |

---

## 3. Ciclo de vida del pedido

```mermaid
stateDiagram-v2
  [*] --> PENDING_PAYMENT: checkout
  PENDING_PAYMENT --> ACCEPTED: pago confirmado / efectivo
  PENDING_PAYMENT --> CANCELLED: pago falla / timeout
  ACCEPTED --> IN_PREPARATION: negocio acepta
  IN_PREPARATION --> READY_FOR_PICKUP: pedido listo
  READY_FOR_PICKUP --> AT_RESTAURANT: rider llega al local
  AT_RESTAURANT --> PICKED_UP: rider retira
  PICKED_UP --> ON_THE_WAY: en trayecto
  ON_THE_WAY --> DELIVERED: rider entrega
  DELIVERED --> [*]
  ACCEPTED --> CANCELLED
  IN_PREPARATION --> CANCELLED
  READY_FOR_PICKUP --> CANCELLED
  CANCELLED --> [*]
```

### Ramificación del Dispatch según `operationMode`

```mermaid
flowchart TD
  A["Pedido listo para asignar<br/>(READY_FOR_PICKUP)"] --> B{"operationMode<br/>del negocio"}
  B -->|OWN_FLEET| C["Lista riders con<br/>businessId = pedido.businessId"]
  B -->|MARKETPLACE_FLEET| D["Lista riders del pool ATS<br/>(businessId IS NULL)<br/>filtrados por zona/disponibilidad"]
  B -->|HYBRID| E["1° intenta OWN_FLEET"]
  E -->|sin rider| D
  C --> F["Asignación MANUAL (MVP)<br/>negocio o admin ATS elige"]
  D --> F
  F --> G["Delivery.status = ASSIGNED"]

  classDef futuro fill:#30363d,color:#8b949e,stroke:#30363d;
  class E futuro;
```

> En el MVP la asignación es **manual** (negocio para OWN_FLEET, admin ATS para
> MARKETPLACE_FLEET). `HYBRID` está previsto en el modelo de datos pero **no
> operativo**. La automatización por proximidad queda para etapa posterior.

---

## 4. SAGA de checkout (orquestada en Orders)

El checkout coordina varios pasos sin transacciones distribuidas. Cada paso tiene
su **acción de compensación** si un paso posterior falla.

```mermaid
sequenceDiagram
  autonumber
  participant C as Cliente
  participant O as Orders (SAGA orquestador)
  participant Cat as Catalog
  participant Pay as Payments
  participant N as Notifications

  C->>O: checkout(pedido)
  O->>Cat: 1. Reservar disponibilidad (stock/menú)
  alt sin stock
    Cat-->>O: falla
    O-->>C: pedido rechazado
  else ok
    Cat-->>O: reservado
    O->>Pay: 2. Cobrar (MercadoPago) o marcar CASH
    alt pago falla
      Pay-->>O: falla
      O->>Cat: COMPENSA: liberar reserva de stock
      O-->>C: pago rechazado (CANCELLED)
    else pago ok / efectivo
      Pay-->>O: PAID / pendiente cobro al entregar
      O->>O: 3. Estado = ACCEPTED
      O->>N: 4. Notificar al negocio
      Note over O: Dispatch (asignación de rider) ocurre luego,<br/>como paso operativo separado (manual en MVP).
      O-->>C: pedido confirmado
    end
  end
```

**Compensaciones por paso:**

| Paso | Falla | Compensación |
|---|---|---|
| Reservar stock | sin disponibilidad | abortar, no se cobra |
| Cobrar | pago rechazado | liberar reserva de stock → `CANCELLED` |
| Asignar rider (post-checkout) | sin rider disponible | notificar al negocio, reintentar o cancelar |

> En el MVP (Etapa 1) el pago es **solo efectivo/contraentrega**, por lo que el
> paso 2 solo registra el método. MercadoPago se integra en Etapa 2 y ahí la SAGA
> ejerce la compensación de pago real.

---

## 5. Tracking en vivo (Supabase Realtime)

```mermaid
sequenceDiagram
  participant R as App Rider
  participant SB as Supabase
  participant Cli as App/Web Cliente
  participant Neg as Panel Negocio

  R->>SB: upsert rider_locations (lat/lng)<br/>(RLS: solo su propia fila)
  SB-->>Cli: push cambio (RLS: solo su pedido activo)
  SB-->>Neg: push cambio (RLS: riders de sus pedidos)
  Note over SB: Estados de orders/deliveries también<br/>se propagan por Realtime con RLS fino.
```

El tracking usa `rider_locations` (1 fila por rider, upsert desde la app). El
front se suscribe vía Supabase Realtime; las RLS finas garantizan que cada quien
solo ve lo que le corresponde, **mientras el delivery está activo**.

---

## 6. Stack y despliegue

| Capa | Tecnología | Despliegue |
|---|---|---|
| Backend | NestJS + Prisma v5 (monorepo `apps/api`) | **Render** |
| DB / Auth / Storage / Realtime | Supabase (Postgres + RLS) | Supabase |
| Web cliente + paneles | React + Vite + Tailwind (`apps/web`, `apps/admin`) | **Vercel** |
| Mobile cliente + rider | React Native + Expo → EAS Build (`apps/mobile`) | EAS / stores |
| Pagos | MercadoPago Checkout API | — |
| Mapas | Mapbox | — |
| Keep-alive | `GET /health` (sin tocar DB) golpeado por cron-job.org c/10 min | — |

**Estructura del monorepo (pnpm + Turborepo):**

```
ATS-Express/
├── apps/
│   ├── api/        # NestJS (monolito modular) + Prisma
│   │   └── prisma/
│   │       ├── schema.prisma
│   │       └── rls/policies.sql
│   ├── web/        # Web cliente (React + Vite)
│   ├── admin/      # Panel negocio + Admin ATS (React + Vite)
│   └── mobile/     # App cliente + rider (RN + Expo)
├── packages/
│   └── shared/     # tipos compartidos + cliente Prisma
└── docs/
    └── architecture.md
```

---

## 7. Etapas de desarrollo

| Etapa | Contenido | Estado |
|---|---|---|
| **0** | Schema Prisma + RLS + arquitectura | ✅ **completada** |
| 1 | MVP núcleo: Catalog + Orders + Business Panel + cliente básico, solo efectivo | ⏭️ siguiente |
| 2 | MercadoPago + Dispatch manual + Riders + estados completos + tracking | |
| 3 | Marketplace: Admin ATS + suscripciones + pool de riders | |
| 4 | Notificaciones (push/WhatsApp) + reportes + `/health` keep-alive | |
| 5 | Hardening: RLS, rate limiting, observabilidad, Dispatch automático, HYBRID real | |
