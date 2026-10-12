-- =====================================================================
-- WEEK 3 + 4: SAVING ORDERS AND PAYMENTS IN SUPABASE
--
-- Run this ONCE in the Supabase SQL Editor, after the menu_items setup.
-- It is safe to run again, and safe to run on a shop that already has the
-- Week 3 version: it adds the payment columns without touching existing orders.
--
-- BEFORE YOU RUN IT: replace PASTE-OWNER-UID in step 1 below (one place only)
-- with the owner's User UID from Authentication > Users. Keep the quotes
-- and the ::uuid after it.
--
-- How the safety works, in plain words:
--   * The public can NOT read, add, change or delete anything in "orders".
--   * The only way a customer can create an order is the place_order()
--     function. It checks every field, looks up the prices itself from
--     menu_items (so a customer cannot change a price), and refuses sold-out
--     items, orders below the minimum, and too many orders in an hour.
--   * Only the owner (is_owner) can read and update orders.
--   * Payments: customers choose UPI, cash on delivery (delivery orders only)
--     or pay at pickup (pickup orders only). The function checks the choice,
--     applies free delivery and the cash-on-delivery limit itself.
--
-- AFTER RUNNING IT, set the shop's UPI ID once (Table Editor > shop_settings,
-- column upi_id) or run:   update shop_settings set upi_id = 'yourshop@upi';
-- Without a UPI ID, UPI is not offered to customers.
-- =====================================================================


