create extension "uuid-ossp";

create table guests (
  id               uuid          primary key default uuid_generate_v4(),
  guest_name       text          not null        ,
  herokai_name     text          not null        ,
  lunch            boolean       default false   ,
  nda              boolean       default false   ,
  salesforce       boolean       default false   ,
  notify_hipchat   boolean       default false   ,
  notify_gchat     boolean       default false   ,
  notify_sms       text                          ,
  notes            text                          ,
  created_at       timestamptz   default now()   ,
  visiting_range   daterange     not null
);
create index visitng_range_gist on guests using gist(visiting_range);

create table checkins (
  id         uuid        primary key default uuid_generate_v4(),
  guest_id   uuid        not null                ,
  created_at timestamptz not null default now()
);
create index on checkins(guest_id);
create unique index on checkins (guest_id, date_trunc('day', created_at at time zone 'UTC'));
