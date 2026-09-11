import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'generated_localizations_en.dart';
import 'generated_localizations_ro.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of GeneratedLocalizations
/// returned by `GeneratedLocalizations.of(context)`.
///
/// Applications need to include `GeneratedLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/generated_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: GeneratedLocalizations.localizationsDelegates,
///   supportedLocales: GeneratedLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the GeneratedLocalizations.supportedLocales
/// property.
abstract class GeneratedLocalizations {
  GeneratedLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static GeneratedLocalizations of(BuildContext context) {
    return Localizations.of<GeneratedLocalizations>(
      context,
      GeneratedLocalizations,
    )!;
  }

  static const LocalizationsDelegate<GeneratedLocalizations> delegate =
      _GeneratedLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ro'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Pinlend'**
  String get appName;

  /// No description provided for @nearYou.
  ///
  /// In en, this message translates to:
  /// **'Near you'**
  String get nearYou;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @productsLoadError.
  ///
  /// In en, this message translates to:
  /// **'We could not load products from the database.'**
  String get productsLoadError;

  /// No description provided for @emptyProducts.
  ///
  /// In en, this message translates to:
  /// **'There are no products available right now.'**
  String get emptyProducts;

  /// No description provided for @exploreObjects.
  ///
  /// In en, this message translates to:
  /// **'Explore items'**
  String get exploreObjects;

  /// No description provided for @dayShort.
  ///
  /// In en, this message translates to:
  /// **'/day'**
  String get dayShort;

  /// No description provided for @navExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get navExplore;

  /// No description provided for @navListings.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get navListings;

  /// No description provided for @navRentals.
  ///
  /// In en, this message translates to:
  /// **'Rentals'**
  String get navRentals;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @myListings.
  ///
  /// In en, this message translates to:
  /// **'My listings'**
  String get myListings;

  /// No description provided for @myRentals.
  ///
  /// In en, this message translates to:
  /// **'My rentals'**
  String get myRentals;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get myProfile;

  /// No description provided for @addListing.
  ///
  /// In en, this message translates to:
  /// **'Add listing'**
  String get addListing;

  /// No description provided for @newAccount.
  ///
  /// In en, this message translates to:
  /// **'New account'**
  String get newAccount;

  /// No description provided for @heroTitle.
  ///
  /// In en, this message translates to:
  /// **'Borrow. Share. Simple.'**
  String get heroTitle;

  /// No description provided for @heroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your community for quality items.'**
  String get heroSubtitle;

  /// No description provided for @startNow.
  ///
  /// In en, this message translates to:
  /// **'Start now'**
  String get startNow;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get alreadyHaveAccount;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'TERMS'**
  String get terms;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'PRIVACY'**
  String get privacy;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'CONTACT'**
  String get contact;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @emptyFavorites.
  ///
  /// In en, this message translates to:
  /// **'You do not have favorite listings yet.'**
  String get emptyFavorites;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account to continue'**
  String get signInSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get emailHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @yourPassword.
  ///
  /// In en, this message translates to:
  /// **'Your password'**
  String get yourPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'OR CONTINUE WITH'**
  String get orContinueWith;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Do not have an account?'**
  String get noAccount;

  /// No description provided for @createNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Create new account'**
  String get createNewAccount;

  /// No description provided for @cannotConnectServer.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to the server.'**
  String get cannotConnectServer;

  /// No description provided for @appleMissingToken.
  ///
  /// In en, this message translates to:
  /// **'Apple did not return an authentication token.'**
  String get appleMissingToken;

  /// No description provided for @appleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in failed.'**
  String get appleSignInFailed;

  /// No description provided for @googleMissingToken.
  ///
  /// In en, this message translates to:
  /// **'Google did not return an authentication token.'**
  String get googleMissingToken;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed.'**
  String get googleSignInFailed;

  /// No description provided for @safeVerifiedCommunity.
  ///
  /// In en, this message translates to:
  /// **'Safe and verified community'**
  String get safeVerifiedCommunity;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @createAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start borrowing and sharing today.'**
  String get createAccountSubtitle;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: Alex Smith'**
  String get fullNameHint;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'+1 555 000 0000'**
  String get phoneHint;

  /// No description provided for @passwordMinHint.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordMinHint;

  /// No description provided for @alreadyHaveAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccountQuestion;

  /// No description provided for @acceptTermsWarning.
  ///
  /// In en, this message translates to:
  /// **'You must accept the terms to continue.'**
  String get acceptTermsWarning;

  /// No description provided for @accountCreatedFor.
  ///
  /// In en, this message translates to:
  /// **'Account created for'**
  String get accountCreatedFor;

  /// No description provided for @iAgreeTo.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get iAgreeTo;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsAndConditions;

  /// No description provided for @andWord.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get andWord;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @registerFooter.
  ///
  /// In en, this message translates to:
  /// **'© 2024 Lend. Shared economy for a better future.'**
  String get registerFooter;

