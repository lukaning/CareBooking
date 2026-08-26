-- EmBeLife initial schema
-- Compatible with Supabase (Postgres + auth.users) and plain Postgres.

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------

create type public.user_role as enum ('client', 'provider');
create type public.booking_status as enum ('requested', 'booked', 'completed', 'cancelled');
create type public.task_priority as enum ('low', 'medium', 'high');

-- ---------------------------------------------------------------------------
-- Profiles (1:1 with auth.users when using Supabase Auth)
-- ---------------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  first_name text not null default '',
  middle_name text not null default '',
  last_name text not null default '',
  mobile text not null default '',
  address text not null default '',
  role public.user_role not null default 'client',
  role_label text not null default 'Customer',
  account_type text not null default 'Owner Account',
  languages text[] not null default '{}',
  preferred_language text not null default 'English',
  search_radius_miles numeric(6, 1) not null default 25,
  custom_location text not null default '',
  custom_address text not null default '',
  custom_zipcode text not null default '',
  location_choice text check (location_choice in ('current', 'custom')),
  has_uploaded_photo boolean not null default false,
  is_published boolean not null default false,
  rating numeric(3, 2) not null default 0,
  review_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index profiles_role_idx on public.profiles (role);

-- ---------------------------------------------------------------------------
-- Family members (care recipients on a client profile)
-- ---------------------------------------------------------------------------

create table public.family_members (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  first_name text not null,
  last_name text not null default '',
  preferred_services text[] not null default '{}',
  preferred_times text[] not null default '{}',
  avatar_style text not null default 'pink',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index family_members_profile_idx on public.family_members (profile_id);

-- ---------------------------------------------------------------------------
-- Providers (care professionals shown in Home / booking)
-- ---------------------------------------------------------------------------

create table public.providers (
  id text primary key,
  name text not null,
  title text not null,
  rate_per_hour integer not null check (rate_per_hour >= 0),
  rating numeric(3, 2) not null default 0,
  review_count integer not null default 0,
  bio text not null default '',
  specialties text not null default '',
  booking_count integer not null default 0,
  image_name text not null default 'providerAvatar',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Optional link from a provider profile user → provider row
alter table public.profiles
  add column if not exists provider_id text references public.providers (id);

-- ---------------------------------------------------------------------------
-- Bookings
-- ---------------------------------------------------------------------------

create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.profiles (id) on delete cascade,
  provider_id text not null references public.providers (id),
  status public.booking_status not null default 'requested',
  service_date date not null,
  start_time timestamptz not null,
  duration_minutes integer not null check (duration_minutes > 0),
  service_provided_to text not null default '',
  title text not null default '',
  task_description text not null default '',
  location text not null default '',
  client_review_rating integer check (client_review_rating between 1 and 5),
  client_review_text text,
  reschedule_reason text,
  reschedule_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index bookings_client_idx on public.bookings (client_id);
create index bookings_provider_idx on public.bookings (provider_id);
create index bookings_status_idx on public.bookings (status);
create index bookings_service_date_idx on public.bookings (service_date);

-- ---------------------------------------------------------------------------
-- Checklist tasks (parent + nested sub-tasks via parent_task_id)
-- ---------------------------------------------------------------------------

create table public.checklist_tasks (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings (id) on delete cascade,
  parent_task_id uuid references public.checklist_tasks (id) on delete cascade,
  title text not null,
  category text not null default '',
  subcategory text not null default '',
  priority public.task_priority not null default 'medium',
  deadline timestamptz,
  detail_description text not null default '',
  estimated_minutes integer,
  attachment_names text[] not null default '{}',
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index checklist_tasks_booking_idx on public.checklist_tasks (booking_id);
create index checklist_tasks_parent_idx on public.checklist_tasks (parent_task_id);

-- ---------------------------------------------------------------------------
-- Saved task templates ("Save for next time")
-- ---------------------------------------------------------------------------

create table public.saved_task_templates (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  category text not null default '',
  subcategory text not null default '',
  priority public.task_priority not null default 'medium',
  detail_description text not null default '',
  estimated_minutes integer,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index saved_task_templates_profile_idx on public.saved_task_templates (profile_id);

-- ---------------------------------------------------------------------------
-- updated_at helper
-- ---------------------------------------------------------------------------

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

create trigger family_members_set_updated_at
  before update on public.family_members
  for each row execute function public.set_updated_at();

create trigger providers_set_updated_at
  before update on public.providers
  for each row execute function public.set_updated_at();

create trigger bookings_set_updated_at
  before update on public.bookings
  for each row execute function public.set_updated_at();

create trigger checklist_tasks_set_updated_at
  before update on public.checklist_tasks
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Auto-create profile row when a Supabase auth user signs up
-- ---------------------------------------------------------------------------

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
