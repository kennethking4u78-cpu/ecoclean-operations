# EcoClean Ghana Operations MVP (Mobile + Web Dashboard + Backend)

Starter MVP you can run and extend into a full production system.

## Included
- Backend API: Node.js + Express + Prisma + PostgreSQL + JWT auth
- Web Dashboard: React (Vite) + Material UI (MUI)
- Mobile App: Flutter (Android-first) with login, client list, register client, photo upload, lat/lng capture, open Google Maps link

## Quick start (local)
### Backend
```bash
cd backend
cp .env.example .env
npm install
npx prisma migrate dev --name init
npm run seed
npm run dev
```
API: http://localhost:4000

Default admin:
- username: admin
- password: Admin@1234

### Web dashboard
```bash
cd web_dashboard
npm install
npm run dev
```
Web: http://localhost:5173

### Mobile
```bash
cd mobile_flutter
flutter pub get
flutter run
```

## Notes
- For Android emulator, API base URL is set to `http://10.0.2.2:4000`
- Add Google Maps SDK keys if you want in-app map pickers (Phase 2)


## Make it LIVE (no coding knowledge) – easiest path

### Step 1: Upload code to GitHub (no coding)
1. Create a free GitHub account
2. Click **New repository**
3. On the repo page, click **Upload files**
4. Drag-and-drop the *contents of this zip* (or unzip locally then upload)
5. Click **Commit changes**

### Step 2: Create Database (Supabase)
1. Go to Supabase and create a new project
2. Copy your **Postgres connection string**
3. Keep it for the backend deploy step

### Step 3: Deploy Backend (Render – click deploy)
1. Create a Render account
2. New → **Web Service**
3. Connect your GitHub repo
4. Choose the `backend` folder as root
5. Set Build Command:
   - `npm install && npx prisma migrate deploy`
6. Set Start Command:
   - `node src/index.js`
7. Add environment variables:
   - `DATABASE_URL` = your Supabase connection string
   - `JWT_SECRET` = long random string
   - `CORS_ORIGIN` = your web dashboard URL (from Vercel step)
8. Deploy

### Step 4: Deploy Web Dashboard (Vercel)
1. Create a Vercel account
2. New Project → import your GitHub repo
3. Set Root Directory: `web_dashboard`
4. Add Env Var:
   - `VITE_API_BASE_URL` = your Render backend URL
5. Deploy

### Step 5: Make the Mobile App installable (no coding)
**Option A (recommended): Codemagic (build APK from GitHub)**
1. Create Codemagic account → connect GitHub repo
2. Select Flutter project path: `mobile_flutter`
3. Set environment variable (optional):
   - `API_BASE_URL` = your Render backend URL
4. Build Android **APK**
5. Download APK and install on phones (enable “Install unknown apps”)

**Option B: Ask any Android developer to build APK once**
They run `flutter build apk` and send you the APK file.

> When you’re ready for Play Store, the same build can be uploaded.

### IMPORTANT: Create your driver user
After backend is deployed, use a tool like Postman or add a small admin UI later.
For MVP, you can temporarily create driver users directly in the database (Supabase table `User`) with:
- role = DRIVER
- username/password hash (we can add an admin “Create User” screen next)

If you want, I can upgrade the dashboard to include **Create Users** (Admin) so you never touch the database.
