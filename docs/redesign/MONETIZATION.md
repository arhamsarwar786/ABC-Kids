# Ads: retained integration, changed placements, proposals

No compliance claim is made here. Policy text quoted below was read on
2026-11-02 from the links supplied by the product owner; it must be re-checked
before release.

## What was kept

- `google_mobile_ads` dependency, AdMob app ID in `AndroidManifest.xml` and
  `ios/Runner/Info.plist`, SKAdNetwork list, all ad unit IDs in
  `lib/core/constants/ad_constants.dart` (test IDs in debug builds).
- Request configuration: `maxAdContentRating: G`,
  `ageRestrictedTreatment: AgeRestrictedTreatment.child` (unchanged from original).
- Code for banner, native, interstitial, rewarded and app-open ads
  (`lib/core/services/ads_service.dart`, `lib/features/shared/widgets/`).

## What changed

| Placement (original) | Now | Switch in `AdPlacementPolicy` |
|---|---|---|
| Banner at bottom of Home, ABC, Numbers, Detail | Off in child screens | `childBanners: false` |
| Native ad between Home cards | Off | `childNative: false` |
| Interstitial when leaving ABC/Numbers | Off | `sessionEndInterstitial: false` |
| App-open ad on return to foreground | Off | `appOpenOnForeground: false` |
| “Earn a star” rewarded ad (star button on Home) and rewarded interstitial every 5 letters | Off; earlier stars migrated to “stars from before” | `rewardedPrompts: false` |
| Banner on Home, ABC, Numbers, Detail | **Exactly one** banner per screen, Android only, labelled “Advertisement”, never drawn over content: on the four tab screens (Home, ABC, Games, Stickers) it is docked directly above the tab bar; on every other screen (lessons, games, hubs, parent area, welcome) it is a single strip below the content. No inline banners inside scrolling content (Families policy: no multiple ad placements on a page) | `childBanners` via `AdPlacementPolicy.forPlatform()` |

The Mobile Ads SDK starts when the browse tabs first appear (banner only, so no
ad covers the screen at launch). Every request is non-personalised
(`AdsService.childRequest`), child-directed (`AgeRestrictedTreatment.child`) and
G-rated (`MaxAdContentRating.g`). `test/ads_policy_test.dart` fails if a
full-screen format is switched on, a personalised request is added, or an ad
widget is placed inside lessons, games or explorers.

Interstitial, rewarded and app-open ads stay off: for apps aimed at children the
Families policy prohibits “monetization and advertising that take up the entire
screen” and opt-in ads that cannot be closed after 5 seconds (re-read
2026-11-04).

### AdMob console settings (owner to set; not verifiable from code)

- App settings → mark the app as **child-directed / designed for families**.
- Blocking controls → **Sensitive categories**: block dating, gambling (incl.
  sweepstakes), alcohol, references to sex, weight loss, get-rich-quick, politics,
  religion if desired; **General categories**: block media, video games and
  software apps (Families policy lists these as inappropriate for children).
- Keep **max ad content rating G** at app level as well.
- Use the **Ad review center** to check and block individual creatives. The original Share button (an external link out) was removed from
the child area.

## Relevant policy points (quoted)

Google Play Families (support.google.com/googleplay/android-developer/answer/9893335):
- Children-only apps must “use only Families self-certified ads SDK versions”.
- Prohibited for children: “Disruptive monetization and advertising, including monetization and advertising that take up the entire screen”; “Interstitial monetization and advertising displayed immediately upon app launch”; “Multiple ad placements on a page”.
- “Apps solely targeted to children should not request AD_ID permission when targeting Android API 33 or higher.”

Apple App Review Guidelines 1.3 / 5.1.4 and developer.apple.com/kids:
- “Apps in the Kids Category should not include third-party analytics or third-party advertising”, with limited contextual-advertising exceptions requiring human review of creatives.
- “Kids apps should not transmit personally identifiable information or device information to third parties — even in sections intended for adults — unless the parent explicitly consents.”
- “the parental gate requirement for the Kid's Category is generally not the same as securing parental consent”.

## Proposals for the product owner (not implemented)

1. Android: remove `AD_ID` / `ACCESS_ADSERVICES_AD_ID` via `tools:node="remove"` if the app stays children-only, and confirm the SDK version is Families self-certified.
2. iOS: consider shipping without the ads SDK (or with it disabled) if targeting the Kids Category.
3. Longer term: replace ads with a one-off purchase or content packs behind the parent gate (no purchases inside child play).
4. Keep `AdPlacementPolicy` child switches off; any change needs policy review.
