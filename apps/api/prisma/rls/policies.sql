-- =============================================================================
-- ATS-Express — Políticas RLS (Etapa 0)
--
-- Estrategia: "NestJS primario + RLS como defensa en profundidad".
--   - El backend (NestJS/Prisma) se conecta con el SERVICE ROLE de Supabase,
--     que BYPASSEA RLS por diseño. La frontera real de tenant la ponen los
--     guards por businessId en NestJS.
--   - RLS aquí cumple dos funciones:
--       1) DENY BY DEFAULT: al habilitar RLS sin policies, ninguna tabla queda
--          accesible para las keys anon/authenticated (defensa en profundidad).
--       2) POLICIES FINAS solo donde el FRONT lee directo por Supabase Realtime:
--          rider_locations, orders, deliveries (tracking en vivo).
--
-- Aplicar DESPUÉS de `prisma migrate` (este archivo no lo gestiona Prisma).
--   psql:               \i policies.sql
--   o vía Prisma:       npx prisma db execute --file prisma/rls/policies.sql
--
-- Idempotente: se puede re-ejecutar sin romper (DROP POLICY IF EXISTS + CREATE).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1) Helpers (SECURITY DEFINER para no disparar RLS recursivo sobre profiles)
-- -----------------------------------------------------------------------------

-- Rol del usuario autenticado (texto del enum UserRole), o NULL si no existe.
create or replace function public.current_user_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role::text from public.profiles where id = auth.uid();
$$;

-- businessId del usuario autenticado (dueño/staff de negocio), o NULL.
create or replace function public.current_business_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select "businessId" from public.profiles where id = auth.uid();
$$;

-- Rider.id del usuario autenticado (si es RIDER), o NULL.
create or replace function public.current_rider_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select id from public.riders where "profileId" = auth.uid();
$$;

-- ¿Es admin de plataforma (ATS_ADMIN o SUPER_ADMIN)?
create or replace function public.is_platform_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select role in ('ATS_ADMIN','SUPER_ADMIN') from public.profiles where id = auth.uid()),
    false
  );
$$;

-- -----------------------------------------------------------------------------
-- 2) Habilitar RLS en TODAS las tablas (deny by default).
--    Las tablas sin policy quedan inaccesibles para anon/authenticated.
--    El service role (NestJS) bypassa RLS y sigue operando normal.
-- -----------------------------------------------------------------------------

alter table public.zones                 enable row level security;
alter table public.profiles              enable row level security;
alter table public.businesses            enable row level security;
alter table public.business_hours        enable row level security;
alter table public.subscriptions         enable row level security;
alter table public.categories            enable row level security;
alter table public.products              enable row level security;
alter table public.product_variants      enable row level security;
alter table public.modifier_groups       enable row level security;
alter table public.modifiers             enable row level security;
alter table public.customer_addresses    enable row level security;
alter table public.orders                enable row level security;
alter table public.order_items           enable row level security;
alter table public.order_item_modifiers  enable row level security;
alter table public.order_status_history  enable row level security;
alter table public.payments              enable row level security;
alter table public.riders                enable row level security;
alter table public.rider_locations       enable row level security;
alter table public.deliveries            enable row level security;
alter table public.reviews               enable row level security;

-- -----------------------------------------------------------------------------
-- 3) Policies finas para acceso DIRECTO del front vía Supabase Realtime.
--    Solo SELECT (lectura de tracking/estados) salvo rider_locations, donde el
--    rider escribe su propia ubicación. Toda otra escritura pasa por NestJS.
-- -----------------------------------------------------------------------------

-- ====== orders ===============================================================
-- El front se suscribe a cambios de estado del pedido en vivo.

drop policy if exists orders_select_customer on public.orders;
create policy orders_select_customer on public.orders
  for select to authenticated
  using ("customerId" = auth.uid());

