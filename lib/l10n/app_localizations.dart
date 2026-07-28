import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return AppLocalizations(Localizations.localeOf(context));
  }

  bool get isRomanian => locale.languageCode == 'ro';

  String choose(String ro, String en) => isRomanian ? ro : en;

  String get appName => 'BorrowIt';
  String get languageCode => isRomanian ? 'RO' : 'EN';
  String get switchToLanguage => isRomanian ? 'English' : 'Romana';

  String get newAccount => isRomanian ? 'Cont nou' : 'New account';
  String get heroTitle =>
      isRomanian ? 'Imprumuta. Ofera. Simplu.' : 'Borrow. Share. Simple.';
  String get heroSubtitle => isRomanian
      ? 'Comunitatea ta pentru obiecte de calitate.'
      : 'Your community for quality items.';
  String get startNow => isRomanian ? 'Incepe acum' : 'Start now';
  String get alreadyHaveAccount =>
      isRomanian ? 'Am deja cont' : 'I already have an account';
  String get terms => isRomanian ? 'TERMENI' : 'TERMS';
  String get privacy => isRomanian ? 'CONFIDENTIALITATE' : 'PRIVACY';
  String get contact => 'CONTACT';

  String get exploreObjects =>
      isRomanian ? 'Exploreaza Obiecte' : 'Explore Items';
  String get all => isRomanian ? 'Toate' : 'All';
  String get recommended => isRomanian ? 'Recomandate' : 'Recommended';
  String get seeAll => isRomanian ? 'Vezi tot' : 'See all';
  String get nearYou => isRomanian ? 'Aproape de tine' : 'Near you';
  String get map => isRomanian ? 'Harta' : 'Map';
  String get dayShort => isRomanian ? '/zi' : '/day';
  String get productsLoadError => isRomanian
      ? 'Nu am putut incarca produsele din DB.'
      : 'We could not load products from the database.';
  String get retry => isRomanian ? 'Reincearca' : 'Retry';
  String get emptyProducts => isRomanian
      ? 'Nu exista produse disponibile momentan.'
      : 'There are no products available right now.';

  String get navExplore => isRomanian ? 'Exploreaza' : 'Explore';
  String get navListings => isRomanian ? 'Anunturi' : 'Listings';
  String get navRentals => isRomanian ? 'Inchirieri' : 'Rentals';
  String get navProfile => isRomanian ? 'Profil' : 'Profile';
}
