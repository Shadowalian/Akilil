import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported app languages. English is the default / main language.
enum AppLanguage {
  en,
  am;

  String get code => name;

  Locale get locale => Locale(code);

  String get labelEn => this == AppLanguage.en ? 'English' : 'Amharic';

  String get labelNative => this == AppLanguage.en ? 'English' : 'አማርኛ';

  static AppLanguage fromCode(String? code) {
    if (code == 'am') return AppLanguage.am;
    return AppLanguage.en;
  }
}

const _prefsKey = 'akilil_language';

class LocaleController extends StateNotifier<AppLanguage> {
  LocaleController() : super(AppLanguage.en) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppLanguage.fromCode(prefs.getString(_prefsKey));
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (state == language) return;
    state = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, language.code);
  }

  Future<void> toggle() async {
    await setLanguage(
      state == AppLanguage.en ? AppLanguage.am : AppLanguage.en,
    );
  }
}

final localeControllerProvider =
    StateNotifierProvider<LocaleController, AppLanguage>(
  (ref) => LocaleController(),
);

/// EN/AM copy for Akilil.
///
/// Amharic is written for how people actually talk about care in Ethiopia —
/// short, warm, respectful — not a mirror of English product marketing.
class S {
  S._(this._am);
  final bool _am;

  bool get isAmharic => _am;

  /// Inline copy for one screen: `s.t('English', 'አማርኛ')`. Keeps the
  /// Amharic beside the English it replaces, so it is written for that
  /// context rather than translated word by word from a key.
  String t(String en, String am) => _am ? am : en;

  factory S.of(AppLanguage lang) => S._(lang == AppLanguage.am);

  String get appName => 'Akilil';

  // ── Dock (C03: Home · Explore · Sessions · Journal · Profile) ───────
  String get home => _am ? 'መነሻ' : 'Home';
  String get today => home;
  String get exploreNav => _am ? 'ያስሱ' : 'Explore';
  String get discover => exploreNav;
  String get sessions => _am ? 'ቀጠሮዎች' : 'Sessions';
  String get journal => _am ? 'ማስታወሻ' : 'Journal';
  String get you => _am ? 'መገለጫ' : 'Profile';

  // ── Welcome / auth (C01) ────────────────────────────────────────────
  String get welcomeBack => _am ? 'እንኳን ደህና ተመለሱ' : 'Welcome back';
  String get signInToAkilil => _am ? 'ወደ አኪሊል ይግቡ' : 'Sign In To Akilil';
  String get welcomeToAkilil =>
      _am ? 'ወደ አኪሊል እንኳን ደህና መጡ' : 'Welcome to Akilil care';
  String get welcomeHeadline => _am
      ? 'በእውነት የሚረዳዎትን ሰው ያናግሩ።'
      : 'Talk to someone who actually gets it.';
  String get welcomeSubtitle => _am
      ? 'የሥነ-ልቦና ባለሙያዎች፣ የእምነት አማካሪዎችና ሼፎች — እውነተኛ ሰዎች፣ እርስዎ ሲዘጋጁ።'
      : 'Therapists, faith guides and chefs — real people, ready when you are.';
  String get welcomeVerifiedLine => _am
      ? 'እያንዳንዱ ባለሙያ በቡድናችን ተረጋግጧል። የሚያናግርዎ ሰው ነው፣ ማሽን አይደለም።'
      : 'Every professional is hand-verified. No bots, ever.';
  String get welcomeVerifiedBold =>
      _am ? 'እያንዳንዱ ባለሙያ በቡድናችን ተረጋግጧል።' : 'Every professional is hand-verified.';
  String get welcomeVerifiedRest => _am ? 'የሚያናግርዎ ሰው ነው፣ ማሽን አይደለም።' : 'No bots, ever.';
  String get getStarted => _am ? 'እንጀምር' : 'Get started';
  String get alreadyHaveAccount =>
      _am ? 'አካውንት አለዎት? ' : 'Already have an account? ';
  String get alreadyHaveAccountLink =>
      _am ? 'አካውንት አለኝ' : 'I already have an account';
  String get trustPrivate => _am ? 'ምስጢርዎ የተጠበቀ ነው' : 'Private by design';
  String get trustLicensed => _am ? 'ፈቃድ ያላቸው ባለሙያዎች' : 'Licensed pros';
  String get trustPayEtb => _am ? 'በብር ይክፈሉ' : 'Pay in ETB';
  String get signIn => _am ? 'ይግቡ' : 'Sign in';
  String get takeABreath =>
      _am ? 'በረጅሙ ይተንፍሱ። ከጎንዎ ነን።' : 'Take a breath. We’re here.';
  String get careTagline =>
      _am ? 'አእምሮዎ የሚያርፍበት ቦታ።' : 'Care for your mind. One quiet place.';
  String get email => _am ? 'ኢሜይል' : 'Email';
  String get password => _am ? 'የይለፍ ቃል' : 'Password';
  String get continueLabel => _am ? 'ይቀጥሉ' : 'Continue';
  String get logIn => _am ? 'ይግቡ' : 'Log in';
  String get newHereCreate =>
      _am ? 'አዲስ ነዎት? ይመዝገቡ' : 'New here? Create';
  String get logOut => _am ? 'ይውጡ' : 'Log out';
  String hiName(String name) => _am ? 'ሰላም $name' : 'Hi, $name';
  String get forgotPassword =>
      _am ? 'የይለፍ ቃልዎን ረስተዋል?' : 'Forgot Password';
  String get dontHaveAccount =>
      _am ? 'አካውንት የለዎትም? ' : "Don't have an account? ";
  String get signUp => _am ? 'ይመዝገቡ' : 'Sign Up';

