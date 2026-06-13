// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get appName => 'వాచక లేఖిని';

  @override
  String get appTagline => 'మీ వ్యక్తిగత ఆధ్యాత్మిక సాధన సహాయి';

  @override
  String get appMottoChant => 'ఉద్దేశంతో జపించండి | గర్వంగా ట్రాక్ చేయండి';

  @override
  String get setLanguage => 'భాష సెట్ చేయండి';

  @override
  String get existingUser => 'ఇప్పటికే వినియోగదారా?';

  @override
  String get loginButton => 'లాగిన్';

  @override
  String get newUser => 'కొత్త వినియోగదారా?';

  @override
  String get registerButton => 'నమోదు చేయండి';

  @override
  String get knowOurApp => 'మా యాప్ గురించి తెలుసుకోండి';

  @override
  String get createAccountTitle => 'ఖాతా సృష్టించండి';

  @override
  String get beginSpiritualJourney => 'మీ ఆధ్యాత్మిక యాత్రను ప్రారంభించండి';

  @override
  String get quickSetup => 'త్వరిత సెటప్ · 30 సెకన్లు పడుతుంది';

  @override
  String get usernameLabel => 'వినియోగదారు పేరు';

  @override
  String get usernameHint => 'మీ పేరు నమోదు చేయండి';

  @override
  String get mobileNumberLabel => 'మొబైల్ నంబర్';

  @override
  String get mobileNumberHint => '98765 43210';

  @override
  String get referralCodeLabel => 'రెఫరల్ కోడ్ (ఐచ్ఛికం)';

  @override
  String get referralCodeHint => 'రెఫరల్ కోడ్ నమోదు చేయండి';

  @override
  String get selectLanguage => 'భాష ఎంచుకోండి';

  @override
  String get sendingButton => 'పంపుతోంది…';

  @override
  String get sendOtpButton => 'OTP పంపండి';

  @override
  String get verifyingButton => 'ధృవీకరిస్తోంది…';

  @override
  String get registerConfirmButton => 'నమోదు చేయండి';

  @override
  String get alreadyHaveAccount => 'ఇప్పటికే ఖాతా ఉందా? ';

  @override
  String get loginLink => 'లాగిన్';

  @override
  String get loginScreenTitle => 'లాగిన్';

  @override
  String get welcomeBack => 'తిరిగి స్వాగతం';

  @override
  String get enterMobileAssociated =>
      'మీ ఖాతాతో అనుబంధించిన మొబైల్ నంబర్ నమోదు చేయండి.';

  @override
  String get mobileLabel => 'మొబైల్';

  @override
  String get enterSixDigitCode => '6 అంకెల కోడ్ నమోదు చేయండి';

  @override
  String get enterSixDigitCodeSent =>
      'మీ నంబర్‌కు పంపిన 6 అంకెల కోడ్ నమోదు చేయండి.';

  @override
  String enterSixDigitCodeSentToMobile(String mobile) {
    return '+91$mobile కు పంపిన 6 అంకెల కోడ్ నమోదు చేయండి';
  }

  @override
  String resendOtpCountdown(int seconds) {
    return '$secondsసె. లో OTP మళ్లీ పంపండి';
  }

  @override
  String get resendOtp => 'OTP మళ్లీ పంపండి';

  @override
  String get loginConfirmButton => 'లాగిన్';

  @override
  String get dontHaveAccount => 'ఖాతా లేదా? ';

  @override
  String get createOneLink => 'ఒకటి సృష్టించండి';

  @override
  String get welcomeGreeting => 'స్వాగతం';

  @override
  String welcomeGreetingUser(String name) {
    return 'స్వాగతం, $name!';
  }

  @override
  String get homeSublineEmpty => 'మీ ఆధ్యాత్మిక ప్రయాణాన్ని ప్రారంభించండి';

  @override
  String homeSublineActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'బాగుంది! $count కార్యక్రమాలు చురుకుగా ఉన్నాయి',
      one: 'బాగుంది! 1 కార్యక్రమం చురుకుగా ఉంది',
    );
    return '$_temp0';
  }

  @override
  String get saveNameButton => 'పేరు సేవ్ చేయండి';

  @override
  String get savingNameButton => 'సేవ్ అవుతోంది…';

  @override
  String get pressBackAgainToExit => 'మళ్ళీ బ్యాక్ నొక్కి నిష్క్రమించండి';

  @override
  String get rewardPoints => 'బహుమతి పాయింట్లు';

  @override
  String get storeButton => 'స్టోర్';

  @override
  String get dailyPractice => 'రోజువారీ సాధన';

  @override
  String get startFirstGoalToday => 'ఈరోజు మీ మొదటి లక్ష్యాన్ని ప్రారంభించండి';

  @override
  String continueGoal(int days) {
    return 'మీ $days-రోజుల లక్ష్యాన్ని కొనసాగించండి';
  }

  @override
  String get quickStartPractice => 'త్వరిత సాధన ప్రారంభం';

  @override
  String get continuePractice => 'సాధన కొనసాగించండి';

  @override
  String get browseMantras => 'మంత్రాలు చూడండి';

  @override
  String get selectFromPrograms => 'మీ కార్యక్రమాల నుండి ఎంచుకోండి';

  @override
  String get createNewProgram => 'కొత్త కార్యక్రమం సృష్టించండి';

  @override
  String get mantraSelectionTitle => 'మంత్ర ఎంపిక';

  @override
  String get selectMantraByNeed => 'మీ అవసరం ఆధారంగా మంత్రం ఎంచుకోండి →';

  @override
  String get confirmSelection => 'ఎంపిక ధృవీకరించండి';

  @override
  String get mantraNotFound => 'మంత్రం కనుగొనబడలేదు';

  @override
  String get mantraNotFoundTitle => 'కనుగొనబడలేదు';

  @override
  String startPracticeWithMantra(String name) {
    return '$name మంత్రంతో సాధన ప్రారంభించండి';
  }

  @override
  String get pronunciationGuide => 'ఉచ్చారణ మార్గదర్శి';

  @override
  String get mantraForYourNeeds => 'మీ అవసరాలకు మంత్రం';

  @override
  String get selectNeedOrProblem => 'మీ అవసరం లేదా సమస్యను ఎంచుకోండి';

  @override
  String get selectDropdownHint => 'ఎంచుకోండి…';

  @override
  String get startThisPractice => 'ఈ సాధన ప్రారంభించండి';

  @override
  String recitationsTimes(int count) {
    return 'రోజుకు $count సార్లు';
  }

  @override
  String get recitationsSub => 'పఠనాలు';

  @override
  String forDays(int count) {
    return '$count రోజులు';
  }

  @override
  String get durationSub => 'వ్యవధి';

  @override
  String get learnMore => 'మరింత తెలుసుకోండి';

  @override
  String get quickStartTitle => 'త్వరిత సాధన';

  @override
  String get quickStartButton => 'త్వరిత ప్రారంభం';

  @override
  String get globalCount => 'గ్లోబల్ కౌంట్';

  @override
  String get liveUsers => 'ప్రత్యక్ష వినియోగదారులు';

  @override
  String get changeMantra => 'మంత్రం మార్చండి';

  @override
  String get sessionStats => 'సెషన్ గణాంకాలు';

  @override
  String get todaysCount => 'నేటి కౌంట్';

  @override
  String get toMilestone => 'మైలురాయికి';

  @override
  String get milestoneCompleted => 'పూర్తయింది';

  @override
  String milestoneLeft(int count) {
    return '$count మిగిలింది';
  }

  @override
  String get practisingFor => 'సాధన చేస్తున్నారు ';

  @override
  String practiceDay(int days) {
    return '$days రోజు';
  }

  @override
  String practiceDays(int days) {
    return '$days రోజులు';
  }

  @override
  String get startButton => 'ప్రారంభించు';

  @override
  String get noActivePrograms => 'చురుకైన కార్యక్రమాలు లేవు';

  @override
  String get chooseMantra => 'మంత్రం ఎంచుకోండి';

  @override
  String get selectActiveProgramDescription =>
      'ఈ డాష్‌బోర్డ్‌ను నవీకరించడానికి చురుకైన కార్యక్రమాన్ని ఎంచుకోండి.';

  @override
  String get noActivePractice => 'ఇంకా చురుకైన సాధన లేదు';

  @override
  String get pickMantraAndTarget =>
      'జపించడం లేదా రాయడం ప్రారంభించడానికి మంత్రం మరియు లక్ష్యాన్ని ఎంచుకోండి.';

  @override
  String get chooseAMantra => 'మంత్రం ఎంచుకోండి';

  @override
  String get practiceScreenTitle => 'సాధన';

  @override
  String sessionSaved(int count) {
    return 'సెషన్ సేవ్ అయింది · +$count జపాలు';
  }

  @override
  String get todaysProgress => 'నేటి పురోగతి';

  @override
  String get microphoneNeeded => 'మైక్రోఫోన్ అవసరం';

  @override
  String get openSettings => 'సెట్టింగ్‌లు తెరవండి';

  @override
  String get tryVoiceAgain => 'వాయిస్ మళ్లీ ప్రయత్నించండి';

  @override
  String get useManual => 'మాన్యువల్ ఉపయోగించండి';

  @override
  String get pauseButton => 'పాజ్';

  @override
  String get resumeButton => 'కొనసాగించు';

  @override
  String get finishButton => 'ముగించు';

  @override
  String countDisplay(String count) {
    return 'గ్లోబల్ మంత్ర కౌంట్ : $count';
  }

  @override
  String get yoursDisplay => 'మీది : ';

  @override
  String get ambienceSound => 'వాతావరణ ధ్వని';

  @override
  String get phoneMode => 'ఫోన్ మోడ్';

  @override
  String get ownWritingModeLabel => 'స్వంత రాత మోడ్';

  @override
  String get everyJourneyBegins => 'ప్రతి యాత్ర ఒక్క అడుగుతో మొదలవుతుంది.';

  @override
  String get totalChants => 'మొత్తం జపాలు';

  @override
  String get complete => 'పూర్తి';

  @override
  String get daysPractising => 'సాధన రోజులు';

  @override
  String get programs => 'కార్యక్రమాలు';

  @override
  String get overallProgress => 'మొత్తం పురోగతి';

  @override
  String get createNewProgramButton => 'కొత్త కార్యక్రమం';

  @override
  String get myRecitationPrograms => 'నా పఠన కార్యక్రమాలు';

  @override
  String get completedPrograms => 'పూర్తయిన కార్యక్రమాలు';

  @override
  String get noProgramsYet => 'ఇంకా కార్యక్రమాలు లేవు';

  @override
  String get pickMantraAndTargetToStart =>
      'మీ మొదటి కార్యక్రమాన్ని ప్రారంభించడానికి మంత్రం మరియు లక్ష్యాన్ని ఎంచుకోండి.';

  @override
  String get completedWithCheck => 'పూర్తయింది ✓';

  @override
  String get setYourPracticeTarget => 'మీ సాధన లక్ష్యం నిర్ణయించండి';

  @override
  String daysValue(int days) {
    return '$days రోజులు';
  }

  @override
  String get confirmAndBegin => 'నిర్ధారించి ప్రారంభించండి';

  @override
  String get creatingButton => 'సృష్టిస్తోంది…';

  @override
  String get writingsTargetCrore => '1,00,00,000 రాతలు';

  @override
  String get mostPopularBadge => 'అత్యంత ప్రాచుర్యం';

  @override
  String get writingsTargetMillion => '10,00,000 రాతలు';

  @override
  String get setCustomTarget => 'అనుకూల లక్ష్యం నిర్ణయించండి';

  @override
  String get totalWritingsLabel => 'మొత్తం రాతలు';

  @override
  String get totalWritingsHint => 'ఉదా., 5,00,000';

  @override
  String get cancelButton => 'రద్దు';

  @override
  String get searchRewards => 'బహుమతులు వెతకండి…';

  @override
  String get allFilter => 'అన్నీ';

  @override
  String get specialOffer => 'ప్రత్యేక ఆఫర్';

  @override
  String get guidedMeditationSeries => 'మార్గదర్శిత ధ్యాన శ్రేణి';

  @override
  String get unlockPeaceSeries =>
      'మా కొత్త 7-రోజుల శ్రేణితో శాంతిని అన్‌లాక్ చేయండి';

  @override
  String get redeemButton => 'రీడీమ్';

  @override
  String get notEnoughPoints => 'సరిపోవు';

  @override
  String get noRewardsMatch => 'మీ వెతుకులాటకు సరిపోలే బహుమతులు లేవు';

  @override
  String rewardedItemTitle(String title) {
    return '$title రీడీమ్ చేయబడింది';
  }

  @override
  String get rewardPointsHistory => 'బహుమతి పాయింట్లు & చరిత్ర';

  @override
  String get yourTotalPoints => '★ మీ మొత్తం పాయింట్లు';

  @override
  String get visitRewardStore => 'బహుమతి స్టోర్ సందర్శించండి';

  @override
  String get pointsHistory => 'పాయింట్ల చరిత్ర';

  @override
  String get noRewardActivity =>
      'ఇంకా బహుమతి కార్యకలాపాలు లేవు.\nమీ మొదటి పాయింట్లు సంపాదించడానికి సెషన్ ముగించండి.';

  @override
  String get filterAll => 'అన్నీ';

  @override
  String get filterEarned => 'సంపాదించినవి';

  @override
  String get filterSpent => 'ఖర్చు చేసినవి';

  @override
  String get profileTitle => 'ప్రొఫైల్';

  @override
  String get editButton => 'సవరించు';

  @override
  String get totalChantsKpi => 'మొత్తం జపాలు';

  @override
  String get currentStreak => 'ప్రస్తుత స్ట్రీక్';

  @override
  String get milestones => 'మైలురాళ్ళు';

  @override
  String get rewardPointsLabel => 'బహుమతి పాయింట్లు';

  @override
  String get visitStore => 'స్టోర్ సందర్శించండి';

  @override
  String get familyCommunitySection => 'కుటుంబం & సమాజం';

  @override
  String get familyMembers => 'కుటుంబ సభ్యులు';

  @override
  String get inviteFriends => 'స్నేహితులను ఆహ్వానించండి';

  @override
  String get practiceSettingsSection => 'సాధన సెట్టింగ్‌లు';

  @override
  String get reminderTime => 'రిమైండర్ సమయం';

  @override
  String get notificationSound => 'నోటిఫికేషన్ ధ్వని';

  @override
  String get notificationSoundBell => 'గంట';

  @override
  String get notificationSoundConch => 'శంఖం';

  @override
  String get notificationSoundBowl => 'గిన్నె';

  @override
  String get notificationSoundChime => 'చైమ్';

  @override
  String get notificationSoundNone => 'లేదు';

  @override
  String get voiceSettingsSection => 'వాయిస్ సెట్టింగ్‌లు';

  @override
  String get reTrainVoice => 'వాయిస్ పునః శిక్షణ';

  @override
  String get microphoneSensitivity => 'మైక్రోఫోన్ సున్నితత్వం';

  @override
  String get displaySection => 'డిస్‌ప్లే';

  @override
  String get languageSetting => 'భాష';

  @override
  String get languagePickerTitle => 'భాష';

  @override
  String get themeSetting => 'థీమ్';

  @override
  String get themeLight => 'లైట్';

  @override
  String get themeDark => 'డార్క్';

  @override
  String get themeSystem => 'సిస్టమ్';

  @override
  String get fontSizeSetting => 'అక్షర పరిమాణం';

  @override
  String get fontSizeSmall => 'చిన్నది (90%)';

  @override
  String get fontSizeDefaultPct => 'డిఫాల్ట్ (100%)';

  @override
  String get fontSizeLarge => 'పెద్దది (115%)';

  @override
  String get fontSizeExtraLarge => 'చాలా పెద్దది (130%)';

  @override
  String get linkSocialSection => 'సోషల్ లింక్';

  @override
  String get linkFacebook => 'ఫేస్‌బుక్ లింక్ చేయండి';

  @override
  String get linkWhatsApp => 'వాట్సాప్ లింక్ చేయండి';

  @override
  String get linkInstagram => 'ఇన్‌స్టాగ్రామ్ లింక్ చేయండి';

  @override
  String get supportPrivacySection => 'సహాయం & గోప్యత';

  @override
  String get helpFaqs => 'సహాయం & FAQ లు';

  @override
  String get reportIssue => 'సమస్య నివేదించండి';

  @override
  String get shareFeedback => 'అభిప్రాయం పంచుకోండి';

  @override
  String get privacyPolicy => 'గోప్యతా విధానం';

  @override
  String get downloadYourData => 'మీ డేటా డౌన్‌లోడ్ చేయండి';

  @override
  String get aboutApp => 'యాప్ గురించి';

  @override
  String get logoutButton => 'లాగ్అవుట్';

  @override
  String get deleteAccount => 'ఖాతా తొలగించండి';

  @override
  String get versionNumber => 'వెర్షన్ 0.1.0';

  @override
  String get logoutDialogTitle => 'లాగ్అవుట్ అవుతారా?';

  @override
  String get logoutDialogContent => 'మీ స్థానిక డేటా ఈ పరికరంలో ఉంటుంది.';

  @override
  String get logoutDialogCancel => 'రద్దు';

  @override
  String get logoutDialogConfirm => 'లాగ్అవుట్';

  @override
  String get deleteDialogTitle => 'ఖాతా తొలగించాలా?';

  @override
  String get deleteDialogContent =>
      'ఇది ఈ పరికరంలోని అన్ని కార్యక్రమాలు, సెషన్లు, బహుమతులు మరియు ప్రొఫైల్‌లను తొలగిస్తుంది. ఈ చర్యను రద్దు చేయడం సాధ్యపడదు.';

  @override
  String get deleteDialogCancel => 'రద్దు';

  @override
  String get deleteDialogConfirm => 'అన్నీ తొలగించండి';

  @override
  String get infoHelpTitle => 'సహాయం & FAQ లు';

  @override
  String get infoHelpBody =>
      'సాధారణ ప్రశ్నలు మరియు గైడ్‌లు ఇక్కడ ప్రచురించబడతాయి. అత్యవసర సమస్యల కోసం, దయచేసి సమస్య నివేదించండి ఉపయోగించండి.';

  @override
  String get infoReportTitle => 'సమస్య నివేదించండి';

  @override
  String get infoReportBody =>
      'ఏమి తప్పు జరిగిందో చెప్పండి, మేము పరిశీలిస్తాము. ఇమెయిల్ ఇంటిగ్రేషన్ ఏర్పాటు చేయబడుతోంది.';

  @override
  String get infoFeedbackTitle => 'అభిప్రాయం పంచుకోండి';

  @override
  String get infoFeedbackBody =>
      'మేము ప్రతి సూచనను వింటాము. ఏది సరిగ్గా ఉందో లేదా ఏది మారాలో చెప్పండి.';

  @override
  String get infoPrivacyTitle => 'గోప్యతా విధానం';

  @override
  String get infoPrivacyBody =>
      'మీరు సమకాలీకరించాలని ఎంచుకునే వరకు మీ సాధన డేటా మీ పరికరంలో ఉంటుంది. వాయిస్ మరియు హస్తాక్షర నమూనాలు వెర్షన్ 1లో ఈ పరికరాన్ని వదిలివెళ్ళవు.';

  @override
  String get infoAboutTitle => 'వాచక లేఖిని గురించి';

  @override
  String get infoAboutBody =>
      'వాచక లేఖిని మీ వ్యక్తిగత ఆధ్యాత్మిక సాధన సహాయి. మీరు ఎంచుకున్న మంత్రాలను జపించండి లేదా రాయండి, మీ పురోగతిని ట్రాక్ చేయండి, మరియు మీ కుటుంబంతో కలిసి మీ క్రమశిక్షణను పెంచుకోండి.\n\nవెర్షన్ 0.1.0';

  @override
  String recitationsOnDate(String date) {
    return '$date నాటి పఠనాలు';
  }

  @override
  String get dailyTarget => 'రోజువారీ లక్ష్యం';

  @override
  String get actualAchieved => 'వాస్తవంగా సాధించింది';

  @override
  String get handwritingUsed => 'హస్తలేఖనం ఉపయోగించారా';

  @override
  String get handwritingUsedYes => 'అవును';

  @override
  String get handwritingUsedNo => 'లేదు';

  @override
  String get startPractice => 'సాధన ప్రారంభించండి';

  @override
  String get dedicateProgram => 'ఈ కార్యక్రమాన్ని అంకితం చేయండి';

  @override
  String get dedicateSheetTitle => 'ఈ కార్యక్రమాన్ని అంకితం చేయండి';

  @override
  String get dedicateOfferPractice =>
      'మీ జప సాధనను ఒక ప్రత్యేక వ్యక్తికి అర్పించండి';

  @override
  String dedicateOfferNamedPractice(String mantraName) {
    return 'మీ $mantraName సాధనను ఒక ప్రత్యేక వ్యక్తికి అర్పించండి';
  }

  @override
  String get dedicatedTo => 'అంకితం';

  @override
  String get dedicatedToHint => 'ఉదా: నా అమ్మ, శ్రీ గురు, స్వయం';

  @override
  String get intention => 'సంకల్పం (ఐచ్ఛికం)';

  @override
  String get intentionHint => 'ఉదా: ఆమె ఆరోగ్యం మరియు సంతోషం కోసం…';

  @override
  String get removeDedication => 'అంకితాన్ని తొలగించండి';

  @override
  String get updateDedication => 'అంకితాన్ని నవీకరించండి';

  @override
  String get saveDedication => 'అంకితాన్ని సేవ్ చేయండి';

  @override
  String get editGoal => 'లక్ష్యం సవరించండి';

  @override
  String get shareProgram => 'కార్యక్రమం పంచుకోండి';

  @override
  String get dailyProgressTitle => 'రోజువారీ పురోగతి';

  @override
  String communityInviteBanner(int count) {
    return 'మీ సాధన వలయంలో $count మంది స్నేహితులను ఆహ్వానించండి';
  }

  @override
  String get communityInviteSubline =>
      'ఒకరి ఆధ్యాత్మిక యాత్రకు సహకరించడానికి సమాజాన్ని సృష్టించండి.';

  @override
  String get inviteFriendsButton => 'స్నేహితులను ఆహ్వానించండి';

  @override
  String get streakChallenge => 'స్ట్రీక్ సవాలు';

  @override
  String get totalChantsSort => 'మొత్తం జపాలు';

  @override
  String get sendEncouragement => 'ప్రోత్సాహం పంపండి';

  @override
  String get viewGroupStats => 'గ్రూప్ గణాంకాలు చూడండి';

  @override
  String get youLabel => 'మీరు';

  @override
  String get streakLabel => 'స్ట్రీక్';

  @override
  String get inviteFriendsTitle => 'స్నేహితులను ఆహ్వానించండి';

  @override
  String get shareJourneyTitle => 'ఆధ్యాత్మిక వృద్ధి యాత్రను\nపంచుకోండి';

  @override
  String get inviteEarnPoints =>
      'వాచక లేఖినిలో చేరడానికి స్నేహితులను ఆహ్వానించి బహుమతి పాయింట్లు సంపాదించండి.';

  @override
  String get inviteLinkCopied => 'ఆహ్వాన లింక్ కాపీ అయింది';

  @override
  String get shareViaWhatsApp => 'వాట్సాప్ ద్వారా పంచుకోండి';

  @override
  String get shareViaFacebook => 'ఫేస్‌బుక్ ద్వారా పంచుకోండి';

  @override
  String get shareViaInstagram => 'ఇన్‌స్టాగ్రామ్ ద్వారా పంచుకోండి';

  @override
  String get allChannelsShareSheet =>
      'అన్ని ఛానెళ్లు మీ పరికర షేర్ షీట్ తెరుస్తాయి.';

  @override
  String get whoIsPracticing => 'ఎవరు సాధన చేస్తున్నారు?';

  @override
  String get manageProfiles => 'ప్రొఫైల్‌లు నిర్వహించండి';

  @override
  String get loginWithAnotherNumber => 'వేరే నంబర్‌తో లాగిన్ అవ్వండి';

  @override
  String get createNewAccount => 'కొత్త ఖాతా సృష్టించండి';

  @override
  String get addMemberTile => 'సభ్యుని జోడించండి';

  @override
  String get addFamilyMemberDialogTitle => 'కుటుంబ సభ్యుని జోడించండి';

  @override
  String get nameInputLabel => 'పేరు';

  @override
  String get relationshipLabel => 'సంబంధం';

  @override
  String get addDialogCancel => 'రద్దు';

  @override
  String get addDialogConfirm => 'జోడించు';

  @override
  String get addFamilyTitle => 'కుటుంబ సభ్యులను జోడించండి';

  @override
  String addFamilyDescription(int cap) {
    return 'మీ నమోదు చేసిన మొబైల్ నంబర్ కింద $cap వరకు కుటుంబ సభ్యులను జోడించండి. ప్రతి సభ్యుడికి వారి స్వంత సాధన కౌంటర్ ఉంటుంది.';
  }

  @override
  String slotsRemaining(int remaining) {
    return 'మిగిలిన స్లాట్లు: $remaining';
  }

  @override
  String get existingMembersLabel => 'ఇప్పటికే ఉన్న సభ్యులు';

  @override
  String get registeredMobileLabel => 'నమోదు చేసిన మొబైల్';

  @override
  String get familyMemberNameLabel => 'కుటుంబ సభ్యుని పేరు';

  @override
  String get familyMemberNameHint => 'ఉదా., అనన్య శర్మ';

  @override
  String get relationshipDropdownLabel => 'సంబంధం';

  @override
  String get savingButton => 'సేవ్ అవుతోంది…';

  @override
  String get saveMemberButton => 'సభ్యుని సేవ్ చేయండి';

  @override
  String get maxFamilyMembersReached =>
      'మీరు కుటుంబ సభ్యుల గరిష్ట సంఖ్యకు చేరుకున్నారు.';

  @override
  String get enterNameError => 'పేరు నమోదు చేయండి';

  @override
  String get writeOnScreenInstruction => 'చుక్కల లోపల రాయండి';

  @override
  String handwritingSaved(int count) {
    return 'హస్తలేఖనం సేవ్ అయింది · +$count';
  }

  @override
  String get saveLabel => 'సేవ్';

  @override
  String get clearTooltip => 'క్లియర్';

  @override
  String get undoTooltip => 'రద్దు';

  @override
  String get redoTooltip => 'మళ్లీ చేయండి';

  @override
  String get penColorBrown => 'గోధుమ';

  @override
  String get penColorOrange => 'నారింజ';

  @override
  String get penColorTeal => 'టీల్';

  @override
  String get penColorRed => 'ఎరుపు';

  @override
  String get penColorBlue => 'నీలం';

  @override
  String get penColorBlack => 'నలుపు';

  @override
  String get penColorTooltip => 'పెన్ రంగు';

  @override
  String get uploadHandwritingTitle => 'మీ హస్తలేఖనం అప్‌లోడ్ చేయండి';

  @override
  String get deselectAll => 'అన్నీ రద్దు చేయండి';

  @override
  String get selectImageHint => 'మీ హస్తలేఖనం చిత్రాన్ని ఎంచుకోండి';

  @override
  String get noImagesYet => 'ఇంకా చిత్రాలు లేవు';

  @override
  String get pickFromGallery => 'గ్యాలరీ నుండి ఎంచుకోండి';

  @override
  String get openingButton => 'తెరుస్తోంది…';

  @override
  String get pickMore => 'మరిన్ని ఎంచుకోండి';

  @override
  String uploadSelected(int count) {
    return 'ఎంచుకున్నవి అప్‌లోడ్ చేయండి ($count)';
  }

  @override
  String get captureHandwritingTitle => 'మీ హస్తలేఖనాన్ని క్యాప్చర్ చేయండి';

  @override
  String get noCameraAvailable => 'ఈ పరికరంలో కెమెరా అందుబాటులో లేదు';

  @override
  String get submitHandwritingTitle => 'మీ హస్తలేఖనం సమర్పించండి';

  @override
  String get submitHandwritingDescription =>
      'వ్యక్తిగతీకరించిన PDF మంత్ర పఠనాల కోసం మీ హస్తలేఖనం అప్‌లోడ్ చేయండి. మా AI నమూనాలను యాదృచ్ఛికంగా ఎంచుకుంటుంది.';

  @override
  String get confirmSelectionButton => 'ఎంపిక నిర్ధారించండి';

  @override
  String get modeWriteOnScreenLabel => 'మీ పరికరంపై నేరుగా గీయండి';

  @override
  String get modeCaptureCameraLabel => 'మీ రాతకు ఫోటో తీయండి';

  @override
  String get modeUploadGalleryLabel => 'ఇప్పటికే ఉన్న చిత్రాన్ని ఎంచుకోండి';

  @override
  String get modeDefaultFontLabel => 'యాప్ యొక్క ప్రమాణ ఫాంట్ ఉపయోగించండి';

  @override
  String get trainYourVoice => 'మీ వాయిస్‌ని శిక్షించండి';

  @override
  String get learnChantingPattern =>
      'ఖచ్చితమైన గణన కోసం మీ ప్రత్యేక జప విధానాన్ని నేర్చుకోనివ్వండి.';

  @override
  String get sayMantraInstruction => 'చెప్పండి ';

  @override
  String get sayMantraElevenTimes => ' పదకొండు సార్లు స్పష్టంగా';

  @override
  String get speakNaturally =>
      'మీ సాధారణ వేగం మరియు వాల్యూమ్‌లో సహజంగా మాట్లాడండి';

  @override
  String recordingStatus(int count, int target) {
    return '● రికార్డింగ్  ·  $count / $target';
  }

  @override
  String get tapStartToBegin => 'ప్రారంభించడానికి స్టార్ట్ నొక్కండి';

  @override
  String get stopButton => 'ఆపు';

  @override
  String get startRecordingButton => 'రికార్డింగ్ ప్రారంభించండి';

  @override
  String get skipUseManualCounter => 'దాటవేయి & మాన్యువల్ కౌంటర్ ఉపయోగించు';

  @override
  String get navHome => 'హోమ్';

  @override
  String get navPrograms => 'నా కార్యక్రమాలు';

  @override
  String get navPractice => 'సాధన';

  @override
  String get navCommunity => 'స్ట్రీక్ లీడర్‌బోర్డ్';

  @override
  String get navStore => 'బహుమతి స్టోర్';

  @override
  String get seeHistory => 'చరిత్ర చూడండి';

  @override
  String get rewardStore => 'బహుమతి స్టోర్';

  @override
  String get encouragementSentLabel => 'ప్రోత్సాహం పంపబడింది! 🙏';

  @override
  String get membersLabel => 'సభ్యులు';

  @override
  String get bestStreakLabel => 'అత్యుత్తమ స్ట్రీక్';

  @override
  String get daysLabel => 'రోజులు';

  @override
  String get closeLabel => 'మూసివేయి';

  @override
  String get authErrorInvalidOtp =>
      'తప్పు ధృవీకరణ కోడ్. దయచేసి మళ్ళీ ప్రయత్నించండి.';

  @override
  String get authErrorInvalidMobile =>
      'దయచేసి సరైన 10 అంకెల మొబైల్ నంబర్ నమోదు చేయండి.';

  @override
  String get authErrorAccountNotFound =>
      'ఈ నంబర్‌కు ఖాతా కనుగొనబడలేదు. ముందు ఖాతా సృష్టించండి.';

  @override
  String get authErrorAccountExists =>
      'ఈ నంబర్‌కు ఖాతా ఇప్పటికే ఉంది. దయచేసి లాగిన్ చేయండి.';

  @override
  String get authErrorServerUnavailable =>
      'సర్వర్ అందుబాటులో లేదు. మీ కనెక్షన్ తనిఖీ చేయండి.';

  @override
  String get authErrorNoInternet =>
      'ఇంటర్నెట్ కనెక్షన్ లేదు. మీ నెట్‌వర్క్ తనిఖీ చేయండి.';

  @override
  String get authErrorOtpExpired =>
      'ధృవీకరణ కోడ్ గడువు మీరింది. కొత్తది అభ్యర్థించండి.';

  @override
  String get authErrorServerError =>
      'సర్వర్ లోపం. కొంత సేపు తర్వాత మళ్ళీ ప్రయత్నించండి.';

  @override
  String get authErrorTooManyAttempts =>
      'చాలా ప్రయత్నాలు. కొంత సేపు వేచి ఉండండి.';

  @override
  String get authErrorUnknown =>
      'ఏదో తప్పు జరిగింది. దయచేసి మళ్ళీ ప్రయత్నించండి.';

  @override
  String get authErrorEnterName => 'దయచేసి మీ పేరు నమోదు చేయండి.';

  @override
  String get authErrorEnterMobileValid =>
      'సరైన 10 అంకెల మొబైల్ నంబర్ నమోదు చేయండి.';

  @override
  String get authErrorEnterOtpDigits => '6 అంకెల కోడ్ నమోదు చేయండి.';

  @override
  String get authErrorMobileIndian =>
      'సరైన భారతీయ మొబైల్ నంబర్ నమోదు చేయండి (6–9తో ప్రారంభించాలి).';

  @override
  String get authErrorSameMobile => 'ఇది ఇప్పటికే మీ ప్రస్తుత మొబైల్ నంబర్.';

  @override
  String get authErrorEnterOtp6 => 'దయచేసి 6 అంకెల ధృవీకరణ కోడ్ నమోదు చేయండి.';

  @override
  String get nameUpdatedSuccess => 'పేరు విజయవంతంగా నవీకరించబడింది.';

  @override
  String get mobileUpdatedSuccess => 'మొబైల్ నంబర్ విజయవంతంగా నవీకరించబడింది.';

  @override
  String get nameEmptyError => 'పేరు ఖాళీగా ఉండకూడదు.';

  @override
  String get deleteMemberTitle => 'సభ్యుడిని తొలగించాలా?';

  @override
  String deleteMemberContent(String name) {
    return '$nameని మీ ఖాతా నుండి తొలగిస్తుంది.';
  }

  @override
  String get deleteMemberConfirm => 'తొలగించు';

  @override
  String get changeMobileNumber => 'మొబైల్ నంబర్ మార్చండి';

  @override
  String get numberNotRegistered => 'నంబర్ నమోదు కాలేదు';

  @override
  String get noAccountForNumber => 'ఈ నంబర్‌కు ఖాతా కనుగొనబడలేదు.';

  @override
  String get createAnAccount => 'ఖాతా సృష్టించండి';

  @override
  String get numberAlreadyRegistered => 'నంబర్ ఇప్పటికే నమోదు చేయబడింది';

  @override
  String get accountAlreadyExistsForNumber => 'ఈ నంబర్‌కు ఖాతా ఇప్పటికే ఉంది.';

  @override
  String get logInInstead => 'లాగిన్ చేయండి';

  @override
  String resendCodeIn(int seconds) {
    return '$seconds సెకండ్లలో కోడ్ మళ్ళీ పంపండి';
  }

  @override
  String get resendCode => 'కోడ్ మళ్ళీ పంపండి';

  @override
  String get editProfileTitle => 'ప్రొఫైల్ సవరించు';

  @override
  String get displayNameLabel => 'ప్రదర్శన పేరు';

  @override
  String get displayNameHint => 'మీ పేరు';

  @override
  String get mobileNumberLabel2 => 'మొబైల్ నంబర్';

  @override
  String get changeMobileSheetTitle => 'మొబైల్ నంబర్ మార్చండి';

  @override
  String get enterNewMobileHint =>
      'మీ కొత్త మొబైల్ నంబర్ నమోదు చేయండి. నిర్ధారించడానికి ధృవీకరణ కోడ్ పంపుతాం.';

  @override
  String get sendingOtpButton => 'పంపుతున్నాం…';

  @override
  String get confirmNewNumber => 'కొత్త నంబర్ నిర్ధారించు';

  @override
  String get verifyingButton2 => 'ధృవీకరిస్తున్నాం…';

  @override
  String get writingStyleSection => 'రాత శైలి';

  @override
  String get retrainWritingStyle => 'రాత శైలి మళ్ళీ శిక్షణ ఇవ్వండి';

  @override
  String resendCodeCountdown(int seconds) {
    return '$seconds సె. లో కోడ్ మళ్ళీ పంపండి';
  }

  @override
  String get mantraNeedWealthProsperity => 'సంపద & సమృద్ధి';
  @override
  String get mantraNeedPeaceCalm => 'శాంతి & ప్రశాంతత';
  @override
  String get mantraNeedHealing => 'వైద్యం';
  @override
  String get mantraNeedProtection => 'రక్షణ';
  @override
  String get mantraNeedStrengthCourage => 'బలం & ధైర్యం';
  @override
  String get mantraNeedSpiritualLiberation => 'ఆధ్యాత్మిక విముక్తి';
  @override
  String get mantraNeedWisdomEnlightenment => 'జ్ఞానం & జ్ఞానోదయం';
  @override
  String get mantraNeedDevotion => 'భక్తి';
  @override
  String get appTitle => 'వాచిక లేఖిని';
}
