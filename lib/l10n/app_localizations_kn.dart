// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kannada (`kn`).
class AppLocalizationsKn extends AppLocalizations {
  AppLocalizationsKn([String locale = 'kn']) : super(locale);

  @override
  String get appName => 'ವಾಚಕ ಲೇಖಿನಿ';

  @override
  String get appTagline => 'ನಿಮ್ಮ ವೈಯಕ್ತಿಕ ಆಧ್ಯಾತ್ಮಿಕ ಅಭ್ಯಾಸ ಸಹಾಯಕ';

  @override
  String get appMottoChant => 'ಉದ್ದೇಶದಿಂದ ಜಪಿಸಿ | ಹೆಮ್ಮೆಯಿಂದ ಟ್ರ್ಯಾಕ್ ಮಾಡಿ';

  @override
  String get setLanguage => 'ಭಾಷೆ ಆಯ್ಕೆಮಾಡಿ';

  @override
  String get existingUser => 'ಈಗಾಗಲೇ ಬಳಕೆದಾರರಿದ್ದೀರಾ?';

  @override
  String get loginButton => 'ಲಾಗಿನ್';

  @override
  String get newUser => 'ಹೊಸ ಬಳಕೆದಾರರಾ?';

  @override
  String get registerButton => 'ನೋಂದಾಯಿಸಿ';

  @override
  String get knowOurApp => 'ನಮ್ಮ ಅಪ್ಲಿಕೇಶನ್ ತಿಳಿಯಿರಿ';

  @override
  String get createAccountTitle => 'ಖಾತೆ ರಚಿಸಿ';

  @override
  String get beginSpiritualJourney => 'ನಿಮ್ಮ ಆಧ್ಯಾತ್ಮಿಕ ಯಾತ್ರೆ ಪ್ರಾರಂಭಿಸಿ';

  @override
  String get quickSetup => 'ತ್ವರಿತ ಸೆಟಪ್ · 30 ಸೆಕೆಂಡ್ ತೆಗೆದುಕೊಳ್ಳುತ್ತದೆ';

  @override
  String get usernameLabel => 'ಹೆಸರು';

  @override
  String get usernameHint => 'ನಿಮ್ಮ ಹೆಸರು ನಮೂದಿಸಿ';

  @override
  String get mobileNumberLabel => 'ಮೊಬೈಲ್ ಸಂಖ್ಯೆ';

  @override
  String get mobileNumberHint => 'Enter your mobile number';

  @override
  String get referralCodeLabel => 'ರೆಫರಲ್ ಕೋಡ್ (ಐಚ್ಛಿಕ)';

  @override
  String get referralCodeHint => 'ರೆಫರಲ್ ಕೋಡ್ ನಮೂದಿಸಿ';

  @override
  String get selectLanguage => 'ಭಾಷೆ ಆಯ್ಕೆ ಮಾಡಿ';

  @override
  String get sendingButton => 'ಕಳುಹಿಸಲಾಗುತ್ತಿದೆ…';

  @override
  String get sendOtpButton => 'OTP ಕಳುಹಿಸಿ';

  @override
  String get verifyingButton => 'ಪರಿಶೀಲಿಸಲಾಗುತ್ತಿದೆ…';

  @override
  String get registerConfirmButton => 'ನೋಂದಾಯಿಸಿ';

  @override
  String get alreadyHaveAccount => 'ಈಗಾಗಲೇ ಖಾತೆ ಇದೆಯಾ? ';

  @override
  String get loginLink => 'ಲಾಗಿನ್';

  @override
  String get loginScreenTitle => 'ಲಾಗಿನ್';

  @override
  String get welcomeBack => 'ಮತ್ತೆ ಸ್ವಾಗತ';

  @override
  String get enterMobileAssociated =>
      'ನಿಮ್ಮ ಖಾತೆಗೆ ಸಂಯೋಜಿತ ಮೊಬೈಲ್ ಸಂಖ್ಯೆ ನಮೂದಿಸಿ.';

  @override
  String get mobileLabel => 'ಮೊಬೈಲ್';

  @override
  String get enterSixDigitCode => '6 ಅಂಕಿಯ ಕೋಡ್ ನಮೂದಿಸಿ';

  @override
  String get enterSixDigitCodeSent =>
      'ನಿಮ್ಮ ಸಂಖ್ಯೆಗೆ ಕಳುಹಿಸಿದ 6 ಅಂಕಿಯ ಕೋಡ್ ನಮೂದಿಸಿ.';

  @override
  String enterSixDigitCodeSentToMobile(String mobile) {
    return '+91$mobile ಗೆ ಕಳುಹಿಸಿದ 6 ಅಂಕಿಯ ಕೋಡ್ ನಮೂದಿಸಿ';
  }

  @override
  String resendOtpCountdown(int seconds) {
    return '$secondsಸೆ. ನಲ್ಲಿ OTP ಮರುಕಳುಹಿಸಿ';
  }

  @override
  String get resendOtp => 'OTP ಮರುಕಳುಹಿಸಿ';

  @override
  String get loginConfirmButton => 'ಲಾಗಿನ್';

  @override
  String get dontHaveAccount => 'ಖಾತೆ ಇಲ್ಲವಾ? ';

  @override
  String get createOneLink => 'ಒಂದನ್ನು ರಚಿಸಿ';

  @override
  String get welcomeGreeting => 'ಸ್ವಾಗತ';

  @override
  String welcomeGreetingUser(String name) {
    return 'ಸ್ವಾಗತ, $name!';
  }

  @override
  String get homeSublineEmpty => 'ನಿಮ್ಮ ಆಧ್ಯಾತ್ಮಿಕ ಪ್ರಯಾಣ ಪ್ರಾರಂಭಿಸಿ';