  // ── Onboarding — choose support (C02) ─────────────────────────────
  String get chooseSupportTitle => _am
      ? 'ምን ዓይነት ድጋፍ\nይፈልጋሉ?'
      : 'What kind of support\nare you looking for?';
  String get chooseSupportSub => _am
      ? 'አንድ ወይም ከዚያ በላይ ይምረጡ። በኋላ መቀየር ይችላሉ።'
      : 'Pick one or more. You can change this anytime.';
  String get skip => _am ? 'ይዝለሉ' : 'Skip';
  String continueWithSelected(int n) {
    if (n < 1) {
      return _am ? 'አንድ ይምረጡ' : 'Continue with selected';
    }
    if (_am) return '$n ተመርጠዋል — ይቀጥሉ';
    if (n == 1) return 'Continue with 1 selected';
    return 'Continue with $n selected';
  }

  String get spiritualCareDesc => _am
      ? 'ለኦርቶዶክስ፣ ለሙስሊም፣ ለፕሮቴስታንትና ለካቶሊክ ምእመናን — እምነትዎን የሚያከብሩ አማካሪዎች።'
      : 'Faith guides for Orthodox, Muslim, Protestant, and Catholic traditions.';
  String get chefSessionsDesc => _am
      ? 'ከሼፎች ጋር በቀጥታ አብረው ያብስሉ — የቤት ውስጥና የዕለት ተዕለት ምግቦች።'
      : 'Cook along live with chefs teaching comfort food and everyday meals.';
  String get psychiatryTherapyDesc => _am
      ? 'ፈቃድ ያላቸው የአእምሮ ጤና ሐኪሞችና የሥነ-ልቦና ባለሙያዎች።'
      : 'Licensed psychiatrists and therapists for clinical support.';
  String get guidesBadge => _am ? 'እምነትን የሚያከብሩ' : 'FAITH-AWARE';
  String get chefsBadge => _am ? 'በቀጥታ' : 'LIVE CLASSES';
  String get cliniciansBadge => _am ? 'ፈቃድ ያላቸው' : 'LICENSED';

  // ── Profile groups ──────────────────────────────────────────────────
  String get account => _am ? 'መለያዬ' : 'Account';
  String get wellness => _am ? 'ጤንነቴ' : 'Wellness';
  String get preferences => _am ? 'ምርጫዎቼ' : 'Preferences';
  String get language => _am ? 'ቋንቋ' : 'Language';
  String get twoFactor =>
      _am ? 'ባለሁለት ደረጃ መግቢያ' : 'Two-factor authentication';
  String get enabled => _am ? 'በርቷል' : 'Enabled';
  String get recommended => _am ? 'ይመከራል' : 'Recommended';
  String get wallet => _am ? 'ሂሳቤ' : 'Wallet';
  String get walletSubtitle =>
      _am ? 'ቀሪ ሂሳብና የቀጠሮ ክፍያዎች' : 'Balance and session payments';
  String get goalsHabits => _am ? 'ግቦችና ልማዶች' : 'Goals & habits';
  String get community => _am ? 'ማኅበረሰብ' : 'Community';
  String get notifications => _am ? 'ማሳወቂያዎች' : 'Notifications';
  String get privacyData => _am ? 'ግላዊነት' : 'Privacy & data';
  String get profile => you;