  /// No description provided for @joinCommunity.
  ///
  /// In en, this message translates to:
  /// **'Join the community.'**
  String get joinCommunity;

  /// No description provided for @joinCommunityBody.
  ///
  /// In en, this message translates to:
  /// **'Save money and protect the environment by sharing resources with your neighbors.'**
  String get joinCommunityBody;

  /// No description provided for @secureTransactions.
  ///
  /// In en, this message translates to:
  /// **'Secure transactions'**
  String get secureTransactions;

  /// No description provided for @secureTransactionsBody.
  ///
  /// In en, this message translates to:
  /// **'Every member is verified for your safety.'**
  String get secureTransactionsBody;

  /// No description provided for @securedByLendTrust.
  ///
  /// In en, this message translates to:
  /// **'Secured by LendTrust'**
  String get securedByLendTrust;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @rented.
  ///
  /// In en, this message translates to:
  /// **'Rented'**
  String get rented;

  /// No description provided for @totalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total income'**
  String get totalIncome;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @noListingsYet.
  ///
  /// In en, this message translates to:
  /// **'No listings yet'**
  String get noListingsYet;

  /// No description provided for @couldNotLoadListings.
  ///
  /// In en, this message translates to:
  /// **'Could not load listings'**
  String get couldNotLoadListings;

  /// No description provided for @couldNotLoadListingsBody.
  ///
  /// In en, this message translates to:
  /// **'Check that the backend is running and try again.'**
  String get couldNotLoadListingsBody;

  /// No description provided for @emptyListingsBody.
  ///
  /// In en, this message translates to:
  /// **'Listings created by your account will appear here directly from the database.'**
  String get emptyListingsBody;

  /// No description provided for @profileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load profile'**
  String get profileLoadError;

  /// No description provided for @profileLoadErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Check the backend and try again.'**
  String get profileLoadErrorBody;

  /// No description provided for @avatarReadError.
  ///
  /// In en, this message translates to:
  /// **'Could not read the selected image.'**
  String get avatarReadError;

  /// No description provided for @avatarTypeWarning.
  ///
  /// In en, this message translates to:
  /// **'Choose a JPG, PNG, or WebP image.'**
  String get avatarTypeWarning;

  /// No description provided for @listedItems.
  ///
  /// In en, this message translates to:
  /// **'Lent items'**
  String get listedItems;

  /// No description provided for @earned.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get earned;

  /// No description provided for @changeProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get changeProfilePhoto;

  /// No description provided for @accountAndSafety.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT & SAFETY'**
  String get accountAndSafety;

  /// No description provided for @verification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verification;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment methods'**
  String get paymentMethods;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @verifiedUser.
  ///
  /// In en, this message translates to:
  /// **'Verified user'**
  String get verifiedUser;

  /// No description provided for @profileSyncBody.
  ///
  /// In en, this message translates to:
  /// **'Data is synchronized with your database profile.'**
  String get profileSyncBody;

  /// No description provided for @availablePayout.
  ///
  /// In en, this message translates to:
  /// **'{amount} RON available'**
  String availablePayout(int amount);

  /// No description provided for @payoutStripeReady.
  ///
  /// In en, this message translates to:
  /// **'Your Stripe account is ready for withdrawals.'**
  String get payoutStripeReady;

  /// No description provided for @payoutStripeSetup.
  ///
  /// In en, this message translates to:
  /// **'Configure Stripe to receive your money.'**
  String get payoutStripeSetup;

  /// No description provided for @receiveMoney.
  ///
  /// In en, this message translates to:
  /// **'Receive money'**
  String get receiveMoney;

  /// No description provided for @profileRatingListings.
  ///
  /// In en, this message translates to:
  /// **'{rating} ({count} listings)'**
  String profileRatingListings(String rating, int count);

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @readAll.
  ///
  /// In en, this message translates to:
  /// **'Read all'**
  String get readAll;

  /// No description provided for @youAreUpToDate.
  ///
  /// In en, this message translates to:
  /// **'You are up to date'**
  String get youAreUpToDate;

  /// No description provided for @newNotifications.
  ///
  /// In en, this message translates to:
  /// **'{count} new notifications'**
  String newNotifications(int count);

  /// No description provided for @notificationsSummaryBody.
  ///
  /// In en, this message translates to:
  /// **'Important account activity appears here.'**
  String get notificationsSummaryBody;

  /// No description provided for @unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unread;

  /// No description provided for @noUnreadNotifications.
  ///
  /// In en, this message translates to:
  /// **'No unread notifications'**
  String get noUnreadNotifications;

  /// No description provided for @notificationReturnReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Return ready to scan'**
  String get notificationReturnReadyTitle;

  /// No description provided for @notificationReturnReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Apartament Berceni 2 is waiting for QR confirmation.'**
  String get notificationReturnReadyBody;

