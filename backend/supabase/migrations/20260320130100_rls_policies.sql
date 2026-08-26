-- Row Level Security for EmBeLife
-- Assumes Supabase Auth (auth.uid()).

alter table public.profiles enable row level security;
alter table public.family_members enable row level security;
alter table public.providers enable row level security;
alter table public.bookings enable row level security;
alter table public.checklist_tasks enable row level security;
alter table public.saved_task_templates enable row level security;

-- Profiles: users manage their own row
create policy "profiles_select_own"
  on public.profiles for select
  using (auth.uid() = id);

create policy "profiles_update_own"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

create policy "profiles_insert_own"
  on public.profiles for insert
  with check (auth.uid() = id);

-- Family members
create policy "family_members_all_own"
  on public.family_members for all
  using (auth.uid() = profile_id)
  with check (auth.uid() = profile_id);

-- Providers: readable by any signed-in user; writes via service role / admin later
create policy "providers_select_authenticated"
  on public.providers for select
  to authenticated
  using (is_active = true);

-- Bookings: client owns their bookings
create policy "bookings_select_own"
  on public.bookings for select
  using (auth.uid() = client_id);

create policy "bookings_insert_own"
  on public.bookings for insert
  with check (auth.uid() = client_id);

create policy "bookings_update_own"
  on public.bookings for update
  using (auth.uid() = client_id)
  with check (auth.uid() = client_id);

create policy "bookings_delete_own"
  on public.bookings for delete
  using (auth.uid() = client_id);

-- Checklist tasks: via parent booking ownership
create policy "checklist_tasks_select_own"
  on public.checklist_tasks for select
  using (
    exists (
      select 1 from public.bookings b
      where b.id = checklist_tasks.booking_id
        and b.client_id = auth.uid()
    )
  );

create policy "checklist_tasks_insert_own"
  on public.checklist_tasks for insert
  with check (
    exists (
      select 1 from public.bookings b
      where b.id = checklist_tasks.booking_id
        and b.client_id = auth.uid()
    )
  );

create policy "checklist_tasks_update_own"
  on public.checklist_tasks for update
  using (
    exists (
      select 1 from public.bookings b
      where b.id = checklist_tasks.booking_id
        and b.client_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.bookings b
      where b.id = checklist_tasks.booking_id
        and b.client_id = auth.uid()
    )
  );

create policy "checklist_tasks_delete_own"
  on public.checklist_tasks for delete
  using (
    exists (
      select 1 from public.bookings b
      where b.id = checklist_tasks.booking_id
        and b.client_id = auth.uid()
    )
  );

-- Saved templates
create policy "saved_task_templates_all_own"
  on public.saved_task_templates for all
  using (auth.uid() = profile_id)
  with check (auth.uid() = profile_id);