  // ── Pillars — names people would actually say ───────────────────────
  String get spiritualPsychiatry =>
      _am ? 'መንፈሳዊ ምክር' : 'Spiritual care';
  String get spiritualPsychiatrySub => _am
      ? 'በእምነትዎ ላይ የተመሠረተ ምክርና ድጋፍ።'
      : 'Guidance rooted in your faith.';
  String get psychiatry =>
      _am ? 'የአእምሮ ጤና ሕክምና' : 'Psychiatry & therapy';
  String get psychiatrySub => _am
      ? 'ፈቃድ ያላቸው የአእምሮ ጤና ሐኪሞችና የሥነ-ልቦና ባለሙያዎች።'
      : 'Licensed psychiatrists and therapists.';
  String get cooking => _am ? 'ከሼፍ ጋር ማብሰል' : 'Chef sessions';
  String get cookingSub => _am
      ? 'ከእውነተኛ ሼፎች ጋር አብረው ያብስሉ። ቀስ ብለው፣ በደንብ ይመገቡ።'
      : 'Cook along with real chefs. Slow down, eat well.';

  String get therapyLabel => _am ? 'የአእምሮ ጤና ሕክምና' : 'Therapy';
  String get chefSessionsLabel => cooking;
  String get spiritualCareLabel => spiritualPsychiatry;

  String get explore => _am ? 'ይመልከቱ' : 'Explore';
  String get more => _am ? 'ተጨማሪ' : 'More';
  String get upNext => _am ? 'ቀጣዩ ቀጠሮ' : 'Up next';
  String get checkIn => _am ? 'ስሜትዎን ይመዝግቡ' : 'Check in';
  String get choosePath => _am ? 'የትኛውን ድጋፍ ይፈልጋሉ?' : 'Choose your path';
  String get allPillars => _am
      ? 'መንፈሳዊ ምክር · የአእምሮ ጤና · ማብሰል'
      : 'Spiritual Psychiatry · Psychiatry · Cooking';
  String get filters => _am ? 'ማጣሪያ' : 'Filters';
  String get noMatches =>
      _am ? 'በዚህ ዘርፍ እስካሁን የሚስማማ ባለሙያ የለም' : 'No matches in this path yet';
  String get tryAnotherPillar => _am
      ? 'ሌላ ዘርፍ ይሞክሩ፣ ወይም ማጣሪያውን ያስፉ።'
      : 'Try another Akilil pillar or widen filters.';
  String get adjustFilters => _am ? 'ማጣሪያውን ይቀይሩ' : 'Adjust filters';
  String get couldntLoadPros =>
      _am ? 'ባለሙያዎችን ማሳየት አልተቻለም' : "Couldn't load professionals";
  String get checkConnection => _am
      ? 'ኔትዎን ይመልከቱ፣ ከዚያ እንደገና ይሞክሩ።'
      : 'Check your connection and try again.';
  String get retry => _am ? 'እንደገና ይሞክሩ' : 'Retry';

  // ── Explore — C04 / C05 / C06 ───────────────────────────────────────
  String get chipAll => _am ? 'ሁሉም' : 'All';
  String get guidesForYou => _am ? 'ለእርስዎ የሚስማሙ አማካሪዎች' : 'Guides for you';
  String get chefsForYou => _am ? 'ለእርስዎ ሼፎች' : 'Chefs for you';
  String get cliniciansForYou =>
      _am ? 'ለእርስዎ ባለሙያዎች' : 'Clinicians for you';
  String get sortedByMatch => _am ? 'በተስማሚነት የተደረደሩ' : 'Sorted by match';
  String get liveNow => _am ? 'አሁን በቀጥታ' : 'Live now';
  String get free => _am ? 'ነጻ' : 'Free';
  String get faithOrthodox => _am ? 'ኦርቶዶክስ' : 'Orthodox';
  String get faithMuslim => _am ? 'ሙስሊም' : 'Muslim';
  String get faithProtestant => _am ? 'ፕሮቴስታንት' : 'Protestant';
  String get faithCatholic => _am ? 'ካቶሊክ' : 'Catholic';
  String get chipPsychiatrists => _am ? 'የአእምሮ ሐኪሞች' : 'Psychiatrists';
  String get chipPsychologists => _am ? 'የሥነ-ልቦና ባለሙያዎች' : 'Psychologists';
  String get chipCounselors => _am ? 'አማካሪዎች' : 'Counselors';
  String priceEtb(int amount) => _am ? '$amount ብር' : '$amount ETB';

