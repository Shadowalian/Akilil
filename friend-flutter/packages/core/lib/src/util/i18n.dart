/// Translation hook for shared widgets. Apps that translate (the client
/// app) set this to their own lookup; otherwise copy stays English.
String Function(String en) coreTr = _identity;

String _identity(String en) => en;

/// Language code sent to the API as Accept-Language so server messages
/// (errors, confirmations) come back in the language the user picked.
String coreLanguageCode = 'en';
