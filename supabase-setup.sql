-- Ejecuta este SQL en Supabase → SQL Editor
-- https://supabase.com/dashboard → tu proyecto → SQL Editor

create table if not exists characters (
  id           uuid default gen_random_uuid() primary key,
  created_at   timestamptz default now(),

  -- Datos del jugador
  player_name  text not null,
  char_name    text not null,

  -- Clase determinada por el test
  class        text not null check (class in ('Marine', 'Teamster', 'Scientist', 'Android')),

  -- Stats primarios
  strength     int not null,
  speed        int not null,
  intellect    int not null,
  combat       int not null,

  -- Saves secundarios
  sanity_save  int not null,
  fear_save    int not null,
  body_save    int not null,

  -- Stress
  max_stress   int not null default 20,

  -- Habilidades y equipo (array de texto)
  skills       text[] not null default '{}',
  equipment    text[] not null default '{}',
  trinket      text,

  -- Respuestas del cuestionario (para referencia)
  quiz_answers jsonb
);

-- Acceso público de lectura/escritura (los jugadores pueden crear fichas)
alter table characters enable row level security;

create policy "Cualquiera puede insertar"
  on characters for insert
  with check (true);

create policy "Cualquiera puede leer"
  on characters for select
  using (true);