  String prosSectionTitle(String slug) {
    switch (slug) {
      case 'spiritual-psychiatry':
        return guidesForYou;
      case 'cooking':
        return chefsForYou;
      case 'psychiatry':
        return cliniciansForYou;
      default:
        return guidesForYou;
    }
  }

  String discoverHeroAsset(String slug) {
    switch (slug) {
      case 'spiritual-psychiatry':
        return 'assets/figma/c04_hero.jpg';
      case 'cooking':
        return 'assets/figma/c05_hero.jpg';
      case 'psychiatry':
        return 'assets/figma/c06_hero.jpg';
      default:
        return 'assets/figma/c04_hero.jpg';
    }
  }
  String get circlesVents => _am ? 'የውይይት ቡድኖችና የልብ ማውጫ' : 'Circles & vents';
  String get privateNotes => _am ? 'ለእርስዎ ብቻ' : 'Private notes';
  String get balanceTopUps => _am ? 'ቀሪ ሂሳብና ገንዘብ መሙያ' : 'Balance & top-ups';
  String get threePaths => _am ? 'ሦስት መንገዶች' : '3 Akilil paths';
  String get takeBreathReady => _am
      ? 'በረጅሙ ይተንፍሱ። ሲዘጋጁ የሚያናግርዎ ሰው አለ።'
      : 'Take a breath. Someone is here when you are ready.';

  String get validEmail =>
      _am ? 'ትክክለኛ ኢሜይል ያስገቡ' : 'Enter a valid email';
  String get minPassword =>
      _am ? 'ቢያንስ 8 ፊደላት' : 'At least 8 characters';
  String get loginFailed =>
      _am ? 'መግባት አልተቻለም። እንደገና ይሞክሩ።' : 'Login failed. Please try again.';
  String get cantReach => _am
      ? 'ከአኪሊል ጋር መገናኘት አልተቻለም። ኢንተርኔትዎን ያረጋግጡ።'
      : "Can't reach Akilil servers. Check your connection.";