  @override
  String homeSublineActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ಅದ್ಭುತ! $count ಸಾಧನಗಳು ಸಕ್ರಿಯವಾಗಿವೆ',
      one: 'ಅದ್ಭುತ! 1 ಸಾಧನ ಸಕ್ರಿಯವಾಗಿದೆ',
    );
    return '$_temp0';
  }

  @override
  String get saveNameButton => 'ಹೆಸರು ಉಳಿಸಿ';

  @override
  String get savingNameButton => 'ಉಳಿಸಲಾಗುತ್ತಿದೆ…';

  @override
  String get pressBackAgainToExit => 'ನಿರ್ಗಮಿಸಲು ಮತ್ತೆ ಬ್ಯಾಕ್ ಒತ್ತಿ';

  @override
  String get rewardPoints => 'ಬಹುಮಾನ ಅಂಕಗಳು';

  @override
  String get storeButton => 'ಅಂಗಡಿ';

  @override
  String get dailyPractice => 'ದೈನಂದಿನ ಅಭ್ಯಾಸ';

  @override
  String get startFirstGoalToday => 'ಇಂದು ನಿಮ್ಮ ಮೊದಲ ಗುರಿ ಪ್ರಾರಂಭಿಸಿ';

  @override
  String continueGoal(int days) {
    return 'ನಿಮ್ಮ $days-ದಿನದ ಗುರಿ ಮುಂದುವರಿಸಿ';
  }

  @override
  String get quickStartPractice => 'ತ್ವರಿತ ಅಭ್ಯಾಸ ಪ್ರಾರಂಭ';

  @override
  String get continuePractice => 'ಅಭ್ಯಾಸ ಮುಂದುವರಿಸಿ';

  @override
  String get browseMantras => 'ಮಂತ್ರಗಳನ್ನು ನೋಡಿ';

  @override
  String get selectFromPrograms => 'ನಿಮ್ಮ ಕಾರ್ಯಕ್ರಮಗಳಿಂದ ಆಯ್ಕೆ ಮಾಡಿ';

  @override
  String get createNewProgram => 'ಹೊಸ ಸಾಧನ ರಚಿಸಿ';

  @override
  String get mantraSelectionTitle => 'ಮಂತ್ರ ಆಯ್ಕೆ';

  @override
  String get selectMantraByNeed => 'ನಿಮ್ಮ ಅಗತ್ಯದ ಆಧಾರದ ಮೇಲೆ ಮಂತ್ರ ಆಯ್ಕೆ ಮಾಡಿ →';

  @override
  String get confirmSelection => 'ಆಯ್ಕೆ ದೃಢಪಡಿಸಿ';

  @override
  String get mantraNotFound => 'ಮಂತ್ರ ಕಂಡುಬಂದಿಲ್ಲ';

  @override
  String get mantraNotFoundTitle => 'ಕಂಡುಬಂದಿಲ್ಲ';

  @override
  String startPracticeWithMantra(String name) {
    return '$name ಮಂತ್ರದೊಂದಿಗೆ ಅಭ್ಯಾಸ ಪ್ರಾರಂಭಿಸಿ';
  }

  @override
  String get pronunciationGuide => 'ಉಚ್ಚಾರಣೆ ಮಾರ್ಗದರ್ಶಿ';

  @override
  String get mantraForYourNeeds => 'ನಿಮ್ಮ ಅಗತ್ಯಗಳಿಗಾಗಿ ಮಂತ್ರ';

  @override
  String get selectNeedOrProblem => 'ನಿಮ್ಮ ಅಗತ್ಯ ಅಥವಾ ಸಮಸ್ಯೆ ಆಯ್ಕೆ ಮಾಡಿ';

  @override
  String get selectDropdownHint => 'ಆಯ್ಕೆ ಮಾಡಿ…';

  @override
  String get startThisPractice => 'ಈ ಅಭ್ಯಾಸ ಪ್ರಾರಂಭಿಸಿ';

  @override
  String recitationsTimes(int count) {
    return 'ದಿನಕ್ಕೆ $count ಬಾರಿ';
  }

  @override
  String get recitationsSub => 'ಪಠಣಗಳು';

  @override
  String forDays(int count) {
    return '$count ದಿನಗಳು';
  }

  @override
  String get durationSub => 'ಅವಧಿ';

  @override
  String get learnMore => 'ಇನ್ನಷ್ಟು ತಿಳಿಯಿರಿ';

  @override
  String get quickStartTitle => 'ತ್ವರಿತ ಅಭ್ಯಾಸ';

  @override
  String get quickStartButton => 'ತ್ವರಿತ ಪ್ರಾರಂಭ';

  @override
  String get globalCount => 'ಜಾಗತಿಕ ಎಣಿಕೆ';

  @override
  String get liveUsers => 'ಲೈವ್ ಬಳಕೆದಾರರು';

  @override
  String get changeMantra => 'ಮಂತ್ರ ಬದಲಿಸಿ';

  @override
  String get sessionStats => 'ಸೆಷನ್ ಅಂಕಿಅಂಶಗಳು';

  @override
  String get todaysCount => 'ಇಂದಿನ ಎಣಿಕೆ';

  @override
  String get toMilestone => 'ಮೈಲಿಗಲ್ಲಿಗೆ';

  @override
  String get milestoneCompleted => 'ಪೂರ್ಣವಾಯಿತು';

  @override
  String milestoneLeft(int count) {
    return '$count ಉಳಿದಿದೆ';
  }

  @override
  String get practisingFor => 'ಅಭ್ಯಾಸ ಮಾಡುತ್ತಿದ್ದಾರೆ ';

  @override
  String practiceDay(int days) {
    return '$days ದಿನ';
  }

  @override
  String practiceDays(int days) {
    return '$days ದಿನಗಳು';
  }

  @override
  String get startButton => 'ಪ್ರಾರಂಭಿಸಿ';

  @override
  String get noActivePrograms => 'ಸಕ್ರಿಯ ಸಾಧನಗಳಿಲ್ಲ';

  @override
  String get chooseMantra => 'ಮಂತ್ರ ಆಯ್ಕೆ ಮಾಡಿ';

  @override
  String get selectActiveProgramDescription =>
      'ಈ ಡ್ಯಾಶ್‌ಬೋರ್ಡ್ ನವೀಕರಿಸಲು ಸಕ್ರಿಯ ಕಾರ್ಯಕ್ರಮ ಆಯ್ಕೆ ಮಾಡಿ.';

  @override
  String get noActivePractice => 'ಇನ್ನೂ ಸಕ್ರಿಯ ಅಭ್ಯಾಸ ಇಲ್ಲ';

  @override
  String get pickMantraAndTarget =>
      'ಜಪ ಅಥವಾ ಬರೆಯಲು ಪ್ರಾರಂಭಿಸಲು ಮಂತ್ರ ಮತ್ತು ಗುರಿ ಆಯ್ಕೆ ಮಾಡಿ.';

  @override
  String get chooseAMantra => 'ಮಂತ್ರ ಆಯ್ಕೆ ಮಾಡಿ';

  @override
  String get practiceScreenTitle => 'ಅಭ್ಯಾಸ';

  @override
  String sessionSaved(int count) {
    return 'ಸೆಷನ್ ಉಳಿಸಲಾಗಿದೆ · +$count ಜಪಗಳು';
  }

  @override
  String get todaysProgress => 'ಇಂದಿನ ಪ್ರಗತಿ';

  @override
  String get microphoneNeeded => 'ಮೈಕ್ರೋಫೋನ್ ಅಗತ್ಯ';

  @override
  String get openSettings => 'ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ತೆರೆಯಿರಿ';

  @override
  String get tryVoiceAgain => 'ಧ್ವನಿ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ';

  @override
  String get useManual => 'ಕೈಪಿಡಿ ಬಳಸಿ';

  @override
  String get pauseButton => 'ವಿರಾಮ';

  @override
  String get resumeButton => 'ಮುಂದುವರಿಸಿ';

  @override
  String get finishButton => 'ಮುಗಿಸಿ';

  @override
  String countDisplay(String count) {
    return 'ಜಾಗತಿಕ ಮಂತ್ರ ಎಣಿಕೆ : $count';
  }

  @override
  String get yoursDisplay => 'ನಿಮ್ಮದು : ';

  @override
  String get ambienceSound => 'ವಾತಾವರಣ ಶಬ್ದ';

  @override
  String get phoneMode => 'ಫೋನ್ ಮೋಡ್';

  @override
  String get ownWritingModeLabel => 'ಬರವಣಿಗೆ ಮೋಡ್';

  @override
  String get everyJourneyBegins =>
      'ಪ್ರತಿ ಯಾತ್ರೆ ಒಂದು ಹೆಜ್ಜೆಯಿಂದ ಪ್ರಾರಂಭವಾಗುತ್ತದೆ.';

  @override
  String get allSadhanasComplete => 'All Sadhanas complete. Begin a new one!';

  @override
  String get keepChanting =>
      'Every chant is a step closer to the divine. Keep going!';

  @override
  String get browseGlobalSadhanas => 'Browse Global Sadhanas';

  @override
  String get totalChants => 'ಒಟ್ಟು ಜಪಗಳು';

  @override
  String get complete => 'ಪೂರ್ಣ';

  @override
  String get daysPractising => 'ಅಭ್ಯಾಸದ ದಿನಗಳು';

  @override
  String get programs => 'ಸಾಧನಗಳು';

  @override
  String get overallProgress => 'ಒಟ್ಟಾರೆ ಪ್ರಗತಿ';

  @override
  String get createNewProgramButton => 'ಹೊಸ ಸಾಧನ';

  @override
  String get myRecitationPrograms => 'ನನ್ನ ಪಠಣ ಸಾಧನಗಳು';

  @override
  String get completedPrograms => 'ಪೂರ್ಣಗೊಂಡ ಸಾಧನಗಳು';

  @override
  String get noProgramsYet => 'ಇನ್ನೂ ಸಾಧನಗಳಿಲ್ಲ';

  @override
  String get pickMantraAndTargetToStart =>
      'ನಿಮ್ಮ ಮೊದಲ ಕಾರ್ಯಕ್ರಮ ಪ್ರಾರಂಭಿಸಲು ಮಂತ್ರ ಮತ್ತು ಗುರಿ ಆಯ್ಕೆ ಮಾಡಿ.';

  @override
  String get completedWithCheck => 'ಪೂರ್ಣವಾಯಿತು ✓';

  @override
  String get setYourPracticeTarget => 'ನಿಮ್ಮ ಅಭ್ಯಾಸ ಗುರಿ ನಿರ್ಧರಿಸಿ';

  @override
  String daysValue(int days) {
    return '$days ದಿನಗಳು';
  }

  @override
  String get confirmAndBegin => 'ದೃಢಪಡಿಸಿ ಮತ್ತು ಪ್ರಾರಂಭಿಸಿ';

  @override
  String get creatingButton => 'ರಚಿಸಲಾಗುತ್ತಿದೆ…';

  @override
  String get writingsTargetCrore => '1,00,00,000 ಬರವಣಿಗೆಗಳು';

  @override
  String get mostPopularBadge => 'ಅತ್ಯಂತ ಜನಪ್ರಿಯ';

  @override
  String get writingsTargetMillion => '10,00,000 ಬರವಣಿಗೆಗಳು';

  @override
  String get setCustomTarget => 'ಕಸ್ಟಮ್ ಗುರಿ ನಿರ್ಧರಿಸಿ';

  @override
  String get totalWritingsLabel => 'ಒಟ್ಟು ಬರವಣಿಗೆಗಳು';

  @override
  String get totalWritingsHint => 'ಉದಾ., 5,00,000';

  @override
  String get cancelButton => 'ರದ್ದು ಮಾಡಿ';

  @override
  String get searchRewards => 'ಬಹುಮಾನಗಳನ್ನು ಹುಡುಕಿ…';

  @override
  String get allFilter => 'ಎಲ್ಲಾ';

  @override
  String get specialOffer => 'ವಿಶೇಷ ಆಫರ್';

  @override
  String get guidedMeditationSeries => 'ಮಾರ್ಗದರ್ಶಿ ಧ್ಯಾನ ಸರಣಿ';

  @override
  String get unlockPeaceSeries =>
      'ನಮ್ಮ ಹೊಸ 7-ದಿನದ ಸರಣಿಯೊಂದಿಗೆ ಶಾಂತಿ ಅನ್‌ಲಾಕ್ ಮಾಡಿ';

  @override
  String get redeemButton => 'ರಿಡೀಮ್';

  @override
  String get notEnoughPoints => 'ಸಾಕಾಗುವುದಿಲ್ಲ';

  @override
  String get noRewardsMatch => 'ನಿಮ್ಮ ಹುಡುಕಾಟಕ್ಕೆ ಹೊಂದಿಕೆಯಾಗುವ ಬಹುಮಾನಗಳಿಲ್ಲ';

  @override
  String rewardedItemTitle(String title) {
    return '$title ರಿಡೀಮ್ ಮಾಡಲಾಗಿದೆ';
  }

  @override
  String get rewardPointsHistory => 'ಬಹುಮಾನ ಅಂಕಗಳು ಮತ್ತು ಇತಿಹಾಸ';

  @override
  String get yourTotalPoints => '★ ನಿಮ್ಮ ಒಟ್ಟು ಅಂಕಗಳು';

  @override
  String get visitRewardStore => 'ಬಹುಮಾನ ಅಂಗಡಿ ಭೇಟಿ ಮಾಡಿ';

  @override
  String get pointsHistory => 'ಅಂಕ ಇತಿಹಾಸ';

  @override
  String get noRewardActivity =>
      'ಇನ್ನೂ ಬಹುಮಾನ ಚಟುವಟಿಕೆ ಇಲ್ಲ.\nಮೊದಲ ಅಂಕ ಗಳಿಸಲು ಸೆಷನ್ ಮುಗಿಸಿ.';

  @override
  String get filterAll => 'ಎಲ್ಲಾ';

  @override
  String get filterEarned => 'ಗಳಿಸಿದ್ದು';

  @override
  String get filterSpent => 'ಖರ್ಚು ಮಾಡಿದ್ದು';

  @override
  String get profileTitle => 'ಪ್ರೊಫೈಲ್';

  @override
  String get editButton => 'ಸಂಪಾದಿಸಿ';

  @override
  String get totalChantsKpi => 'ಒಟ್ಟು ಜಪಗಳು';

  @override
  String get currentStreak => 'ಪ್ರಸ್ತುತ ಸ್ಟ್ರೀಕ್';

  @override
  String get milestones => 'ಮೈಲಿಗಲ್ಲುಗಳು';

  @override
  String get rewardPointsLabel => 'ಬಹುಮಾನ ಅಂಕಗಳು';

  @override
  String get visitStore => 'ಅಂಗಡಿ ಭೇಟಿ ಮಾಡಿ';

  @override
  String get familyCommunitySection => 'ಕುಟುಂಬ ಮತ್ತು ಸಮುದಾಯ';

  @override
  String get familyMembers => 'ಕುಟುಂಬ ಸದಸ್ಯರು';

  @override
  String get inviteFriends => 'ಸ್ನೇಹಿತರನ್ನು ಆಮಂತ್ರಿಸಿ';

  @override
  String get practiceSettingsSection => 'ಅಭ್ಯಾಸ ಸೆಟ್ಟಿಂಗ್‌ಗಳು';

  @override
  String get reminderTime => 'ನೆನಪೋಲೆ ಸಮಯ';

  @override
  String get notificationSound => 'ಅಧಿಸೂಚನೆ ಶಬ್ದ';

  @override
  String get notificationSoundBell => 'ಗಂಟೆ';

  @override
  String get notificationSoundConch => 'ಶಂಖ';

  @override
  String get notificationSoundBowl => 'ಬಟ್ಟಲು';

  @override
  String get notificationSoundChime => 'ಚೈಮ್';

  @override
  String get notificationSoundNone => 'ಇಲ್ಲ';

  @override
  String get voiceSettingsSection => 'ಧ್ವನಿ ಸೆಟ್ಟಿಂಗ್‌ಗಳು';

  @override
  String get reTrainVoice => 'ಧ್ವನಿ ಮರು-ತರಬೇತಿ';

  @override
  String get microphoneSensitivity => 'ಮೈಕ್ರೋಫೋನ್ ಸಂವೇದನಶೀಲತೆ';

  @override
  String get displaySection => 'ಪ್ರದರ್ಶನ';

  @override
  String get languageSetting => 'ಭಾಷೆ';

  @override
  String get languagePickerTitle => 'ಭಾಷೆ';

  @override
  String get linkSocialSection => 'ಸಾಮಾಜಿಕ ಲಿಂಕ್';

  @override
  String get linkFacebook => 'ಫೇಸ್‌ಬುಕ್ ಲಿಂಕ್ ಮಾಡಿ';

  @override
  String get linkWhatsApp => 'ವಾಟ್ಸ್‌ಆ್ಯಪ್ ಲಿಂಕ್ ಮಾಡಿ';

  @override
  String get linkInstagram => 'ಇನ್‌ಸ್ಟಾಗ್ರಾಮ್ ಲಿಂಕ್ ಮಾಡಿ';

  @override
  String get supportPrivacySection => 'ಬೆಂಬಲ ಮತ್ತು ಗೌಪ್ಯತೆ';

  @override
  String get helpFaqs => 'ಸಹಾಯ ಮತ್ತು FAQ';

  @override
  String get reportIssue => 'ಸಮಸ್ಯೆ ವರದಿ ಮಾಡಿ';

  @override
  String get shareFeedback => 'ಪ್ರತಿಕ್ರಿಯೆ ಹಂಚಿಕೊಳ್ಳಿ';

  @override
  String get privacyPolicy => 'ಗೌಪ್ಯತಾ ನೀತಿ';

  @override
  String get downloadYourData => 'ನಿಮ್ಮ ಡೇಟಾ ಡೌನ್‌ಲೋಡ್ ಮಾಡಿ';

  @override
  String get aboutApp => 'ಅಪ್ಲಿಕೇಶನ್ ಬಗ್ಗೆ';

  @override
  String get logoutButton => 'ಲಾಗ್‌ಔಟ್';

  @override
  String get deleteAccount => 'ಖಾತೆ ಅಳಿಸಿ';

  @override
  String get versionNumber => 'ಆವೃತ್ತಿ 8.0.1';

  @override
  String get logoutDialogTitle => 'ಲಾಗ್‌ಔಟ್ ಆಗುವಿರಾ?';

  @override
  String get logoutDialogContent => 'ನಿಮ್ಮ ಸ್ಥಳೀಯ ಡೇಟಾ ಈ ಸಾಧನದಲ್ಲಿ ಉಳಿಯುತ್ತದೆ.';

  @override
  String get logoutDialogCancel => 'ರದ್ದು';

  @override
  String get logoutDialogConfirm => 'ಲಾಗ್‌ಔಟ್';

  @override
  String get deleteDialogTitle => 'ಖಾತೆ ಅಳಿಸುವಿರಾ?';

  @override
  String get deleteDialogContent =>
      'ಇದು ಈ ಸಾಧನದಲ್ಲಿರುವ ಎಲ್ಲಾ ಕಾರ್ಯಕ್ರಮಗಳು, ಸೆಷನ್‌ಗಳು, ಬಹುಮಾನಗಳು ಮತ್ತು ಪ್ರೊಫೈಲ್‌ಗಳನ್ನು ಅಳಿಸುತ್ತದೆ. ಈ ಕ್ರಿಯೆಯನ್ನು ರದ್ದುಗೊಳಿಸಲಾಗುವುದಿಲ್ಲ.';

  @override
  String get deleteDialogCancel => 'ರದ್ದು';

  @override
  String get deleteDialogConfirm => 'ಎಲ್ಲವನ್ನೂ ಅಳಿಸಿ';

  @override
  String get infoHelpTitle => 'ಸಹಾಯ ಮತ್ತು FAQ';

  @override
  String get infoHelpBody =>
      'ಸಾಮಾನ್ಯ ಪ್ರಶ್ನೆಗಳು ಮತ್ತು ಮಾರ್ಗದರ್ಶಿಗಳನ್ನು ಇಲ್ಲಿ ಪ್ರಕಟಿಸಲಾಗುವುದು. ತುರ್ತು ಸಮಸ್ಯೆಗಳಿಗೆ, ದಯವಿಟ್ಟು ಸಮಸ್ಯೆ ವರದಿ ಮಾಡಿ ಬಳಸಿ.';

  @override
  String get infoReportTitle => 'ಸಮಸ್ಯೆ ವರದಿ ಮಾಡಿ';

  @override
  String get infoReportBody =>
      'ಏನು ತಪ್ಪಾಯಿತೆಂದು ತಿಳಿಸಿ, ನಾವು ಪರಿಶೀಲಿಸುತ್ತೇವೆ. ಇಮೇಲ್ ಏಕೀಕರಣ ಸ್ಥಾಪಿಸಲಾಗುತ್ತಿದೆ.';

  @override
  String get infoFeedbackTitle => 'ಪ್ರತಿಕ್ರಿಯೆ ಹಂಚಿಕೊಳ್ಳಿ';

  @override
  String get infoFeedbackBody =>
      'ನಾವು ಪ್ರತಿ ಸಲಹೆಯನ್ನು ಕೇಳುತ್ತೇವೆ. ಏನು ಸರಿಯಾಗಿದೆ ಅಥವಾ ಏನು ಬದಲಾಗಬೇಕೆಂದು ತಿಳಿಸಿ.';

  @override
  String get infoPrivacyTitle => 'ಗೌಪ್ಯತಾ ನೀತಿ';

  @override
  String get infoPrivacyBody =>
      'ನೀವು ಸಿಂಕ್ ಮಾಡಲು ಆಯ್ಕೆ ಮಾಡುವವರೆಗೆ ನಿಮ್ಮ ಅಭ್ಯಾಸ ಡೇಟಾ ನಿಮ್ಮ ಸಾಧನದಲ್ಲಿ ಇರುತ್ತದೆ. ಧ್ವನಿ ಮತ್ತು ಕೈಬರಹ ಮಾದರಿಗಳು ಆವೃತ್ತಿ 1 ರಲ್ಲಿ ಈ ಸಾಧನ ತೊರೆಯುವುದಿಲ್ಲ.';

  @override
  String get infoAboutTitle => 'ವಾಚಕ ಲೇಖಿನಿ ಬಗ್ಗೆ';

  @override
  String get infoAboutBody =>
      'ವಾಚಕ ಲೇಖಿನಿ ನಿಮ್ಮ ವೈಯಕ್ತಿಕ ಆಧ್ಯಾತ್ಮಿಕ ಅಭ್ಯಾಸ ಸಹಾಯಕ. ನಿಮ್ಮ ಆಯ್ಕೆಯ ಮಂತ್ರಗಳನ್ನು ಜಪಿಸಿ ಅಥವಾ ಬರೆಯಿರಿ, ನಿಮ್ಮ ಪ್ರಗತಿ ಟ್ರ್ಯಾಕ್ ಮಾಡಿ, ಮತ್ತು ನಿಮ್ಮ ಕುಟುಂಬದೊಂದಿಗೆ ಶಿಸ್ತು ಬೆಳೆಸಿಕೊಳ್ಳಿ.\n\nಆವೃತ್ತಿ 8.0.1';

  @override
  String recitationsOnDate(String date) {
    return '$date ರಂದು ಪಠಣಗಳು';
  }

  @override
  String get dailyTarget => 'ದೈನಂದಿನ ಗುರಿ';

  @override
  String get actualAchieved => 'ವಾಸ್ತವದಲ್ಲಿ ಸಾಧಿಸಿದ್ದು';

  @override
  String get handwritingUsed => 'ಕೈಬರಹ ಬಳಸಲಾಗಿದೆ';

  @override
  String get handwritingUsedYes => 'ಹೌದು';

  @override
  String get handwritingUsedNo => 'ಇಲ್ಲ';

  @override
  String get startPractice => 'ಅಭ್ಯಾಸ ಪ್ರಾರಂಭಿಸಿ';

  @override
  String get dedicateProgram => 'ಈ ಕಾರ್ಯಕ್ರಮ ಅರ್ಪಿಸಿ';

  @override
  String get dedicateSheetTitle => 'ಈ ಕಾರ್ಯಕ್ರಮ ಅರ್ಪಿಸಿ';

  @override
  String get dedicateOfferPractice =>
      'ನಿಮ್ಮ ಜಪ ಸಾಧನೆಯನ್ನು ಒಬ್ಬ ವಿಶೇಷ ವ್ಯಕ್ತಿಗೆ ಅರ್ಪಿಸಿ';

  @override
  String dedicateOfferNamedPractice(String mantraName) {
    return 'ನಿಮ್ಮ $mantraName ಸಾಧನೆಯನ್ನು ಒಬ್ಬ ವಿಶೇಷ ವ್ಯಕ್ತಿಗೆ ಅರ್ಪಿಸಿ';
  }

  @override
  String get dedicatedTo => 'ಅರ್ಪಿಸಲಾಗಿದೆ';

  @override
  String get dedicatedToHint => 'ಉದಾ: ನನ್ನ ತಾಯಿ, ಶ್ರೀ ಗುರು, ಸ್ವಯಂ';

  @override
  String get intention => 'ಸಂಕಲ್ಪ (ಐಚ್ಛಿಕ)';

  @override
  String get intentionHint => 'ಉದಾ: ಅವಳ ಆರೋಗ್ಯ ಮತ್ತು ಸಂತೋಷಕ್ಕಾಗಿ…';

  @override
  String get removeDedication => 'ಅರ್ಪಣೆ ತೆಗೆದುಹಾಕಿ';

  @override
  String get updateDedication => 'ಅರ್ಪಣೆ ನವೀಕರಿಸಿ';

  @override
  String get saveDedication => 'ಅರ್ಪಣೆ ಉಳಿಸಿ';

  @override
  String get editGoal => 'ಗುರಿ ಸಂಪಾದಿಸಿ';

  @override
  String get shareProgram => 'ಸಾಧನ ಹಂಚಿಕೊಳ್ಳಿ';

  @override
  String get dailyProgressTitle => 'ದೈನಂದಿನ ಪ್ರಗತಿ';

  @override
  String communityInviteBanner(int count) {
    return 'ನಿಮ್ಮ ಅಭ್ಯಾಸ ವಲಯಕ್ಕೆ $count ಸ್ನೇಹಿತರನ್ನು ಆಮಂತ್ರಿಸಿ';
  }

  @override
  String get communityInviteSubline =>
      'ಪರಸ್ಪರ ಆಧ್ಯಾತ್ಮಿಕ ಯಾತ್ರೆಯನ್ನು ಬೆಂಬಲಿಸಲು ಸಮುದಾಯ ರಚಿಸಿ.';

  @override
  String get inviteFriendsButton => 'ಸ್ನೇಹಿತರನ್ನು ಆಮಂತ್ರಿಸಿ';

  @override
  String get streakChallenge => 'ಸ್ಟ್ರೀಕ್ಸ್';

  @override
  String get totalChantsSort => 'ಜಪಗಳು';

  @override
  String get sendEncouragement => 'ಪ್ರೋತ್ಸಾಹ ಕಳುಹಿಸಿ';

  @override
  String get viewGroupStats => 'ಗುಂಪು ಅಂಕಿಅಂಶ ನೋಡಿ';

  @override
  String get youLabel => 'ನೀವು';

  @override
  String get streakLabel => 'ಸ್ಟ್ರೀಕ್';

  @override
  String get inviteFriendsTitle => 'ಸ್ನೇಹಿತರನ್ನು ಆಮಂತ್ರಿಸಿ';

  @override
  String get shareJourneyTitle => 'ಆಧ್ಯಾತ್ಮಿಕ ಬೆಳವಣಿಗೆಯ\nಯಾತ್ರೆ ಹಂಚಿಕೊಳ್ಳಿ';

  @override
  String get inviteEarnPoints =>
      'ವಾಚಕ ಲೇಖಿನಿಗೆ ಸೇರಲು ಸ್ನೇಹಿತರನ್ನು ಆಮಂತ್ರಿಸಿ ಮತ್ತು ಬಹುಮಾನ ಅಂಕಗಳನ್ನು ಗಳಿಸಿ.';

  @override
  String get inviteLinkCopied => 'ಆಮಂತ್ರಣ ಲಿಂಕ್ ನಕಲಿಸಲಾಗಿದೆ';

  @override
  String get shareViaWhatsApp => 'ವಾಟ್ಸ್‌ಆ್ಯಪ್ ಮೂಲಕ ಹಂಚಿಕೊಳ್ಳಿ';

  @override
  String get shareViaFacebook => 'ಫೇಸ್‌ಬುಕ್ ಮೂಲಕ ಹಂಚಿಕೊಳ್ಳಿ';

  @override
  String get shareViaInstagram => 'ಇನ್‌ಸ್ಟಾಗ್ರಾಮ್ ಮೂಲಕ ಹಂಚಿಕೊಳ್ಳಿ';

  @override
  String get allChannelsShareSheet =>
      'ಎಲ್ಲಾ ಚಾನೆಲ್‌ಗಳು ನಿಮ್ಮ ಸಾಧನದ ಶೇರ್ ಶೀಟ್ ತೆರೆಯುತ್ತವೆ.';

  @override
  String get whoIsPracticing => 'ಯಾರು ಅಭ್ಯಾಸ ಮಾಡುತ್ತಿದ್ದಾರೆ?';

  @override
  String get manageProfiles => 'ಪ್ರೊಫೈಲ್‌ಗಳನ್ನು ನಿರ್ವಹಿಸಿ';

  @override
  String get loginWithAnotherNumber => 'ಬೇರೆ ಸಂಖ್ಯೆಯಿಂದ ಲಾಗಿನ್ ಆಗಿ';

  @override
  String get createNewAccount => 'ಹೊಸ ಖಾತೆ ರಚಿಸಿ';

  @override
  String get addMemberTile => 'ಸದಸ್ಯರನ್ನು ಸೇರಿಸಿ';

  @override
  String get addFamilyMemberDialogTitle => 'ಕುಟುಂಬ ಸದಸ್ಯರನ್ನು ಸೇರಿಸಿ';

  @override
  String get nameInputLabel => 'ಹೆಸರು';

  @override
  String get relationshipLabel => 'ಸಂಬಂಧ';

  @override
  String get addDialogCancel => 'ರದ್ದು';

  @override
  String get addDialogConfirm => 'ಸೇರಿಸಿ';

  @override
  String get addFamilyTitle => 'ಕುಟುಂಬ ಸದಸ್ಯರನ್ನು ಸೇರಿಸಿ';

  @override
  String addFamilyDescription(int cap) {
    return 'ನಿಮ್ಮ ನೋಂದಾಯಿತ ಮೊಬೈಲ್ ಸಂಖ್ಯೆ ಅಡಿಯಲ್ಲಿ $cap ವರೆಗೆ ಕುಟುಂಬ ಸದಸ್ಯರನ್ನು ಸೇರಿಸಿ. ಪ್ರತಿ ಸದಸ್ಯರಿಗೆ ತಮ್ಮದೇ ಅಭ್ಯಾಸ ಕೌಂಟರ್ ಇರುತ್ತದೆ.';
  }

  @override
  String slotsRemaining(int remaining) {
    return 'ಉಳಿದ ಸ್ಲಾಟ್‌ಗಳು: $remaining';
  }

  @override
  String get existingMembersLabel => 'ಅಸ್ತಿತ್ವದಲ್ಲಿರುವ ಸದಸ್ಯರು';

  @override
  String get registeredMobileLabel => 'ನೋಂದಾಯಿತ ಮೊಬೈಲ್';

  @override
  String get familyMemberNameLabel => 'ಕುಟುಂಬ ಸದಸ್ಯರ ಹೆಸರು';

  @override
  String get familyMemberNameHint => 'ಉದಾ., ಅನನ್ಯ ಶರ್ಮ';

  @override
  String get relationshipDropdownLabel => 'ಸಂಬಂಧ';

  @override
  String get savingButton => 'ಉಳಿಸಲಾಗುತ್ತಿದೆ…';

  @override
  String get saveMemberButton => 'ಸದಸ್ಯರನ್ನು ಉಳಿಸಿ';

  @override
  String get maxFamilyMembersReached =>
      'ನೀವು ಕುಟುಂಬ ಸದಸ್ಯರ ಗರಿಷ್ಠ ಸಂಖ್ಯೆಯನ್ನು ತಲುಪಿದ್ದೀರಿ.';

  @override
  String get enterNameError => 'ಹೆಸರು ನಮೂದಿಸಿ';

  @override
  String get writeOnScreenInstruction => 'ಚುಕ್ಕಿಗಳ ಒಳಗೆ ಬರೆಯಿರಿ';

  @override
  String handwritingSaved(int count) {
    return 'ಕೈಬರಹ ಉಳಿಸಲಾಗಿದೆ · +$count';
  }

  @override
  String get saveLabel => 'ಉಳಿಸಿ';

  @override
  String get clearTooltip => 'ತೆರವುಗೊಳಿಸಿ';

  @override
  String get undoTooltip => 'ರದ್ದು';

  @override
  String get redoTooltip => 'ಮರುಮಾಡಿ';

  @override
  String get penColorBrown => 'ಕಂದು';

  @override
  String get penColorOrange => 'ಕಿತ್ತಳೆ';

  @override
  String get penColorTeal => 'ಟೀಲ್';

  @override
  String get penColorRed => 'ಕೆಂಪು';

  @override
  String get penColorBlue => 'ನೀಲಿ';

  @override
  String get penColorBlack => 'ಕಪ್ಪು';

  @override
  String get penColorTooltip => 'ಪೆನ್ ಬಣ್ಣ';

  @override
  String get uploadHandwritingTitle => 'ನಿಮ್ಮ ಕೈಬರಹ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ';

  @override
  String get deselectAll => 'ಎಲ್ಲವನ್ನೂ ತೆಗೆದುಹಾಕಿ';

  @override
  String get selectImageHint => 'ನಿಮ್ಮ ಕೈಬರಹದ ಚಿತ್ರ ಆಯ್ಕೆ ಮಾಡಿ';

  @override
  String get noImagesYet => 'ಇನ್ನೂ ಚಿತ್ರಗಳಿಲ್ಲ';

  @override
  String get pickFromGallery => 'ಗ್ಯಾಲರಿಯಿಂದ ಆಯ್ಕೆ ಮಾಡಿ';

  @override
  String get openingButton => 'ತೆರೆಯಲಾಗುತ್ತಿದೆ…';

  @override
  String get pickMore => 'ಇನ್ನಷ್ಟು ಆಯ್ಕೆ ಮಾಡಿ';

  @override
  String uploadSelected(int count) {
    return 'ಆಯ್ಕೆ ಮಾಡಿದ್ದನ್ನು ಅಪ್‌ಲೋಡ್ ಮಾಡಿ ($count)';
  }

  @override
  String get captureHandwritingTitle => 'ನಿಮ್ಮ ಕೈಬರಹ ಕ್ಯಾಪ್ಚರ್ ಮಾಡಿ';

  @override
  String get noCameraAvailable => 'ಈ ಸಾಧನದಲ್ಲಿ ಕ್ಯಾಮೆರಾ ಲಭ್ಯವಿಲ್ಲ';

  @override
  String get submitHandwritingTitle => 'ನಿಮ್ಮ ಕೈಬರಹ ಸಲ್ಲಿಸಿ';

  @override
  String get submitHandwritingDescription =>
      'ವ್ಯಕ್ತಿಗತ PDF ಮಂತ್ರ ಪಠಣಗಳಿಗಾಗಿ ನಿಮ್ಮ ಕೈಬರಹ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ. ನಮ್ಮ AI ಯಾದೃಚ್ಛಿಕವಾಗಿ ಮಾದರಿಗಳನ್ನು ಆಯ್ಕೆ ಮಾಡುತ್ತದೆ.';

  @override
  String get confirmSelectionButton => 'ಆಯ್ಕೆ ದೃಢಪಡಿಸಿ';

  @override
  String get modeWriteOnScreenLabel => 'ನಿಮ್ಮ ಸಾಧನದಲ್ಲಿ ನೇರವಾಗಿ ಬರೆಯಿರಿ';

  @override
  String get modeCaptureCameraLabel => 'ನಿಮ್ಮ ಬರವಣಿಗೆಯ ಫೋಟೋ ತೆಗೆಯಿರಿ';

  @override
  String get modeUploadGalleryLabel => 'ಅಸ್ತಿತ್ವದಲ್ಲಿರುವ ಚಿತ್ರ ಆಯ್ಕೆ ಮಾಡಿ';

  @override
  String get modeDefaultFontLabel => 'ಅಪ್ಲಿಕೇಶನ್‌ನ ಪ್ರಮಾಣಿತ ಫಾಂಟ್ ಬಳಸಿ';

  @override
  String get trainYourVoice => 'ನಿಮ್ಮ ಧ್ವನಿಯನ್ನು ತರಬೇತಿಗೊಳಿಸಿ';

  @override
  String get learnChantingPattern =>
      'ನಿಖರ ಎಣಿಕೆಗಾಗಿ ನಿಮ್ಮ ವಿಶಿಷ್ಟ ಜಪ ಮಾದರಿ ಕಲಿಯಲು ಅನುಮತಿಸಿ.';

  @override
  String get sayMantraInstruction => 'ಹೇಳಿ ';

  @override
  String get sayMantraElevenTimes => ' ಹನ್ನೊಂದು ಬಾರಿ ಸ್ಪಷ್ಟವಾಗಿ';

  @override
  String get speakNaturally =>
      'ನಿಮ್ಮ ಸಾಮಾನ್ಯ ವೇಗ ಮತ್ತು ಧ್ವನಿಮಟ್ಟದಲ್ಲಿ ಸ್ವಾಭಾವಿಕವಾಗಿ ಮಾತನಾಡಿ';

  @override
  String recordingStatus(int count, int target) {
    return '● ರೆಕಾರ್ಡಿಂಗ್  ·  $count / $target';
  }

  @override
  String get tapStartToBegin => 'ಪ್ರಾರಂಭಿಸಲು ಸ್ಟಾರ್ಟ್ ಒತ್ತಿ';

  @override
  String get stopButton => 'ನಿಲ್ಲಿಸಿ';

  @override
  String get startRecordingButton => 'ರೆಕಾರ್ಡಿಂಗ್ ಪ್ರಾರಂಭಿಸಿ';

  @override
  String get skipUseManualCounter => 'ಬಿಟ್ಟುಬಿಡಿ ಮತ್ತು ಕೈಪಿಡಿ ಕೌಂಟರ್ ಬಳಸಿ';

  @override
  String get navHome => 'ಮನೆ';

  @override
  String get navPrograms => 'ನನ್ನ ಸಾಧನಗಳು';

  @override
  String get navPractice => 'ಅಭ್ಯಾಸ';

  @override
  String get navCommunity => 'ಗ್ಲೋಬಲ್ ಲೀಡರ್‌ಬೋರ್ಡ್';

  @override
  String get navStore => 'ಬಹುಮಾನ ಅಂಗಡಿ';

  @override
  String get seeHistory => 'ಇತಿಹಾಸ ನೋಡಿ';

  @override
  String get rewardStore => 'ಬಹುಮಾನ ಅಂಗಡಿ';

  @override
  String get encouragementSentLabel => 'ಪ್ರೋತ್ಸಾಹ ಕಳುಹಿಸಲಾಗಿದೆ! 🙏';

  @override
  String get membersLabel => 'ಸದಸ್ಯರು';

  @override
  String get bestStreakLabel => 'ಅತ್ಯುತ್ತಮ ಸ್ಟ್ರೀಕ್';

  @override
  String get daysLabel => 'ದಿನಗಳು';

  @override
  String get closeLabel => 'ಮುಚ್ಚು';

  @override
  String get authErrorInvalidOtp =>
      'ತಪ್ಪಾದ ಪರಿಶೀಲನಾ ಕೋಡ್. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get authErrorInvalidMobile =>
      'ದಯವಿಟ್ಟು ಮಾನ್ಯ 10 ಅಂಕಿಯ ಮೊಬೈಲ್ ಸಂಖ್ಯೆ ನಮೂದಿಸಿ.';

  @override
  String get authErrorAccountNotFound =>
      'ಈ ಸಂಖ್ಯೆಗೆ ಖಾತೆ ಕಂಡುಬಂದಿಲ್ಲ. ಮೊದಲು ಖಾತೆ ರಚಿಸಿ.';

  @override
  String get authErrorAccountExists =>
      'ಈ ಸಂಖ್ಯೆಗೆ ಖಾತೆ ಈಗಾಗಲೇ ಇದೆ. ದಯವಿಟ್ಟು ಲಾಗಿನ್ ಮಾಡಿ.';

  @override
  String get authErrorServerUnavailable =>
      'ಸರ್ವರ್ ಲಭ್ಯವಿಲ್ಲ. ನಿಮ್ಮ ಸಂಪರ್ಕ ಪರಿಶೀಲಿಸಿ.';

  @override
  String get authErrorNoInternet =>
      'ಇಂಟರ್ನೆಟ್ ಸಂಪರ್ಕ ಇಲ್ಲ. ನಿಮ್ಮ ನೆಟ್‌ವರ್ಕ್ ಪರಿಶೀಲಿಸಿ.';

  @override
  String get authErrorOtpExpired =>
      'ಪರಿಶೀಲನಾ ಕೋಡ್ ಅವಧಿ ಮೀರಿದೆ. ಹೊಸದನ್ನು ವಿನಂತಿಸಿ.';

  @override
  String get authErrorServerError =>
      'ಸರ್ವರ್ ದೋಷ. ಸ್ವಲ್ಪ ಸಮಯದ ನಂತರ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get authErrorTooManyAttempts => 'ಹಲವು ಪ್ರಯತ್ನಗಳು. ಸ್ವಲ್ಪ ಕಾಯಿರಿ.';

  @override
  String get authErrorAccountBanned =>
      'ನಿಮ್ಮ ಖಾತೆಯನ್ನು ನಿಲಿಗಡೆ ಮಾಡಲಾಗಿದೆ. ಬೆಂಬಲ ತಂಡವನ್ನು ಸಂಪರ್ಕಿಸಿ.';

  @override
  String get authErrorAccountSuspended =>
      'ನಿಮ್ಮ ಖಾತೆಯನ್ನು ತಾತ್ಕಾಲಿಕವಾಗಿ ಅಮಾನತುಗೊಳಿಸಲಾಗಿದೆ. ದಯವಿಟ್ಟು ಬೆಂಬಲವನ್ನು ಸಂಪರ್ಕಿಸಿ.';

  @override
  String get authErrorOtpMaxAttempts =>
      'ತಪ್ಪಾದ ಪ್ರಯತ್ನಗಳು ಹೆಚ್ಚಾಗಿವೆ. ಹೊಸ ಕೋಡ್ ವಿನಂತಿಸಿ.';

  @override
  String get authErrorOtpAlreadyUsed =>
      'ಈ ಕೋಡ್ ಅನ್ನು ಈಗಾಗಲೇ ಬಳಸಲಾಗಿದೆ. ಹೊಸದನ್ನು ವಿನಂತಿಸಿ.';

  @override
  String get authErrorCooldownActive =>
      'ಇನ್ನೊಂದು ಕೋಡ್ ವಿನಂತಿಸುವ ಮೊದಲು ಸ್ವಲ್ಪ ಕಾಯಿರಿ.';

  @override
  String get authErrorDailyLimitReached =>
      'ದೈನಂದಿನ OTP ಮಿತಿ ತಲುಪಿದೆ. ನಾಳೆ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get authErrorDeliveryFailure =>
      'OTP ತಲುಪಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ನಿಮ್ಮ ಸಂಖ್ಯೆಯನ್ನು ಪರಿಶೀಲಿಸಿ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get authErrorUnknown => 'ಏನೋ ತಪ್ಪಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get authErrorEnterName => 'ದಯವಿಟ್ಟು ನಿಮ್ಮ ಹೆಸರು ನಮೂದಿಸಿ.';

  @override
  String get authErrorEnterMobileValid =>
      'ಮಾನ್ಯ 10 ಅಂಕಿಯ ಮೊಬೈಲ್ ಸಂಖ್ಯೆ ನಮೂದಿಸಿ.';

  @override
  String get authErrorEnterOtpDigits => '6 ಅಂಕಿಯ ಕೋಡ್ ನಮೂದಿಸಿ.';

  @override
  String get authErrorMobileIndian =>
      'ಮಾನ್ಯ ಭಾರತೀಯ ಮೊಬೈಲ್ ಸಂಖ್ಯೆ ನಮೂದಿಸಿ (6–9 ರಿಂದ ಪ್ರಾರಂಭ).';

  @override
  String get authErrorSameMobile => 'ಇದು ಈಗಾಗಲೇ ನಿಮ್ಮ ಪ್ರಸ್ತುತ ಮೊಬೈಲ್ ಸಂಖ್ಯೆ.';

  @override
  String get authErrorEnterOtp6 => 'ದಯವಿಟ್ಟು 6 ಅಂಕಿಯ ಪರಿಶೀಲನಾ ಕೋಡ್ ನಮೂದಿಸಿ.';

  @override
  String get nameUpdatedSuccess => 'ಹೆಸರು ಯಶಸ್ವಿಯಾಗಿ ನವೀಕರಿಸಲಾಗಿದೆ.';

  @override
  String get mobileUpdatedSuccess => 'ಮೊಬೈಲ್ ಸಂಖ್ಯೆ ಯಶಸ್ವಿಯಾಗಿ ನವೀಕರಿಸಲಾಗಿದೆ.';

  @override
  String get nameEmptyError => 'ಹೆಸರು ಖಾಲಿ ಇರಬಾರದು.';

  @override
  String get deleteMemberTitle => 'ಸದಸ್ಯರನ್ನು ತೆಗೆದುಹಾಕಬೇಕೇ?';

  @override
  String deleteMemberContent(String name) {
    return '$name ಅನ್ನು ನಿಮ್ಮ ಖಾತೆಯಿಂದ ತೆಗೆದುಹಾಕುತ್ತದೆ.';
  }

  @override
  String get deleteMemberConfirm => 'ತೆಗೆದುಹಾಕು';

  @override
  String get changeMobileNumber => 'ಮೊಬೈಲ್ ಸಂಖ್ಯೆ ಬದಲಿಸಿ';

  @override
  String get numberNotRegistered => 'ಸಂಖ್ಯೆ ನೋಂದಾಯಿಸಲಾಗಿಲ್ಲ';

  @override
  String get noAccountForNumber => 'ಈ ಸಂಖ್ಯೆಗೆ ಖಾತೆ ಕಂಡುಬಂದಿಲ್ಲ.';

  @override
  String get createAnAccount => 'ಖಾತೆ ರಚಿಸಿ';

  @override
  String get numberAlreadyRegistered => 'ಸಂಖ್ಯೆ ಈಗಾಗಲೇ ನೋಂದಾಯಿಸಲಾಗಿದೆ';

  @override
  String get accountAlreadyExistsForNumber => 'ಈ ಸಂಖ್ಯೆಗೆ ಖಾತೆ ಈಗಾಗಲೇ ಇದೆ.';

  @override
  String get logInInstead => 'ಲಾಗಿನ್ ಮಾಡಿ';

  @override
  String resendCodeIn(int seconds) {
    return '$seconds ಸೆಕೆಂಡ್‌ನಲ್ಲಿ ಕೋಡ್ ಮರಳಿ ಕಳಿಸಿ';
  }

  @override
  String get resendCode => 'ಕೋಡ್ ಮರಳಿ ಕಳಿಸಿ';

  @override
  String get editProfileTitle => 'ಪ್ರೊಫೈಲ್ ಸಂಪಾದಿಸಿ';

  @override
  String get displayNameLabel => 'ಪ್ರದರ್ಶನ ಹೆಸರು';

  @override
  String get displayNameHint => 'ನಿಮ್ಮ ಹೆಸರು';

  @override
  String get mobileNumberLabel2 => 'ಮೊಬೈಲ್ ಸಂಖ್ಯೆ';

  @override
  String get changeMobileSheetTitle => 'ಮೊಬೈಲ್ ಸಂಖ್ಯೆ ಬದಲಿಸಿ';

  @override
  String get enterNewMobileHint =>
      'ನಿಮ್ಮ ಹೊಸ ಮೊಬೈಲ್ ಸಂಖ್ಯೆ ನಮೂದಿಸಿ. ದೃಢೀಕರಿಸಲು ಪರಿಶೀಲನಾ ಕೋಡ್ ಕಳಿಸಲಾಗುತ್ತದೆ.';

  @override
  String get sendingOtpButton => 'ಕಳಿಸಲಾಗುತ್ತಿದೆ…';

  @override
  String get confirmNewNumber => 'ಹೊಸ ಸಂಖ್ಯೆ ದೃಢೀಕರಿಸಿ';

  @override
  String get verifyingButton2 => 'ಪರಿಶೀಲಿಸಲಾಗುತ್ತಿದೆ…';

  @override
  String get writingStyleSection => 'ಬರಹ ಶೈಲಿ';

  @override
  String get retrainWritingStyle => 'ಬರಹ ಶೈಲಿ ಮರು-ತರಬೇತಿ';

  @override
  String resendCodeCountdown(int seconds) {
    return '$seconds ಸೆ.ನಲ್ಲಿ ಕೋಡ್ ಮರಳಿ ಕಳಿಸಿ';
  }

  @override
  String get mantraNeedWealthProsperity => 'ಸಂಪತ್ತು & ಸಮೃದ್ಧಿ';

  @override
  String get mantraNeedPeaceCalm => 'ಶಾಂತಿ & ನೆಮ್ಮದಿ';

  @override
  String get mantraNeedHealing => 'ಚಿಕಿತ್ಸೆ';

  @override
  String get mantraNeedProtection => 'ರಕ್ಷಣೆ';

  @override
  String get mantraNeedStrengthCourage => 'ಶಕ್ತಿ & ಧೈರ್ಯ';

  @override
  String get mantraNeedSpiritualLiberation => 'ಆಧ್ಯಾತ್ಮಿಕ ಮುಕ್ತಿ';

  @override
  String get mantraNeedWisdomEnlightenment => 'ಜ್ಞಾನ & ಜ್ಞಾನೋದಯ';

  @override
  String get mantraNeedDevotion => 'ಭಕ್ತಿ';

  @override
  String get appTitle => 'ವಾಚಿಕ ಲೇಖಿನಿ';

  @override
  String get noRankingsYet => 'ಇನ್ನೂ ರ್ಯಾಂಕಿಂಗ್ ಇಲ್ಲ';

  @override
  String get noRankingsSubtitle =>
      'ಲೀಡರ್‌ಬೋರ್ಡ್‌ನಲ್ಲಿ ಕಾಣಿಸಲು ಸಾಧನೆ ಪ್ರಾರಂಭಿಸಿ';

  @override
  String get longestStreakLabel => 'ಅತ್ಯಂತ ದೀರ್ಘ ಸ್ಟ್ರೀಕ್';

  @override
  String get currentStreakLabel => 'ಪ್ರಸ್ತುತ ಸ್ಟ್ರೀಕ್';

  @override
  String streakDaysCount(int days) {
    return '$days ದಿನಗಳು';
  }

  @override
  String get continueSadhana => 'ನಿಮ್ಮ ಸಾಧನೆ ಮುಂದುವರಿಸಿ';

  @override
  String programDayOf(int current, int total) {
    return 'ದಿನ $current / $total';
  }
}
