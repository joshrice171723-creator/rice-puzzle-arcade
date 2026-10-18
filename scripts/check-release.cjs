require('./app-config.cjs').validateAds({ ...process.env, EAS_BUILD_PROFILE: 'production' });
console.log('Ad IDs validated. Account readiness and signing require separate verification.');