  // ── Today — write what people say, not English UI calques ───────────
  String get searchHint =>
      _am ? 'ማንን ማናገር ይፈልጋሉ?' : 'Search listeners, sessions…';
  String get yourPaths => _am ? 'መንገዶችዎ' : 'Your paths';
  String get mindfulTracker => _am ? 'የራስዎ መከታተያ' : 'Mindful Tracker';
  String get journalSubtitle =>
      _am ? 'ዛሬ የተሰማዎትን ይጻፉ' : 'Write down what today felt like';
  String get moodSubtitle =>
      _am ? 'አሁን እንዴት ነዎት?' : 'Log how you are feeling right now';
  String get sessionsSubtitle =>
      _am ? 'ቀጠሮዎችዎና ያለፉ ክፍለ ጊዜዎች' : 'Your bookings and past sessions';
  String get quickActions => _am ? 'ፈጣን አገልግሎቶች' : 'Quick actions';
  String get worksheets => _am ? 'ልምምዶች' : 'Worksheets';
  String get assess => _am ? 'ራስን መመዘኛ' : 'Assess';
  String get groups => _am ? 'ቡድኖች' : 'Groups';
  String get crisis => _am ? 'የአስቸኳይ ጊዜ እርዳታ' : 'Crisis';
  String get mood => _am ? 'ስሜት' : 'Mood';
  String get boxBreathingSubtitle =>
      _am ? 'በአራት እየቆጠሩ ቀስ ብለው ይተንፍሱ' : '4-4-4-4 calming breath exercise';
  String get clinicalTools => _am ? 'ራስን መርጃዎች' : 'Clinical tools';
  String get assessmentCheckIn =>
      _am ? 'የጭንቀትና የድባቴ መመዘኛ' : 'PHQ-9 & GAD-7 Check-in';
  String get assessmentSubtitle =>
      _am ? 'ጭንቀትና ድባቴዎን በጊዜ ሂደት ይከታተሉ' : 'Track anxiety and depression levels';
  String get boxBreathing => _am ? 'የመረጋጋት ትንፋሽ' : 'Box breathing';
  String get safetyPlan => _am ? 'የደህንነት እቅዴ' : 'Safety plan';
  String get safetyPlanSubtitle =>
      _am ? 'ከባድ ጊዜ ሲመጣ የሚከተሉት የራስዎ እቅድ' : 'Your personalised crisis plan';
  String get topListeners => _am ? 'ለእርስዎ የሚመከሩ' : 'Top listeners';
  String get seeAll => _am ? 'ሁሉንም ይመልከቱ' : 'See all';
  String get exploreSupport =>
      _am ? 'ድጋፍ ይፈልጉ' : 'Explore support';
  String get howAreYouFeeling =>
      _am ? 'አሁን እንዴት ነዎት?' : 'How are you feeling?';
  String get moodAwful => _am ? 'በጣም ከፍቶኛል' : 'Awful';
  String get moodLow => _am ? 'ደብሮኛል' : 'Low';
  String get moodOkay => _am ? 'ደህና ነኝ' : 'Okay';
  String get moodGood => _am ? 'ጥሩ ነኝ' : 'Good';
  String get moodGreat => _am ? 'በጣም ደስ ብሎኛል' : 'Great';
  String get reschedule => _am ? 'ቀጠሮ ያሸጋግሩ' : 'Reschedule';
  String get join => _am ? 'ይቀላቀሉ' : 'Join';
  String get videoTherapy => _am ? 'የቪዲዮ ቀጠሮ' : 'Video therapy';
  String startsIn(int hours, int minutes) {
    if (_am) {
      if (hours > 0) {
        return 'ከ$hours ሰዓት ከ$minutes ደቂቃ በኋላ ይጀምራል';
      }
      return 'ከ$minutes ደቂቃ በኋላ ይጀምራል';
    }
    if (hours > 0) return 'Starts in ${hours}h ${minutes}m';
    return 'Starts in ${minutes}m';
  }

  String dayStreak(int days) =>
      _am ? 'ለ$days ቀናት በተከታታይ' : '$days-day streak';

