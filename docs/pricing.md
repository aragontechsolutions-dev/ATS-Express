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

## Notas de implementación

- Enum `SubscriptionPlan` = `FREE | PRO | PREMIUM` (ver `schema.prisma`).
- El gating de features por plan se aplica en NestJS (guards/policies por
  `subscription.plan`); el front solo oculta/muestra.
- El tope de pedidos del plan FREE se controla en el módulo Orders.
- Precios y topes son parámetros de negocio: dejarlos configurables, no
  hardcodeados en la lógica.
