-- ClipBet Database Schema for Supabase
-- Run this in the Supabase SQL Editor to create all tables

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ============================================================
-- ORGANIZERS
-- ============================================================

create table organizers (
  id uuid primary key default uuid_generate_v4(),
  apple_user_id text unique not null,
  stripe_connect_id text,
  tos_agreed_at timestamptz,
  verified_at timestamptz,
  events_created integer default 0,
  disputes_against integer default 0,
  rating numeric(3,2) default 5.00,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index idx_organizers_apple on organizers(apple_user_id);

-- ============================================================
-- EVENTS
-- ============================================================

create type event_status as enum ('planned', 'live', 'bets_closed', 'resolved', 'cancelled');
create type betting_window as enum ('manual', 'at_start', 'stay_open');

create table events (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  description text,
  image_url text,
  status event_status default 'live',
  minimum_bet numeric(10,2) default 5.00,
  betting_window betting_window default 'manual',
  organizer_id uuid references organizers(id) not null,
  location_lat numeric(10,7),
  location_lng numeric(10,7),
  location_name text,
  winning_option_id uuid,
  total_pool numeric(10,2) default 0,
  platform_fee numeric(10,2) default 0,
  winner_pool numeric(10,2) default 0,
  event_time timestamptz,
  event_end_time timestamptz,
  created_at timestamptz default now(),
  started_at timestamptz,
  closed_at timestamptz,
  resolved_at timestamptz,
  updated_at timestamptz default now()
);

create index idx_events_status on events(status);
create index idx_events_organizer on events(organizer_id);
create index idx_events_location on events(location_lat, location_lng);

-- ============================================================
-- OPTIONS (Bet Outcomes)
-- ============================================================

create table options (
  id uuid primary key default uuid_generate_v4(),
  event_id uuid references events(id) on delete cascade not null,
  name text not null,
  total_bets integer default 0,
  total_amount numeric(10,2) default 0,
  percentage numeric(5,2) default 0,
  created_at timestamptz default now()
);

create index idx_options_event on options(event_id);

-- ============================================================
-- BETS
-- ============================================================

create type bet_status as enum ('pending', 'confirmed', 'won', 'lost', 'refunded');
create type payout_status as enum ('none', 'processing', 'completed', 'failed');

create table bets (
  id uuid primary key default uuid_generate_v4(),
  event_id uuid references events(id) not null,
  option_id uuid references options(id) not null,
  amount numeric(10,2) not null,
  nickname text default 'Anonymous',
  email text,
  stripe_payment_intent_id text,
  status bet_status default 'pending',
  payout_amount numeric(10,2),
  payout_status payout_status default 'none',
  created_at timestamptz default now()
);

create index idx_bets_event on bets(event_id);
create index idx_bets_option on bets(option_id);
create index idx_bets_stripe on bets(stripe_payment_intent_id);

-- ============================================================
-- DISPUTES
-- ============================================================

create type dispute_status as enum ('open', 'resolved', 'rejected');

create table disputes (
  id uuid primary key default uuid_generate_v4(),
  event_id uuid references events(id) not null,
  bettor_email text not null,
  reason text not null,
  status dispute_status default 'open',
  resolution text,
  created_at timestamptz default now(),
  resolved_at timestamptz
);

create index idx_disputes_event on disputes(event_id);

-- ============================================================
-- FUNCTIONS
-- ============================================================

-- Auto-update updated_at timestamp
create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger events_updated_at
  before update on events
  for each row execute function update_updated_at();

create trigger organizers_updated_at
  before update on organizers
  for each row execute function update_updated_at();

-- Recalculate option percentages after bet changes
create or replace function recalculate_percentages()
returns trigger as $$
declare
  pool numeric;
begin
  select coalesce(sum(total_amount), 0) into pool
    from options where event_id = new.event_id;

  update options
    set percentage = case
      when pool > 0 then (total_amount / pool) * 100
      else 0
    end
    where event_id = new.event_id;

  update events
    set total_pool = pool,
        platform_fee = pool * 0.05,
        winner_pool = pool * 0.95
    where id = new.event_id;

  return new;
end;
$$ language plpgsql;

create trigger options_recalculate
  after update of total_amount on options
  for each row execute function recalculate_percentages();

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table events enable row level security;
alter table options enable row level security;
alter table bets enable row level security;
alter table organizers enable row level security;
alter table disputes enable row level security;

-- Public read for events and options
create policy "Events are publicly readable"
  on events for select using (true);

create policy "Options are publicly readable"
  on options for select using (true);

-- Bets readable by the backend service role
create policy "Bets managed by service role"
  on bets for all using (true);

-- Organizers managed by service role
create policy "Organizers managed by service role"
  on organizers for all using (true);

-- Disputes managed by service role
create policy "Disputes managed by service role"
  on disputes for all using (true);