  String greetingTime() {
    final h = DateTime.now().hour;
    if (_am) {
      if (h < 12) return 'እንደምን አደሩ';
      if (h < 17) return 'እንደምን ዋሉ';
      return 'እንደምን አመሹ';
    }
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String greetingWithName(String firstName) => '${greetingTime()}, $firstName';

  String moodLabel(int index) {
    switch (index) {
      case 0:
        return moodAwful;
      case 1:
        return moodLow;
      case 2:
        return moodOkay;
      case 3:
        return moodGood;
      case 4:
        return moodGreat;
      default:
        return moodOkay;
    }
  }

  String professionalsAvailable(int count) => _am
      ? '$count ባለሙያዎች'
      : count == 1 ? '1 professional' : '$count professionals';
  String get noListenersYet =>
      _am ? 'በዚህ ዘርፍ እስካሁን ባለሙያ የለም።' : 'No listeners in this path yet.';
  String get sessionReady =>
      _am ? 'ክፍሉ ዝግጁ ነው።' : 'Session room is ready.';
  String scheduledInMins(int mins) => _am
      ? 'ከ$mins ደቂቃ በኋላ ይጀምራል · ክፍሉ ዝግጁ ነው።'
      : 'Starts in $mins min · your room is ready.';
  String minutesShort(int n) => _am ? '$n ደቂቃ' : '$n min';
  String get joinSession => _am ? 'ክፍለ ጊዜውን ይቀላቀሉ' : 'Join session';
  String get joinVideoSession =>
      _am ? 'ወደ ቪዲዮ ይግቡ' : 'Join video session';
  String get setup => _am ? 'ማዘጋጃ' : 'Setup';
  String get noSessionBooked =>
      _am ? 'ገና ቀጠሮ አልያዙም' : 'No session booked';
  String get findListenerPrompt => _am
      ? 'የሚስማማዎትን ባለሙያ ይምረጡ፤ ሲዘጋጁ በግል በቪዲዮ ይነጋገሩ።'
      : 'Find a listener and book a private video session when you are ready.';
  String get findAListener => _am ? 'ባለሙያ ይፈልጉ' : 'Find a listener';
  String get verifiedListener => _am ? 'የተረጋገጠ ባለሙያ' : 'Verified listener';
  String fromRate(String rate) => _am ? 'ከ $rate' : 'From $rate';
  String get book => _am ? 'ቀጠሮ ይያዙ' : 'Book';
  String get listenerFallback => _am ? 'ባለሙያ' : 'Listener';
  String perSession(String amount) =>
      _am ? 'በአንድ ቀጠሮ $amount' : '$amount/session';

  // ── Professional profile & booking (C07 / C08) ─────────────────────
  String get licenseVerified =>
      _am ? 'ፈቃድ ተረጋግጧል' : 'License verified';
  String get nextAvailable =>
      _am ? 'ቀጣይ ክፍት ጊዜ' : 'Next available';
  String get bookSession =>
      _am ? 'ቀጠሮ ይያዙ' : 'Book session';
  String perFiftyMinSession(int minutes) => _am
      ? 'ለ$minutes ደቂቃ ቀጠሮ'
      : 'per $minutes-min session';
  String get bookASession =>
      _am ? 'ቀጠሮ ይያዙ' : 'Book a session';
  String get availableTimesEat => _am
      ? 'ክፍት ሰዓቶች · በፈረንጅ አቆጣጠር (EAT)'
      : 'Available times · East Africa Time';
  String confirmAndPay(int amount) => _am
      ? 'አረጋግጥ እና $amount ብር ይክፈሉ'
      : 'Confirm and pay $amount ETB';
  String get serviceFee => _am ? 'የአገልግሎት ክፍያ' : 'Service fee';
  String get akililWallet => _am ? 'የአኪሊል ሂሳብዎ' : 'Akilil wallet';
  String get changePayment => _am ? 'ይቀይሩ' : 'Change';
  String get statReviews => _am ? 'ግምገማዎች' : 'reviews';
  String get statSessions => _am ? 'ክፍለ ጊዜዎች' : 'sessions';
  String get statExperience => _am ? 'የሥራ ልምድ' : 'experience';
  String yrsExperience(int years) =>
      _am ? '$years ዓመት' : '$years yrs';
  String get modeChat => _am ? 'በጽሑፍ' : 'Chat';
  String get modeVoice => _am ? 'በድምፅ' : 'Voice';
  String get modeVideo => _am ? 'በቪዲዮ' : 'Video';
  String get total => _am ? 'ጠቅላላ' : 'Total';
  String get unavailable => _am ? 'አይገኝም' : 'Unavailable';
  String get shareProfile => _am ? 'ያጋሩ' : 'Share';
  String get saveProfile => _am ? 'ያስቀምጡ' : 'Save';
  String get aboutMe => _am ? 'ስለ እኔ' : 'About me';
  String get specialtiesTopics =>
      _am ? 'የሚሰሩባቸው ዘርፎች' : 'Specialties & topics';
  String get cityFallback => _am ? 'አዲስ አበባ' : 'Addis Ababa';
  String get sessionSummary => _am ? 'ማጠቃለያ' : 'Summary';
  String get walletBalance => _am ? 'ቀሪ ሂሳብ' : 'Balance';

  // ── Journal (C10) ───────────────────────────────────────────────────
  String get journalScreenTitle => journal;
  String get newJournalEntry => _am ? 'አዲስ ማስታወሻ' : 'New entry';
  String get thisWeek => _am ? 'በዚህ ሳምንት' : 'This week';
  String get tonightsPrompt => _am ? 'የዛሬ ምሽት ጥያቄ' : "Tonight's prompt";
  String get journalDefaultPrompt => _am
      ? 'ካለፈው ሳምንት በተሻለ መንገድ የያዙት አንድ ነገር ምንድን ነው?'
      : "What's one thing you handled better than last week?";
  String get recent => _am ? 'የቅርብ ጊዜ' : 'Recent';
  String get journalMoodSummary =>
      _am ? 'በአብዛኛው ጥሩ' : 'Mostly good';
  String get journalMoodSteady => _am ? 'የተረጋጋ' : 'Steady';
  String get journalMoodMixed => _am ? 'ተቀላቅሏል' : 'Mixed';
  String get journalMoodTough => _am ? 'ከባድ ሳምንት' : 'Tough week';
  String moodWeekTrend(int percent) => _am
      ? 'ካለፈው ሳምንት ጋር ሲነጻጸር $percent%'
      : '$percent% vs last week';
  String sharedWith(String name) =>
      _am ? 'ለ$name ተጋርቷል' : 'Shared with $name';
  String get sharedWithCareTeam =>
      _am ? 'ለሚያክምዎ ቡድን ተጋርቷል' : 'Shared with your care team';
  String get journalLoadError =>
      _am ? 'ማስታወሻዎን መክፈት አልተቻለም' : "Couldn't load journal";
  String get journalEmptyTitle =>
      _am ? 'የመጀመሪያ ማስታወሻዎን ይጻፉ' : 'Start your private journal';
  String get journalEmptyMessage =>
      _am ? 'ለእርስዎ ብቻ የሚታይ፤ በምስጢር ይቀመጣል።' : 'Just for you. Encrypted at rest.';

  // ── Wallet (C11) ──────────────────────────────────────────────────
  String get availableBalance =>
      _am ? 'ያለዎት ቀሪ ሂሳብ' : 'Available balance';
  String get topUp => _am ? 'ገንዘብ ይሙሉ' : 'Top up';
  String get activity => _am ? 'የገንዘብ እንቅስቃሴ' : 'Activity';
  String get walletLoadError => _am
      ? 'ቀሪ ሂሳብዎን ማሳየት አልተቻለም'
      : "Couldn't load your balance.";
  String get noActivityYet => _am ? 'እንቅስቃሴ የለም' : 'No activity yet';
  String get noActivityMessage => _am
      ? 'ገንዘብ ሲሞሉና ሲከፍሉ እዚህ ይታያል።'
      : 'Top-ups and session payments show up here.';
  String get couldntLoadTransactions => _am
      ? 'ግብይቶችን ማሳየት አልተቻለም'
      : "Couldn't load transactions";
  String topUpAmount(String amount) =>
      _am ? '$amount ይሙሉ' : 'Top up $amount';
  String get processingTopUp => _am ? 'በሂደት ላይ…' : 'Processing…';

  // ── Safety (C12) ────────────────────────────────────────────────────
  String get safetyTitle => _am ? 'ደህንነት' : 'Safety';
  String get notAlone =>
      _am ? 'ብቻዎን አይደሉም።' : "You're not alone.";
  String get someoneCanTalkNow => _am
      ? 'አሁን የሚያናግርዎ ሰው አለ።'
      : 'Someone can talk with you right now.';
  String get talkToListenerNow =>
      _am ? 'አሁን የሚያናግርዎ ሰው ያግኙ' : 'Talk to a listener now';
  String get listenersAvailableFree =>
      _am ? 'ዛሬ የሚያነጋግርዎ ሰው ያግኙ' : 'Find someone to talk to today';
  String get emergencyServices =>
      _am ? 'የአስቸኳይ ጊዜ አገልግሎት' : 'Emergency services';
  String get localEmergencyNumber => _am ? '991' : '991';
  String get call => _am ? 'ይደውሉ' : 'Call';
  String get trustedContact => _am ? 'የሚያምኑት ሰው' : 'Trusted contact';
  String get breatheWithMe =>
      _am ? 'አብረን እንተንፍስ' : 'Breathe with me';
  String get guidedGrounding => _am
      ? 'የ2 ደቂቃ የመረጋጋት ልምምድ'
      : '2-minute guided grounding';
  String get mySafetyPlan => safetyPlan;
  String safetyPlanStepsComplete(int done, int total) => _am
      ? 'ከ$total ደረጃዎች $done ተሞልተዋል'
      : '$done of $total steps complete';
  String get verifiedCrisisLifelines => _am
      ? 'የአስቸኳይ ጊዜ ቁጥሮች'
      : 'Emergency numbers';

  String pillarName(String slug) {
    switch (slug) {
      case 'spiritual-psychiatry':
        return spiritualPsychiatry;
      case 'psychiatry':
        return psychiatry;
      case 'cooking':
        return cooking;
      default:
        return slug;
    }
  }

  String pillarSubtitle(String slug) {
    switch (slug) {
      case 'spiritual-psychiatry':
        return spiritualPsychiatrySub;
      case 'psychiatry':
        return psychiatrySub;
      case 'cooking':
        return cookingSub;
      default:
        return '';
    }
  }
}

final stringsProvider = Provider<S>((ref) {
  return S.of(ref.watch(localeControllerProvider));
});
