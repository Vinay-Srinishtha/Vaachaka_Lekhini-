// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Vaachaka Lekhini';

  @override
  String get appTagline => 'Your Personal Spiritual Practice Companion';

  @override
  String get appMottoChant => 'Chant with Purpose | Track with Pride';

  @override
  String get setLanguage => 'Set Language';

  @override
  String get existingUser => 'Existing user?';

  @override
  String get loginButton => 'Login';

  @override
  String get newUser => 'New user?';

  @override
  String get registerButton => 'Register';

  @override
  String get knowOurApp => 'Know our App';

  @override
  String get createAccountTitle => 'Create Account';

  @override
  String get beginSpiritualJourney => 'Begin your spiritual journey';

  @override
  String get quickSetup => 'Quick setup · takes 30 seconds';

  @override
  String get usernameLabel => 'Username';

  @override
  String get usernameHint => 'Enter your name';

  @override
  String get mobileNumberLabel => 'Mobile Number';

  @override
  String get mobileNumberHint => '98765 43210';

  @override
  String get referralCodeLabel => 'Referral Code (Optional)';

  @override
  String get referralCodeHint => 'Enter referral code';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get sendingButton => 'Sending…';

  @override
  String get sendOtpButton => 'Send OTP';

  @override
  String get verifyingButton => 'Verifying…';

  @override
  String get registerConfirmButton => 'Register';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get loginLink => 'Login';

  @override
  String get loginScreenTitle => 'Login';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get enterMobileAssociated =>
      'Enter the mobile number associated with your account.';

  @override
  String get mobileLabel => 'Mobile';

  @override
  String get enterSixDigitCode => 'Enter the 6-digit code';

  @override
  String get enterSixDigitCodeSent =>
      'Enter the 6-digit code sent to your number.';

  @override
  String enterSixDigitCodeSentToMobile(String mobile) {
    return 'Enter the 6-digit code sent to +91$mobile';
  }

  @override
  String resendOtpCountdown(int seconds) {
    return 'Resend OTP in ${seconds}s';
  }

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String get loginConfirmButton => 'Login';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get createOneLink => 'Create one';

  @override
  String get welcomeGreeting => 'Welcome';

  @override
  String welcomeGreetingUser(String name) {
    return 'Welcome, $name!';
  }

  @override
  String get homeSublineEmpty => 'Start your spiritual journey';

  @override
  String homeSublineActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You\'re doing great! $count Programs Active',
      one: 'You\'re doing great! 1 Program Active',
    );
    return '$_temp0';
  }

  @override
  String get saveNameButton => 'Save Name';

  @override
  String get savingNameButton => 'Saving…';

  @override
  String get pressBackAgainToExit => 'Press back again to exit';

  @override
  String get rewardPoints => 'Reward Points';

  @override
  String get storeButton => 'Store';

  @override
  String get dailyPractice => 'DAILY PRACTICE';

  @override
  String get startFirstGoalToday => 'Start your first goal today';

  @override
  String continueGoal(int days) {
    return 'Continue your $days-day goal';
  }

  @override
  String get quickStartPractice => 'Quick Start Practice';

  @override
  String get continuePractice => 'Continue Practice';

  @override
  String get browseMantras => 'Browse Mantras';

  @override
  String get selectFromPrograms => 'Select from your Programs';

  @override
  String get createNewProgram => 'Create a New Program';

  @override
  String get mantraSelectionTitle => 'Mantra Selection';

  @override
  String get selectMantraByNeed => 'Select mantra based on your need →';

  @override
  String get confirmSelection => 'Confirm Selection';

  @override
  String get mantraNotFound => 'Mantra not found';

  @override
  String get mantraNotFoundTitle => 'Not found';

  @override
  String startPracticeWithMantra(String name) {
    return 'Start Practice with $name Mantra';
  }

  @override
  String get pronunciationGuide => 'Pronunciation Guide';

  @override
  String get mantraForYourNeeds => 'Mantra for Your Needs';

  @override
  String get selectNeedOrProblem => 'Select your need or problem';

  @override
  String get selectDropdownHint => 'Select…';

  @override
  String get startThisPractice => 'Start This Practice';

  @override
  String recitationsTimes(int count) {
    return '$count times daily';
  }

  @override
  String get recitationsSub => 'Recitations';

  @override
  String forDays(int count) {
    return 'For $count days';
  }

  @override
  String get durationSub => 'Duration';

  @override
  String get learnMore => 'Learn More';

  @override
  String get quickStartTitle => 'Quick Start Practice';

  @override
  String get quickStartButton => 'Quick Start';

  @override
  String get globalCount => 'Global Count';

  @override
  String get liveUsers => 'Live users';

  @override
  String get changeMantra => 'Change Mantra';

  @override
  String get sessionStats => 'Session Stats';

  @override
  String get todaysCount => 'Today\'s Count';

  @override
  String get toMilestone => 'To Milestone';

  @override
  String get milestoneCompleted => 'Completed';

  @override
  String milestoneLeft(int count) {
    return '$count left';
  }

  @override
  String get practisingFor => 'Practising for ';

  @override
  String practiceDay(int days) {
    return '$days Day';
  }

  @override
  String practiceDays(int days) {
    return '$days Days';
  }

  @override
  String get startButton => 'START';

  @override
  String get noActivePrograms => 'No active programs';

  @override
  String get chooseMantra => 'Choose Mantra';

  @override
  String get selectActiveProgramDescription =>
      'Select an active program to update this dashboard.';

  @override
  String get noActivePractice => 'No active practice yet';

  @override
  String get pickMantraAndTarget =>
      'Pick a mantra and set a target to begin chanting or writing.';

  @override
  String get chooseAMantra => 'Choose a Mantra';

  @override
  String get practiceScreenTitle => 'Practice';

  @override
  String sessionSaved(int count) {
    return 'Session saved · +$count chants';
  }

  @override
  String get todaysProgress => 'Today\'s Progress';

  @override
  String get microphoneNeeded => 'Microphone needed';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get tryVoiceAgain => 'Try Voice Again';

  @override
  String get useManual => 'Use Manual';

  @override
  String get pauseButton => 'PAUSE';

  @override
  String get resumeButton => 'RESUME';

  @override
  String get finishButton => 'Finish';

  @override
  String countDisplay(String count) {
    return 'Global Mantra Count : $count';
  }

  @override
  String get yoursDisplay => 'Yours : ';

  @override
  String get ambienceSound => 'Ambience Sound';

  @override
  String get phoneMode => 'Phone Mode';

  @override
  String get ownWritingModeLabel => 'Own writing mode';

  @override
  String get everyJourneyBegins => 'Every journey begins with a single step.';

  @override
  String get totalChants => 'Total Chants';

  @override
  String get complete => 'Complete';

  @override
  String get daysPractising => 'Days Practising';

  @override
  String get programs => 'Programs';

  @override
  String get overallProgress => 'Overall Progress';

  @override
  String get createNewProgramButton => 'Create New Program';

  @override
  String get myRecitationPrograms => 'My Recitation Programs';

  @override
  String get completedPrograms => 'Completed Programs';

  @override
  String get noProgramsYet => 'No programs yet';

  @override
  String get pickMantraAndTargetToStart =>
      'Pick a mantra and set a target to start your first program.';

  @override
  String get completedWithCheck => 'Completed ✓';

  @override
  String get setYourPracticeTarget => 'Set Your Practice Target';

  @override
  String chooseDaysSpread(String count) {
    return 'Choose how many days you want to spread $count across.';
  }

  @override
  String get presetFastest => 'Fastest';

  @override
  String get presetBalanced => 'Balanced';

  @override
  String get presetGentle => 'Gentle';

  @override
  String get presetSustainable => 'Sustainable';

  @override
  String get setCustomDuration => 'Set a Custom Duration';

  @override
  String get durationLabel => 'Duration';

  @override
  String daysValue(int days) {
    return '$days days';
  }

  @override
  String thisMeansPace(String pace) {
    return 'This means $pace';
  }

  @override
  String get confirmAndBegin => 'Confirm & Begin';

  @override
  String get creatingButton => 'Creating…';

  @override
  String get choosePracticeTarget =>
      'Choose a target for your practice. You can select one of the popular targets or set your own custom one.';

  @override
  String get writingsTargetCrore => '1,00,00,000 writings';

  @override
  String get mostPopularBadge => 'Most Popular';

  @override
  String get writingsTargetMillion => '1,000,000 writings';

  @override
  String get setCustomTarget => 'Set a custom target';

  @override
  String get totalWritingsLabel => 'Total Writings';

  @override
  String get totalWritingsHint => 'e.g., 500,000';

  @override
  String get completionTimeLabel => 'Completion Time (in days)';

  @override
  String get completionTimeHint => 'e.g., 365';

  @override
  String get confirmTarget => 'Confirm Target';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get searchRewards => 'Search for rewards…';

  @override
  String get allFilter => 'All';

  @override
  String get specialOffer => 'SPECIAL OFFER';

  @override
  String get guidedMeditationSeries => 'Guided Meditation Series';

  @override
  String get unlockPeaceSeries => 'Unlock peace with our new 7-day series';

  @override
  String get redeemButton => 'Redeem';

  @override
  String get notEnoughPoints => 'Not enough';

  @override
  String get noRewardsMatch => 'No rewards match your search';

  @override
  String rewardedItemTitle(String title) {
    return 'Redeemed $title';
  }

  @override
  String get rewardPointsHistory => 'Reward Points & History';

  @override
  String get yourTotalPoints => '★ Your Total Points';

  @override
  String get visitRewardStore => 'Visit Reward Store';

  @override
  String get pointsHistory => 'Points History';

  @override
  String get noRewardActivity =>
      'No reward activity yet.\nFinish a session to earn your first points.';

  @override
  String get filterAll => 'All';

  @override
  String get filterEarned => 'Earned';

  @override
  String get filterSpent => 'Spent';

  @override
  String get profileTitle => 'Profile';

  @override
  String get editButton => 'Edit';

  @override
  String get totalChantsKpi => 'Total Chants';

  @override
  String get currentStreak => 'Current Streak';

  @override
  String get milestones => 'Milestones';

  @override
  String get rewardPointsLabel => 'REWARD POINTS';

  @override
  String get visitStore => 'Visit Store';

  @override
  String get familyCommunitySection => 'FAMILY & COMMUNITY';

  @override
  String get familyMembers => 'Family Members';

  @override
  String get inviteFriends => 'Invite Friends';

  @override
  String get practiceSettingsSection => 'PRACTICE SETTINGS';

  @override
  String get reminderTime => 'Reminder Time';

  @override
  String get notificationSound => 'Notification Sound';

  @override
  String get notificationSoundBell => 'Bell';

  @override
  String get notificationSoundConch => 'Conch';

  @override
  String get notificationSoundBowl => 'Bowl';

  @override
  String get notificationSoundChime => 'Chime';

  @override
  String get notificationSoundNone => 'None';

  @override
  String get voiceSettingsSection => 'VOICE SETTINGS';

  @override
  String get reTrainVoice => 'Re-train Voice';

  @override
  String get microphoneSensitivity => 'Microphone Sensitivity';

  @override
  String get displaySection => 'DISPLAY';

  @override
  String get languageSetting => 'Language';

  @override
  String get languagePickerTitle => 'Language';

  @override
  String get themeSetting => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get fontSizeSetting => 'Font Size';

  @override
  String get fontSizeSmall => 'Small (90%)';

  @override
  String get fontSizeDefaultPct => 'Default (100%)';

  @override
  String get fontSizeLarge => 'Large (115%)';

  @override
  String get fontSizeExtraLarge => 'Extra Large (130%)';

  @override
  String get linkSocialSection => 'LINK SOCIAL';

  @override
  String get linkFacebook => 'Link Facebook';

  @override
  String get linkWhatsApp => 'Link WhatsApp';

  @override
  String get linkInstagram => 'Link Instagram';

  @override
  String get supportPrivacySection => 'SUPPORT & PRIVACY';

  @override
  String get helpFaqs => 'Help & FAQs';

  @override
  String get reportIssue => 'Report Issue';

  @override
  String get shareFeedback => 'Share Feedback';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get downloadYourData => 'Download Your Data';

  @override
  String get aboutApp => 'About App';

  @override
  String get logoutButton => 'Logout';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get versionNumber => 'Version 0.1.0';

  @override
  String get logoutDialogTitle => 'Logout?';

  @override
  String get logoutDialogContent => 'Your local data stays on this device.';

  @override
  String get logoutDialogCancel => 'Cancel';

  @override
  String get logoutDialogConfirm => 'Logout';

  @override
  String get deleteDialogTitle => 'Delete account?';

  @override
  String get deleteDialogContent =>
      'This wipes all programs, sessions, rewards, and profiles on this device. This action cannot be undone.';

  @override
  String get deleteDialogCancel => 'Cancel';

  @override
  String get deleteDialogConfirm => 'Delete everything';

  @override
  String get infoHelpTitle => 'Help & FAQs';

  @override
  String get infoHelpBody =>
      'Common questions and how-to guides will be published here. For urgent issues, please use Report Issue.';

  @override
  String get infoReportTitle => 'Report Issue';

  @override
  String get infoReportBody =>
      'Tell us what went wrong and we will look into it. Email integration is being set up.';

  @override
  String get infoFeedbackTitle => 'Share Feedback';

  @override
  String get infoFeedbackBody =>
      'We listen to every suggestion. Let us know what feels right or what needs to change.';

  @override
  String get infoPrivacyTitle => 'Privacy Policy';

  @override
  String get infoPrivacyBody =>
      'Your practice data lives on your device until you choose to sync it. Voice and handwriting samples never leave this device in version 1.';

  @override
  String get infoAboutTitle => 'About Vaachaka Lekhini';

  @override
  String get infoAboutBody =>
      'Vaachaka Lekhini is your personal spiritual practice companion. Chant or write your chosen mantras, track your progress, and grow your discipline — together with your family.\n\nVersion 0.1.0';

  @override
  String recitationsOnDate(String date) {
    return 'Recitations on $date';
  }

  @override
  String get dailyTarget => 'Daily Target';

  @override
  String get actualAchieved => 'Actual Achieved';

  @override
  String get handwritingUsed => 'Handwriting Used';

  @override
  String get handwritingUsedYes => 'Yes';

  @override
  String get handwritingUsedNo => 'No';

  @override
  String get startPractice => 'Start Practice';

  @override
  String get dedicateProgram => 'Dedicate this program';

  @override
  String get dedicateSheetTitle => 'Dedicate this Program';

  @override
  String get dedicateOfferPractice =>
      'Offer your chanting practice to someone special';

  @override
  String dedicateOfferNamedPractice(String mantraName) {
    return 'Offer your $mantraName practice to someone special';
  }

  @override
  String get dedicatedTo => 'Dedicated to';

  @override
  String get dedicatedToHint => 'e.g. My Mother, Sri Guru, Self';

  @override
  String get intention => 'Intention (optional)';

  @override
  String get intentionHint => 'e.g. For her health and happiness…';

  @override
  String get removeDedication => 'Remove dedication';

  @override
  String get updateDedication => 'Update Dedication';

  @override
  String get saveDedication => 'Save Dedication';

  @override
  String get editGoal => 'Edit Goal';

  @override
  String get shareProgram => 'Share Program';

  @override
  String get dailyProgressTitle => 'Daily Progress';

  @override
  String communityInviteBanner(int count) {
    return 'Invite up to $count friends to your practice circle';
  }

  @override
  String get communityInviteSubline =>
      'Create a community to support each other\'s spiritual journey.';

  @override
  String get inviteFriendsButton => 'Invite Friends';

  @override
  String get streakChallenge => 'Streak Challenge';

  @override
  String get totalChantsSort => 'Total Chants';

  @override
  String get sendEncouragement => 'Send Encouragement';

  @override
  String get viewGroupStats => 'View Group Stats';

  @override
  String get youLabel => 'You';

  @override
  String get streakLabel => 'Streak';

  @override
  String get inviteFriendsTitle => 'Invite Friends';

  @override
  String get shareJourneyTitle => 'Share the journey of\nspiritual growth';

  @override
  String get inviteEarnPoints =>
      'Invite friends to join Vaachaka Lekhini and earn reward points.';

  @override
  String get inviteLinkCopied => 'Invite link copied';

  @override
  String get shareViaWhatsApp => 'Share via WhatsApp';

  @override
  String get shareViaFacebook => 'Share via Facebook';

  @override
  String get shareViaInstagram => 'Share via Instagram';

  @override
  String get allChannelsShareSheet =>
      'All channels open your device share sheet.';

  @override
  String get whoIsPracticing => 'Who is Practicing?';

  @override
  String get manageProfiles => 'Manage Profiles';

  @override
  String get loginWithAnotherNumber => 'Login with another number';

  @override
  String get createNewAccount => 'Create a new account';

  @override
  String get addMemberTile => 'Add Member';

  @override
  String get addFamilyMemberDialogTitle => 'Add Family Member';

  @override
  String get nameInputLabel => 'Name';

  @override
  String get relationshipLabel => 'Relationship';

  @override
  String get addDialogCancel => 'Cancel';

  @override
  String get addDialogConfirm => 'Add';

  @override
  String get addFamilyTitle => 'Add Family Members';

  @override
  String addFamilyDescription(int cap) {
    return 'Add up to $cap family members under your registered mobile number. Each member has their own practice counter.';
  }

  @override
  String slotsRemaining(int remaining) {
    return 'Slots remaining: $remaining';
  }

  @override
  String get existingMembersLabel => 'Existing members';

  @override
  String get registeredMobileLabel => 'Registered Mobile';

  @override
  String get familyMemberNameLabel => 'Family Member Name';

  @override
  String get familyMemberNameHint => 'e.g., Ananya Sharma';

  @override
  String get relationshipDropdownLabel => 'Relationship';

  @override
  String get savingButton => 'Saving…';

  @override
  String get saveMemberButton => 'Save Member';

  @override
  String get maxFamilyMembersReached =>
      'You have reached the maximum number of family members.';

  @override
  String get enterNameError => 'Enter a name';

  @override
  String get writeOnScreenInstruction => 'Write Inside the dots';

  @override
  String handwritingSaved(int count) {
    return 'Handwriting saved · +$count';
  }

  @override
  String get saveLabel => 'Save';

  @override
  String get clearTooltip => 'Clear';

  @override
  String get undoTooltip => 'Undo';

  @override
  String get redoTooltip => 'Redo';

  @override
  String get penColorBrown => 'Brown';

  @override
  String get penColorOrange => 'Orange';

  @override
  String get penColorTeal => 'Teal';

  @override
  String get penColorRed => 'Red';

  @override
  String get penColorBlue => 'Blue';

  @override
  String get penColorBlack => 'Black';

  @override
  String get penColorTooltip => 'Pen color';

  @override
  String get uploadHandwritingTitle => 'Upload Your Handwriting';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String get selectImageHint => 'Select an image of your handwriting';

  @override
  String get noImagesYet => 'No images yet';

  @override
  String get pickFromGallery => 'Pick from Gallery';

  @override
  String get openingButton => 'Opening…';

  @override
  String get pickMore => 'Pick more';

  @override
  String uploadSelected(int count) {
    return 'Upload Selected ($count)';
  }

  @override
  String get captureHandwritingTitle => 'Capture Your Handwriting';

  @override
  String get noCameraAvailable => 'No camera available on this device';

  @override
  String get submitHandwritingTitle => 'Submit Your Handwriting';

  @override
  String get submitHandwritingDescription =>
      'Upload your handwriting for personalised PDF mantra recitations. Our AI will randomly select samples to feature.';

  @override
  String get confirmSelectionButton => 'Confirm selection';

  @override
  String get modeWriteOnScreenLabel => 'Draw directly on your device';

  @override
  String get modeCaptureCameraLabel => 'Take a photo of your writing';

  @override
  String get modeUploadGalleryLabel => 'Select an existing image';

  @override
  String get modeDefaultFontLabel => 'Use the app\'s standard font';

  @override
  String get trainYourVoice => 'Train Your Voice';

  @override
  String get learnChantingPattern =>
      'Let me learn your unique chanting pattern for accurate counting.';

  @override
  String get sayMantraInstruction => 'Say ';

  @override
  String get sayMantraElevenTimes => ' eleven times clearly';

  @override
  String get speakNaturally => 'Speak naturally at your normal pace and volume';

  @override
  String recordingStatus(int count, int target) {
    return '● Recording  ·  $count / $target';
  }

  @override
  String get tapStartToBegin => 'Tap Start to begin';

  @override
  String get stopButton => 'Stop';

  @override
  String get startRecordingButton => 'Start Recording';

  @override
  String get skipUseManualCounter => 'Skip & Use Manual Counter';

  @override
  String get navHome => 'Home';

  @override
  String get navPrograms => 'My Programs';

  @override
  String get navPractice => 'Practice';

  @override
  String get navCommunity => 'Streak Leaderboard';

  @override
  String get navStore => 'Reward Store';

  @override
  String get seeHistory => 'See History';

  @override
  String get rewardStore => 'Reward Store';

  @override
  String get encouragementSentLabel => 'Encouragement sent! 🙏';

  @override
  String get membersLabel => 'Members';

  @override
  String get bestStreakLabel => 'Best Streak';

  @override
  String get daysLabel => 'days';

  @override
  String get closeLabel => 'Close';

  @override
  String get authErrorInvalidOtp =>
      'Wrong verification code. Please try again.';

  @override
  String get authErrorInvalidMobile =>
      'Please enter a valid 10-digit mobile number.';

  @override
  String get authErrorAccountNotFound =>
      'No account found for this number. Please create an account first.';

  @override
  String get authErrorAccountExists =>
      'An account already exists for this number. Please log in instead.';

  @override
  String get authErrorServerUnavailable =>
      'Server is unreachable. Please check your connection and try again.';

  @override
  String get authErrorNoInternet =>
      'No internet connection. Please check your network and try again.';

  @override
  String get authErrorOtpExpired =>
      'Verification code has expired. Please request a new one.';

  @override
  String get authErrorServerError =>
      'Server error. Please try again in a moment.';

  @override
  String get authErrorTooManyAttempts =>
      'Too many attempts. Please wait a moment before trying again.';

  @override
  String get authErrorUnknown => 'Something went wrong. Please try again.';

  @override
  String get authErrorEnterName => 'Please enter your name.';

  @override
  String get authErrorEnterMobileValid =>
      'Enter a valid 10-digit mobile number.';

  @override
  String get authErrorEnterOtpDigits => 'Enter the 6-digit code.';

  @override
  String get authErrorMobileIndian =>
      'Enter a valid Indian mobile number (starts with 6–9).';

  @override
  String get authErrorSameMobile =>
      'This is already your current mobile number.';

  @override
  String get authErrorEnterOtp6 =>
      'Please enter the 6-digit verification code.';

  @override
  String get nameUpdatedSuccess => 'Name updated successfully.';

  @override
  String get mobileUpdatedSuccess => 'Mobile number updated successfully.';

  @override
  String get nameEmptyError => 'Name cannot be empty.';

  @override
  String get deleteMemberTitle => 'Remove member?';

  @override
  String deleteMemberContent(String name) {
    return 'This will remove $name from your account.';
  }

  @override
  String get deleteMemberConfirm => 'Remove';

  @override
  String get changeMobileNumber => 'Change Mobile Number';

  @override
  String get numberNotRegistered => 'Number not registered';

  @override
  String get noAccountForNumber =>
      'We couldn\'t find an account for this number.';

  @override
  String get createAnAccount => 'Create an account';

  @override
  String get numberAlreadyRegistered => 'Number already registered';

  @override
  String get accountAlreadyExistsForNumber =>
      'An account already exists for this number.';

  @override
  String get logInInstead => 'Log in instead';

  @override
  String resendCodeIn(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get resendCode => 'Resend code';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get displayNameLabel => 'Display Name';

  @override
  String get displayNameHint => 'Your name';

  @override
  String get mobileNumberLabel2 => 'Mobile Number';

  @override
  String get changeMobileSheetTitle => 'Change Mobile Number';

  @override
  String get enterNewMobileHint =>
      'Enter your new mobile number. We will send a verification code to confirm.';

  @override
  String get sendingOtpButton => 'Sending…';

  @override
  String get confirmNewNumber => 'Confirm New Number';

  @override
  String get verifyingButton2 => 'Verifying…';

  @override
  String get writingStyleSection => 'Writing Style';

  @override
  String get retrainWritingStyle => 'Retrain Writing Style';

  @override
  String resendCodeCountdown(int seconds) {
    return 'Resend code in ${seconds}s';
  }
}