  /// No description provided for @notificationReturnReadyTime.
  ///
  /// In en, this message translates to:
  /// **'5 min ago'**
  String get notificationReturnReadyTime;

  /// No description provided for @notificationAvatarUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated'**
  String get notificationAvatarUpdatedTitle;

  /// No description provided for @notificationAvatarUpdatedBody.
  ///
  /// In en, this message translates to:
  /// **'Your avatar is synced in profile and the top bar.'**
  String get notificationAvatarUpdatedBody;

  /// No description provided for @notificationAvatarUpdatedTime.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get notificationAvatarUpdatedTime;

  /// No description provided for @notificationPaymentCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Check payment method'**
  String get notificationPaymentCheckTitle;

  /// No description provided for @notificationPaymentCheckBody.
  ///
  /// In en, this message translates to:
  /// **'Add or confirm your card before the next rental.'**
  String get notificationPaymentCheckBody;

  /// No description provided for @notificationPaymentCheckTime.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get notificationPaymentCheckTime;

  /// No description provided for @notificationListingLiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Your listing is live'**
  String get notificationListingLiveTitle;

  /// No description provided for @notificationListingLiveBody.
  ///
  /// In en, this message translates to:
  /// **'Apartament Berceni 2 now appears in search.'**
  String get notificationListingLiveBody;

  /// No description provided for @notificationListingLiveTime.
  ///
  /// In en, this message translates to:
  /// **'2 days'**
  String get notificationListingLiveTime;

  /// No description provided for @notificationSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure session'**
  String get notificationSecurityTitle;

  /// No description provided for @notificationSecurityBody.
  ///
  /// In en, this message translates to:
  /// **'If you do not recognize activity, sign out from profile.'**
  String get notificationSecurityBody;

  /// No description provided for @notificationSecurityTime.
  ///
  /// In en, this message translates to:
  /// **'3 days'**
  String get notificationSecurityTime;

  /// No description provided for @myCart.
  ///
  /// In en, this message translates to:
  /// **'My cart'**
  String get myCart;

  /// No description provided for @cartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage the items prepared for rental.'**
  String get cartSubtitle;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @period.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get period;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @pricePerHourShort.
  ///
  /// In en, this message translates to:
  /// **'Price / hour'**
  String get pricePerHourShort;

  /// No description provided for @pricePerDayShort.
  ///
  /// In en, this message translates to:
  /// **'Price / day'**
  String get pricePerDayShort;

  /// No description provided for @pricePerMonthShort.
  ///
  /// In en, this message translates to:
  /// **'Price / month'**
  String get pricePerMonthShort;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @hoursCount.
  ///
  /// In en, this message translates to:
  /// **'{count} hours'**
  String hoursCount(int count);

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String daysCount(int count);

  /// No description provided for @oneMonth.
  ///
  /// In en, this message translates to:
  /// **'1 month'**
  String get oneMonth;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order summary'**
  String get orderSummary;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @serviceFee.
  ///
  /// In en, this message translates to:
  /// **'Service fee'**
  String get serviceFee;

  /// No description provided for @deposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get deposit;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @vatIncluded.
  ///
  /// In en, this message translates to:
  /// **'VAT included'**
  String get vatIncluded;

  /// No description provided for @continueToCheckout.
  ///
  /// In en, this message translates to:
  /// **'Continue to checkout'**
  String get continueToCheckout;

  /// No description provided for @securePayment.
  ///
  /// In en, this message translates to:
  /// **'SECURE PAYMENT'**
  String get securePayment;

  /// No description provided for @emptyCart.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get emptyCart;

  /// No description provided for @emptyCartBody.
  ///
  /// In en, this message translates to:
  /// **'Explore the community and find what you need.'**
  String get emptyCartBody;

  /// No description provided for @signInRequired.
  ///
  /// In en, this message translates to:
  /// **'You need to be signed in.'**
  String get signInRequired;

  /// No description provided for @periodBlocked.
  ///
  /// In en, this message translates to:
  /// **'The period has been blocked.'**
  String get periodBlocked;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// No description provided for @manualBlockDates.
  ///
  /// In en, this message translates to:
  /// **'Manually block dates'**
  String get manualBlockDates;

  /// No description provided for @selectPeriodStartEnd.
  ///
  /// In en, this message translates to:
  /// **'Select the start and end of the period.'**
  String get selectPeriodStartEnd;

  /// No description provided for @availabilityReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Optional reason: service, personal use'**
  String get availabilityReasonHint;

  /// No description provided for @blockPeriod.
  ///
  /// In en, this message translates to:
  /// **'Block period'**
  String get blockPeriod;

  /// No description provided for @manualBlocks.
  ///
  /// In en, this message translates to:
  /// **'Manual blocks'**
  String get manualBlocks;

