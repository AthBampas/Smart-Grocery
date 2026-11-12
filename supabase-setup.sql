-- Smart Grocery: δημιουργία βάσης (τρέξε το ΜΙΑ φορά στο Supabase → SQL Editor)

create table if not exists public.items (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  cat text not null default 'Άλλο',
  unit text not null default 'τεμ.',
  min_qty numeric not null default 0,
  barcode text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.tx (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  item_id uuid not null references public.items(id) on delete cascade,
  type text not null check (type in ('in','out')),
  qty numeric not null check (qty > 0),
  expiry date,
  created_at timestamptz not null default now()
);

create table if not exists public.settings (
  user_id uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  cats jsonb not null default '[]'::jsonb
);

create index if not exists items_user_idx on public.items(user_id);
create index if not exists tx_user_idx on public.tx(user_id);
create index if not exists tx_item_idx on public.tx(item_id);

-- Ασφάλεια: κάθε χρήστης βλέπει και αλλάζει ΜΟΝΟ τα δικά του δεδομένα
alter table public.items enable row level security;
alter table public.tx enable row level security;
alter table public.settings enable row level security;

drop policy if exists "own items" on public.items;
drop policy if exists "own tx" on public.tx;
drop policy if exists "own settings" on public.settings;

create policy "own items" on public.items for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "own tx" on public.tx for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "own settings" on public.settings for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Άμεσος συγχρονισμός μεταξύ συσκευών (realtime)
alter publication supabase_realtime add table public.items, public.tx, public.settings;
