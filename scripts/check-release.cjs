for (const slug of Object.keys(require('../packages/ads/publisher.json'))) {
  require('./app-config.cjs').validateAds({ ...process.env, EAS_BUILD_PROFILE: 'production' }, slug);
}
console.log('Ad IDs validated. Account readiness and signing require separate verification.');
