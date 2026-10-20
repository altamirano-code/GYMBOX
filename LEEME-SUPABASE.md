# Dashboard de productos con Supabase

1. **Proyecto.** Entra a supabase.com y crea un proyecto (o usa uno existente).
2. **Base de datos.** Ve a *SQL Editor → New query*, pega todo `supabase/setup.sql` y dale *Run*. Esto crea:
   - la tabla `productos` con los 6 productos actuales,
   - la tabla `admins`,
   - las reglas de seguridad (RLS),
   - el bucket público `productos` para las fotos.
3. **Correo del administrador.** Antes de correr el SQL, cambia el correo del paso 5 del archivo si el dashboard lo va a usar otra cuenta. Si ya lo corriste, agrega otros correos con:
   `insert into public.admins (email) values ('otro@correo.com');`
4. **Usuario.** Ve a *Authentication → Users → Add user → Create new user*.
   - Usa el mismo correo de `admins` y una contraseña.
   - Marca *Auto Confirm User*.
5. **Cerrar registros.** Ve a *Authentication → Sign In / Providers* y desactiva *Allow new users to sign up*. Así nadie más puede crearse una cuenta.
6. **Llaves.** Ve a *Project Settings → API Keys* y copia:
   - la **Project URL**,
   - la llave **anon** o **publishable**. Nunca la *service_role* ni la *secret*.

   Pégalas en `supabase-config.js`.
7. **Publicar.** Sube todos los archivos a tu hosting. Debe ser HTTPS; GitHub Pages sirve.
8. **Entrar.** Abre `tu-sitio/admin.html` e inicia sesión. Desde ahí puedes:
   - agregar, editar y eliminar productos,
   - ocultarlos,
   - cambiar el orden,
   - subir fotos,
   - marcar el aviso de "precio aproximado".

La tienda carga los productos desde Supabase al abrirse. Si Supabase no responde, usa la lista de respaldo que está en `tienda.html`.

Las categorías se definen en el arreglo `CATEGORIAS` de `tienda.html` y de `admin.html`. Si agregas una nueva, ponla en los dos archivos.
