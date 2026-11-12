# Global leaderboards (optional, one-time setup)

The game always keeps **local** top-10 boards. To make them **global**, create a free Supabase project:

1. supabase.com -> New project (free tier).
2. SQL editor, run:

```sql
create table scores (
  id bigint generated always as identity primary key,
  board text not null,
  name text not null check (char_length(name) <= 16),
  value double precision not null,
  created_at timestamptz default now()
);
alter table scores enable row level security;
create policy "read scores" on scores for select using (true);
create policy "add scores" on scores for insert with check (true);
```

3. Project Settings -> API: copy the Project URL and the `anon` public key.
4. Put them in `config/online.cfg`:

```
[online]
url="https://YOURPROJECT.supabase.co"
key="YOUR_ANON_KEY"
```

5. Commit and push. The deploy workflow republishes the game.

Boards: survival, ranger, discoveries, photo, rescue (lower is better), arrests.

Note: the anon key is public by design, and scores are submitted from the client, so there is no anti-cheat.
Treat this as a friendly leaderboard, not a competitive one.
