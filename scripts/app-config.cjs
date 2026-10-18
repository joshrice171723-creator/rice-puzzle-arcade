const sample = 'ca-app-pub-3940256099942544~3347511713';
const publishers = require('../packages/ads/publisher.json');
function validateAds(env = process.env, slug) {
  if (env.EAS_BUILD_PROFILE !== 'production' && env.EXPO_PUBLIC_BUILD_PROFILE !== 'production') return sample;
  if (env.EXPO_PUBLIC_ADS_MODE !== 'production') throw new Error('Production ads mode must be explicit.');
  const publisher = publishers[slug];
  if (!publisher) throw new Error('Unknown production game; publisher mapping required.');
  const expected = { ADMOB_ANDROID_APP_ID: publisher.appId, EXPO_PUBLIC_ADMOB_REWARDED_ID: publisher.rewarded, EXPO_PUBLIC_ADMOB_INTERSTITIAL_ID: publisher.interstitial };
  for (const [key, separator] of [['ADMOB_ANDROID_APP_ID', '~'], ['EXPO_PUBLIC_ADMOB_REWARDED_ID', '/'], ['EXPO_PUBLIC_ADMOB_INTERSTITIAL_ID', '/']]) {
    const value = expected[key];
    if (env[key] && env[key] !== value) throw new Error(`Mismatched ${key} for ${slug}.`);
    if (!new RegExp(`^ca-app-pub-[0-9]{16}${separator}[0-9]{10}$`).test(value) || value.includes('3940256099942544')) throw new Error(`Missing real owner ${key}; production blocked.`);
  }
  if (env.PUBLISHER_RELEASE_APPROVED !== 'true') throw new Error('Owner audience and disclosure review required.');
  return publisher.appId;
}
module.exports = function(slug, name, packageId, color) {
  return { name, slug, version: '0.1.0', orientation: 'portrait', userInterfaceStyle: 'dark', icon: './assets/icon.png',
    splash: { image: './assets/splash.png', resizeMode: 'contain', backgroundColor: color },
    android: { package: packageId, versionCode: 1, adaptiveIcon: { foregroundImage: './assets/adaptive-icon.png', backgroundColor: color }, blockedPermissions: ['android.permission.RECORD_AUDIO'], allowBackup: false },
    ios: { bundleIdentifier: packageId }, web: { bundler: 'metro', favicon: './assets/icon.png' },
    plugins: [['expo-build-properties', { android: { compileSdkVersion: 37, targetSdkVersion: 36, minSdkVersion: 24 } }],
      ['react-native-google-mobile-ads', { androidAppId: validateAds(process.env, slug), iosAppId: 'ca-app-pub-3940256099942544~1458002511', delayAppMeasurementInit: true }]] };
};
module.exports.validateAds = validateAds;
