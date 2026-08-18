import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return AppLocalizations(Localizations.localeOf(context));
  }

  bool get isRomanian => locale.languageCode == 'ro';

  String choose(String ro, String en) {
    if (!isRomanian) {
      return _normalizeBrand(_englishCorrections[en] ?? en);
    }

    return _normalizeBrand(
      _romanianCorrections[ro] ?? _applyRomanianDiacritics(ro),
    );
  }

  String get appName => 'Lend';
  String get languageCode => isRomanian ? 'RO' : 'EN';
  String get switchToLanguage => isRomanian ? 'English' : 'Română';

  String get newAccount => choose('Cont nou', 'New account');
  String get heroTitle =>
      choose('Imprumuta. Ofera. Simplu.', 'Borrow. Share. Simple.');
  String get heroSubtitle => isRomanian
      ? 'Comunitatea ta pentru obiecte de calitate.'
      : 'Your community for quality items.';
  String get startNow => choose('Incepe acum', 'Start now');
  String get alreadyHaveAccount =>
      choose('Am deja cont', 'I already have an account');
  String get terms => choose('TERMENI', 'TERMS');
  String get privacy => choose('CONFIDENTIALITATE', 'PRIVACY');
  String get contact => 'CONTACT';

  String get exploreObjects => choose('Exploreaza Obiecte', 'Explore Items');
  String get all => choose('Toate', 'All');
  String get recommended => choose('Recomandate', 'Recommended');
  String get seeAll => choose('Vezi tot', 'See all');
  String get nearYou => choose('Aproape de tine', 'Near you');
  String get map => choose('Harta', 'Map');
  String get dayShort => choose('/zi', '/day');
  String get productsLoadError => choose(
    'Nu am putut incarca produsele din DB.',
    'We could not load products from the database.',
  );
  String get retry => choose('Reincearca', 'Retry');
  String get emptyProducts => choose(
    'Nu exista produse disponibile momentan.',
    'There are no products available right now.',
  );

  String get navExplore => choose('Exploreaza', 'Explore');
  String get navListings => choose('Anunturi', 'Listings');
  String get navRentals => choose('Inchirieri', 'Rentals');
  String get navProfile => choose('Profil', 'Profile');

  static String _applyRomanianDiacritics(String value) {
    var result = value;
    for (final entry in _romanianWordCorrections.entries) {
      result = result.replaceAllMapped(
        RegExp(r'\b' + RegExp.escape(entry.key) + r'\b', caseSensitive: false),
        (match) => _matchCase(match.group(0)!, entry.value),
      );
    }
    return result;
  }

  static String _matchCase(String source, String replacement) {
    if (source.toUpperCase() == source) {
      return replacement.toUpperCase();
    }
    if (source.length > 1 && source[0].toUpperCase() == source[0]) {
      return replacement[0].toUpperCase() + replacement.substring(1);
    }
    return replacement;
  }

  static String _normalizeBrand(String value) {
    return value
        .replaceAll('BorrowIt Protect', 'Lend Protect')
        .replaceAll('BorrowTrust', 'LendTrust')
        .replaceAll('BorrowIt', 'Lend');
  }

  static const Map<String, String> _romanianCorrections = {
    'Accept': 'Acceptă',
    'Adauga anunt': 'Adaugă anunț',
    'Adauga in cos': 'Adaugă în coș',
    'Adauga media': 'Adaugă media',
    'Alege o categorie': 'Alege o categorie',
    'Alege perioada': 'Alege perioada',
    'Ai deja cont?': 'Ai deja cont?',
    'Am deja cont': 'Am deja cont',
    'Am uitat parola': 'Am uitat parola',
    'Anunturile mele': 'Anunțurile mele',
    'Asigurare inclusa': 'Asigurare inclusă',
    'Autentificarea cu Apple nu a reusit.':
        'Autentificarea cu Apple nu a reușit.',
    'Autentificarea cu Google nu a reusit.':
        'Autentificarea cu Google nu a reușit.',
    'Bine ai revenit': 'Bine ai revenit',
    'Casa & Gradina': 'Casă & Grădină',
    'Castigat': 'Câștigat',
    'Categorie': 'Categorie',
    'Citeste tot': 'Citește tot',
    'Conecteaza-te': 'Conectează-te',
    'Confirmi returul?': 'Confirmi returul?',
    'Cont creat pentru': 'Cont creat pentru',
    'Cont nou': 'Cont nou',
    'Cosul meu': 'Coșul meu',
    'Cosul tau este gol': 'Coșul tău este gol',
    'Creeaza cont': 'Creează cont',
    'Creeaza cont nou': 'Creează cont nou',
    'Data inceput': 'Data de început',
    'Data sfarsit': 'Data de sfârșit',
    'Deconectare': 'Deconectare',
    'Descriere': 'Descriere',
    'Detalii produs': 'Detalii produs',
    'Durata': 'Durată',
    'Durata totala': 'Durată totală',
    'Editeaza': 'Editează',
    'Editeaza anuntul': 'Editează anunțul',
    'Electronice': 'Electronice',
    'Esti la zi': 'Ești la zi',
    'Expira azi': 'Expiră azi',
    'Exploreaza': 'Explorează',
    'Exploreaza Obiecte': 'Explorează obiecte',
    'Finalizare retur': 'Finalizare retur',
    'Fotografii': 'Fotografii',
    'Garantie': 'Garanție',
    'Google nu a returnat un token de autentificare.':
        'Google nu a returnat un token de autentificare.',
    'Harta': 'Hartă',
    'In curs': 'În curs',
    'Inapoi la inchirieri': 'Înapoi la închirieri',
    'Incepe acum': 'Începe acum',
    'Inchiriaza acum': 'Închiriază acum',
    'Inchirieri': 'Închirieri',
    'Inchirierile mele': 'Închirierile mele',
    'Inchiriat': 'Închiriat',
    'Informatii de baza': 'Informații de bază',
    'Locatie': 'Locație',
    'Maxim 8 fisiere': 'Maximum 8 fișiere',
    'Metode de plata': 'Metode de plată',
    'Nu ai anunturi inca': 'Nu ai anunțuri încă',
    'Nu ai istoric inca': 'Nu ai istoric încă',
    'Nu ai un cont?': 'Nu ai cont?',
    'Nu am putut incarca produsele din DB.':
        'Nu am putut încărca produsele din baza de date.',
    'Nu exista produse disponibile momentan.':
        'Nu există produse disponibile momentan.',
    'Nu se poate conecta la server.': 'Nu se poate conecta la server.',
    'Numar de telefon': 'Număr de telefon',
    'Numele articolului': 'Numele articolului',
    'Obiecte oferite': 'Obiecte oferite',
    'Oras': 'Oraș',
    'Parola': 'Parolă',
    'Parola ta': 'Parola ta',
    'Perioada': 'Perioadă',
    'Perioada selectata': 'Perioada selectată',
    'Pret / zi': 'Preț / zi',
    'Pret pe ora': 'Preț pe oră',
    'Pret pe zi': 'Preț pe zi',
    'Pret total': 'Preț total',
    'Profilul meu': 'Profilul meu',
    'Publica anuntul': 'Publică anunțul',
    'Reincearca': 'Reîncearcă',
    'Retur in curs': 'Retur în curs',
    'Salveaza modificarile': 'Salvează modificările',
    'Scaneaza returul': 'Scanează returul',
    'Schimba poza de profil': 'Schimbă poza de profil',
    'Se incarca...': 'Se încarcă...',
    'Se trimite...': 'Se trimite...',
    'Semnati aici': 'Semnați aici',
    'Semneaza si trimite': 'Semnează și trimite',
    'Securizat': 'Securizat',
    'Securizat prin BorrowTrust': 'Securizat prin LendTrust',
    'Sterge semnatura': 'Șterge semnătura',
    'Taxa serviciu': 'Taxă serviciu',
    'Trimite mesaj': 'Trimite mesaj',
    'Unelte': 'Unelte',
    'Unelte & DIY': 'Unelte & DIY',
    'Utilizati degetul': 'Utilizați degetul',
    'Utilizator verificat': 'Utilizator verificat',
    'Vezi toate': 'Vezi toate',
    'Vezi tot': 'Vezi tot',
    'Verificare': 'Verificare',
  };

  static const Map<String, String> _englishCorrections = {
    'Do not have an account?': "Don't have an account?",
    'Post item': 'Publish listing',
    'Lent items': 'Listed items',
  };

  static const Map<String, String> _romanianWordCorrections = {
    'adaug': 'adaugă',
    'adauga': 'adaugă',
    'anunt': 'anunț',
    'anunturi': 'anunțuri',
    'asigurare': 'asigurare',
    'bucuresti': 'București',
    'casa': 'casă',
    'castigat': 'câștigat',
    'citeste': 'citește',
    'conecteaza': 'conectează',
    'cos': 'coș',
    'cosul': 'coșul',
    'creeaza': 'creează',
    'deschide': 'deschide',
    'editeaza': 'editează',
    'esti': 'ești',
    'expira': 'expiră',
    'exploreaza': 'explorează',
    'fisiere': 'fișiere',
    'garantie': 'garanție',
    'gradina': 'grădină',
    'harta': 'hartă',
    'inca': 'încă',
    'incarca': 'încarcă',
    'inceput': 'început',
    'incepe': 'începe',
    'inchiriaza': 'închiriază',
    'inchiriat': 'închiriat',
    'inchiriez': 'închiriez',
    'inchirieri': 'închirieri',
    'inchirierile': 'închirierile',
    'informatii': 'informații',
    'inclusa': 'inclusă',
    'inclus': 'inclus',
    'inregistrare': 'înregistrare',
    'inapoi': 'înapoi',
    'in': 'în',
    'intre': 'între',
    'locatar': 'chiriaș',
    'maxim': 'maximum',
    'modificarile': 'modificările',
    'nicio': 'nicio',
    'notificari': 'notificări',
    'numar': 'număr',
    'ora': 'oră',
    'oras': 'oraș',
    'parola': 'parolă',
    'perioada': 'perioadă',
    'plata': 'plată',
    'pret': 'preț',
    'proprietar': 'proprietar',
    'publica': 'publică',
    'reincerca': 'reîncearcă',
    'reincearca': 'reîncearcă',
    'retur': 'retur',
    'reusit': 'reușit',
    'salveaza': 'salvează',
    'scaneaza': 'scanează',
    'securizata': 'securizată',
    'semnati': 'semnați',
    'semneaza': 'semnează',
    'semnatura': 'semnătură',
    'sfarsit': 'sfârșit',
    'stergere': 'ștergere',
    'sterge': 'șterge',
    'suport': 'suport',
    'taxa': 'taxă',
    'toti': 'toți',
    'tranzactie': 'tranzacție',
    'utilizati': 'utilizați',
    'verificata': 'verificată',
    'verificat': 'verificat',
  };
}
