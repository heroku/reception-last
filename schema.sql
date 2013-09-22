create extension "uuid-ossp";
create table guests (
  id               uuid          primary key default uuid_generate_v4(),
  guest_name       text          not null        ,
  herokai_name     text          not null        ,
  visiting_on      timestamptz   not null        ,
  lunch            boolean       default false   ,
  nda              boolean       default false   ,
  notify_hipchat   boolean       default false   ,
  notify_gchat     boolean       default false   ,
  notify_sms       text                          ,
  notes            text                          ,
  created_at       timestamptz   default now()
);