  /// No description provided for @noManualBlocksThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No manual blocks this month.'**
  String get noManualBlocksThisMonth;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blocked;

  /// No description provided for @availableItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} available items'**
  String availableItemsCount(int count);

  /// No description provided for @emptyMapItems.
  ///
  /// In en, this message translates to:
  /// **'There are no items to show on the map.'**
  String get emptyMapItems;

  /// No description provided for @openItem.
  ///
  /// In en, this message translates to:
  /// **'Open item'**
  String get openItem;

  /// No description provided for @returnCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Return completed successfully'**
  String get returnCompletedTitle;

  /// No description provided for @returnCompletedBody.
  ///
  /// In en, this message translates to:
  /// **'Thank you for choosing our services. The rental has been closed, and the confirmation was saved to your account.'**
  String get returnCompletedBody;

  /// No description provided for @returnCompletedNote.
  ///
  /// In en, this message translates to:
  /// **'Everything is all set. You can find this rental in your history.'**
  String get returnCompletedNote;

  /// No description provided for @backToRentals.
  ///
  /// In en, this message translates to:
  /// **'Back to rentals'**
  String get backToRentals;

  /// No description provided for @confirmReturnTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm return?'**
  String get confirmReturnTitle;

  /// No description provided for @confirmReturnBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to confirm this QR code? The rental will be marked as completed.'**
  String get confirmReturnBody;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @invalidReturnQr.
  ///
  /// In en, this message translates to:
  /// **'This QR code is not a valid return code. Open the QR again from the active rental.'**
  String get invalidReturnQr;

  /// No description provided for @scanReturn.
  ///
  /// In en, this message translates to:
  /// **'Scan return'**
  String get scanReturn;

  /// No description provided for @waitingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for confirmation...'**
  String get waitingConfirmation;

  /// No description provided for @confirmingReturn.
  ///
  /// In en, this message translates to:
  /// **'Confirming return...'**
  String get confirmingReturn;

  /// No description provided for @scanQrShownByRenter.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code shown by the renter.'**
  String get scanQrShownByRenter;

  /// No description provided for @scanReturnHelp.
  ///
  /// In en, this message translates to:
  /// **'After scanning, the rental is marked completed.'**
  String get scanReturnHelp;

  /// No description provided for @reportProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get reportProblem;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupport;

  /// No description provided for @completeReturn.
  ///
  /// In en, this message translates to:
  /// **'Complete return'**
  String get completeReturn;

  /// No description provided for @returnInProgress.
  ///
  /// In en, this message translates to:
  /// **'Return in progress'**
  String get returnInProgress;

  /// No description provided for @showCodeToOwner.
  ///
  /// In en, this message translates to:
  /// **'Show this code to the owner'**
  String get showCodeToOwner;

  /// No description provided for @showCodeToOwnerBody.
  ///
  /// In en, this message translates to:
  /// **'The owner needs to scan this code to confirm the item was received in good condition.'**
  String get showCodeToOwnerBody;

  /// No description provided for @returnedItem.
  ///
  /// In en, this message translates to:
  /// **'Returned item'**
  String get returnedItem;

  /// No description provided for @secureTransaction.
  ///
  /// In en, this message translates to:
  /// **'Secure transaction'**
  String get secureTransaction;

  /// No description provided for @returnDepositReleaseNote.
  ///
  /// In en, this message translates to:
  /// **'Your deposit will be released automatically after the owner confirms the item condition.'**
  String get returnDepositReleaseNote;

  /// No description provided for @startSearch.
  ///
  /// In en, this message translates to:
  /// **'Start a search'**
  String get startSearch;

  /// No description provided for @suggestionBike.
  ///
  /// In en, this message translates to:
  /// **'Bicycle'**
  String get suggestionBike;

  /// No description provided for @suggestionCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get suggestionCamera;

  /// No description provided for @suggestionGoPro.
  ///
  /// In en, this message translates to:
  /// **'GoPro'**
  String get suggestionGoPro;

  /// No description provided for @suggestionDrill.
  ///
  /// In en, this message translates to:
  /// **'Drill'**
  String get suggestionDrill;

  /// No description provided for @suggestionTent.
  ///
  /// In en, this message translates to:
  /// **'Tent'**
  String get suggestionTent;

  /// No description provided for @suggestionPowerTools.
  ///
  /// In en, this message translates to:
  /// **'Power tools'**
  String get suggestionPowerTools;

  /// No description provided for @suggestionLaptop.
  ///
  /// In en, this message translates to:
  /// **'Laptop'**
  String get suggestionLaptop;

  /// No description provided for @suggestionSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Portable speaker'**
  String get suggestionSpeaker;

  /// No description provided for @nearYouSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Near you'**
  String get nearYouSuggestion;

  /// No description provided for @forRentSuggestion.
  ///
  /// In en, this message translates to:
  /// **'{query} for rent'**
  String forRentSuggestion(String query);