drop policy if exists orders_select_business on public.orders;
create policy orders_select_business on public.orders
  for select to authenticated
  using (
    "businessId" = public.current_business_id()
    and public.current_user_role() in ('BUSINESS_OWNER','BUSINESS_STAFF')
  );

drop policy if exists orders_select_rider on public.orders;
create policy orders_select_rider on public.orders
  for select to authenticated
  using (
    exists (
      select 1 from public.deliveries d
      where d."orderId" = orders.id
        and d."riderId" = public.current_rider_id()
    )
  );

drop policy if exists orders_select_admin on public.orders;
create policy orders_select_admin on public.orders
  for select to authenticated
  using (public.is_platform_admin());

-- ====== deliveries ===========================================================
-- Estado de la asignación / etapas del despacho en vivo.

drop policy if exists deliveries_select_rider on public.deliveries;
create policy deliveries_select_rider on public.deliveries
  for select to authenticated
  using ("riderId" = public.current_rider_id());

drop policy if exists deliveries_select_business on public.deliveries;
create policy deliveries_select_business on public.deliveries
  for select to authenticated
  using (
    exists (
      select 1 from public.orders o
      where o.id = deliveries."orderId"
        and o."businessId" = public.current_business_id()
    )
  );

drop policy if exists deliveries_select_customer on public.deliveries;
create policy deliveries_select_customer on public.deliveries
  for select to authenticated
  using (
    exists (
      select 1 from public.orders o
      where o.id = deliveries."orderId"
        and o."customerId" = auth.uid()
    )
  );

drop policy if exists deliveries_select_admin on public.deliveries;
create policy deliveries_select_admin on public.deliveries
  for select to authenticated
  using (public.is_platform_admin());

-- ====== rider_locations ======================================================
-- Núcleo del tracking en vivo (1 fila por rider, upsert desde la app del rider).

-- Lectura: el propio rider, el negocio dueño del pedido, el cliente del pedido
-- (mientras esté activo), y los admins.
drop policy if exists rider_locations_select_rider on public.rider_locations;
create policy rider_locations_select_rider on public.rider_locations
  for select to authenticated
  using ("riderId" = public.current_rider_id());

drop policy if exists rider_locations_select_business on public.rider_locations;
create policy rider_locations_select_business on public.rider_locations
  for select to authenticated
  using (
    exists (
      select 1
      from public.deliveries d
      join public.orders o on o.id = d."orderId"
      where d."riderId" = rider_locations."riderId"
        and o."businessId" = public.current_business_id()
        and d.status not in ('DELIVERED','CANCELLED')
    )
  );

drop policy if exists rider_locations_select_customer on public.rider_locations;
create policy rider_locations_select_customer on public.rider_locations
  for select to authenticated
  using (
    exists (
      select 1
      from public.deliveries d
      join public.orders o on o.id = d."orderId"
      where d."riderId" = rider_locations."riderId"
        and o."customerId" = auth.uid()
        and d.status not in ('DELIVERED','CANCELLED')
    )
  );

drop policy if exists rider_locations_select_admin on public.rider_locations;
create policy rider_locations_select_admin on public.rider_locations
  for select to authenticated
  using (public.is_platform_admin());

-- Escritura: el rider actualiza/crea SOLO su propia fila de ubicación.
drop policy if exists rider_locations_insert_own on public.rider_locations;
create policy rider_locations_insert_own on public.rider_locations
  for insert to authenticated
  with check ("riderId" = public.current_rider_id());

drop policy if exists rider_locations_update_own on public.rider_locations;
create policy rider_locations_update_own on public.rider_locations
  for update to authenticated
  using ("riderId" = public.current_rider_id())
  with check ("riderId" = public.current_rider_id());

-- =============================================================================
-- FIN. Todas las demás tablas quedan en deny-all para anon/authenticated:
-- el acceso ocurre exclusivamente vía NestJS (service role), que bypassa RLS.
-- Cuando algún front necesite leer otra tabla directo de Supabase, se agregan
-- aquí sus policies finas siguiendo el mismo patrón.
-- =============================================================================
