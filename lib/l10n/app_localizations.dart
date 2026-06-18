import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
    Locale('en'),
    Locale('hi'),
    Locale('kn'),
    Locale('te'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Vaachaka Lekhini'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Your Personal Spiritual Practice Companion'**
  String get appTagline;

  /// No description provided for @appMottoChant.
  ///
  /// In en, this message translates to:
  /// **'Chant with Purpose | Track with Pride'**
  String get appMottoChant;

  /// No description provided for @setLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get setLanguage;

  /// No description provided for @existingUser.
  ///
  /// In en, this message translates to:
  /// **'Existing user?'**
  String get existingUser;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @newUser.
  ///
  /// In en, this message translates to:
  /// **'New user?'**
  String get newUser;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// No description provided for @knowOurApp.
  ///
  /// In en, this message translates to:
  /// **'Know our App'**
  String get knowOurApp;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountTitle;

  /// No description provided for @beginSpiritualJourney.
  ///
  /// In en, this message translates to:
  /// **'Begin your spiritual journey'**
  String get beginSpiritualJourney;

  /// No description provided for @quickSetup.
  ///
  /// In en, this message translates to:
  /// **'Quick setup · takes 30 seconds'**
  String get quickSetup;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get usernameHint;

  /// No description provided for @mobileNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumberLabel;

  /// No description provided for @mobileNumberHint.
  ///
  /// In en, this message translates to:
  /// **'98765 43210'**
  String get mobileNumberHint;

  /// No description provided for @referralCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Referral Code (Optional)'**
  String get referralCodeLabel;

  /// No description provided for @referralCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter referral code'**
  String get referralCodeHint;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @sendingButton.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get sendingButton;

  /// No description provided for @sendOtpButton.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtpButton;

  /// No description provided for @verifyingButton.
  ///
  /// In en, this message translates to:
  /// **'Verifying…'**
  String get verifyingButton;

  /// No description provided for @registerConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerConfirmButton;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @loginLink.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginLink;

  /// No description provided for @loginScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginScreenTitle;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @enterMobileAssociated.
  ///
  /// In en, this message translates to:
  /// **'Enter the mobile number associated with your account.'**
  String get enterMobileAssociated;

  /// No description provided for @mobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get mobileLabel;

  /// No description provided for @enterSixDigitCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get enterSixDigitCode;

  /// No description provided for @enterSixDigitCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to your number.'**
  String get enterSixDigitCodeSent;

  /// No description provided for @enterSixDigitCodeSentToMobile.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to +91{mobile}'**
  String enterSixDigitCodeSentToMobile(String mobile);

  /// No description provided for @resendOtpCountdown.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP in {seconds}s'**
  String resendOtpCountdown(int seconds);

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @loginConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginConfirmButton;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @createOneLink.
  ///
  /// In en, this message translates to:
  /// **'Create one'**
  String get createOneLink;

  /// No description provided for @welcomeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcomeGreeting;

  /// No description provided for @welcomeGreetingUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}!'**
  String welcomeGreetingUser(String name);

  /// No description provided for @homeSublineEmpty.
  ///
  /// In en, this message translates to:
  /// **'Start your spiritual journey'**
  String get homeSublineEmpty;

  /// No description provided for @homeSublineActive.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You\'re doing great! 1 Sadhana Active} other{You\'re doing great! {count} Sadhanas Active}}'**
  String homeSublineActive(int count);

  /// No description provided for @saveNameButton.
  ///
  /// In en, this message translates to:
  /// **'Save Name'**
  String get saveNameButton;

  /// No description provided for @savingNameButton.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get savingNameButton;

  /// No description provided for @pressBackAgainToExit.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get pressBackAgainToExit;

  /// No description provided for @rewardPoints.
  ///
  /// In en, this message translates to:
  /// **'Reward Points'**
  String get rewardPoints;

  /// No description provided for @storeButton.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get storeButton;

  /// No description provided for @dailyPractice.
  ///
  /// In en, this message translates to:
  /// **'DAILY PRACTICE'**
  String get dailyPractice;

  /// No description provided for @startFirstGoalToday.
  ///
  /// In en, this message translates to:
  /// **'Start your first goal today'**
  String get startFirstGoalToday;

  /// No description provided for @continueGoal.
  ///
  /// In en, this message translates to:
  /// **'Continue your {days}-day goal'**
  String continueGoal(int days);

  /// No description provided for @quickStartPractice.
  ///
  /// In en, this message translates to:
  /// **'Quick Start Practice'**
  String get quickStartPractice;

  /// No description provided for @continuePractice.
  ///
  /// In en, this message translates to:
  /// **'Continue Practice'**
  String get continuePractice;

  /// No description provided for @browseMantras.
  ///
  /// In en, this message translates to:
  /// **'Browse Mantras'**
  String get browseMantras;

  /// No description provided for @selectFromPrograms.
  ///
  /// In en, this message translates to:
  /// **'Select from your Sadhanas'**
  String get selectFromPrograms;

  /// No description provided for @createNewProgram.
  ///
  /// In en, this message translates to:
  /// **'Start New Sadhana'**
  String get createNewProgram;

  /// No description provided for @mantraSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Mantra Selection'**
  String get mantraSelectionTitle;

  /// No description provided for @selectMantraByNeed.
  ///
  /// In en, this message translates to:
  /// **'Select mantra based on your need →'**
  String get selectMantraByNeed;

  /// No description provided for @confirmSelection.
  ///
  /// In en, this message translates to:
  /// **'Confirm Selection'**
  String get confirmSelection;

  /// No description provided for @mantraNotFound.
  ///
  /// In en, this message translates to:
  /// **'Mantra not found'**
  String get mantraNotFound;

  /// No description provided for @mantraNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get mantraNotFoundTitle;

  /// No description provided for @startPracticeWithMantra.
  ///
  /// In en, this message translates to:
  /// **'Start Practice with {name} Mantra'**
  String startPracticeWithMantra(String name);

  /// No description provided for @pronunciationGuide.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation Guide'**
  String get pronunciationGuide;

  /// No description provided for @mantraForYourNeeds.
  ///
  /// In en, this message translates to:
  /// **'Mantra for Your Needs'**
  String get mantraForYourNeeds;

  /// No description provided for @selectNeedOrProblem.
  ///
  /// In en, this message translates to:
  /// **'Select your need or problem'**
  String get selectNeedOrProblem;

  /// No description provided for @selectDropdownHint.
  ///
  /// In en, this message translates to:
  /// **'Select…'**
  String get selectDropdownHint;

  /// No description provided for @startThisPractice.
  ///
  /// In en, this message translates to:
  /// **'Start This Practice'**
  String get startThisPractice;

  /// No description provided for @recitationsTimes.
  ///
  /// In en, this message translates to:
  /// **'{count} times daily'**
  String recitationsTimes(int count);

  /// No description provided for @recitationsSub.
  ///
  /// In en, this message translates to:
  /// **'Recitations'**
  String get recitationsSub;

  /// No description provided for @forDays.
  ///
  /// In en, this message translates to:
  /// **'For {count} days'**
  String forDays(int count);

  /// No description provided for @durationSub.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationSub;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get learnMore;

  /// No description provided for @quickStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Start Practice'**
  String get quickStartTitle;

  /// No description provided for @quickStartButton.
  ///
  /// In en, this message translates to:
  /// **'Quick Start'**
  String get quickStartButton;

  /// No description provided for @globalCount.
  ///
  /// In en, this message translates to:
  /// **'Global Count'**
  String get globalCount;

  /// No description provided for @liveUsers.
  ///
  /// In en, this message translates to:
  /// **'Live users'**
  String get liveUsers;

  /// No description provided for @changeMantra.
  ///
  /// In en, this message translates to:
  /// **'Change Mantra'**
  String get changeMantra;

  /// No description provided for @sessionStats.
  ///
  /// In en, this message translates to:
  /// **'Session Stats'**
  String get sessionStats;

  /// No description provided for @todaysCount.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Count'**
  String get todaysCount;

  /// No description provided for @toMilestone.
  ///
  /// In en, this message translates to:
  /// **'To Milestone'**
  String get toMilestone;

  /// No description provided for @milestoneCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get milestoneCompleted;

  /// No description provided for @milestoneLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String milestoneLeft(int count);

  /// No description provided for @practisingFor.
  ///
  /// In en, this message translates to:
  /// **'Practising for '**
  String get practisingFor;

  /// No description provided for @practiceDay.
  ///
  /// In en, this message translates to:
  /// **'{days} Day'**
  String practiceDay(int days);

  /// No description provided for @practiceDays.
  ///
  /// In en, this message translates to:
  /// **'{days} Days'**
  String practiceDays(int days);

  /// No description provided for @startButton.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get startButton;

  /// No description provided for @noActivePrograms.
  ///
  /// In en, this message translates to:
  /// **'No active sadhanas'**
  String get noActivePrograms;

  /// No description provided for @chooseMantra.
  ///
  /// In en, this message translates to:
  /// **'Choose Mantra'**
  String get chooseMantra;

  /// No description provided for @selectActiveProgramDescription.
  ///
  /// In en, this message translates to:
  /// **'Select an active sadhana to update this dashboard.'**
  String get selectActiveProgramDescription;

  /// No description provided for @noActivePractice.
  ///
  /// In en, this message translates to:
  /// **'No active practice yet'**
  String get noActivePractice;

  /// No description provided for @pickMantraAndTarget.
  ///
  /// In en, this message translates to:
  /// **'Pick a mantra and set a target to begin chanting or writing.'**
  String get pickMantraAndTarget;

  /// No description provided for @chooseAMantra.
  ///
  /// In en, this message translates to:
  /// **'Choose a Mantra'**
  String get chooseAMantra;

  /// No description provided for @practiceScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get practiceScreenTitle;

  /// No description provided for @sessionSaved.
  ///
  /// In en, this message translates to:
  /// **'Session saved · +{count} chants'**
  String sessionSaved(int count);

  /// No description provided for @todaysProgress.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Progress'**
  String get todaysProgress;

  /// No description provided for @microphoneNeeded.
  ///
  /// In en, this message translates to:
  /// **'Microphone needed'**
  String get microphoneNeeded;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @tryVoiceAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Voice Again'**
  String get tryVoiceAgain;

  /// No description provided for @useManual.
  ///
  /// In en, this message translates to:
  /// **'Use Manual'**
  String get useManual;

  /// No description provided for @pauseButton.
  ///
  /// In en, this message translates to:
  /// **'PAUSE'**
  String get pauseButton;

  /// No description provided for @resumeButton.
  ///
  /// In en, this message translates to:
  /// **'RESUME'**
  String get resumeButton;

  /// No description provided for @finishButton.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishButton;

  /// No description provided for @countDisplay.
  ///
  /// In en, this message translates to:
  /// **'Global Mantra Count : {count}'**
  String countDisplay(String count);

  /// No description provided for @yoursDisplay.
  ///
  /// In en, this message translates to:
  /// **'Yours : '**
  String get yoursDisplay;

  /// No description provided for @ambienceSound.
  ///
  /// In en, this message translates to:
  /// **'Ambience Sound'**
  String get ambienceSound;

  /// No description provided for @phoneMode.
  ///
  /// In en, this message translates to:
  /// **'Phone Mode'**
  String get phoneMode;

  /// No description provided for @ownWritingModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Own writing mode'**
  String get ownWritingModeLabel;

  /// No description provided for @everyJourneyBegins.
  ///
  /// In en, this message translates to:
  /// **'Every journey begins with a single step.'**
  String get everyJourneyBegins;

  /// No description provided for @totalChants.
  ///
  /// In en, this message translates to:
  /// **'Total Chants'**
  String get totalChants;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @daysPractising.
  ///
  /// In en, this message translates to:
  /// **'Days Practising'**
  String get daysPractising;

  /// No description provided for @programs.
  ///
  /// In en, this message translates to:
  /// **'Sadhanas'**
  String get programs;

  /// No description provided for @overallProgress.
  ///
  /// In en, this message translates to:
  /// **'Overall Progress'**
  String get overallProgress;

  /// No description provided for @createNewProgramButton.
  ///
  /// In en, this message translates to:
  /// **'Create New Sadhana'**
  String get createNewProgramButton;

  /// No description provided for @myRecitationPrograms.
  ///
  /// In en, this message translates to:
  /// **'My Recitation Sadhanas'**
  String get myRecitationPrograms;

  /// No description provided for @completedPrograms.
  ///
  /// In en, this message translates to:
  /// **'Completed Sadhanas'**
  String get completedPrograms;

  /// No description provided for @noProgramsYet.
  ///
  /// In en, this message translates to:
  /// **'No sadhanas yet'**
  String get noProgramsYet;

  /// No description provided for @pickMantraAndTargetToStart.
  ///
  /// In en, this message translates to:
  /// **'Pick a mantra and set a target to start your first sadhana.'**
  String get pickMantraAndTargetToStart;

  /// No description provided for @completedWithCheck.
  ///
  /// In en, this message translates to:
  /// **'Completed ✓'**
  String get completedWithCheck;

  /// No description provided for @setYourPracticeTarget.
  ///
  /// In en, this message translates to:
  /// **'Set Your Practice Target'**
  String get setYourPracticeTarget;

  /// No description provided for @daysValue.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String daysValue(int days);

  /// No description provided for @confirmAndBegin.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Begin'**
  String get confirmAndBegin;

  /// No description provided for @creatingButton.
  ///
  /// In en, this message translates to:
  /// **'Creating…'**
  String get creatingButton;

  /// No description provided for @writingsTargetCrore.
  ///
  /// In en, this message translates to:
  /// **'1,00,00,000 writings'**
  String get writingsTargetCrore;

  /// No description provided for @mostPopularBadge.
  ///
  /// In en, this message translates to:
  /// **'Most Popular'**
  String get mostPopularBadge;

  /// No description provided for @writingsTargetMillion.
  ///
  /// In en, this message translates to:
  /// **'1,000,000 writings'**
  String get writingsTargetMillion;

  /// No description provided for @setCustomTarget.
  ///
  /// In en, this message translates to:
  /// **'Set a custom target'**
  String get setCustomTarget;

  /// No description provided for @totalWritingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Writings'**
  String get totalWritingsLabel;

  /// No description provided for @totalWritingsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 500,000'**
  String get totalWritingsHint;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @searchRewards.
  ///
  /// In en, this message translates to:
  /// **'Search for rewards…'**
  String get searchRewards;

  /// No description provided for @allFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allFilter;

  /// No description provided for @specialOffer.
  ///
  /// In en, this message translates to:
  /// **'SPECIAL OFFER'**
  String get specialOffer;

  /// No description provided for @guidedMeditationSeries.
  ///
  /// In en, this message translates to:
  /// **'Guided Meditation Series'**
  String get guidedMeditationSeries;

  /// No description provided for @unlockPeaceSeries.
  ///
  /// In en, this message translates to:
  /// **'Unlock peace with our new 7-day series'**
  String get unlockPeaceSeries;

  /// No description provided for @redeemButton.
  ///
  /// In en, this message translates to:
  /// **'Redeem'**
  String get redeemButton;

  /// No description provided for @notEnoughPoints.
  ///
  /// In en, this message translates to:
  /// **'Not enough'**
  String get notEnoughPoints;

  /// No description provided for @noRewardsMatch.
  ///
  /// In en, this message translates to:
  /// **'No rewards match your search'**
  String get noRewardsMatch;

  /// No description provided for @rewardedItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Redeemed {title}'**
  String rewardedItemTitle(String title);

  /// No description provided for @rewardPointsHistory.
  ///
  /// In en, this message translates to:
  /// **'Reward Points & History'**
  String get rewardPointsHistory;

  /// No description provided for @yourTotalPoints.
  ///
  /// In en, this message translates to:
  /// **'★ Your Total Points'**
  String get yourTotalPoints;

  /// No description provided for @visitRewardStore.
  ///
  /// In en, this message translates to:
  /// **'Visit Reward Store'**
  String get visitRewardStore;

  /// No description provided for @pointsHistory.
  ///
  /// In en, this message translates to:
  /// **'Points History'**
  String get pointsHistory;

  /// No description provided for @noRewardActivity.
  ///
  /// In en, this message translates to:
  /// **'No reward activity yet.\nFinish a session to earn your first points.'**
  String get noRewardActivity;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterEarned.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get filterEarned;

  /// No description provided for @filterSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get filterSpent;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @editButton.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editButton;

  /// No description provided for @totalChantsKpi.
  ///
  /// In en, this message translates to:
  /// **'Total Chants'**
  String get totalChantsKpi;

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current Streak'**
  String get currentStreak;

  /// No description provided for @milestones.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get milestones;

  /// No description provided for @rewardPointsLabel.
  ///
  /// In en, this message translates to:
  /// **'REWARD POINTS'**
  String get rewardPointsLabel;

  /// No description provided for @visitStore.
  ///
  /// In en, this message translates to:
  /// **'Visit Store'**
  String get visitStore;

  /// No description provided for @familyCommunitySection.
  ///
  /// In en, this message translates to:
  /// **'FAMILY & COMMUNITY'**
  String get familyCommunitySection;

  /// No description provided for @familyMembers.
  ///
  /// In en, this message translates to:
  /// **'Family Members'**
  String get familyMembers;

  /// No description provided for @inviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get inviteFriends;

  /// No description provided for @practiceSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'PRACTICE SETTINGS'**
  String get practiceSettingsSection;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get reminderTime;

  /// No description provided for @notificationSound.
  ///
  /// In en, this message translates to:
  /// **'Notification Sound'**
  String get notificationSound;

  /// No description provided for @notificationSoundBell.
  ///
  /// In en, this message translates to:
  /// **'Bell'**
  String get notificationSoundBell;

  /// No description provided for @notificationSoundConch.
  ///
  /// In en, this message translates to:
  /// **'Conch'**
  String get notificationSoundConch;

  /// No description provided for @notificationSoundBowl.
  ///
  /// In en, this message translates to:
  /// **'Bowl'**
  String get notificationSoundBowl;

  /// No description provided for @notificationSoundChime.
  ///
  /// In en, this message translates to:
  /// **'Chime'**
  String get notificationSoundChime;

  /// No description provided for @notificationSoundNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get notificationSoundNone;

  /// No description provided for @voiceSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'VOICE SETTINGS'**
  String get voiceSettingsSection;

  /// No description provided for @reTrainVoice.
  ///
  /// In en, this message translates to:
  /// **'Re-train Voice'**
  String get reTrainVoice;

  /// No description provided for @microphoneSensitivity.
  ///
  /// In en, this message translates to:
  /// **'Microphone Sensitivity'**
  String get microphoneSensitivity;

  /// No description provided for @displaySection.
  ///
  /// In en, this message translates to:
  /// **'DISPLAY'**
  String get displaySection;

  /// No description provided for @languageSetting.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSetting;

  /// No description provided for @languagePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languagePickerTitle;

  /// No description provided for @linkSocialSection.
  ///
  /// In en, this message translates to:
  /// **'LINK SOCIAL'**
  String get linkSocialSection;

  /// No description provided for @linkFacebook.
  ///
  /// In en, this message translates to:
  /// **'Link Facebook'**
  String get linkFacebook;

  /// No description provided for @linkWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Link WhatsApp'**
  String get linkWhatsApp;

  /// No description provided for @linkInstagram.
  ///
  /// In en, this message translates to:
  /// **'Link Instagram'**
  String get linkInstagram;

  /// No description provided for @supportPrivacySection.
  ///
  /// In en, this message translates to:
  /// **'SUPPORT & PRIVACY'**
  String get supportPrivacySection;

  /// No description provided for @helpFaqs.
  ///
  /// In en, this message translates to:
  /// **'Help & FAQs'**
  String get helpFaqs;

  /// No description provided for @reportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get reportIssue;

  /// No description provided for @shareFeedback.
  ///
  /// In en, this message translates to:
  /// **'Share Feedback'**
  String get shareFeedback;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @downloadYourData.
  ///
  /// In en, this message translates to:
  /// **'Download Your Data'**
  String get downloadYourData;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutApp;

  /// No description provided for @logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutButton;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @versionNumber.
  ///
  /// In en, this message translates to:
  /// **'Version 0.1.0'**
  String get versionNumber;

  /// No description provided for @logoutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout?'**
  String get logoutDialogTitle;

  /// No description provided for @logoutDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Your local data stays on this device.'**
  String get logoutDialogContent;

  /// No description provided for @logoutDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get logoutDialogCancel;

  /// No description provided for @logoutDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutDialogConfirm;

  /// No description provided for @deleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteDialogTitle;

  /// No description provided for @deleteDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This wipes all sadhanas, sessions, rewards, and profiles on this device. This action cannot be undone.'**
  String get deleteDialogContent;

  /// No description provided for @deleteDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get deleteDialogCancel;

  /// No description provided for @deleteDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete everything'**
  String get deleteDialogConfirm;

  /// No description provided for @infoHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & FAQs'**
  String get infoHelpTitle;

  /// No description provided for @infoHelpBody.
  ///
  /// In en, this message translates to:
  /// **'Common questions and how-to guides will be published here. For urgent issues, please use Report Issue.'**
  String get infoHelpBody;

  /// No description provided for @infoReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get infoReportTitle;

  /// No description provided for @infoReportBody.
  ///
  /// In en, this message translates to:
  /// **'Tell us what went wrong and we will look into it. Email integration is being set up.'**
  String get infoReportBody;

  /// No description provided for @infoFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Share Feedback'**
  String get infoFeedbackTitle;

  /// No description provided for @infoFeedbackBody.
  ///
  /// In en, this message translates to:
  /// **'We listen to every suggestion. Let us know what feels right or what needs to change.'**
  String get infoFeedbackBody;

  /// No description provided for @infoPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get infoPrivacyTitle;

  /// No description provided for @infoPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'Your practice data lives on your device until you choose to sync it. Voice and handwriting samples never leave this device in version 1.'**
  String get infoPrivacyBody;

  /// No description provided for @infoAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About Vaachaka Lekhini'**
  String get infoAboutTitle;

  /// No description provided for @infoAboutBody.
  ///
  /// In en, this message translates to:
  /// **'Vaachaka Lekhini is your personal spiritual practice companion. Chant or write your chosen mantras, track your progress, and grow your discipline — together with your family.\n\nVersion 0.1.0'**
  String get infoAboutBody;

  /// No description provided for @recitationsOnDate.
  ///
  /// In en, this message translates to:
  /// **'Recitations on {date}'**
  String recitationsOnDate(String date);

  /// No description provided for @dailyTarget.
  ///
  /// In en, this message translates to:
  /// **'Daily Target'**
  String get dailyTarget;

  /// No description provided for @actualAchieved.
  ///
  /// In en, this message translates to:
  /// **'Actual Achieved'**
  String get actualAchieved;

  /// No description provided for @handwritingUsed.
  ///
  /// In en, this message translates to:
  /// **'Handwriting Used'**
  String get handwritingUsed;

  /// No description provided for @handwritingUsedYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get handwritingUsedYes;

  /// No description provided for @handwritingUsedNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get handwritingUsedNo;

  /// No description provided for @startPractice.
  ///
  /// In en, this message translates to:
  /// **'Start Practice'**
  String get startPractice;

  /// No description provided for @dedicateProgram.
  ///
  /// In en, this message translates to:
  /// **'Dedicate this sadhana'**
  String get dedicateProgram;

  /// No description provided for @dedicateSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Dedicate this Sadhana'**
  String get dedicateSheetTitle;

  /// No description provided for @dedicateOfferPractice.
  ///
  /// In en, this message translates to:
  /// **'Offer your chanting practice to someone special'**
  String get dedicateOfferPractice;

  /// No description provided for @dedicateOfferNamedPractice.
  ///
  /// In en, this message translates to:
  /// **'Offer your {mantraName} practice to someone special'**
  String dedicateOfferNamedPractice(String mantraName);

  /// No description provided for @dedicatedTo.
  ///
  /// In en, this message translates to:
  /// **'Dedicated to'**
  String get dedicatedTo;

  /// No description provided for @dedicatedToHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. My Mother, Sri Guru, Self'**
  String get dedicatedToHint;

  /// No description provided for @intention.
  ///
  /// In en, this message translates to:
  /// **'Intention (optional)'**
  String get intention;

  /// No description provided for @intentionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. For her health and happiness…'**
  String get intentionHint;

  /// No description provided for @removeDedication.
  ///
  /// In en, this message translates to:
  /// **'Remove dedication'**
  String get removeDedication;

  /// No description provided for @updateDedication.
  ///
  /// In en, this message translates to:
  /// **'Update Dedication'**
  String get updateDedication;

  /// No description provided for @saveDedication.
  ///
  /// In en, this message translates to:
  /// **'Save Dedication'**
  String get saveDedication;

  /// No description provided for @editGoal.
  ///
  /// In en, this message translates to:
  /// **'Edit Goal'**
  String get editGoal;

  /// No description provided for @shareProgram.
  ///
  /// In en, this message translates to:
  /// **'Share Sadhana'**
  String get shareProgram;

  /// No description provided for @dailyProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Progress'**
  String get dailyProgressTitle;

  /// No description provided for @communityInviteBanner.
  ///
  /// In en, this message translates to:
  /// **'Invite up to {count} friends to your practice circle'**
  String communityInviteBanner(int count);

  /// No description provided for @communityInviteSubline.
  ///
  /// In en, this message translates to:
  /// **'Create a community to support each other\'s spiritual journey.'**
  String get communityInviteSubline;

  /// No description provided for @inviteFriendsButton.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get inviteFriendsButton;

  /// No description provided for @streakChallenge.
  ///
  /// In en, this message translates to:
  /// **'Streaks'**
  String get streakChallenge;

  /// No description provided for @totalChantsSort.
  ///
  /// In en, this message translates to:
  /// **'Chants'**
  String get totalChantsSort;

  /// No description provided for @sendEncouragement.
  ///
  /// In en, this message translates to:
  /// **'Send Encouragement'**
  String get sendEncouragement;

  /// No description provided for @viewGroupStats.
  ///
  /// In en, this message translates to:
  /// **'View Group Stats'**
  String get viewGroupStats;

  /// No description provided for @youLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youLabel;

  /// No description provided for @streakLabel.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streakLabel;

  /// No description provided for @inviteFriendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get inviteFriendsTitle;

  /// No description provided for @shareJourneyTitle.
  ///
  /// In en, this message translates to:
  /// **'Share the journey of\nspiritual growth'**
  String get shareJourneyTitle;

  /// No description provided for @inviteEarnPoints.
  ///
  /// In en, this message translates to:
  /// **'Invite friends to join Vaachaka Lekhini and earn reward points.'**
  String get inviteEarnPoints;

  /// No description provided for @inviteLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite link copied'**
  String get inviteLinkCopied;

  /// No description provided for @shareViaWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Share via WhatsApp'**
  String get shareViaWhatsApp;

  /// No description provided for @shareViaFacebook.
  ///
  /// In en, this message translates to:
  /// **'Share via Facebook'**
  String get shareViaFacebook;

  /// No description provided for @shareViaInstagram.
  ///
  /// In en, this message translates to:
  /// **'Share via Instagram'**
  String get shareViaInstagram;

  /// No description provided for @allChannelsShareSheet.
  ///
  /// In en, this message translates to:
  /// **'All channels open your device share sheet.'**
  String get allChannelsShareSheet;

  /// No description provided for @whoIsPracticing.
  ///
  /// In en, this message translates to:
  /// **'Who is Practicing?'**
  String get whoIsPracticing;

  /// No description provided for @manageProfiles.
  ///
  /// In en, this message translates to:
  /// **'Manage Profiles'**
  String get manageProfiles;

  /// No description provided for @loginWithAnotherNumber.
  ///
  /// In en, this message translates to:
  /// **'Login with another number'**
  String get loginWithAnotherNumber;

  /// No description provided for @createNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Create a new account'**
  String get createNewAccount;

  /// No description provided for @addMemberTile.
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get addMemberTile;

  /// No description provided for @addFamilyMemberDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Family Member'**
  String get addFamilyMemberDialogTitle;

  /// No description provided for @nameInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameInputLabel;

  /// No description provided for @relationshipLabel.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get relationshipLabel;

  /// No description provided for @addDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get addDialogCancel;

  /// No description provided for @addDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addDialogConfirm;

  /// No description provided for @addFamilyTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Family Members'**
  String get addFamilyTitle;

  /// No description provided for @addFamilyDescription.
  ///
  /// In en, this message translates to:
  /// **'Add up to {cap} family members under your registered mobile number. Each member has their own practice counter.'**
  String addFamilyDescription(int cap);

  /// No description provided for @slotsRemaining.
  ///
  /// In en, this message translates to:
  /// **'Slots remaining: {remaining}'**
  String slotsRemaining(int remaining);

  /// No description provided for @existingMembersLabel.
  ///
  /// In en, this message translates to:
  /// **'Existing members'**
  String get existingMembersLabel;

  /// No description provided for @registeredMobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Registered Mobile'**
  String get registeredMobileLabel;

  /// No description provided for @familyMemberNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Family Member Name'**
  String get familyMemberNameLabel;

  /// No description provided for @familyMemberNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Ananya Sharma'**
  String get familyMemberNameHint;

  /// No description provided for @relationshipDropdownLabel.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get relationshipDropdownLabel;

  /// No description provided for @savingButton.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get savingButton;

  /// No description provided for @saveMemberButton.
  ///
  /// In en, this message translates to:
  /// **'Save Member'**
  String get saveMemberButton;

  /// No description provided for @maxFamilyMembersReached.
  ///
  /// In en, this message translates to:
  /// **'You have reached the maximum number of family members.'**
  String get maxFamilyMembersReached;

  /// No description provided for @enterNameError.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get enterNameError;

  /// No description provided for @writeOnScreenInstruction.
  ///
  /// In en, this message translates to:
  /// **'Write Inside the dots'**
  String get writeOnScreenInstruction;

  /// No description provided for @handwritingSaved.
  ///
  /// In en, this message translates to:
  /// **'Handwriting saved · +{count}'**
  String handwritingSaved(int count);

  /// No description provided for @saveLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveLabel;

  /// No description provided for @clearTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearTooltip;

  /// No description provided for @undoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoTooltip;

  /// No description provided for @redoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redoTooltip;

  /// No description provided for @penColorBrown.
  ///
  /// In en, this message translates to:
  /// **'Brown'**
  String get penColorBrown;

  /// No description provided for @penColorOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get penColorOrange;

  /// No description provided for @penColorTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get penColorTeal;

  /// No description provided for @penColorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get penColorRed;

  /// No description provided for @penColorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get penColorBlue;

  /// No description provided for @penColorBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get penColorBlack;

  /// No description provided for @penColorTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pen color'**
  String get penColorTooltip;

  /// No description provided for @uploadHandwritingTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload Your Handwriting'**
  String get uploadHandwritingTitle;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @selectImageHint.
  ///
  /// In en, this message translates to:
  /// **'Select an image of your handwriting'**
  String get selectImageHint;

  /// No description provided for @noImagesYet.
  ///
  /// In en, this message translates to:
  /// **'No images yet'**
  String get noImagesYet;

  /// No description provided for @pickFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Pick from Gallery'**
  String get pickFromGallery;

  /// No description provided for @openingButton.
  ///
  /// In en, this message translates to:
  /// **'Opening…'**
  String get openingButton;

  /// No description provided for @pickMore.
  ///
  /// In en, this message translates to:
  /// **'Pick more'**
  String get pickMore;

  /// No description provided for @uploadSelected.
  ///
  /// In en, this message translates to:
  /// **'Upload Selected ({count})'**
  String uploadSelected(int count);

  /// No description provided for @captureHandwritingTitle.
  ///
  /// In en, this message translates to:
  /// **'Capture Your Handwriting'**
  String get captureHandwritingTitle;

  /// No description provided for @noCameraAvailable.
  ///
  /// In en, this message translates to:
  /// **'No camera available on this device'**
  String get noCameraAvailable;

  /// No description provided for @submitHandwritingTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit Your Handwriting'**
  String get submitHandwritingTitle;

  /// No description provided for @submitHandwritingDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload your handwriting for personalised PDF mantra recitations. Our AI will randomly select samples to feature.'**
  String get submitHandwritingDescription;

  /// No description provided for @confirmSelectionButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm selection'**
  String get confirmSelectionButton;

  /// No description provided for @modeWriteOnScreenLabel.
  ///
  /// In en, this message translates to:
  /// **'Draw directly on your device'**
  String get modeWriteOnScreenLabel;

  /// No description provided for @modeCaptureCameraLabel.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of your writing'**
  String get modeCaptureCameraLabel;

  /// No description provided for @modeUploadGalleryLabel.
  ///
  /// In en, this message translates to:
  /// **'Select an existing image'**
  String get modeUploadGalleryLabel;

  /// No description provided for @modeDefaultFontLabel.
  ///
  /// In en, this message translates to:
  /// **'Use the app\'s standard font'**
  String get modeDefaultFontLabel;

  /// No description provided for @trainYourVoice.
  ///
  /// In en, this message translates to:
  /// **'Train Your Voice'**
  String get trainYourVoice;

  /// No description provided for @learnChantingPattern.
  ///
  /// In en, this message translates to:
  /// **'Let me learn your unique chanting pattern for accurate counting.'**
  String get learnChantingPattern;

  /// No description provided for @sayMantraInstruction.
  ///
  /// In en, this message translates to:
  /// **'Say '**
  String get sayMantraInstruction;

  /// No description provided for @sayMantraElevenTimes.
  ///
  /// In en, this message translates to:
  /// **' eleven times clearly'**
  String get sayMantraElevenTimes;

  /// No description provided for @speakNaturally.
  ///
  /// In en, this message translates to:
  /// **'Speak naturally at your normal pace and volume'**
  String get speakNaturally;

  /// No description provided for @recordingStatus.
  ///
  /// In en, this message translates to:
  /// **'● Recording  ·  {count} / {target}'**
  String recordingStatus(int count, int target);

  /// No description provided for @tapStartToBegin.
  ///
  /// In en, this message translates to:
  /// **'Tap Start to begin'**
  String get tapStartToBegin;

  /// No description provided for @stopButton.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopButton;

  /// No description provided for @startRecordingButton.
  ///
  /// In en, this message translates to:
  /// **'Start Recording'**
  String get startRecordingButton;

  /// No description provided for @skipUseManualCounter.
  ///
  /// In en, this message translates to:
  /// **'Skip & Use Manual Counter'**
  String get skipUseManualCounter;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navPrograms.
  ///
  /// In en, this message translates to:
  /// **'My Sadhanas'**
  String get navPrograms;

  /// No description provided for @navPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get navPractice;

  /// No description provided for @navCommunity.
  ///
  /// In en, this message translates to:
  /// **'Global Leaderboard'**
  String get navCommunity;

  /// No description provided for @navStore.
  ///
  /// In en, this message translates to:
  /// **'Reward Store'**
  String get navStore;

  /// No description provided for @seeHistory.
  ///
  /// In en, this message translates to:
  /// **'See History'**
  String get seeHistory;

  /// No description provided for @rewardStore.
  ///
  /// In en, this message translates to:
  /// **'Reward Store'**
  String get rewardStore;

  /// No description provided for @encouragementSentLabel.
  ///
  /// In en, this message translates to:
  /// **'Encouragement sent! 🙏'**
  String get encouragementSentLabel;

  /// No description provided for @membersLabel.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get membersLabel;

  /// No description provided for @bestStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Best Streak'**
  String get bestStreakLabel;

  /// No description provided for @daysLabel.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get daysLabel;

  /// No description provided for @closeLabel.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeLabel;

  /// No description provided for @authErrorInvalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Wrong verification code. Please try again.'**
  String get authErrorInvalidOtp;

  /// No description provided for @authErrorInvalidMobile.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 10-digit mobile number.'**
  String get authErrorInvalidMobile;

  /// No description provided for @authErrorAccountNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found for this number. Please create an account first.'**
  String get authErrorAccountNotFound;

  /// No description provided for @authErrorAccountExists.
  ///
  /// In en, this message translates to:
  /// **'An account already exists for this number. Please log in instead.'**
  String get authErrorAccountExists;

  /// No description provided for @authErrorServerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Server is unreachable. Please check your connection and try again.'**
  String get authErrorServerUnavailable;

  /// No description provided for @authErrorNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network and try again.'**
  String get authErrorNoInternet;

  /// No description provided for @authErrorOtpExpired.
  ///
  /// In en, this message translates to:
  /// **'Verification code has expired. Please request a new one.'**
  String get authErrorOtpExpired;

  /// No description provided for @authErrorServerError.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again in a moment.'**
  String get authErrorServerError;

  /// No description provided for @authErrorTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment before trying again.'**
  String get authErrorTooManyAttempts;

  /// No description provided for @authErrorAccountBanned.
  ///
  /// In en, this message translates to:
  /// **'Your account has been suspended. Please contact support.'**
  String get authErrorAccountBanned;

  /// No description provided for @authErrorAccountSuspended.
  ///
  /// In en, this message translates to:
  /// **'Your account has been temporarily suspended. Please contact support.'**
  String get authErrorAccountSuspended;

  /// No description provided for @authErrorOtpMaxAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many incorrect attempts. Request a new code to continue.'**
  String get authErrorOtpMaxAttempts;

  /// No description provided for @authErrorOtpAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'This code has already been used. Request a new one.'**
  String get authErrorOtpAlreadyUsed;

  /// No description provided for @authErrorCooldownActive.
  ///
  /// In en, this message translates to:
  /// **'Please wait a moment before requesting another code.'**
  String get authErrorCooldownActive;

  /// No description provided for @authErrorDailyLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Daily OTP limit reached. Try again tomorrow.'**
  String get authErrorDailyLimitReached;

  /// No description provided for @authErrorDeliveryFailure.
  ///
  /// In en, this message translates to:
  /// **'Could not deliver the OTP. Check your number and try again.'**
  String get authErrorDeliveryFailure;

  /// No description provided for @authErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authErrorUnknown;

  /// No description provided for @authErrorEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name.'**
  String get authErrorEnterName;

  /// No description provided for @authErrorEnterMobileValid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit mobile number.'**
  String get authErrorEnterMobileValid;

  /// No description provided for @authErrorEnterOtpDigits.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code.'**
  String get authErrorEnterOtpDigits;

  /// No description provided for @authErrorMobileIndian.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Indian mobile number (starts with 6–9).'**
  String get authErrorMobileIndian;

  /// No description provided for @authErrorSameMobile.
  ///
  /// In en, this message translates to:
  /// **'This is already your current mobile number.'**
  String get authErrorSameMobile;

  /// No description provided for @authErrorEnterOtp6.
  ///
  /// In en, this message translates to:
  /// **'Please enter the 6-digit verification code.'**
  String get authErrorEnterOtp6;

  /// No description provided for @nameUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Name updated successfully.'**
  String get nameUpdatedSuccess;

  /// No description provided for @mobileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Mobile number updated successfully.'**
  String get mobileUpdatedSuccess;

  /// No description provided for @nameEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty.'**
  String get nameEmptyError;

  /// No description provided for @deleteMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove member?'**
  String get deleteMemberTitle;

  /// No description provided for @deleteMemberContent.
  ///
  /// In en, this message translates to:
  /// **'This will remove {name} from your account.'**
  String deleteMemberContent(String name);

  /// No description provided for @deleteMemberConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get deleteMemberConfirm;

  /// No description provided for @changeMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Change Mobile Number'**
  String get changeMobileNumber;

  /// No description provided for @numberNotRegistered.
  ///
  /// In en, this message translates to:
  /// **'Number not registered'**
  String get numberNotRegistered;

  /// No description provided for @noAccountForNumber.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find an account for this number.'**
  String get noAccountForNumber;

  /// No description provided for @createAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAnAccount;

  /// No description provided for @numberAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'Number already registered'**
  String get numberAlreadyRegistered;

  /// No description provided for @accountAlreadyExistsForNumber.
  ///
  /// In en, this message translates to:
  /// **'An account already exists for this number.'**
  String get accountAlreadyExistsForNumber;

  /// No description provided for @logInInstead.
  ///
  /// In en, this message translates to:
  /// **'Log in instead'**
  String get logInInstead;

  /// No description provided for @resendCodeIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String resendCodeIn(int seconds);

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayNameLabel;

  /// No description provided for @displayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get displayNameHint;

  /// No description provided for @mobileNumberLabel2.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumberLabel2;

  /// No description provided for @changeMobileSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Mobile Number'**
  String get changeMobileSheetTitle;

  /// No description provided for @enterNewMobileHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your new mobile number. We will send a verification code to confirm.'**
  String get enterNewMobileHint;

  /// No description provided for @sendingOtpButton.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get sendingOtpButton;

  /// No description provided for @confirmNewNumber.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Number'**
  String get confirmNewNumber;

  /// No description provided for @verifyingButton2.
  ///
  /// In en, this message translates to:
  /// **'Verifying…'**
  String get verifyingButton2;

  /// No description provided for @writingStyleSection.
  ///
  /// In en, this message translates to:
  /// **'Writing Style'**
  String get writingStyleSection;

  /// No description provided for @retrainWritingStyle.
  ///
  /// In en, this message translates to:
  /// **'Retrain Writing Style'**
  String get retrainWritingStyle;

  /// No description provided for @resendCodeCountdown.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String resendCodeCountdown(int seconds);

  /// No description provided for @mantraNeedWealthProsperity.
  ///
  /// In en, this message translates to:
  /// **'Wealth & Prosperity'**
  String get mantraNeedWealthProsperity;

  /// No description provided for @mantraNeedPeaceCalm.
  ///
  /// In en, this message translates to:
  /// **'Peace & Calm'**
  String get mantraNeedPeaceCalm;

  /// No description provided for @mantraNeedHealing.
  ///
  /// In en, this message translates to:
  /// **'Healing'**
  String get mantraNeedHealing;

  /// No description provided for @mantraNeedProtection.
  ///
  /// In en, this message translates to:
  /// **'Protection'**
  String get mantraNeedProtection;

  /// No description provided for @mantraNeedStrengthCourage.
  ///
  /// In en, this message translates to:
  /// **'Strength & Courage'**
  String get mantraNeedStrengthCourage;

  /// No description provided for @mantraNeedSpiritualLiberation.
  ///
  /// In en, this message translates to:
  /// **'Spiritual Liberation'**
  String get mantraNeedSpiritualLiberation;

  /// No description provided for @mantraNeedWisdomEnlightenment.
  ///
  /// In en, this message translates to:
  /// **'Wisdom & Enlightenment'**
  String get mantraNeedWisdomEnlightenment;

  /// No description provided for @mantraNeedDevotion.
  ///
  /// In en, this message translates to:
  /// **'Devotion'**
  String get mantraNeedDevotion;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Vaachaka Lekhini'**
  String get appTitle;

  /// No description provided for @noRankingsYet.
  ///
  /// In en, this message translates to:
  /// **'No rankings yet'**
  String get noRankingsYet;

  /// No description provided for @noRankingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a sadhana to appear on the leaderboard'**
  String get noRankingsSubtitle;

  /// No description provided for @longestStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Longest Streak'**
  String get longestStreakLabel;

  /// No description provided for @currentStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Streak'**
  String get currentStreakLabel;

  /// No description provided for @streakDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{days} Days'**
  String streakDaysCount(int days);

  /// No description provided for @continueSadhana.
  ///
  /// In en, this message translates to:
  /// **'Continue your Sadhana'**
  String get continueSadhana;

  /// No description provided for @programDayOf.
  ///
  /// In en, this message translates to:
  /// **'Day {current} of {total}'**
  String programDayOf(int current, int total);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'kn', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