  /// No description provided for @noItemsFoundForQuery.
  ///
  /// In en, this message translates to:
  /// **'No items found for \"{query}\".'**
  String noItemsFoundForQuery(String query);

  /// No description provided for @cameraSearch.
  ///
  /// In en, this message translates to:
  /// **'Camera search'**
  String get cameraSearch;

  /// No description provided for @imageSearch.
  ///
  /// In en, this message translates to:
  /// **'Image search'**
  String get imageSearch;

  /// No description provided for @couldNotLoadRentals.
  ///
  /// In en, this message translates to:
  /// **'Could not load rentals'**
  String get couldNotLoadRentals;

  /// No description provided for @noActiveRentals.
  ///
  /// In en, this message translates to:
  /// **'No active rentals'**
  String get noActiveRentals;

  /// No description provided for @rentingEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Submitted rental orders will appear here.'**
  String get rentingEmptyBody;

  /// No description provided for @lendingEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Orders received for your items will appear here.'**
  String get lendingEmptyBody;

  /// No description provided for @noHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get noHistoryYet;

  /// No description provided for @completedRentalsBody.
  ///
  /// In en, this message translates to:
  /// **'Completed rentals will appear here.'**
  String get completedRentalsBody;

  /// No description provided for @iRent.
  ///
  /// In en, this message translates to:
  /// **'I rent'**
  String get iRent;

  /// No description provided for @fromMe.
  ///
  /// In en, this message translates to:
  /// **'From me'**
  String get fromMe;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @waitingPaymentAuthorization.
  ///
  /// In en, this message translates to:
  /// **'Waiting for payment authorization'**
  String get waitingPaymentAuthorization;

  /// No description provided for @editTime.
  ///
  /// In en, this message translates to:
  /// **'Edit time'**
  String get editTime;

  /// No description provided for @waitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval'**
  String get waitingApproval;

  /// No description provided for @scanReturnCode.
  ///
  /// In en, this message translates to:
  /// **'Scan return code'**
  String get scanReturnCode;

  /// No description provided for @returnedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Returned successfully'**
  String get returnedSuccessfully;

  /// No description provided for @expiresToday.
  ///
  /// In en, this message translates to:
  /// **'Expires today'**
  String get expiresToday;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress;

  /// No description provided for @ownerDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get ownerDefaultName;

  /// No description provided for @renterDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Renter'**
  String get renterDefaultName;

  /// No description provided for @rentedProductDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Rented item'**
  String get rentedProductDefaultTitle;

  /// No description provided for @submittedOrder.
  ///
  /// In en, this message translates to:
  /// **'Order submitted'**
  String get submittedOrder;

  /// No description provided for @untilDate.
  ///
  /// In en, this message translates to:
  /// **'Until {date}'**
  String untilDate(Object date);

  /// No description provided for @rentalSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule: {pickupTime} - {returnTime}'**
  String rentalSchedule(Object pickupTime, Object returnTime);

  /// No description provided for @pickupReturnSchedule.
  ///
  /// In en, this message translates to:
  /// **'Pickup {startDate} {pickupTime} - return {endDate} {returnTime}'**
  String pickupReturnSchedule(
    Object endDate,
    Object pickupTime,
    Object returnTime,
    Object startDate,
  );

  /// No description provided for @fromOwner.
  ///
  /// In en, this message translates to:
  /// **'From {owner}'**
  String fromOwner(Object owner);

  /// No description provided for @renterLabel.
  ///
  /// In en, this message translates to:
  /// **'Renter: {renter}'**
  String renterLabel(Object renter);

  /// No description provided for @completedRental.
  ///
  /// In en, this message translates to:
  /// **'Completed rental'**
  String get completedRental;

  /// No description provided for @rentedDateRange.
  ///
  /// In en, this message translates to:
  /// **'Rented: {startDate} - {endDate}'**
  String rentedDateRange(Object endDate, Object startDate);

  /// No description provided for @requestAccepted.
  ///
  /// In en, this message translates to:
  /// **'The request was accepted.'**
  String get requestAccepted;

  /// No description provided for @requestRejected.
  ///
  /// In en, this message translates to:
  /// **'The request was rejected.'**
  String get requestRejected;

  /// No description provided for @videoLabel.
  ///
  /// In en, this message translates to:
  /// **'VIDEO'**
  String get videoLabel;

  /// No description provided for @choosePeriod.
  ///
  /// In en, this message translates to:
  /// **'Choose period'**
  String get choosePeriod;

  /// No description provided for @ownerVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified owner'**
  String get ownerVerified;

  /// No description provided for @checkingAvailability.
  ///
  /// In en, this message translates to:
  /// **'Checking availability...'**
  String get checkingAvailability;

  /// No description provided for @availabilityRefreshError.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh availability.'**
  String get availabilityRefreshError;

