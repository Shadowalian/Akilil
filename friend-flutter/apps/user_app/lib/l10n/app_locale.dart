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

  factory S.of(AppLanguage lang) => S._(lang == AppLanguage.am);

  String get appName => 'Akilil';

  // ── Dock (C03: Home · Explore · Sessions · Journal · Profile) ───────
  String get home => _am ? 'መነሻ' : 'Home';
  String get today => home;
  String get exploreNav => _am ? 'አስስ' : 'Explore';
  String get discover => exploreNav;
  String get sessions => _am ? 'ቀጠሮ' : 'Sessions';
  String get journal => _am ? 'ማስታወሻ' : 'Journal';
  String get you => _am ? 'መገለጫ' : 'Profile';

  // ── Welcome / auth (C01) ────────────────────────────────────────────
  String get welcomeBack => _am ? 'እንኳን ደህና መጡ' : 'Welcome back';
  String get signInToAkilil => _am ? 'አኪሊል ይግቡ' : 'Sign In To Akilil';
  String get welcomeToAkilil =>
      _am ? 'አኪሊል እንኳን በደህና መጡ' : 'Welcome to Akilil care';
  String get welcomeHeadline => _am
      ? 'የሚረዳዎትን ሰው ያግኙ።'
      : 'Talk to someone who actually gets it.';
  String get welcomeSubtitle => _am
      ? 'ባለሙያ አማካሪዎች፣ የእምነት መሪዎችና ሼፎች — እውነተኛ ሰዎች፣ ሲፈልጉ።'
      : 'Therapists, faith guides and chefs — real people, ready when you are.';
  String get welcomeVerifiedLine => _am
      ? 'እያንዳንዱ ባለሙያ በእጅ ተረጋግጧል። ቦት የለም።'
      : 'Every professional is hand-verified. No bots, ever.';
  String get welcomeVerifiedBold =>
      _am ? 'እያንዳንዱ ባለሙያ በእጅ ተረጋግጧል።' : 'Every professional is hand-verified.';
  String get welcomeVerifiedRest => _am ? 'ቦት የለም።' : 'No bots, ever.';
  String get getStarted => _am ? 'እንጀምር' : 'Get started';
  String get alreadyHaveAccount =>
      _am ? 'አካውንት አለዎት? ' : 'Already have an account? ';
  String get alreadyHaveAccountLink =>
      _am ? 'አካውንት አለኝ' : 'I already have an account';
  String get trustPrivate => _am ? 'በግል የተጠበቀ' : 'Private by design';
  String get trustLicensed => _am ? 'ፈቃድ ያላቸው' : 'Licensed pros';
  String get trustPayEtb => _am ? 'በብር ይክፈሉ' : 'Pay in ETB';
  String get signIn => _am ? 'ግባ' : 'Sign in';
  String get takeABreath =>
      _am ? 'ቀስ ብለው ይተንፉ። ከጎንዎ ነን።' : 'Take a breath. We’re here.';
  String get careTagline =>
      _am ? 'አእምሮዎ የሚያርፍበት ቦታ።' : 'Care for your mind. One quiet place.';
  String get email => _am ? 'ኢሜይል' : 'Email';
  String get password => _am ? 'የይለፍ ቃል' : 'Password';
  String get continueLabel => _am ? 'ቀጥል' : 'Continue';
  String get logIn => _am ? 'ግባ' : 'Log in';
  String get newHereCreate =>
      _am ? 'አዲስ ነዎት? ይመዝገቡ' : 'New here? Create';
  String get logOut => _am ? 'ውጣ' : 'Log out';
  String hiName(String name) => _am ? 'ሰላም $name' : 'Hi, $name';
  String get forgotPassword =>
      _am ? 'የይለፍ ቃል ረሱ?' : 'Forgot Password';
  String get dontHaveAccount =>
      _am ? 'አካውንት የለዎትም? ' : "Don't have an account? ";
  String get signUp => _am ? 'ይመዝገቡ' : 'Sign Up';

  // ── Onboarding — choose support (C02) ─────────────────────────────
  String get chooseSupportTitle => _am
      ? 'ምን ዓይነት እንክብካቤ\nይፈልጋሉ?'
      : 'What kind of support\nare you looking for?';
  String get chooseSupportSub => _am
      ? 'አንድ ወይም ተጨማሪ ይምረጡ። በኋላ ማለት ይችላሉ።'
      : 'Pick one or more. You can change this anytime.';
  String get skip => _am ? 'ይዝለሉ' : 'Skip';
  String continueWithSelected(int n) {
    if (n < 1) {
      return _am ? 'አንድ ይምረጡ' : 'Continue with selected';
    }
    if (_am) return 'ከ $n የተመረጡ ጋር ይቀጥሉ';
    if (n == 1) return 'Continue with 1 selected';
    return 'Continue with $n selected';
  }

  String get spiritualCareDesc => _am
      ? 'ለኦርቶዶክስ፣ ሙስሊም፣ ፕሮቴስታንትና ካቶሊክ — እምነትን የሚያክብሩ መሪዎች።'
      : 'Faith guides for Orthodox, Muslim, Protestant, and Catholic traditions.';
  String get chefSessionsDesc => _am
      ? 'ከሼፎች ጋር በቀጥታ ይታኩ — ምግብ እና የቤት ክፍሎች።'
      : 'Cook along live with chefs teaching comfort food and everyday meals.';
  String get psychiatryTherapyDesc => _am
      ? 'ፈቃድ ያላቸው ሐኪሞችና አማካሪዎች ለባለሙያ እንክብካቤ።'
      : 'Licensed psychiatrists and therapists for clinical support.';
  String get guidesBadge => _am ? '42 መሪዎች' : '42 GUIDES';
  String get chefsBadge => _am ? '18 ሼፎች' : '18 CHEFS';
  String get cliniciansBadge => _am ? '96 ባለሙያዎች' : '96 CLINICIANS';

  // ── Profile groups ──────────────────────────────────────────────────
  String get account => _am ? 'መለያዬ' : 'Account';
  String get wellness => _am ? 'እንክብካቤዬ' : 'Wellness';
  String get preferences => _am ? 'ምርጫዎቼ' : 'Preferences';
  String get language => _am ? 'ቋንቋ' : 'Language';
  String get twoFactor =>
      _am ? 'ተጨማሪ ጥበቃ' : 'Two-factor authentication';
  String get enabled => _am ? 'በርቷል' : 'Enabled';
  String get recommended => _am ? 'ይመከራል' : 'Recommended';
  String get wallet => _am ? 'ክፍያዬ' : 'Wallet';
  String get walletSubtitle =>
      _am ? 'ቀሪ ገንዘብና የቀጠሮ ክፍያ' : 'Balance and session payments';
  String get goalsHabits => _am ? 'ግቦቼ' : 'Goals & habits';
  String get community => _am ? 'ከሌሎች ጋር' : 'Community';
  String get notifications => _am ? 'ማሳወቂያ' : 'Notifications';
  String get comingSoon => _am ? 'በቅርቡ' : 'Coming soon';
  String get privacyData => _am ? 'ግላዊነት' : 'Privacy & data';
  String get exportDelete =>
      _am ? 'መረጃ ማውረድ ወይም ማጥፋት' : 'Export and delete';
  String get profile => you;

  // ── Pillars — names people would actually say ───────────────────────
  String get spiritualPsychiatry =>
      _am ? 'በእምነት እንክብካቤ' : 'Spiritual care';
  String get spiritualPsychiatrySub => _am
      ? 'በእምነትዎ ላይ የተመሠረተ መምሪያ።'
      : 'Guidance rooted in your faith.';
  String get psychiatry =>
      _am ? 'የባለሙያ እንክብካቤ' : 'Psychiatry & therapy';
  String get psychiatrySub => _am
      ? 'ፈቃድ ያላቸው ሐኪሞችና አማካሪዎች።'
      : 'Licensed psychiatrists and therapists.';
  String get cooking => _am ? 'የሼፍ ትምህርት' : 'Chef sessions';
  String get cookingSub => _am
      ? 'ከእውነተኛ ሼፎች ጋር ይታኩ። ዝግ ብለው፣ በደንብ ይብሉ።'
      : 'Cook along with real chefs. Slow down, eat well.';

  String get therapyLabel => _am ? 'የባለሙያ እንክብካቤ' : 'Therapy';
  String get chefSessionsLabel => cooking;
  String get spiritualCareLabel => spiritualPsychiatry;

  String get explore => _am ? 'ይመልከቱ' : 'Explore';
  String get more => _am ? 'ተጨማሪ' : 'More';
  String get upNext => _am ? 'ቀጣይ ቀጠሮ' : 'Up next';
  String get checkIn => _am ? 'ግባ' : 'Check in';
  String get choosePath => _am ? 'የት መሄድ ይፈልጋሉ?' : 'Choose your path';
  String get allPillars => _am
      ? 'እምነት · ባለሙያ · ማብሰል'
      : 'Spiritual Psychiatry · Psychiatry · Cooking';
  String get filters => _am ? 'አጣራ' : 'Filters';
  String get noMatches =>
      _am ? 'በዚህ መንገድ እስካሁን ማንም የለም' : 'No matches in this path yet';
  String get tryAnotherPillar => _am
      ? 'ሌላ መንገድ ይሞክሩ፣ ወይም አጣራውን ያስፋፉ።'
      : 'Try another Akilil pillar or widen filters.';
  String get adjustFilters => _am ? 'አጣራውን ይቀይሩ' : 'Adjust filters';
  String get couldntLoadPros =>
      _am ? 'ባለሙያዎቹ አልመጡም' : "Couldn't load professionals";
  String get checkConnection => _am
      ? 'ኔትዎን ይመልከቱ፣ ከዚያ እንደገና ይሞክሩ።'
      : 'Check your connection and try again.';
  String get retry => _am ? 'እንደገና' : 'Retry';

  // ── Explore — C04 / C05 / C06 ───────────────────────────────────────
  String get chipAll => _am ? 'ሁሉ' : 'All';
  String get guidesForYou => _am ? 'ለእርስዎ መሪዎች' : 'Guides for you';
  String get chefsForYou => _am ? 'ለእርስዎ ሼፎች' : 'Chefs for you';
  String get cliniciansForYou =>
      _am ? 'ለእርስዎ ባለሙያዎች' : 'Clinicians for you';
  String get sortedByMatch => _am ? 'በማዛመድ' : 'Sorted by match';
  String get liveNow => _am ? 'አሁን ቀጥታ' : 'Live now';
  String get free => _am ? 'ነጻ' : 'Free';
  String get faithOrthodox => _am ? 'ኦርቶዶክስ' : 'Orthodox';
  String get faithMuslim => _am ? 'ሙስሊም' : 'Muslim';
  String get faithProtestant => _am ? 'ፕሮቴስታንት' : 'Protestant';
  String get faithCatholic => _am ? 'ካቶሊክ' : 'Catholic';
  String get chipPsychiatrists => _am ? 'ሐኪሞች' : 'Psychiatrists';
  String get chipPsychologists => _am ? 'ስነ-አእምሮ ባለሙያ' : 'Psychologists';
  String get chipCounselors => _am ? 'አማካሪዎች' : 'Counselors';
  String get liveEveningPrayer => _am
      ? 'የምሽት ጸሎት እና ማሰብ'
      : 'Evening prayer & reflection';
  String get liveMemhirDaniel =>
      _am ? 'መምህር ዳንኤል · 23 ይሰማሉ' : 'Memhir Daniel · 23 listening';
  String get liveChefShiro =>
      _am ? 'ለአንድ ሺሮ' : 'Shiro for one';
  String get liveChefTsion => _am
      ? 'ሼፍ ጽዮን በቀለ · 30 ደቂ · 6 ቦታ'
      : 'Chef Tsion Bekele · 30 min · 6 spots left';
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
  String get circlesVents => _am ? 'ክበብና ልብ ማውጫ' : 'Circles & vents';
  String get privateNotes => _am ? 'ለእርስዎ ብቻ' : 'Private notes';
  String get balanceTopUps => _am ? 'ቀሪና መሙላት' : 'Balance & top-ups';
  String get threePaths => _am ? 'ሦስት መንገዶች' : '3 Akilil paths';
  String get takeBreathReady => _am
      ? 'ቀስ ብለው ይተንፉ። ሲዘጋጁ ሰው እዚህ አለ።'
      : 'Take a breath. Someone is here when you are ready.';

  String get validEmail =>
      _am ? 'ትክክለኛ ኢሜይል ያስገቡ' : 'Enter a valid email';
  String get minPassword =>
      _am ? 'ቢያንስ ስድስት ፊደል' : 'Min 6 characters';
  String get loginFailed =>
      _am ? 'አልገባም። እንደገና ይሞክሩ።' : 'Login failed. Please try again.';
  String get cantReach => _am
      ? 'አኪሊል አሁን አልተገኘም። ኔትዎን ይመልከቱ።'
      : "Can't reach Akilil servers. Check your connection.";

  // ── Today — write what people say, not English UI calques ───────────
  String get searchHint =>
      _am ? 'ማንን ማናገር ይፈልጋሉ?' : 'Search listeners, sessions…';
  String get yourPaths => _am ? 'መንገዶችዎ' : 'Your paths';
  String get mindfulTracker => _am ? 'ለራስዎ' : 'Mindful Tracker';
  String get journalSubtitle =>
      _am ? 'ዛሬ የተሰማዎትን ይጻፉ' : 'Write down what today felt like';
  String get moodSubtitle =>
      _am ? 'አሁን እንዴት ነዎት?' : 'Log how you are feeling right now';
  String get sessionsSubtitle =>
      _am ? 'ቀጠሮዎችዎና ያለፉ ንግግሮች' : 'Your bookings and past sessions';
  String get quickActions => _am ? 'በፍጥነት' : 'Quick actions';
  String get worksheets => _am ? 'ልምምድ' : 'Worksheets';
  String get assess => _am ? 'ግምገማ' : 'Assess';
  String get groups => _am ? 'ቡድን' : 'Groups';
  String get crisis => _am ? 'አስቸኳይ' : 'Crisis';
  String get mood => _am ? 'ስሜት' : 'Mood';
  String get boxBreathingSubtitle =>
      _am ? 'አራት ቆጠራ — ቀስ ብለው ይተንፉ' : '4-4-4-4 calming breath exercise';
  String get clinicalTools => _am ? 'እንክብካቤ' : 'Clinical tools';
  String get assessmentCheckIn =>
      _am ? 'ስሜትዎን ይመዝኑ' : 'PHQ-9 & GAD-7 Check-in';
  String get assessmentSubtitle =>
      _am ? 'ጭንቀት ወይም ሐዘን ሲሰማዎት' : 'Track anxiety and depression levels';
  String get boxBreathing => _am ? 'የመረጋጋት ትንፋሽ' : 'Box breathing';
  String get safetyPlan => _am ? 'ሲከብድዎ እቅድ' : 'Safety plan';
  String get safetyPlanSubtitle =>
      _am ? 'ከባድ ጊዜ ሲመጣ የሚረዳዎ' : 'Your personalised crisis plan';
  String get topListeners => _am ? 'የሚመከሩ አድማጮች' : 'Top listeners';
  String get seeAll => _am ? 'ሁሉም' : 'See all';
  String get exploreSupport =>
      _am ? 'እንክብካቤ ይመልከቱ' : 'Explore support';
  String get howAreYouFeeling =>
      _am ? 'አሁን እንዴት ነዎት?' : 'How are you feeling?';
  String get moodAwful => _am ? 'በጣም መጥፎ' : 'Awful';
  String get moodLow => _am ? 'ዝቅተኛ' : 'Low';
  String get moodOkay => _am ? 'መካከለኛ' : 'Okay';
  String get moodGood => _am ? 'ጥሩ' : 'Good';
  String get moodGreat => _am ? 'በጣም ጥሩ' : 'Great';
  String get reschedule => _am ? 'መርሐግብር ቀይር' : 'Reschedule';
  String get join => _am ? 'ይግቡ' : 'Join';
  String get videoTherapy => _am ? 'ቪዲዮ የሕክምና ክፍለ ጊዜ' : 'Video therapy';
  String startsIn(int hours, int minutes) {
    if (_am) {
      if (hours > 0) {
        return 'ከ $hoursሰ $minutesደ በኋላ ይጀምራል';
      }
      return 'ከ $minutes ደቂቃ በኋላ ይጀምራል';
    }
    if (hours > 0) return 'Starts in ${hours}h ${minutes}m';
    return 'Starts in ${minutes}m';
  }

  String dayStreak(int days) =>
      _am ? '$days ቀን ተከታታይ' : '$days-day streak';

  String greetingTime() {
    final h = DateTime.now().hour;
    if (_am) {
      if (h < 12) return 'እንደምን አደሩ';
      if (h < 17) return 'እንደምን ዋሉ';
      return 'መልካም ምሽት';
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
      _am ? 'በዚህ መንገድ እስካሁን አድማጭ የለም።' : 'No listeners in this path yet.';
  String get sessionReady =>
      _am ? 'ለመጀመር ዝግጁ ነው።' : 'Session room is ready.';
  String scheduledInMins(int mins) => _am
      ? 'ከ $mins ደቂቃ በኋላ · ዝግጁ ነው።'
      : 'Scheduled in $mins mins • Tech check & 4K room ready.';
  String minutesShort(int n) => _am ? '$n ደቂቃ' : '$n min';
  String get joinSession => _am ? 'ይግቡ' : 'Join session';
  String get joinVideoSession =>
      _am ? 'ቪዲዮ ይክፈቱ' : 'Join video session';
  String get setup => _am ? 'ያዘጋጁ' : 'Setup';
  String get noSessionBooked =>
      _am ? 'ገና ቀጠሮ አልያዙም' : 'No session booked';
  String get findListenerPrompt => _am
      ? 'አድማጭ ይምረጡ። ሲዘጋጁ በግል ይነጋገሩ።'
      : 'Find a listener and book a private video session when you are ready.';
  String get findAListener => _am ? 'አድማጭ ይምረጡ' : 'Find a listener';
  String get verifiedListener => _am ? 'የተረጋገጠ አድማጭ' : 'Verified listener';
  String fromRate(String rate) => _am ? 'ከ $rate' : 'From $rate';
  String get book => _am ? 'ይያዙ' : 'Book';
  String get listenerFallback => _am ? 'አድማጭ' : 'Listener';
  String perSession(String amount) =>
      _am ? '$amount በቀጠሮ' : '$amount/session';

  // ── Professional profile & booking (C07 / C08) ─────────────────────
  String get licenseVerified =>
      _am ? 'ፈቃድ ተረጋግጧል' : 'License verified';
  String get nextAvailable =>
      _am ? 'ቀጣይ ክፍት ጊዜ' : 'Next available';
  String get bookSession =>
      _am ? 'ቀጠሮ ይያዙ' : 'Book session';
  String perFiftyMinSession(int minutes) => _am
      ? 'በ $minutes ደቂቃ ክፍለ ጊዜ'
      : 'per $minutes-min session';
  String get bookASession =>
      _am ? 'ቀጠሮ ይያዙ' : 'Book a session';
  String get availableTimesEat => _am
      ? 'ዝግጁ ሰዓቶች · የምሥራቅ አፍሪካ ሰዓት'
      : 'Available times · East Africa Time';
  String confirmAndPay(int amount) => _am
      ? 'አረጋግጥ እና $amount ብር ይክፈሉ'
      : 'Confirm and pay $amount ETB';
  String get serviceFee => _am ? 'የአገልግሎት ክፍያ' : 'Service fee';
  String get akililWallet => _am ? 'የአኪሊል ቦርሳ' : 'Akilil wallet';
  String get changePayment => _am ? 'ቀይር' : 'Change';
  String get statReviews => _am ? 'ግምገማዎች' : 'reviews';
  String get statSessions => _am ? 'ክፍለ ጊዜዎች' : 'sessions';
  String get statExperience => _am ? 'ልምድ' : 'experience';
  String yrsExperience(int years) =>
      _am ? '$years ዓመት' : '$years yrs';
  String get modeChat => _am ? 'ጽሁፍ' : 'Chat';
  String get modeVoice => _am ? 'ድምፅ' : 'Voice';
  String get modeVideo => _am ? 'ቪዲዮ' : 'Video';
  String get total => _am ? 'ድምር' : 'Total';
  String get unavailable => _am ? 'አልተዘጋጀም' : 'Unavailable';
  String get shareProfile => _am ? 'አጋራ' : 'Share';
  String get saveProfile => _am ? 'አስቀምጥ' : 'Save';
  String get aboutMe => _am ? 'ስለ እኔ' : 'About me';
  String get specialtiesTopics =>
      _am ? 'ልዩ ችሎታዎች' : 'Specialties & topics';
  String get cityFallback => _am ? 'አዲስ አበባ' : 'Addis Ababa';
  String get sessionSummary => _am ? 'ማጠቃለያ' : 'Summary';
  String get walletBalance => _am ? 'ቀሪ ሂሳብ' : 'Balance';

  // ── Journal (C10) ───────────────────────────────────────────────────
  String get journalScreenTitle => journal;
  String get newJournalEntry => _am ? 'አዲስ ማስታወሻ' : 'New entry';
  String get thisWeek => _am ? 'በዚህ ሳምንት' : 'This week';
  String get tonightsPrompt => _am ? 'የዛሬ ማብራሪያ' : "Tonight's prompt";
  String get journalDefaultPrompt => _am
      ? 'ባለፈው ሳምንት የበለጠ በተሻለ ሁኔታ የተያዙት እነሱ የትኞቹ ናቸው?'
      : "What's one thing you handled better than last week?";
  String get recent => _am ? 'በቅርቡ' : 'Recent';
  String get journalMoodSummary =>
      _am ? 'በአብዛኛው ጥሩ' : 'Mostly good';
  String get journalMoodSteady => _am ? 'ተረጋጋ' : 'Steady';
  String get journalMoodMixed => _am ? 'የተለያየ' : 'Mixed';
  String get journalMoodTough => _am ? 'ከባድ ሳምንት' : 'Tough week';
  String moodWeekTrend(int percent) => _am
      ? 'ከባለፈው ሳምንት $percent%'
      : '$percent% vs last week';
  String sharedWith(String name) =>
      _am ? 'ከ $name ጋር ተጋርቷል' : 'Shared with $name';
  String get sharedWithCareTeam =>
      _am ? 'ከእንክብካቤ ቡድን ጋር ተጋርቷል' : 'Shared with your care team';
  String get journalLoadError =>
      _am ? 'ማስታወሻ አልተጫነም' : "Couldn't load journal";
  String get journalEmptyTitle =>
      _am ? 'መጀመሪያ ማስታወሻዎን ይጻፉ' : 'Start your private journal';
  String get journalEmptyMessage =>
      _am ? 'ለእርስዎ ብቻ። በኋላ የተሞላ የተጠበቀ።' : 'Just for you. Encrypted at rest.';

  // ── Wallet (C11) ──────────────────────────────────────────────────
  String get availableBalance =>
      _am ? 'ያለ ቀሪ ሂሳብ' : 'Available balance';
  String get topUp => _am ? 'መሙላት' : 'Top up';
  String get activity => _am ? 'እንቅስቃሴ' : 'Activity';
  String get walletLoadError => _am
      ? 'ቀሪ ሂሳብ አልተጫነም'
      : "Couldn't load your balance.";
  String get noActivityYet => _am ? 'እንቅስቃሴ የለም' : 'No activity yet';
  String get noActivityMessage => _am
      ? 'መሙላቶችና ክፍያዎች እዚህ ይታያሉ።'
      : 'Top-ups and session payments show up here.';
  String get couldntLoadTransactions => _am
      ? 'ግብይቶች አልተጫኑም'
      : "Couldn't load transactions";
  String topUpAmount(String amount) =>
      _am ? '$amount ያስገቡ' : 'Top up $amount';
  String get processingTopUp => _am ? 'በሂደት ላይ…' : 'Processing…';

  // ── Safety (C12) ────────────────────────────────────────────────────
  String get safetyTitle => _am ? 'ደህንነት' : 'Safety';
  String get notAlone =>
      _am ? 'ብቻ አይደሉም።' : "You're not alone.";
  String get someoneCanTalkNow => _am
      ? 'አሁን ማውራት የሚችሉ ሰው አለ።'
      : 'Someone can talk with you right now.';
  String get talkToListenerNow =>
      _am ? 'አሁን አዳማጭ ያግኙ' : 'Talk to a listener now';
  String get listenersAvailableFree =>
      _am ? '4 ዝግጁ · ነጻ' : '4 available · free';
  String get emergencyServices =>
      _am ? 'የአስቸኳይ አገልግሎት' : 'Emergency services';
  String get localEmergencyNumber => _am ? '991' : '991';
  String get call => _am ? 'ደውል' : 'Call';
  String get trustedContact => _am ? 'የሚታመነ ዕውቂያ' : 'Trusted contact';
  String get breatheWithMe =>
      _am ? 'እንክብካቤ እባክዎን ተንፉ' : 'Breathe with me';
  String get guidedGrounding => _am
      ? '2 ደቂቃ የተመራ ማረጋገጥ'
      : '2-minute guided grounding';
  String get mySafetyPlan => safetyPlan;
  String safetyPlanStepsComplete(int done, int total) => _am
      ? '$total ውስጥ $done ተጠናቋል'
      : '$done of $total steps complete';
  String get verifiedCrisisLifelines => _am
      ? 'የተረጋገጡ የአስቸኳይ መስመሮች'
      : 'Verified crisis lifelines';

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
