-- Ejecutar en Supabase → SQL Editor (como administrador del proyecto).
-- Sustituye el UUID si usas otro usuario.
-- Roles válidos en la app: super_admin, admin, secretario, encargado

-- 1) Si ya tiene fila en profiles: solo subir rol
UPDATE public.profiles
SET role = 'super_admin'
WHERE user_id = 'b31eb06d-f7ff-4f1e-b501-0459049befd5';

-- 2) Si no tenía fila (usuario nuevo en Auth sin trigger de perfil):
--    Requiere que ese UUID exista en auth.users.
INSERT INTO public.profiles (user_id, role)
VALUES ('b31eb06d-f7ff-4f1e-b501-0459049befd5', 'super_admin')
ON CONFLICT (user_id) DO UPDATE
SET role = EXCLUDED.role;

-- Si ON CONFLICT falla porque la PK no es user_id, usa solo el UPDATE
-- y crea la fila a mano con las columnas que exija tu tabla (p. ej. display_name).