  /// No description provided for @selectDayAndTime.
  ///
  /// In en, this message translates to:
  /// **'Select a day, then an available time slot'**
  String get selectDayAndTime;

  /// No description provided for @notSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get notSelected;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @janShort.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get janShort;

  /// No description provided for @febShort.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get febShort;

  /// No description provided for @marShort.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get marShort;

  /// No description provided for @aprShort.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get aprShort;

  /// No description provided for @mayShort.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get mayShort;

  /// No description provided for @junShort.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get junShort;

  /// No description provided for @julShort.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get julShort;

  /// No description provided for @augShort.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get augShort;

  /// No description provided for @sepShort.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get sepShort;

  /// No description provided for @octShort.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get octShort;

  /// No description provided for @novShort.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get novShort;

  /// No description provided for @decShort.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get decShort;

  /// No description provided for @chooseHours.
  ///
  /// In en, this message translates to:
  /// **'Choose hours'**
  String get chooseHours;

  /// No description provided for @pickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// No description provided for @returnLabel.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get returnLabel;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get endDate;

  /// No description provided for @totalPriceWithDuration.
  ///
  /// In en, this message translates to:
  /// **'Total price ({duration})'**
  String totalPriceWithDuration(String duration);

  /// No description provided for @lendProtectionIncluded.
  ///
  /// In en, this message translates to:
  /// **'Lend protection included'**
  String get lendProtectionIncluded;

  /// No description provided for @lendProtectionBody.
  ///
  /// In en, this message translates to:
  /// **'Your rental is protected against accidental damage. Handover and return are documented digitally.'**
  String get lendProtectionBody;

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to cart'**
  String get addToCart;

  /// No description provided for @selectedPeriod.
  ///
  /// In en, this message translates to:
  /// **'Selected period'**
  String get selectedPeriod;

  /// No description provided for @selectedPeriodWithDays.
  ///
  /// In en, this message translates to:
  /// **'{start} - {end} ({days} days)'**
  String selectedPeriodWithDays(String start, String end, int days);

  /// No description provided for @chooseStartAndEndDate.
  ///
  /// In en, this message translates to:
  /// **'Choose start and end date'**
  String get chooseStartAndEndDate;

  /// No description provided for @contractAndSignature.
  ///
  /// In en, this message translates to:
  /// **'Contract and signature'**
  String get contractAndSignature;

  /// No description provided for @legalDocument.
  ///
  /// In en, this message translates to:
  /// **'LEGAL DOCUMENT'**
  String get legalDocument;

  /// No description provided for @securedByLend.
  ///
  /// In en, this message translates to:
  /// **'Secured by Lend'**
  String get securedByLend;

  /// No description provided for @legalGeneralTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'1. General terms'**
  String get legalGeneralTermsTitle;

  /// No description provided for @legalGeneralTermsBody.
  ///
  /// In en, this message translates to:
  /// **'This rental agreement sets the conditions under which the owner provides the item to the renter for the specified period.'**
  String get legalGeneralTermsBody;

  /// No description provided for @pickupAndReturn.
  ///
  /// In en, this message translates to:
  /// **'Pickup and return'**
  String get pickupAndReturn;

  /// No description provided for @pickupReturnContractBody.
  ///
  /// In en, this message translates to:
  /// **'Pickup is at {pickupTime} and return is at {returnTime}.'**
  String pickupReturnContractBody(String pickupTime, String returnTime);

  /// No description provided for @responsibility.
  ///
  /// In en, this message translates to:
  /// **'Responsibility'**
  String get responsibility;

  /// No description provided for @responsibilityBody.
  ///
  /// In en, this message translates to:
  /// **'The renter assumes full responsibility for the item during the rental period. Any damage caused by negligence or improper use is covered by the renter.'**
  String get responsibilityBody;

  /// No description provided for @depositContractBody.
  ///
  /// In en, this message translates to:
  /// **'The deposit held through Lend secures the return of the item in its original condition. It is released within 24 hours after return confirmation.'**
  String get depositContractBody;

  /// No description provided for @contractTerminationTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Contract termination'**
  String get contractTerminationTitle;

  /// No description provided for @contractTerminationBody.
  ///
  /// In en, this message translates to:
  /// **'The contract for {productTitle} ends automatically when the {duration} period expires or by prior written agreement between both parties through the app messaging system.'**
  String contractTerminationBody(String productTitle, String duration);

  /// No description provided for @ownerSignature.
  ///
  /// In en, this message translates to:
  /// **'OWNER SIGNATURE'**
  String get ownerSignature;

  /// No description provided for @verifiedIdentity.
  ///
  /// In en, this message translates to:
  /// **'Verified identity'**
  String get verifiedIdentity;

  /// No description provided for @renterSignature.
  ///
  /// In en, this message translates to:
  /// **'RENTER SIGNATURE (YOU)'**
  String get renterSignature;

