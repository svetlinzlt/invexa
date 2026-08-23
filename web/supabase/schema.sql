-- Списък на чакащи за Invexa.
-- Пусни това в Supabase → SQL Editor → New query.

create table if not exists public.waitlist (
  id          uuid primary key default gen_random_uuid(),
  email       text not null,
  plan        text not null check (plan in ('free', 'premium')),
  lang        text not null default 'bg' check (lang in ('bg', 'en')),
  country     text,
  referrer    text,
  user_agent  text,
  created_at  timestamptz not null default now()
);

-- Един запис на имейл, без значение от регистъра на буквите.
create unique index if not exists waitlist_email_key
  on public.waitlist (lower(email));

-- Заявките по държава и по план са единственото, което ще четеш редовно.
create index if not exists waitlist_country_idx on public.waitlist (country);
create index if not exists waitlist_plan_idx    on public.waitlist (plan);

-- Включваме защитата на редовете и НЕ добавяме политики.
-- Така таблицата е недостъпна за анонимния ключ; пише само сървърът
-- със service_role ключа, който заобикаля RLS.
alter table public.waitlist enable row level security;


-- ── Заявката, която ще гледаш всяка седмица ──────────────────────
--
--   select
--     coalesce(country, 'неизвестна')                as държава,
--     count(*)                                       as общо,
--     count(*) filter (where plan = 'premium')       as премиум,
--     round(
--       100.0 * count(*) filter (where plan = 'premium') / count(*), 1
--     )                                              as процент_премиум
--   from public.waitlist
--   group by 1
--   order by общо desc;
--
-- Прагът от плана: ≥ 300 записани за 4 седмици и ≥ 3% избрали премиум.
