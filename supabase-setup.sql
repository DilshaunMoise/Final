-- Pizza Yard Supabase setup. Run in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.pizza_orders (
 id uuid primary key default gen_random_uuid(),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 customer_name text not null,
 customer_phone text not null,
 customer_email text not null,
 order_type text not null check(order_type in ('pickup','delivery')),
 delivery_address text,
 pizza_size text not null,
 toppings jsonb not null default '[]'::jsonb,
 topping_count integer not null check(topping_count>=0),
 unit_price numeric(10,2) not null check(unit_price>=0),
 included_toppings integer not null check(included_toppings>=0),
 extra_toppings integer not null check(extra_toppings>=0),
 extra_topping_cost numeric(10,2) not null check(extra_topping_cost>=0),
 quantity integer not null check(quantity>=1),
 delivery_fee numeric(10,2) not null default 0 check(delivery_fee>=0),
 special_instructions text,
 total numeric(10,2) not null check(total>=0),
 status text not null default 'new' check(status in ('new','preparing','ready','completed','cancelled'))
);
create index if not exists pizza_orders_created_at_idx on public.pizza_orders(created_at desc);
create index if not exists pizza_orders_status_idx on public.pizza_orders(status);

create table if not exists public.staff_users (
 user_id uuid primary key references auth.users(id) on delete cascade,
 created_at timestamptz not null default now()
);

alter table public.pizza_orders enable row level security;
alter table public.staff_users enable row level security;

drop policy if exists "Anyone can create pizza orders" on public.pizza_orders;
create policy "Anyone can create pizza orders" on public.pizza_orders for insert to anon with check(true);

drop policy if exists "Staff can view pizza orders" on public.pizza_orders;
create policy "Staff can view pizza orders" on public.pizza_orders for select to authenticated
using(exists(select 1 from public.staff_users where staff_users.user_id=(select auth.uid())));

drop policy if exists "Staff can update pizza orders" on public.pizza_orders;
create policy "Staff can update pizza orders" on public.pizza_orders for update to authenticated
using(exists(select 1 from public.staff_users where staff_users.user_id=(select auth.uid())))
with check(exists(select 1 from public.staff_users where staff_users.user_id=(select auth.uid())));

create or replace function public.set_pizza_order_updated_at()
returns trigger language plpgsql security invoker as $$
begin new.updated_at=now(); return new; end; $$;
drop trigger if exists pizza_orders_set_updated_at on public.pizza_orders;
create trigger pizza_orders_set_updated_at before update on public.pizza_orders for each row execute function public.set_pizza_order_updated_at();

alter table public.pizza_orders replica identity full;
do $$ begin
 alter publication supabase_realtime add table public.pizza_orders;
exception when duplicate_object then null; end $$;

-- After creating the staff Auth user, add its UUID with:
-- insert into public.staff_users(user_id) values ('PASTE_AUTH_USER_UUID_HERE');