-- 1. Who is the owner? (the ONLY place the owner's User UID is pasted)
create or replace function is_owner()
returns boolean
language sql
stable
as $$
  select coalesce((select auth.uid()) = '99b05c9c-8039-4509-82a0-b15cee92164d'::uuid, false)
$$;


-- 2. Shop settings: one row the server uses when checking orders.
--    Keep these equal to minOrder and deliveryCharge in index.html CONFIG.
create table if not exists shop_settings (
  id boolean primary key default true check (id),
  accepting_orders boolean not null default true,
  min_order integer not null default 300 check (min_order >= 0),
  delivery_charge integer not null default 50 check (delivery_charge >= 0)
);

insert into shop_settings default values on conflict do nothing;

alter table shop_settings enable row level security;
revoke insert, update, delete on shop_settings from anon;   -- the public can only read

drop policy if exists "Anyone can read shop settings" on shop_settings;
create policy "Anyone can read shop settings"
  on shop_settings for select using (true);

drop policy if exists "Owner can edit shop settings" on shop_settings;
create policy "Owner can edit shop settings"
  on shop_settings for update to authenticated
  using ((select is_owner())) with check ((select is_owner()));


-- 3. Orders
create table if not exists orders (
  id bigint generated always as identity primary key,
  order_ref text not null unique,
  client_token text not null unique,
  created_at timestamptz not null default now(),
  status text not null default 'new'
    check (status in ('new', 'confirmed', 'ready', 'completed', 'cancelled')),
  customer_name text not null check (char_length(customer_name) between 1 and 60),
  customer_phone text not null check (customer_phone ~ '^[6-9][0-9]{9}$'),
  order_type text not null check (order_type in ('Delivery', 'Pickup')),
  address text check (address is null or char_length(address) <= 250),
  requested_date date,
  requested_time text check (requested_time is null or char_length(requested_time) <= 60),
  notes text check (notes is null or char_length(notes) <= 300),
  items jsonb not null,
  subtotal integer not null check (subtotal >= 0),
  delivery_charge integer not null default 0 check (delivery_charge >= 0),
  total integer not null check (total >= 0),
  constraint delivery_needs_address
    check (order_type <> 'Delivery' or (address is not null and char_length(address) >= 8))
);

create index if not exists orders_created_idx on orders (created_at desc);
create index if not exists orders_phone_idx on orders (customer_phone, created_at);

alter table orders enable row level security;
revoke all on orders from anon;

drop policy if exists "Owner can read orders" on orders;
create policy "Owner can read orders"
  on orders for select to authenticated using ((select is_owner()));

drop policy if exists "Owner can update orders" on orders;
create policy "Owner can update orders"
  on orders for update to authenticated
  using ((select is_owner())) with check ((select is_owner()));

drop policy if exists "Owner can delete orders" on orders;
create policy "Owner can delete orders"
  on orders for delete to authenticated using ((select is_owner()));


-- 3b. Payments (Week 4). Each line is safe to run again.
alter table shop_settings
  add column if not exists free_delivery_above integer not null default 1000 check (free_delivery_above >= 0),
  add column if not exists cod_max_total integer not null default 1500 check (cod_max_total >= 0),
  add column if not exists accept_upi boolean not null default true,
  add column if not exists accept_cod boolean not null default true,
  add column if not exists accept_pay_at_pickup boolean not null default true,
  add column if not exists upi_id text
    check (upi_id is null or upi_id ~ '^[A-Za-z0-9._-]{2,64}@[A-Za-z0-9]{2,32}$');
-- free_delivery_above: items total at or above this get free delivery (0 = never free)
-- cod_max_total:       largest order total allowed for cash on delivery (0 = no limit)

alter table orders
  add column if not exists payment_method text
    check (payment_method is null or payment_method in ('UPI', 'COD', 'PAY_AT_PICKUP')),
  add column if not exists payment_status text not null default 'unpaid'
    check (payment_status in ('unpaid', 'paid', 'refunded')),
  add column if not exists paid_at timestamptz;
-- orders placed before this update have payment_method empty


-- 4. place_order(): the only way a customer creates an order
create or replace function place_order(p jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  s          shop_settings%rowtype;
  v_token    text;
  v_name     text;
  v_phone    text;
  v_type     text;
  v_address  text;
  v_time     text;
  v_notes    text;
  v_payment  text;
  v_date     date;
  v_today    date := (now() at time zone 'Asia/Kolkata')::date;
  v_in       jsonb;
  v_line     jsonb;
  v_id       bigint;
  v_qty      integer;
  v_item     menu_items%rowtype;
  v_items    jsonb := '[]'::jsonb;
  v_subtotal integer := 0;
  v_delivery integer := 0;
  v_total    integer;
  v_existing orders%rowtype;
  v_new      orders%rowtype;
begin
  if jsonb_typeof(p) is distinct from 'object' then
    raise exception 'INVALID_ORDER';
  end if;

  v_token := p->>'token';
  if v_token is null or v_token !~ '^[A-Za-z0-9-]{16,64}$' then
    raise exception 'INVALID_ORDER';
  end if;

  -- Same token again (a double tap or a retry): return the order already saved
  select * into v_existing from orders where client_token = v_token;
  if found then
    return jsonb_build_object(
      'order_ref', v_existing.order_ref, 'subtotal', v_existing.subtotal,
      'delivery_charge', v_existing.delivery_charge, 'total', v_existing.total,
      'payment_method', v_existing.payment_method, 'payment_status', v_existing.payment_status);
  end if;

  select * into s from shop_settings limit 1;
  if not found or not s.accepting_orders then
    raise exception 'ORDERS_PAUSED';
  end if;

  v_name    := btrim(coalesce(p->>'name', ''));
  v_phone   := regexp_replace(coalesce(p->>'phone', ''), '\D', '', 'g');
  v_type    := p->>'type';
  v_address := nullif(btrim(coalesce(p->>'address', '')), '');
  v_time    := nullif(btrim(coalesce(p->>'time', '')), '');
  v_notes   := nullif(btrim(coalesce(p->>'notes', '')), '');
  v_payment := p->>'payment';
  v_in      := p->'items';

  if char_length(v_name) not between 1 and 60 then raise exception 'INVALID_NAME'; end if;

  if length(v_phone) = 12 and left(v_phone, 2) = '91' then
    v_phone := substr(v_phone, 3);
  elsif length(v_phone) = 11 and left(v_phone, 1) = '0' then
    v_phone := substr(v_phone, 2);
  end if;
  if v_phone !~ '^[6-9][0-9]{9}$' then raise exception 'INVALID_PHONE'; end if;

  if v_type is null or v_type not in ('Delivery', 'Pickup') then raise exception 'INVALID_TYPE'; end if;
  if v_type = 'Pickup' then v_address := null; end if;
  if v_type = 'Delivery' and (v_address is null or char_length(v_address) < 8) then
    raise exception 'INVALID_ADDRESS';
  end if;
  if char_length(coalesce(v_address, '')) > 250 then raise exception 'INVALID_ADDRESS'; end if;

  if char_length(coalesce(v_time, '')) > 60 or char_length(coalesce(v_notes, '')) > 300 then
    raise exception 'INVALID_TEXT';
  end if;

  begin
    v_date := nullif(p->>'date', '')::date;
  exception when others then
    raise exception 'INVALID_DATE';
  end;
  if v_date is not null and (v_date < v_today or v_date > v_today + 120) then
    raise exception 'INVALID_DATE';
  end if;

  -- Items: look every one up in menu_items; the customer's prices are never used
  if jsonb_typeof(v_in) is distinct from 'array' or jsonb_array_length(v_in) not between 1 and 30 then
    raise exception 'INVALID_ITEMS';
  end if;

  for v_line in select * from jsonb_array_elements(v_in) loop
    begin
      v_id  := (v_line->>'id')::bigint;
      v_qty := (v_line->>'qty')::integer;
    exception when others then
      raise exception 'INVALID_ITEMS';
    end;
    if v_qty is null or v_qty not between 1 and 20 then raise exception 'INVALID_ITEMS'; end if;

    select * into v_item from menu_items where id = v_id;
    if not found then raise exception 'INVALID_ITEMS'; end if;
    if not v_item.available then raise exception 'ITEM_UNAVAILABLE'; end if;

    v_items := v_items || jsonb_build_object('id', v_item.id, 'name', v_item.name, 'price', v_item.price, 'qty', v_qty);
    v_subtotal := v_subtotal + v_item.price * v_qty;
  end loop;

  if v_subtotal < s.min_order then raise exception 'BELOW_MINIMUM'; end if;

  -- Delivery charge, free above the threshold
  if v_type = 'Delivery' then
    if s.free_delivery_above > 0 and v_subtotal >= s.free_delivery_above then
      v_delivery := 0;
    else
      v_delivery := s.delivery_charge;
    end if;
  end if;
  v_total := v_subtotal + v_delivery;

  -- Payment method: must be allowed for this order type and switched on
  if v_payment is null or v_payment not in ('UPI', 'COD', 'PAY_AT_PICKUP') then
    raise exception 'INVALID_PAYMENT';
  end if;
  if v_payment = 'UPI' and (not s.accept_upi or s.upi_id is null) then
    raise exception 'INVALID_PAYMENT';
  end if;
  if v_payment = 'COD' then
    if v_type <> 'Delivery' or not s.accept_cod then raise exception 'INVALID_PAYMENT'; end if;
    if s.cod_max_total > 0 and v_total > s.cod_max_total then raise exception 'COD_LIMIT'; end if;
  end if;
  if v_payment = 'PAY_AT_PICKUP' and (v_type <> 'Pickup' or not s.accept_pay_at_pickup) then
    raise exception 'INVALID_PAYMENT';
  end if;

  -- Simple limits against spam: 5 orders per phone per hour, 100 orders per hour in total
  if (select count(*) from orders where customer_phone = v_phone and created_at > now() - interval '1 hour') >= 5
     or (select count(*) from orders where created_at > now() - interval '1 hour') >= 100 then
    raise exception 'TOO_MANY_ORDERS';
  end if;

  insert into orders (order_ref, client_token, customer_name, customer_phone, order_type, address,
                      requested_date, requested_time, notes, items, subtotal, delivery_charge, total, payment_method)
  values (upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6)), v_token, v_name, v_phone, v_type, v_address,
          v_date, v_time, v_notes, v_items, v_subtotal, v_delivery, v_total, v_payment)
  returning * into v_new;

  return jsonb_build_object(
    'order_ref', v_new.order_ref, 'subtotal', v_new.subtotal,
    'delivery_charge', v_new.delivery_charge, 'total', v_new.total,
    'payment_method', v_new.payment_method, 'payment_status', v_new.payment_status);
end;
$$;

revoke all on function place_order(jsonb) from public;
grant execute on function place_order(jsonb) to anon, authenticated;
