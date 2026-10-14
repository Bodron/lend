# PINLEND Admin

## Docker

Din rădăcina proiectului, pornește backendul și panoul printr-o singură comandă:

```powershell
docker compose -f backend/docker-compose.yml up --build -d
```

Panoul este la `http://localhost:3001`. În container, `BACKEND_API_URL` folosește serviciul `api` din rețeaua Compose. Configurează mai întâi `backend/.env`, apoi acordă rolul unui cont existent cu `docker compose -f backend/docker-compose.yml exec api node scripts/grant-super-admin.js admin@example.com`.

Pentru un cont administrativ nou, după ce MongoDB este accesibil, rulează din rădăcina proiectului:

```powershell
Read-Host "Parola noului cont" | docker compose -f backend/docker-compose.yml exec -T api node scripts/create-super-admin.js cosmin@admin.com
```

Scriptul refuză să modifice un cont cu aceeași adresă, dacă există deja.

Panou Next.js pentru backendul NestJS din `../backend`. Rolul `super_admin` este verificat în backend la fiecare cerere administrativă. Interfața folosește un cookie HttpOnly pentru sesiune și trimite cererile prin rutele sale server-side.

## Pornire locală

1. Pornește MongoDB și backendul (`cd ../backend; npm run start:dev`).
2. Creează un cont normal în aplicație, apoi acordă rolul explicit din folderul `backend`:

   ```powershell
   $env:MONGODB_URI = "mongodb://localhost:27017"
   node scripts/grant-super-admin.js admin@example.com
   ```

   Scriptul modifică doar un cont existent. Folosește baza de date corectă (`MONGODB_DB` dacă nu este `lend`). Nu rula comanda pentru o adresă necontrolată de tine.
3. În `admin`, copiază `.env.example` în `.env.local`, setează `BACKEND_API_URL` spre API, apoi rulează `npm install` și `npm run dev`. Deschide `http://localhost:3001`.

În producție, setează un `JWT_SECRET` puternic în backend și servește adminul prin HTTPS. Backendul refuză să pornească în modul production cu secretul demonstrativ.

## Ce arată panoul

Include și proprietarii ordonați după valoarea închirierilor cu plată capturată, cu vânzările și transferurile efectuate. Lista este paginată.

Prezentare, utilizatori, cereri de ștergere, anunțuri, închirieri și vizionări, cu paginare. Închiderea unui anunț cere motiv și oprește afișarea publică și cererile noi; comenzile și vizionările existente rămân în istoric. Redeschiderea este posibilă din panou.

Sumele sunt în RON și reflectă câmpurile salvate în MongoDB. Totalul capturat al închirierilor include garanții. Rambursările, disputele și plățile bancare externe nu sunt reconciliate în aceste agregate; folosește Stripe pentru raportarea financiară definitivă. Cererile de ștergere sunt vizibile, dar panoul nu șterge conturi automat.