  /// No description provided for @signHere.
  ///
  /// In en, this message translates to:
  /// **'Sign here'**
  String get signHere;

  /// No description provided for @clearSignature.
  ///
  /// In en, this message translates to:
  /// **'Clear signature'**
  String get clearSignature;

  /// No description provided for @useYourFinger.
  ///
  /// In en, this message translates to:
  /// **'Use your finger'**
  String get useYourFinger;

  /// No description provided for @totalDuration.
  ///
  /// In en, this message translates to:
  /// **'Total duration'**
  String get totalDuration;

  /// No description provided for @totalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total price'**
  String get totalPrice;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get submitting;

  /// No description provided for @signAndSubmit.
  ///
  /// In en, this message translates to:
  /// **'Sign and submit'**
  String get signAndSubmit;

  /// No description provided for @productDetails.
  ///
  /// In en, this message translates to:
  /// **'Product details'**
  String get productDetails;

  /// No description provided for @verifiedItem.
  ///
  /// In en, this message translates to:
  /// **'(verified item)'**
  String get verifiedItem;

  /// No description provided for @insuranceIncluded.
  ///
  /// In en, this message translates to:
  /// **'Insurance included'**
  String get insuranceIncluded;

  /// No description provided for @availableNow.
  ///
  /// In en, this message translates to:
  /// **'Available now'**
  String get availableNow;

  /// No description provided for @openDirections.
  ///
  /// In en, this message translates to:
  /// **'Open directions'**
  String get openDirections;

  /// No description provided for @directionsBody.
  ///
  /// In en, this message translates to:
  /// **'Start navigation to this item location in Google Maps.'**
  String get directionsBody;

  /// No description provided for @openInGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get openInGoogleMaps;

  /// No description provided for @googleMapsOpenError.
  ///
  /// In en, this message translates to:
  /// **'Could not open Google Maps.'**
  String get googleMapsOpenError;

  /// No description provided for @hourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly'**
  String get hourly;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @condition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get condition;

  /// No description provided for @verifiedReview.
  ///
  /// In en, this message translates to:
  /// **'Verified review'**
  String get verifiedReview;

  /// No description provided for @sampleReviewerName.
  ///
  /// In en, this message translates to:
  /// **'Mihai Popescu'**
  String get sampleReviewerName;

  /// No description provided for @sampleReviewerInitial.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get sampleReviewerInitial;

  /// No description provided for @sampleReview.
  ///
  /// In en, this message translates to:
  /// **'Everything went perfectly. {ownerName} handed over the item quickly, and it matched the description.'**
  String sampleReview(String ownerName);

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'OWNER'**
  String get owner;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessage;

  /// No description provided for @lendProtectBody.
  ///
  /// In en, this message translates to:
  /// **'You are protected against accidental damage for the entire rental period.'**
  String get lendProtectBody;

  /// No description provided for @perHourSuffix.
  ///
  /// In en, this message translates to:
  /// **'/ hour'**
  String get perHourSuffix;

  /// No description provided for @perDaySuffix.
  ///
  /// In en, this message translates to:
  /// **'/ day'**
  String get perDaySuffix;

  /// No description provided for @rent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get rent;

  /// No description provided for @rentNow.
  ///
  /// In en, this message translates to:
  /// **'Rent now'**
  String get rentNow;

  /// No description provided for @listingFormInvalid.
  ///
  /// In en, this message translates to:
  /// **'Complete the listing and use times like 10:00.'**
  String get listingFormInvalid;

  /// No description provided for @missingProductIdForEdit.
  ///
  /// In en, this message translates to:
  /// **'The product ID is missing for editing.'**
  String get missingProductIdForEdit;

  /// No description provided for @stripeNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Stripe is not configured. The publishable key is missing.'**
  String get stripeNotConfigured;

  /// No description provided for @stripePaymentConfirmationMissing.
  ///
  /// In en, this message translates to:
  /// **'Stripe did not return payment confirmation.'**
  String get stripePaymentConfirmationMissing;

  /// No description provided for @stripeOnboardingOpenError.
  ///
  /// In en, this message translates to:
  /// **'Could not open Stripe onboarding.'**
  String get stripeOnboardingOpenError;

  /// No description provided for @requestSentToOwner.
  ///
  /// In en, this message translates to:
  /// **'Request #{id} was sent to the owner.'**
  String requestSentToOwner(Object id);

  /// No description provided for @timeFormatHint.
  ///
  /// In en, this message translates to:
  /// **'Use times like 10:00.'**
  String get timeFormatHint;

  /// No description provided for @payoutSentToStripe.
  ///
  /// In en, this message translates to:
  /// **'{amount} RON was sent to Stripe.'**
  String payoutSentToStripe(Object amount);

  /// No description provided for @lendOwnerName.
  ///
  /// In en, this message translates to:
  /// **'Lend owner'**
  String get lendOwnerName;

