// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'वाचक लेखिनी';

  @override
  String get appTagline => 'आपका व्यक्तिगत आध्यात्मिक साधना सहायक';

  @override
  String get appMottoChant => 'उद्देश्य के साथ जपें | गर्व के साथ ट्रैक करें';

  @override
  String get setLanguage => 'भाषा सेट करें';

  @override
  String get existingUser => 'पहले से उपयोगकर्ता हैं?';

  @override
  String get loginButton => 'लॉगिन';

  @override
  String get newUser => 'नए उपयोगकर्ता हैं?';

  @override
  String get registerButton => 'पंजीकरण करें';

  @override
  String get knowOurApp => 'हमारा ऐप जानें';

  @override
  String get createAccountTitle => 'खाता बनाएं';

  @override
  String get beginSpiritualJourney => 'अपनी आध्यात्मिक यात्रा शुरू करें';

  @override
  String get quickSetup => 'त्वरित सेटअप · 30 सेकंड लगते हैं';

  @override
  String get usernameLabel => 'उपयोगकर्ता नाम';

  @override
  String get usernameHint => 'अपना नाम दर्ज करें';

  @override
  String get mobileNumberLabel => 'मोबाइल नंबर';

  @override
  String get mobileNumberHint => '98765 43210';

  @override
  String get referralCodeLabel => 'रेफरल कोड (वैकल्पिक)';

  @override
  String get referralCodeHint => 'रेफरल कोड दर्ज करें';

  @override
  String get selectLanguage => 'भाषा चुनें';

  @override
  String get sendingButton => 'भेजा जा रहा है…';

  @override
  String get sendOtpButton => 'OTP भेजें';

  @override
  String get verifyingButton => 'सत्यापित हो रहा है…';

  @override
  String get registerConfirmButton => 'पंजीकरण करें';

  @override
  String get alreadyHaveAccount => 'पहले से खाता है? ';

  @override
  String get loginLink => 'लॉगिन';

  @override
  String get loginScreenTitle => 'लॉगिन';

  @override
  String get welcomeBack => 'वापस स्वागत है';

  @override
  String get enterMobileAssociated =>
      'अपने खाते से जुड़ा मोबाइल नंबर दर्ज करें।';

  @override
  String get mobileLabel => 'मोबाइल';

  @override
  String get enterSixDigitCode => '6 अंकों का कोड दर्ज करें';

  @override
  String get enterSixDigitCodeSent =>
      'अपने नंबर पर भेजा गया 6 अंकों का कोड दर्ज करें।';

  @override
  String enterSixDigitCodeSentToMobile(String mobile) {
    return '+91$mobile पर भेजा गया 6 अंकों का कोड दर्ज करें';
  }

  @override
  String resendOtpCountdown(int seconds) {
    return '$secondsसे. में OTP दोबारा भेजें';
  }

  @override
  String get resendOtp => 'OTP दोबारा भेजें';

  @override
  String get loginConfirmButton => 'लॉगिन';

  @override
  String get dontHaveAccount => 'खाता नहीं है? ';

  @override
  String get createOneLink => 'एक बनाएं';

  @override
  String get welcomeGreeting => 'स्वागत है';

  @override
  String welcomeGreetingUser(String name) {
    return 'स्वागत है, $name!';
  }

  @override
  String get homeSublineEmpty => 'अपनी आध्यात्मिक यात्रा शुरू करें';

  @override
  String homeSublineActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'शानदार! $count कार्यक्रम सक्रिय हैं',
      one: 'शानदार! 1 कार्यक्रम सक्रिय है',
    );
    return '$_temp0';
  }

  @override
  String get saveNameButton => 'नाम सहेजें';

  @override
  String get savingNameButton => 'सहेजा जा रहा है…';

  @override
  String get pressBackAgainToExit => 'बाहर निकलने के लिए फिर से बैक दबाएं';

  @override
  String get rewardPoints => 'पुरस्कार अंक';

  @override
  String get storeButton => 'स्टोर';

  @override
  String get dailyPractice => 'दैनिक साधना';

  @override
  String get startFirstGoalToday => 'आज अपना पहला लक्ष्य शुरू करें';

  @override
  String continueGoal(int days) {
    return 'अपना $days-दिन का लक्ष्य जारी रखें';
  }

  @override
  String get quickStartPractice => 'त्वरित साधना शुरू करें';

  @override
  String get continuePractice => 'साधना जारी रखें';

  @override
  String get browseMantras => 'मंत्र देखें';

  @override
  String get selectFromPrograms => 'अपने कार्यक्रमों से चुनें';

  @override
  String get createNewProgram => 'नया कार्यक्रम बनाएं';

  @override
  String get mantraSelectionTitle => 'मंत्र चयन';

  @override
  String get selectMantraByNeed => 'अपनी जरूरत के अनुसार मंत्र चुनें →';

  @override
  String get confirmSelection => 'चयन की पुष्टि करें';

  @override
  String get mantraNotFound => 'मंत्र नहीं मिला';

  @override
  String get mantraNotFoundTitle => 'नहीं मिला';

  @override
  String startPracticeWithMantra(String name) {
    return '$name मंत्र के साथ साधना शुरू करें';
  }

  @override
  String get pronunciationGuide => 'उच्चारण मार्गदर्शिका';

  @override
  String get mantraForYourNeeds => 'आपकी जरूरतों के लिए मंत्र';

  @override
  String get selectNeedOrProblem => 'अपनी जरूरत या समस्या चुनें';

  @override
  String get selectDropdownHint => 'चुनें…';

  @override
  String get startThisPractice => 'यह साधना शुरू करें';

  @override
  String recitationsTimes(int count) {
    return 'दिन में $count बार';
  }

  @override
  String get recitationsSub => 'पाठ';

  @override
  String forDays(int count) {
    return '$count दिनों के लिए';
  }

  @override
  String get durationSub => 'अवधि';

  @override
  String get learnMore => 'और जानें';

  @override
  String get quickStartTitle => 'त्वरित साधना';

  @override
  String get quickStartButton => 'त्वरित शुरुआत';

  @override
  String get globalCount => 'वैश्विक गिनती';

  @override
  String get liveUsers => 'लाइव उपयोगकर्ता';

  @override
  String get changeMantra => 'मंत्र बदलें';

  @override
  String get sessionStats => 'सत्र आँकड़े';

  @override
  String get todaysCount => 'आज की गिनती';

  @override
  String get toMilestone => 'मील के पत्थर तक';

  @override
  String get milestoneCompleted => 'पूर्ण';

  @override
  String milestoneLeft(int count) {
    return '$count शेष';
  }

  @override
  String get practisingFor => 'साधना कर रहे हैं ';

  @override
  String practiceDay(int days) {
    return '$days दिन';
  }

  @override
  String practiceDays(int days) {
    return '$days दिन';
  }

  @override
  String get startButton => 'शुरू करें';

  @override
  String get noActivePrograms => 'कोई सक्रिय कार्यक्रम नहीं';

  @override
  String get chooseMantra => 'मंत्र चुनें';

  @override
  String get selectActiveProgramDescription =>
      'इस डैशबोर्ड को अपडेट करने के लिए सक्रिय कार्यक्रम चुनें।';

  @override
  String get noActivePractice => 'अभी तक कोई सक्रिय साधना नहीं';

  @override
  String get pickMantraAndTarget =>
      'जप या लेखन शुरू करने के लिए मंत्र और लक्ष्य चुनें।';

  @override
  String get chooseAMantra => 'मंत्र चुनें';

  @override
  String get practiceScreenTitle => 'साधना';

  @override
  String sessionSaved(int count) {
    return 'सत्र सहेजा गया · +$count जप';
  }

  @override
  String get todaysProgress => 'आज की प्रगति';

  @override
  String get microphoneNeeded => 'माइक्रोफोन आवश्यक है';

  @override
  String get openSettings => 'सेटिंग्स खोलें';

  @override
  String get tryVoiceAgain => 'आवाज़ फिर से आज़माएं';

  @override
  String get useManual => 'मैन्युअल उपयोग करें';

  @override
  String get pauseButton => 'रोकें';

  @override
  String get resumeButton => 'जारी रखें';

  @override
  String get finishButton => 'समाप्त करें';

  @override
  String countDisplay(String count) {
    return 'वैश्विक मंत्र गिनती : $count';
  }

  @override
  String get yoursDisplay => 'आपका : ';

  @override
  String get ambienceSound => 'परिवेश ध्वनि';

  @override
  String get phoneMode => 'फोन मोड';

  @override
  String get ownWritingModeLabel => 'लेखन मोड';

  @override
  String get everyJourneyBegins => 'हर यात्रा एक कदम से शुरू होती है।';

  @override
  String get totalChants => 'कुल जप';

  @override
  String get complete => 'पूर्ण';

  @override
  String get daysPractising => 'साधना के दिन';

  @override
  String get programs => 'कार्यक्रम';

  @override
  String get overallProgress => 'कुल प्रगति';

  @override
  String get createNewProgramButton => 'नया कार्यक्रम';

  @override
  String get myRecitationPrograms => 'मेरे पाठ कार्यक्रम';

  @override
  String get completedPrograms => 'पूर्ण कार्यक्रम';

  @override
  String get noProgramsYet => 'अभी तक कोई कार्यक्रम नहीं';

  @override
  String get pickMantraAndTargetToStart =>
      'अपना पहला कार्यक्रम शुरू करने के लिए मंत्र और लक्ष्य चुनें।';

  @override
  String get completedWithCheck => 'पूर्ण ✓';

  @override
  String get setYourPracticeTarget => 'अपना साधना लक्ष्य निर्धारित करें';

  @override
  String daysValue(int days) {
    return '$days दिन';
  }

  @override
  String get confirmAndBegin => 'पुष्टि करें और शुरू करें';

  @override
  String get creatingButton => 'बनाया जा रहा है…';

  @override
  String get writingsTargetCrore => '1,00,00,000 लेखन';

  @override
  String get mostPopularBadge => 'सबसे लोकप्रिय';

  @override
  String get writingsTargetMillion => '10,00,000 लेखन';

  @override
  String get setCustomTarget => 'कस्टम लक्ष्य निर्धारित करें';

  @override
  String get totalWritingsLabel => 'कुल लेखन';

  @override
  String get totalWritingsHint => 'जैसे, 5,00,000';

  @override
  String get cancelButton => 'रद्द करें';

  @override
  String get searchRewards => 'पुरस्कार खोजें…';

  @override
  String get allFilter => 'सभी';

  @override
  String get specialOffer => 'विशेष ऑफर';

  @override
  String get guidedMeditationSeries => 'निर्देशित ध्यान श्रृंखला';

  @override
  String get unlockPeaceSeries =>
      'हमारी नई 7-दिन की श्रृंखला से शांति अनलॉक करें';

  @override
  String get redeemButton => 'रिडीम करें';

  @override
  String get notEnoughPoints => 'पर्याप्त नहीं';

  @override
  String get noRewardsMatch => 'आपकी खोज से मेल खाने वाले कोई पुरस्कार नहीं';

  @override
  String rewardedItemTitle(String title) {
    return '$title रिडीम किया गया';
  }

  @override
  String get rewardPointsHistory => 'पुरस्कार अंक और इतिहास';

  @override
  String get yourTotalPoints => '★ आपके कुल अंक';

  @override
  String get visitRewardStore => 'पुरस्कार स्टोर देखें';

  @override
  String get pointsHistory => 'अंक इतिहास';

  @override
  String get noRewardActivity =>
      'अभी तक कोई पुरस्कार गतिविधि नहीं।\nपहले अंक अर्जित करने के लिए सत्र समाप्त करें।';

  @override
  String get filterAll => 'सभी';

  @override
  String get filterEarned => 'अर्जित';

  @override
  String get filterSpent => 'खर्च';

  @override
  String get profileTitle => 'प्रोफ़ाइल';

  @override
  String get editButton => 'संपादित करें';

  @override
  String get totalChantsKpi => 'कुल जप';

  @override
  String get currentStreak => 'वर्तमान स्ट्रीक';

  @override
  String get milestones => 'मील के पत्थर';

  @override
  String get rewardPointsLabel => 'पुरस्कार अंक';

  @override
  String get visitStore => 'स्टोर देखें';

  @override
  String get familyCommunitySection => 'परिवार और समुदाय';

  @override
  String get familyMembers => 'परिवार के सदस्य';

  @override
  String get inviteFriends => 'मित्रों को आमंत्रित करें';

  @override
  String get practiceSettingsSection => 'साधना सेटिंग्स';

  @override
  String get reminderTime => 'अनुस्मारक समय';

  @override
  String get notificationSound => 'सूचना ध्वनि';

  @override
  String get notificationSoundBell => 'घंटी';

  @override
  String get notificationSoundConch => 'शंख';

  @override
  String get notificationSoundBowl => 'कटोरा';

  @override
  String get notificationSoundChime => 'चाइम';

  @override
  String get notificationSoundNone => 'कोई नहीं';

  @override
  String get voiceSettingsSection => 'आवाज़ सेटिंग्स';

  @override
  String get reTrainVoice => 'आवाज़ पुनः प्रशिक्षित करें';

  @override
  String get microphoneSensitivity => 'माइक्रोफोन संवेदनशीलता';

  @override
  String get displaySection => 'डिस्प्ले';

  @override
  String get languageSetting => 'भाषा';

  @override
  String get languagePickerTitle => 'भाषा';

  @override
  String get linkSocialSection => 'सोशल लिंक';

  @override
  String get linkFacebook => 'फेसबुक लिंक करें';

  @override
  String get linkWhatsApp => 'व्हाट्सऐप लिंक करें';

  @override
  String get linkInstagram => 'इंस्टाग्राम लिंक करें';

  @override
  String get supportPrivacySection => 'सहायता और गोपनीयता';

  @override
  String get helpFaqs => 'सहायता और FAQ';

  @override
  String get reportIssue => 'समस्या रिपोर्ट करें';

  @override
  String get shareFeedback => 'प्रतिक्रिया साझा करें';

  @override
  String get privacyPolicy => 'गोपनीयता नीति';

  @override
  String get downloadYourData => 'अपना डेटा डाउनलोड करें';

  @override
  String get aboutApp => 'ऐप के बारे में';

  @override
  String get logoutButton => 'लॉगआउट';

  @override
  String get deleteAccount => 'खाता हटाएं';

  @override
  String get versionNumber => 'संस्करण 0.1.0';

  @override
  String get logoutDialogTitle => 'लॉगआउट करें?';

  @override
  String get logoutDialogContent => 'आपका स्थानीय डेटा इस डिवाइस पर रहेगा।';

  @override
  String get logoutDialogCancel => 'रद्द करें';

  @override
  String get logoutDialogConfirm => 'लॉगआउट';

  @override
  String get deleteDialogTitle => 'खाता हटाएं?';

  @override
  String get deleteDialogContent =>
      'यह इस डिवाइस पर सभी कार्यक्रम, सत्र, पुरस्कार और प्रोफ़ाइल मिटा देगा। यह क्रिया पूर्ववत नहीं की जा सकती।';

  @override
  String get deleteDialogCancel => 'रद्द करें';

  @override
  String get deleteDialogConfirm => 'सब कुछ हटाएं';

  @override
  String get infoHelpTitle => 'सहायता और FAQ';

  @override
  String get infoHelpBody =>
      'सामान्य प्रश्न और गाइड यहाँ प्रकाशित किए जाएंगे। तत्काल समस्याओं के लिए, कृपया समस्या रिपोर्ट करें का उपयोग करें।';

  @override
  String get infoReportTitle => 'समस्या रिपोर्ट करें';

  @override
  String get infoReportBody =>
      'बताएं क्या गलत हुआ और हम इसे देखेंगे। ईमेल एकीकरण स्थापित किया जा रहा है।';

  @override
  String get infoFeedbackTitle => 'प्रतिक्रिया साझा करें';

  @override
  String get infoFeedbackBody =>
      'हम हर सुझाव सुनते हैं। बताएं क्या सही लगता है या क्या बदलना चाहिए।';

  @override
  String get infoPrivacyTitle => 'गोपनीयता नीति';

  @override
  String get infoPrivacyBody =>
      'आपका साधना डेटा आपके डिवाइस पर रहता है जब तक आप इसे सिंक करना नहीं चुनते। संस्करण 1 में आवाज़ और हस्तलेखन नमूने इस डिवाइस से बाहर नहीं जाते।';

  @override
  String get infoAboutTitle => 'वाचक लेखिनी के बारे में';

  @override
  String get infoAboutBody =>
      'वाचक लेखिनी आपका व्यक्तिगत आध्यात्मिक साधना सहायक है। अपने चुने हुए मंत्रों का जप करें या लिखें, अपनी प्रगति ट्रैक करें, और अपने परिवार के साथ मिलकर अनुशासन बढ़ाएं।\n\nसंस्करण 0.1.0';

  @override
  String recitationsOnDate(String date) {
    return '$date के पाठ';
  }

  @override
  String get dailyTarget => 'दैनिक लक्ष्य';

  @override
  String get actualAchieved => 'वास्तव में प्राप्त';

  @override
  String get handwritingUsed => 'हस्तलेखन उपयोग किया';

  @override
  String get handwritingUsedYes => 'हाँ';

  @override
  String get handwritingUsedNo => 'नहीं';

  @override
  String get startPractice => 'साधना शुरू करें';

  @override
  String get dedicateProgram => 'यह कार्यक्रम समर्पित करें';

  @override
  String get dedicateSheetTitle => 'यह कार्यक्रम समर्पित करें';

  @override
  String get dedicateOfferPractice =>
      'अपनी जप साधना किसी खास व्यक्ति को अर्पित करें';

  @override
  String dedicateOfferNamedPractice(String mantraName) {
    return 'अपनी $mantraName साधना किसी खास व्यक्ति को अर्पित करें';
  }

  @override
  String get dedicatedTo => 'समर्पित';

  @override
  String get dedicatedToHint => 'जैसे: मेरी माँ, श्री गुरु, स्वयं';

  @override
  String get intention => 'संकल्प (वैकल्पिक)';

  @override
  String get intentionHint => 'जैसे: उनके स्वास्थ्य और खुशी के लिए…';

  @override
  String get removeDedication => 'समर्पण हटाएं';

  @override
  String get updateDedication => 'समर्पण अपडेट करें';

  @override
  String get saveDedication => 'समर्पण सहेजें';

  @override
  String get editGoal => 'लक्ष्य संपादित करें';

  @override
  String get shareProgram => 'कार्यक्रम साझा करें';

  @override
  String get dailyProgressTitle => 'दैनिक प्रगति';

  @override
  String communityInviteBanner(int count) {
    return 'अपने साधना मंडल में $count मित्रों को आमंत्रित करें';
  }

  @override
  String get communityInviteSubline =>
      'एक-दूसरे की आध्यात्मिक यात्रा में सहयोग के लिए समुदाय बनाएं।';

  @override
  String get inviteFriendsButton => 'मित्रों को आमंत्रित करें';

  @override
  String get streakChallenge => 'स्ट्रीक चुनौती';

  @override
  String get totalChantsSort => 'कुल जप';

  @override
  String get sendEncouragement => 'प्रोत्साहन भेजें';

  @override
  String get viewGroupStats => 'समूह आँकड़े देखें';

  @override
  String get youLabel => 'आप';

  @override
  String get streakLabel => 'स्ट्रीक';

  @override
  String get inviteFriendsTitle => 'मित्रों को आमंत्रित करें';

  @override
  String get shareJourneyTitle => 'आध्यात्मिक विकास की\nयात्रा साझा करें';

  @override
  String get inviteEarnPoints =>
      'वाचक लेखिनी में शामिल होने के लिए मित्रों को आमंत्रित करें और पुरस्कार अंक अर्जित करें।';

  @override
  String get inviteLinkCopied => 'आमंत्रण लिंक कॉपी हो गया';

  @override
  String get shareViaWhatsApp => 'व्हाट्सऐप से साझा करें';

  @override
  String get shareViaFacebook => 'फेसबुक से साझा करें';

  @override
  String get shareViaInstagram => 'इंस्टाग्राम से साझा करें';

  @override
  String get allChannelsShareSheet =>
      'सभी चैनल आपके डिवाइस का शेयर शीट खोलते हैं।';

  @override
  String get whoIsPracticing => 'कौन साधना कर रहा है?';

  @override
  String get manageProfiles => 'प्रोफ़ाइल प्रबंधित करें';

  @override
  String get loginWithAnotherNumber => 'किसी अन्य नंबर से लॉगिन करें';

  @override
  String get createNewAccount => 'नया खाता बनाएं';

  @override
  String get addMemberTile => 'सदस्य जोड़ें';

  @override
  String get addFamilyMemberDialogTitle => 'परिवार का सदस्य जोड़ें';

  @override
  String get nameInputLabel => 'नाम';

  @override
  String get relationshipLabel => 'रिश्ता';

  @override
  String get addDialogCancel => 'रद्द करें';

  @override
  String get addDialogConfirm => 'जोड़ें';

  @override
  String get addFamilyTitle => 'परिवार के सदस्य जोड़ें';

  @override
  String addFamilyDescription(int cap) {
    return 'अपने पंजीकृत मोबाइल नंबर के अंतर्गत $cap तक परिवार के सदस्य जोड़ें। प्रत्येक सदस्य का अपना साधना काउंटर होता है।';
  }

  @override
  String slotsRemaining(int remaining) {
    return 'शेष स्लॉट: $remaining';
  }

  @override
  String get existingMembersLabel => 'मौजूदा सदस्य';

  @override
  String get registeredMobileLabel => 'पंजीकृत मोबाइल';

  @override
  String get familyMemberNameLabel => 'परिवार के सदस्य का नाम';

  @override
  String get familyMemberNameHint => 'जैसे, अनन्या शर्मा';

  @override
  String get relationshipDropdownLabel => 'रिश्ता';

  @override
  String get savingButton => 'सहेजा जा रहा है…';

  @override
  String get saveMemberButton => 'सदस्य सहेजें';

  @override
  String get maxFamilyMembersReached =>
      'आप परिवार के सदस्यों की अधिकतम संख्या तक पहुँच गए हैं।';

  @override
  String get enterNameError => 'नाम दर्ज करें';

  @override
  String get writeOnScreenInstruction => 'बिंदुओं के अंदर लिखें';

  @override
  String handwritingSaved(int count) {
    return 'हस्तलेखन सहेजा गया · +$count';
  }

  @override
  String get saveLabel => 'सहेजें';

  @override
  String get clearTooltip => 'साफ करें';

  @override
  String get undoTooltip => 'पूर्ववत करें';

  @override
  String get redoTooltip => 'फिर करें';

  @override
  String get penColorBrown => 'भूरा';

  @override
  String get penColorOrange => 'नारंगी';

  @override
  String get penColorTeal => 'टील';

  @override
  String get penColorRed => 'लाल';

  @override
  String get penColorBlue => 'नीला';

  @override
  String get penColorBlack => 'काला';

  @override
  String get penColorTooltip => 'पेन रंग';

  @override
  String get uploadHandwritingTitle => 'अपना हस्तलेखन अपलोड करें';

  @override
  String get deselectAll => 'सभी हटाएं';

  @override
  String get selectImageHint => 'अपने हस्तलेखन की छवि चुनें';

  @override
  String get noImagesYet => 'अभी तक कोई छवि नहीं';

  @override
  String get pickFromGallery => 'गैलरी से चुनें';

  @override
  String get openingButton => 'खुल रहा है…';

  @override
  String get pickMore => 'और चुनें';

  @override
  String uploadSelected(int count) {
    return 'चयनित अपलोड करें ($count)';
  }

  @override
  String get captureHandwritingTitle => 'अपना हस्तलेखन कैप्चर करें';

  @override
  String get noCameraAvailable => 'इस डिवाइस पर कोई कैमरा उपलब्ध नहीं';

  @override
  String get submitHandwritingTitle => 'अपना हस्तलेखन जमा करें';

  @override
  String get submitHandwritingDescription =>
      'व्यक्तिगत PDF मंत्र पाठ के लिए अपना हस्तलेखन अपलोड करें। हमारी AI नमूनों का यादृच्छिक रूप से चयन करेगी।';

  @override
  String get confirmSelectionButton => 'चयन की पुष्टि करें';

  @override
  String get modeWriteOnScreenLabel => 'अपने डिवाइस पर सीधे बनाएं';

  @override
  String get modeCaptureCameraLabel => 'अपने लेखन की फोटो लें';

  @override
  String get modeUploadGalleryLabel => 'मौजूदा छवि चुनें';

  @override
  String get modeDefaultFontLabel => 'ऐप का मानक फ़ॉन्ट उपयोग करें';

  @override
  String get trainYourVoice => 'अपनी आवाज़ प्रशिक्षित करें';

  @override
  String get learnChantingPattern =>
      'सटीक गिनती के लिए मुझे अपना अनूठा जप पैटर्न सीखने दें।';

  @override
  String get sayMantraInstruction => 'बोलें ';

  @override
  String get sayMantraElevenTimes => ' ग्यारह बार स्पष्ट रूप से';

  @override
  String get speakNaturally =>
      'अपनी सामान्य गति और आवाज़ में स्वाभाविक रूप से बोलें';

  @override
  String recordingStatus(int count, int target) {
    return '● रिकॉर्डिंग  ·  $count / $target';
  }

  @override
  String get tapStartToBegin => 'शुरू करने के लिए स्टार्ट दबाएं';

  @override
  String get stopButton => 'रोकें';

  @override
  String get startRecordingButton => 'रिकॉर्डिंग शुरू करें';

  @override
  String get skipUseManualCounter => 'छोड़ें और मैन्युअल काउंटर उपयोग करें';

  @override
  String get navHome => 'होम';

  @override
  String get navPrograms => 'मेरे कार्यक्रम';

  @override
  String get navPractice => 'साधना';

  @override
  String get navCommunity => 'स्ट्रीक लीडरबोर्ड';

  @override
  String get navStore => 'पुरस्कार स्टोर';

  @override
  String get seeHistory => 'इतिहास देखें';

  @override
  String get rewardStore => 'पुरस्कार स्टोर';

  @override
  String get encouragementSentLabel => 'प्रोत्साहन भेजा! 🙏';

  @override
  String get membersLabel => 'सदस्य';

  @override
  String get bestStreakLabel => 'सर्वश्रेष्ठ स्ट्रीक';

  @override
  String get daysLabel => 'दिन';

  @override
  String get closeLabel => 'बंद करें';

  @override
  String get authErrorInvalidOtp => 'गलत सत्यापन कोड। कृपया पुनः प्रयास करें।';

  @override
  String get authErrorInvalidMobile =>
      'कृपया एक मान्य 10-अंकीय मोबाइल नंबर दर्ज करें।';

  @override
  String get authErrorAccountNotFound =>
      'इस नंबर के लिए कोई खाता नहीं मिला। पहले खाता बनाएं।';

  @override
  String get authErrorAccountExists =>
      'इस नंबर के लिए खाता पहले से मौजूद है। कृपया लॉग इन करें।';

  @override
  String get authErrorServerUnavailable =>
      'सर्वर उपलब्ध नहीं है। अपना कनेक्शन जांचें।';

  @override
  String get authErrorNoInternet =>
      'इंटरनेट कनेक्शन नहीं है। अपना नेटवर्क जांचें।';

  @override
  String get authErrorOtpExpired =>
      'सत्यापन कोड की समय-सीमा समाप्त हो गई। नया अनुरोध करें।';

  @override
  String get authErrorServerError =>
      'सर्वर त्रुटि। कृपया थोड़ी देर बाद प्रयास करें।';

  @override
  String get authErrorTooManyAttempts =>
      'बहुत अधिक प्रयास। कृपया थोड़ी देर प्रतीक्षा करें।';

  @override
  String get authErrorAccountBanned =>
      'आपका खाता निलंबित कर दिया गया है। कृपया सहायता से संपर्क करें।';

  @override
  String get authErrorAccountSuspended =>
      'आपका खाता अस्थायी रूप से निलंबित कर दिया गया है। कृपया सहायता से संपर्क करें।';

  @override
  String get authErrorOtpMaxAttempts => 'बहुत अधिक गलत प्रयास। नया कोड माँगें।';

  @override
  String get authErrorOtpAlreadyUsed =>
      'यह कोड पहले ही उपयोग किया जा चुका है। नया माँगें।';

  @override
  String get authErrorCooldownActive =>
      'कृपया दूसरा कोड माँगने से पहले थोड़ी देर प्रतीक्षा करें।';

  @override
  String get authErrorDailyLimitReached =>
      'आज की OTP सीमा समाप्त हो गई। कल पुनः प्रयास करें।';

  @override
  String get authErrorDeliveryFailure =>
      'OTP नहीं भेजा जा सका। अपना नंबर जाँचें और पुनः प्रयास करें।';

  @override
  String get authErrorUnknown => 'कुछ गलत हो गया। कृपया पुनः प्रयास करें।';

  @override
  String get authErrorEnterName => 'कृपया अपना नाम दर्ज करें।';

  @override
  String get authErrorEnterMobileValid =>
      'एक मान्य 10-अंकीय मोबाइल नंबर दर्ज करें।';

  @override
  String get authErrorEnterOtpDigits => '6-अंकीय कोड दर्ज करें।';

  @override
  String get authErrorMobileIndian =>
      'एक मान्य भारतीय मोबाइल नंबर दर्ज करें (6–9 से शुरू)।';

  @override
  String get authErrorSameMobile => 'यह पहले से आपका वर्तमान मोबाइल नंबर है।';

  @override
  String get authErrorEnterOtp6 => 'कृपया 6-अंकीय सत्यापन कोड दर्ज करें।';

  @override
  String get nameUpdatedSuccess => 'नाम सफलतापूर्वक अपडेट किया गया।';

  @override
  String get mobileUpdatedSuccess => 'मोबाइल नंबर सफलतापूर्वक अपडेट किया गया।';

  @override
  String get nameEmptyError => 'नाम खाली नहीं हो सकता।';

  @override
  String get deleteMemberTitle => 'सदस्य हटाएं?';

  @override
  String deleteMemberContent(String name) {
    return '$name को आपके खाते से हटा देगा।';
  }

  @override
  String get deleteMemberConfirm => 'हटाएं';

  @override
  String get changeMobileNumber => 'मोबाइल नंबर बदलें';

  @override
  String get numberNotRegistered => 'नंबर पंजीकृत नहीं है';

  @override
  String get noAccountForNumber => 'इस नंबर के लिए कोई खाता नहीं मिला।';

  @override
  String get createAnAccount => 'खाता बनाएं';

  @override
  String get numberAlreadyRegistered => 'नंबर पहले से पंजीकृत है';

  @override
  String get accountAlreadyExistsForNumber =>
      'इस नंबर के लिए खाता पहले से मौजूद है।';

  @override
  String get logInInstead => 'लॉग इन करें';

  @override
  String resendCodeIn(int seconds) {
    return '$seconds सेकंड में कोड दोबारा भेजें';
  }

  @override
  String get resendCode => 'कोड दोबारा भेजें';

  @override
  String get editProfileTitle => 'प्रोफ़ाइल संपादित करें';

  @override
  String get displayNameLabel => 'प्रदर्शन नाम';

  @override
  String get displayNameHint => 'आपका नाम';

  @override
  String get mobileNumberLabel2 => 'मोबाइल नंबर';

  @override
  String get changeMobileSheetTitle => 'मोबाइल नंबर बदलें';

  @override
  String get enterNewMobileHint =>
      'अपना नया मोबाइल नंबर दर्ज करें। पुष्टि के लिए सत्यापन कोड भेजा जाएगा।';

  @override
  String get sendingOtpButton => 'भेज रहे हैं…';

  @override
  String get confirmNewNumber => 'नया नंबर पुष्टि करें';

  @override
  String get verifyingButton2 => 'सत्यापित कर रहे हैं…';

  @override
  String get writingStyleSection => 'लेखन शैली';

  @override
  String get retrainWritingStyle => 'लेखन शैली पुनः प्रशिक्षित करें';

  @override
  String resendCodeCountdown(int seconds) {
    return '$seconds से. में कोड दोबारा भेजें';
  }

  @override
  String get mantraNeedWealthProsperity => 'धन और समृद्धि';

  @override
  String get mantraNeedPeaceCalm => 'शांति और सुकून';

  @override
  String get mantraNeedHealing => 'उपचार';

  @override
  String get mantraNeedProtection => 'सुरक्षा';

  @override
  String get mantraNeedStrengthCourage => 'शक्ति और साहस';

  @override
  String get mantraNeedSpiritualLiberation => 'आध्यात्मिक मुक्ति';

  @override
  String get mantraNeedWisdomEnlightenment => 'ज्ञान और प्रबोधन';

  @override
  String get mantraNeedDevotion => 'भक्ति';

  @override
  String get appTitle => 'वाचिक लेखिनी';
}
