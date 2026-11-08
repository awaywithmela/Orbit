import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Requests UMP consent before enabling the Mobile Ads SDK.
///
/// Configure the consent message in AdMob under Privacy & messaging. If no
/// message applies to a user, UMP completes without showing a dialog.
class AdsConsentService {
  AdsConsentService._();

  static bool adsReady = false;

  static Future<void> initialize() async {
    final consent = ConsentInformation.instance;
    final completed = Completer<void>();

    consent.requestConsentInfoUpdate(
      ConsentRequestParameters(tagForUnderAgeOfConsent: false),
      () async {
        try {
          await ConsentForm.loadAndShowConsentFormIfRequired((error) async {
            if (error != null) {
              debugPrint('UMP consent form: ${error.message}');
            }
            if (!completed.isCompleted) completed.complete();
          });
        } catch (error) {
          debugPrint('UMP consent form failed: $error');
          if (!completed.isCompleted) completed.complete();
        }
      },
      (error) {
        debugPrint('UMP consent info update: ${error.message}');
        if (!completed.isCompleted) completed.complete();
      },
    );

    await completed.future;
    if (await consent.canRequestAds()) {
      await MobileAds.instance.initialize();
      adsReady = true;
    }
  }
}
