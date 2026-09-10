# Notificări push pentru mesaje

Implementarea mobilă înregistrează tokenul FCM după autentificare, îl actualizează la reluarea aplicației și la rotație și îl elimină la logout. La apăsarea notificării deschide conversația după verificarea contului destinatar. iOS afișează notificări inclusiv în prim-plan; Android afișează un SnackBar în prim-plan și notificări de sistem în fundal. Web/desktop nu sunt înregistrate pentru push.

Backendul trimite notificarea doar destinatarului după salvarea mesajului, atât pentru HTTP, cât și pentru Socket.IO. Notificarea are un text generic, fără conținutul mesajului pe ecranul blocat. Tokenurile invalidate de Firebase sunt eliminate. Eșecurile de livrare sunt jurnalizate și nu anulează mesajul. Nu există o coadă persistentă de reîncercare: o notificare poate fi pierdută dacă procesul se oprește imediat după salvare sau Firebase este indisponibil; mesajul rămâne în chat.

## Configurare necesară pe server

1. În Firebase, proiectul `pinlend-de45e`: Project settings → Service accounts → Firebase Admin SDK. Configurează acreditările pentru backend (preferabil identitate de serviciu/ADC în Google Cloud; pe alte platforme, secretul JSON al unui service account cu permisiunea de trimitere FCM).
2. Setează `FIREBASE_SERVICE_ACCOUNT_JSON` ca secret de mediu pe platforma backendului, cu conținutul complet al JSON-ului. Alternativ, setează `FIREBASE_USE_ADC=true` și configurează Application Default Credentials. `FIREBASE_PROJECT_ID=pinlend-de45e`.
3. Cheia APNs `.p8` rămâne în Firebase Console. Ea NU este credentialul Firebase Admin pentru server. Nu pune niciun fișier privat în Git sau în aplicație.
4. Publică backendul actualizat. Acesta este un repository Git separat în `backend/`. Dacă lipsesc acreditările, serverul pornește cu avertismentul `Push disabled` și chatul continuă să funcționeze.

## iOS / Codemagic

- Cheia APNs Production trebuie încărcată pentru `com.lend.ro` în proiectul Firebase de mai sus.
- În Apple Developer, identificatorul `com.lend.ro` trebuie să aibă Push Notifications activat.
- Regenerează profilul App Store după activarea Push Notifications și actualizează profilul folosit de Codemagic. Profilul trebuie să includă `aps-environment=production`.
- Rulează workflow-ul existent `ios-app-store`. `APP_BASE_URL` trebuie să indice backendul public actualizat, accesibil prin HTTPS de pe iPhone.
- Fișierele proiectului includ entitlement-ul Production și `UIBackgroundModes: remote-notification`. FlutterFire inițializează Firebase din `firebase_options.dart`.

## Verificare pe două conturi

1. Instalează buildul nou din TestFlight pe iPhone, autentifică-te ca destinatar și acceptă notificările.
2. Din alt cont, trimite un mesaj către acesta. Testează aplicația în prim-plan, în fundal și închisă normal.
3. Apasă notificarea: trebuie să deschidă conversația pentru produsul corect. Nu testa după force-quit ca unic criteriu de livrare iOS.
4. Trimite un răspuns: numai celălalt cont trebuie notificat.
5. Ieși din cont, trimite alt mesaj către vechiul cont: dispozitivul nu trebuie notificat. Reautentifică-te cu alt cont și repetă.
6. Verifică logurile serverului pentru erori FCM/APNs. Acceptarea cheii în consolă și compilarea codului nu dovedesc livrarea pe dispozitiv.