  /// No description provided for @toolsDiy.
  ///
  /// In en, this message translates to:
  /// **'Tools & DIY'**
  String get toolsDiy;

  /// No description provided for @tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// No description provided for @homeGarden.
  ///
  /// In en, this message translates to:
  /// **'Home & Garden'**
  String get homeGarden;

  /// No description provided for @electronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get electronics;

  /// No description provided for @sportOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Sport & Outdoor'**
  String get sportOutdoor;

  /// No description provided for @gamingConsole.
  ///
  /// In en, this message translates to:
  /// **'Gaming & Console'**
  String get gamingConsole;

  /// No description provided for @photoVideo.
  ///
  /// In en, this message translates to:
  /// **'Photo & Video'**
  String get photoVideo;

  /// No description provided for @drones.
  ///
  /// In en, this message translates to:
  /// **'Drones'**
  String get drones;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @editListing.
  ///
  /// In en, this message translates to:
  /// **'Edit listing'**
  String get editListing;

  /// No description provided for @secure.
  ///
  /// In en, this message translates to:
  /// **'Secure'**
  String get secure;

  /// No description provided for @coveredByLend.
  ///
  /// In en, this message translates to:
  /// **'You are covered by Lend'**
  String get coveredByLend;

  /// No description provided for @coveredByLendBody.
  ///
  /// In en, this message translates to:
  /// **'Every transaction is protected against damage or theft up to 5000 RON.'**
  String get coveredByLendBody;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @maxEightFiles.
  ///
  /// In en, this message translates to:
  /// **'Maximum 8 files'**
  String get maxEightFiles;

  /// No description provided for @addMedia.
  ///
  /// In en, this message translates to:
  /// **'Add media'**
  String get addMedia;

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic information'**
  String get basicInformation;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get itemName;

  /// No description provided for @itemNameHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: Professional lawn mower'**
  String get itemNameHint;

  /// No description provided for @chooseCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get chooseCategory;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @cityHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: Bucharest'**
  String get cityHint;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @addressHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: 10 Example Street'**
  String get addressHint;

  /// No description provided for @mapPin.
  ///
  /// In en, this message translates to:
  /// **'Map pin'**
  String get mapPin;

  /// No description provided for @centerOnCity.
  ///
  /// In en, this message translates to:
  /// **'Center on city'**
  String get centerOnCity;

  /// No description provided for @mapPinHelp.
  ///
  /// In en, this message translates to:
  /// **'Tap the map or drag the pin for the exact location.'**
  String get mapPinHelp;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the item condition and what is included...'**
  String get descriptionHint;

  /// No description provided for @rates.
  ///
  /// In en, this message translates to:
  /// **'Rates'**
  String get rates;

  /// No description provided for @pricePerHour.
  ///
  /// In en, this message translates to:
  /// **'Price per hour'**
  String get pricePerHour;

  /// No description provided for @pricePerDay.
  ///
  /// In en, this message translates to:
  /// **'Price per day'**
  String get pricePerDay;

  /// No description provided for @pickupAfter.
  ///
  /// In en, this message translates to:
  /// **'Pickup after'**
  String get pickupAfter;

  /// No description provided for @returnBy.
  ///
  /// In en, this message translates to:
  /// **'Return by'**
  String get returnBy;

  /// No description provided for @pricingSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Users often prefer a lower price for rentals longer than 3 days.'**
  String get pricingSuggestion;

  /// No description provided for @insuranceEnabledAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Insurance enabled automatically'**
  String get insuranceEnabledAutomatically;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @publishListing.
  ///
  /// In en, this message translates to:
  /// **'Post item'**
  String get publishListing;

  /// No description provided for @editListingBackendNote.
  ///
  /// In en, this message translates to:
  /// **'Changes will be sent to the backend when the update endpoint is connected.'**
  String get editListingBackendNote;

  /// No description provided for @publishListingTermsNote.
  ///
  /// In en, this message translates to:
  /// **'By tapping \"Post item\" you agree to our terms.'**
  String get publishListingTermsNote;

  /// No description provided for @pricePerMonth.
  ///
  /// In en, this message translates to:
  /// **'Price per month'**
  String get pricePerMonth;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;
}

class _GeneratedLocalizationsDelegate
    extends LocalizationsDelegate<GeneratedLocalizations> {
  const _GeneratedLocalizationsDelegate();

  @override
  Future<GeneratedLocalizations> load(Locale locale) {
    return SynchronousFuture<GeneratedLocalizations>(
      lookupGeneratedLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ro'].contains(locale.languageCode);

  @override
  bool shouldReload(_GeneratedLocalizationsDelegate old) => false;
}

GeneratedLocalizations lookupGeneratedLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return GeneratedLocalizationsEn();
    case 'ro':
      return GeneratedLocalizationsRo();
  }

  throw FlutterError(
    'GeneratedLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
