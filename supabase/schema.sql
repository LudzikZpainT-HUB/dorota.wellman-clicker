-- Schemat dla topki pieniędzy w Multiwersum Clicker.
-- Wklej całość do Supabase → SQL Editor → Run. Skrypt można puścić wielokrotnie.

create table if not exists public.profiles (
    id         uuid primary key references auth.users(id) on delete cascade,
    nick       text not null,
    money      numeric not null default 0 check (money >= 0),
    state      jsonb  not null default '{}'::jsonb,
    updated_at timestamptz not null default now()
);

-- Nick unikalny bez względu na wielkość liter, żeby nie dało się zrobić
-- drugiego "Lukasz" jako "lukasz"
create unique index if not exists profiles_nick_lower_idx
    on public.profiles (lower(nick));

-- Topka sortuje malejąco po kasie
create index if not exists profiles_money_idx
    on public.profiles (money desc);

alter table public.profiles enable row level security;

-- Czytać może każdy, także niezalogowany - topka jest publiczna
drop policy if exists profiles_public_read on public.profiles;
create policy profiles_public_read on public.profiles
    for select using (true);

-- Pisać można TYLKO do własnego wiersza. Bez tego dowolny gracz
-- podmieniłby kasę komuś innemu, mając sam klucz anon.
drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own on public.profiles
    for insert with check (auth.uid() = id);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
    for update using (auth.uid() = id) with check (auth.uid() = id);

-- Celowo brak polityki DELETE: nikt nie usunie wiersza z topki, także własnego.

-- updated_at ustawiamy po stronie serwera, żeby nie dało się go podać z palca
create or replace function public.profiles_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists profiles_touch_updated_at on public.profiles;
create trigger profiles_touch_updated_at
    before insert or update on public.profiles
    for each row execute function public.profiles_touch_updated_at();

-- Nick jest przypisany przy tworzeniu wiersza i nie da się go potem podmienić
-- (inaczej można by podszyć się pod cudzy nick w topce).
create or replace function public.profiles_lock_nick()
returns trigger
language plpgsql
as $$
begin
    if new.nick is distinct from old.nick then
        raise exception 'Nick nie może być zmieniony';
    end if;
    return new;
end;
$$;

drop trigger if exists profiles_lock_nick on public.profiles;
create trigger profiles_lock_nick
    before update on public.profiles
    for each row execute function public.profiles_lock_nick();
