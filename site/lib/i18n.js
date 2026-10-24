const messages = {
  ro: {
    listings: "Anunțuri",
    messages: "Mesaje",
    viewings: "Vizionări",
    findRoommate: "Caută coleg",
    favorites: "Favorite",
    notifications: "Notificări",
    account: "Contul meu",
    menu: "Meniu",
    close: "Închide",
    about: "Despre noi",
    features: "Funcționalități",
    download: "Descarcă",
    navigation: "Navigare principală",
    language: "Limba site-ului",
  },
  en: {
    listings: "Listings",
    messages: "Messages",
    viewings: "Viewings",
    findRoommate: "Find a roommate",
    favorites: "Favorites",
    notifications: "Notifications",
    account: "My account",
    menu: "Menu",
    close: "Close",
    about: "About us",
    features: "Features",
    download: "Download",
    navigation: "Main navigation",
    language: "Site language",
  },
};

export function translations(locale) {
  return messages[locale] || messages.ro;
}
