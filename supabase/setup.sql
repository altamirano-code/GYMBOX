-- =====================================================================
--  GymBox · Supabase
--  Pega TODO este archivo en Supabase → SQL Editor → New query → Run.
--  Se puede volver a ejecutar sin romper nada.
-- =====================================================================

-- 1) Tabla de productos ------------------------------------------------
create table if not exists public.productos (
  id                text primary key default gen_random_uuid()::text,
  nombre            text        not null,
  categoria         text        not null,          -- guantes | vendas | chaleco-peso | chaleco-termico
  precio            numeric(10,2) not null check (precio >= 0),
  precio_aproximado boolean     not null default false,  -- muestra "Precio aproximado, varía según la talla"
  opcion            text,                          -- nombre de la opción: Onzas, Talla, Peso, Color...
  valores           text[]      not null default '{}',   -- p. ej. {12 oz,14 oz,16 oz}
  defecto           text,                          -- valor seleccionado al abrir el producto
  precios           jsonb,                         -- opcional, precio por valor: {"5 kg":700,"10 kg":900}
  descripcion       text        not null default '',
  imagen_url        text        not null default '',
  activo            boolean     not null default true,   -- false = oculto en la tienda
  orden             integer     not null default 0,      -- menor número aparece primero
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create or replace function public.tocar_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;

drop trigger if exists productos_updated_at on public.productos;
create trigger productos_updated_at before update on public.productos
  for each row execute function public.tocar_updated_at();

-- 2) Quién puede administrar ---------------------------------------------
create table if not exists public.admins (
  email text primary key
);

create or replace function public.es_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.admins
    where lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;

-- 3) Seguridad (RLS) -----------------------------------------------------
alter table public.productos enable row level security;
alter table public.admins    enable row level security;

drop policy if exists "Ver productos activos"   on public.productos;
drop policy if exists "Admins agregan"          on public.productos;
drop policy if exists "Admins actualizan"       on public.productos;
drop policy if exists "Admins eliminan"         on public.productos;
drop policy if exists "Admin ve su registro"    on public.admins;

create policy "Ver productos activos" on public.productos
  for select using (activo or public.es_admin());
create policy "Admins agregan" on public.productos
  for insert to authenticated with check (public.es_admin());
create policy "Admins actualizan" on public.productos
  for update to authenticated using (public.es_admin()) with check (public.es_admin());
create policy "Admins eliminan" on public.productos
  for delete to authenticated using (public.es_admin());
create policy "Admin ve su registro" on public.admins
  for select to authenticated using (lower(email) = lower(auth.jwt() ->> 'email'));

-- 4) Bucket para fotos de productos ---------------------------------------
insert into storage.buckets (id, name, public)
values ('productos', 'productos', true)
on conflict (id) do update set public = true;

drop policy if exists "Admins ven fotos"        on storage.objects;
drop policy if exists "Admins suben fotos"      on storage.objects;
drop policy if exists "Admins cambian fotos"    on storage.objects;
drop policy if exists "Admins borran fotos"     on storage.objects;

create policy "Admins ven fotos" on storage.objects
  for select to authenticated using (bucket_id = 'productos' and public.es_admin());
create policy "Admins suben fotos" on storage.objects
  for insert to authenticated with check (bucket_id = 'productos' and public.es_admin());
create policy "Admins cambian fotos" on storage.objects
  for update to authenticated using (bucket_id = 'productos' and public.es_admin());
create policy "Admins borran fotos" on storage.objects
  for delete to authenticated using (bucket_id = 'productos' and public.es_admin());

-- 5) Administrador ---------------------------------------------------------
--    CAMBIA el correo si el dashboard lo va a usar otra cuenta.
--    Debe ser el MISMO correo del usuario que crees en Authentication → Users.
insert into public.admins (email) values ('gymboxcarloszarate@gmail.com')
on conflict (email) do nothing;

-- 6) Productos iniciales (los mismos que tiene la página hoy) --------------
--    Las fotos apuntan a la carpeta img/ de la página; las nuevas se suben desde el dashboard.
insert into public.productos (id, nombre, categoria, precio, precio_aproximado, opcion, valores, defecto, precios, descripcion, imagen_url, orden) values
  ('guantes-adp-elite2-azul', 'Guantes ADP Elite 2 · Azul', 'guantes', 1450, true, 'Onzas',
   '{"12 oz","14 oz","16 oz"}', '14 oz', null,
   'Guantes de agujeta modelo Elite 2 en color azul. Para costal, manoplas y sparring.', 'img/guantes-adp-elite2-azul.jpg', 1),
  ('guantes-adp-negro', 'Guantes ADP · Negro y plata', 'guantes', 1450, true, 'Onzas',
   '{"12 oz","14 oz","16 oz"}', '14 oz', null,
   'Guantes de agujeta en negro con palma plateada. Para costal, manoplas y sparring.', 'img/guantes-adp-negro.jpg', 2),
  ('guantes-newsport-esqueleto', 'Guantes New Sport · Esqueleto', 'guantes', 650, true, 'Onzas',
   '{"10 oz","12 oz","14 oz","16 oz"}', '12 oz', null,
   'Guantes con cierre de velcro, fáciles de poner sin ayuda. Diseño de mano de esqueleto. Ideales para empezar.', 'img/guantes-newsport-esqueleto.jpg', 3),
  ('vendas-box', 'Vendas para box', 'vendas', 150, false, 'Color',
   '{"Negro","Rojo","Blanco","Azul"}', 'Negro', null,
   'Par de vendas para proteger muñecas y nudillos. Se colocan debajo de los guantes en cada entrenamiento.', '', 4),
  ('chaleco-peso', 'Chaleco con peso', 'chaleco-peso', 900, true, 'Peso',
   '{"5 kg","10 kg","15 kg"}', '10 kg', '{"5 kg":700,"10 kg":900,"15 kg":1150}',
   'Agrega carga a tus caminatas, sentadillas, lagartijas y circuitos de entrenamiento funcional.', '', 5),
  ('chaleco-termico', 'Chaleco térmico', 'chaleco-termico', 450, true, 'Talla',
   '{"CH","M","G","XG"}', 'M', null,
   'Chaleco de neopreno que aumenta la sudoración durante el cardio y el trabajo de box.', '', 6)
on conflict (id) do nothing;
