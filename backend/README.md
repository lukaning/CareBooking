# EmBeLife backend

Postgres schema for EmBeLife, kept in this repo and designed for **Supabase** (Auth + RLS). The iOS app still uses in-memory demo data until we wire the SDK.

## Layout

```
backend/
  README.md
  supabase/
    config.toml          # local Supabase project settings
    migrations/          # ordered SQL migrations
    seed.sql             # sample providers
```

## Tables (phase 1)

| Table | Purpose |
|---|---|
| `profiles` | Client/provider profile (linked to `auth.users`) |
| `family_members` | Care recipients on a profile |
| `providers` | Care professionals (Home / Book) |
| `bookings` | Requested / booked / completed visits |
| `checklist_tasks` | Tasks + nested sub-tasks (`parent_task_id`) |
| `saved_task_templates` | “Save for next time” |

Later phases can add messages, notes, payments, gifts, and reviews as tables.

## Option A — Supabase Cloud (fastest)

1. Create a project at [supabase.com](https://supabase.com).
2. Install the CLI: `brew install supabase/tap/supabase`
3. From the repo root:

```bash
cd backend
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
supabase db query --file supabase/seed.sql
```

4. In the Supabase dashboard → **Project Settings → API**, copy:
   - Project URL
   - `anon` public key  

   (We will add these to the iOS app in a later step; do not commit secrets.)

## Option B — Local Supabase

```bash
cd backend
supabase start
supabase db reset   # applies migrations + seed
```

Local Studio UI is printed by `supabase start` (usually http://127.0.0.1:54323).

## Option C — Plain Postgres

If you are not using Supabase Auth yet, apply migrations manually, then skip or adapt the `auth.users` trigger in `20260320130000_initial_schema.sql` (profiles currently reference `auth.users`).

```bash
psql "$DATABASE_URL" -f supabase/migrations/20260320130000_initial_schema.sql
psql "$DATABASE_URL" -f supabase/migrations/20260320130100_rls_policies.sql
psql "$DATABASE_URL" -f supabase/seed.sql
```

## Next step (iOS)

1. Add the Supabase Swift package to `EmBeLife`.
2. Store URL + anon key in Xcode config / xcconfig (not in git).
3. Replace `AppModel` in-memory bookings with API calls for create / cancel / checklist.

Say when you want the iOS client wired to this schema.
