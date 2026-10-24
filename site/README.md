## Docker

Din rădăcina proiectului, pornește site-ul împreună cu API-ul și panoul admin:

```powershell
docker compose -f backend/docker-compose.yml up --build -d
```

Deschide `http://localhost:3002`. Comanda implicită rulează build-ul optimizat (`next start`), fără compilarea fiecărei pagini la navigare. După modificări în `site`, reconstruiește containerul cu `docker compose -f backend/docker-compose.yml up -d --build site`.

Pentru editări cu actualizare automată folosește varianta de dezvoltare (prima accesare a unei pagini poate fi mai lentă):

```powershell
docker compose -f backend/docker-compose.yml -f backend/docker-compose.dev.yml up -d --build site
```

Ca să revii la varianta rapidă, rulează din nou comanda implicită cu `--build`. Navigarea cu `next/link` preîncarcă paginile în modul de producție.
Pagina principală `/` afișează direct anunțurile. Prezentarea platformei este la `/despre-noi`, iar vechea adresă `/archive` redirecționează către `/`.
Site-ul citește `site/.env` pentru a alege backendul. Copiază `site/.env.example` în `site/.env`, apoi setează `SITE_USE_PRODUCTION_BACKEND=true` pentru API-ul live (`SITE_PRODUCTION_BACKEND_API_URL`) sau `false` pentru API-ul local. În Docker, adresa locală este `http://api:3000/api`; când rulezi site-ul separat, adresa implicită este `http://localhost:3000/api`. Repornește containerul site-ului după schimbarea `.env`:

```powershell
docker compose -f backend/docker-compose.yml restart site
```

Aceeași alegere este folosită pentru lista de anunțuri, pagina fiecărui anunț și contul utilizatorului. Containerul citește `site/.env` la pornire dacă fișierul există.

Lista publică de produse este partajată între paginile de anunțuri, detalii și favorite într-un cache de server de 10 secunde, invalidat imediat după publicarea sau editarea unui anunț prin site. Pagina de anunțuri încarcă separat componenta hărții; imaginile cardurilor de sub hartă se încarcă pe măsură ce intră în ecran. Acestea reduc cererile repetate și codul necesar pentru navigarea inițială.

Când folosești API-ul live, poți porni doar site-ul, fără API-ul local:

```powershell
docker compose -f backend/docker-compose.yml up --build -d site
```

Contul utilizatorului este la `http://localhost:3002/account`. Loginul folosește API-ul PINLEND, iar sesiunea este păstrată într-un cookie HttpOnly. Pentru întoarcerea din Stripe Connect către site, API-ul folosește `SITE_PUBLIC_URL` (implicit `http://localhost:3002` în Docker).

Mesajele sunt la `http://localhost:3002/mesaje`. Din pagina unui anunț poți începe o conversație cu proprietarul; lista, trimiterea, citirea și ștergerea conversațiilor folosesc același API ca aplicația mobilă. Conversația deschisă se actualizează la fiecare cinci secunde cât timp pagina este vizibilă.

Funcțiile contului sunt accesibile și pe web: `/anunturile-mele` pentru publicare, editare și perioade blocate, `/vizionari` pentru cereri și plăți de vizionare, `/colegi` pentru cereri de coleg, `/retur` pentru instrucțiunile de descărcare a aplicației în care se face returul cu QR, `/notificari` pentru activitatea contului și `/favorite` pentru anunțuri salvate în cont. Favoritele se sincronizează cu aplicația mobilă prin API-ul `favorites`; listele locale mai vechi sunt importate automat după autentificare. Arhiva include căutare, filtre și afișarea locațiilor pe hartă. Recenziile se pot publica din pagina anunțului după o închiriere eligibilă.

Hărțile web folosesc MapLibre și date OpenStreetMap servite de [OpenFreeMap](https://openfreemap.org/), fără cheie API. Stilul din `public/maps/pinlend-style.json` adaptează paleta `assets/maps/altus_map_3.json` din Flutter: teren gri deschis, apă albastră și fără puncte de interes sau transport. Atribuirea rămâne vizibilă pe hartă. Serviciul public OpenFreeMap este gratuit, inclusiv pentru uz comercial, dar nu oferă SLA; dacă traficul sau disponibilitatea cer alt furnizor, schimbați sursele din stilul hărții.

Butonul „Închiriază” din pagina unui anunț deschide `/inchiriaza/[slug]`. Fluxul folosește același backend ca aplicația mobilă: verifică disponibilitatea, creează cererea, încarcă PDF-ul semnat, autorizează plata prin Stripe și cere verificarea identității înainte de a trimite cererea proprietarului. Cererile întrerupte se pot relua din secțiunea „Închirieri” a contului; proprietarul poate accepta sau refuza acolo cererile pregătite. Modul Stripe (test/live) este determinat de backendul ales și de cheile configurate pe acesta.

This is a [Next.js](https://nextjs.org) project bootstrapped with [`create-next-app`](https://nextjs.org/docs/pages/api-reference/create-next-app).

## Getting Started

First, run the development server:

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

You can start editing the page by modifying `pages/index.js`. The page auto-updates as you edit the file.

[API routes](https://nextjs.org/docs/pages/building-your-application/routing/api-routes) can be accessed on [http://localhost:3000/api/hello](http://localhost:3000/api/hello). This endpoint can be edited in `pages/api/hello.js`.

The `pages/api` directory is mapped to `/api/*`. Files in this directory are treated as [API routes](https://nextjs.org/docs/pages/building-your-application/routing/api-routes) instead of React pages.

This project uses [`next/font`](https://nextjs.org/docs/pages/building-your-application/optimizing/fonts) to automatically optimize and load [Geist](https://vercel.com/font), a new font family for Vercel.

## Learn More

To learn more about Next.js, take a look at the following resources:

- [Next.js Documentation](https://nextjs.org/docs) - learn about Next.js features and API.
- [Learn Next.js](https://nextjs.org/learn-pages-router) - an interactive Next.js tutorial.

You can check out [the Next.js GitHub repository](https://github.com/vercel/next.js) - your feedback and contributions are welcome!

## Deploy on Vercel

The easiest way to deploy your Next.js app is to use the [Vercel Platform](https://vercel.com/new?utm_medium=default-template&filter=next.js&utm_source=create-next-app&utm_campaign=create-next-app-readme) from the creators of Next.js.

Check out our [Next.js deployment documentation](https://nextjs.org/docs/pages/building-your-application/deploying) for more details.
