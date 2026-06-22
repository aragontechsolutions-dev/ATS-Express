# Planes de suscripción — ATS-Express

> Modelo SaaS white-label para locales que **ya tienen sus propios repartidores**.
> ATS factura una **suscripción mensual** al local; no opera flota ni maneja los
> fondos del pedido.

## Contexto que define la estrategia

- Los locales hoy reciben pedidos por **WhatsApp / llamada** → caos, errores,
  pedidos perdidos, sin registro. **Ese es el dolor a resolver.**
- El **cobro ya está resuelto**: efectivo + POS propio del rider contraentrega.
  Por eso el **cobro online NO es el gancho**, es un upsell del plan superior.

**Tesis de monetización:** plan de entrada **gratis** que reemplaza el WhatsApp
(adopción), se monetiza con **tracking + gestión de riders + reportes** (Pro), y
arriba con **cobro online + automatización WhatsApp + multi-sucursal** (Premium).

## Decisiones tomadas

- **Plan Inicial: GRATIS** (freemium, con tope de pedidos/mes).
- **Precios** (UYU/mes, ajustables): Pro **~$2.900** · Premium **~$5.900**.
- **Cobro online** (MercadoPago del local): **exclusivo de Premium**.

## Planes

| Funcionalidad | 🟢 Inicial (FREE) | 🔵 Pro (~$2.900) | 🟣 Premium (~$5.900) |
|---|:---:|:---:|:---:|
| Carta / menú online (link white-label) | ✅ | ✅ | ✅ |
| Recepción de pedidos centralizada (adiós WhatsApp) | ✅ | ✅ | ✅ |
| Notificación de nuevo pedido | ✅ | ✅ | ✅ |
| Cobro efectivo / POS (como hoy) | ✅ | ✅ | ✅ |
| Gestión de riders + asignación | — | ✅ | ✅ |
| ⭐ Tracking en vivo para el cliente | — | ✅ | ✅ |
| Estados de pedido completos + historial | — | ✅ | ✅ |
| Variantes, modificadores, control de stock | limitado | ✅ | ✅ |
| Reportes | básico | ventas / top productos | avanzado / analytics |
| Usuarios / staff | 1 | varios | varios |
| Horarios + zonas de cobertura + fee por zona | — | ✅ | ✅ |
| ⭐ Cobro online (MercadoPago del local) | — | — | ✅ |
| ⭐ WhatsApp automático (confirmación/estados) | — | — | ✅ |
| Multi-sucursal | — | — | ✅ |
| Soporte | email/comunidad | email | prioritario |
| Tope de pedidos / mes | sí (bajo) | alto / ilimitado | ilimitado |

## Features estrella (el "por qué subo de plan")

- **Inicial → Pro:** **tracking en vivo** (el cliente ve al rider en el mapa) +
  organizar a los repartidores propios. Es el mayor "wow" y lo que ningún grupo
  de WhatsApp ofrece.
- **Pro → Premium:** **cobro online** (cobrar al hacer el pedido, sin depender del
  POS) + **WhatsApp automático** + **multi-sucursal**.

## Add-ons (ingresos extra sin inflar los planes)

- Paquete de mensajes WhatsApp.
- Riders adicionales por encima del límite del plan.
- Dominio propio para la carta online.

## Promo de lanzamiento — Primeros 10 clientes

> Es una **promoción**, NO un plan nuevo. Objetivo: conseguir los primeros 10
> locales lo más rápido posible y generar casos de éxito.

**Oferta:** **1 mes de Premium gratis**. Prueban el producto al full (incluido
tracking en vivo y cobro online), y recién después eligen plan.

**Reglas acordadas:**

1. **Al terminar el mes → baja automática a FREE** si no eligen plan ni cargan
   pago. No se suspende el servicio: conservan local y datos, y quedan como
   lead caliente para reconquistar a Pro/Premium.
2. **Cobro online sigue exclusivo de Premium.** Para evitar el "downgrade
   shock", a estos 10 se les ofrece una **rebaja de fidelidad: Premium con
   descuento por 3 meses adicionales** (precio promo a definir, ej. ~$4.900 en
   vez de ~$5.900). Solo para este grupo inicial.
3. **Contrapartida:** un **testimonio / caso de éxito** utilizable para vender a
   los siguientes locales.

**Expectativa realista:** no asumir que >50% se queda en Premium. Muchos bajarán
a **Pro** (que para ellos ya es enorme vs. WhatsApp) — eso **igual es un cliente
que paga**. El éxito se mide en "siguen pagando algo", idealmente Premium.

**Modelado en el sistema (sin features nuevas):**

- `Subscription`: `plan = PREMIUM`, `status = TRIAL`, con fecha de fin de trial.
- Al vencer: si no hay conversión, transición a `plan = FREE`, `status = ACTIVE`.
- La rebaja de fidelidad se modela como precio promocional en la suscripción
  (monto + vigencia 3 meses), no como otro plan.
- Marcar estos locales como "cohorte de lanzamiento" (flag/tag) para poder
  segmentarlos en reportes y aplicarles el precio promo.

## Notas de implementación

- Enum `SubscriptionPlan` = `FREE | PRO | PREMIUM` (ver `schema.prisma`).
- El gating de features por plan se aplica en NestJS (guards/policies por
  `subscription.plan`); el front solo oculta/muestra.
- El tope de pedidos del plan FREE se controla en el módulo Orders.
- Precios y topes son parámetros de negocio: dejarlos configurables, no
  hardcodeados en la lógica.
