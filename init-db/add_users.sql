CREATE TABLE public.users (
  id SERIAL PRIMARY KEY,
  name TEXT,
  email TEXT
);

INSERT INTO public.users (name, email)
VALUES
  ('User_1', 'user_1@demo_meltano.com'),
  ('User_2', 'user_2@demo_meltano.com');