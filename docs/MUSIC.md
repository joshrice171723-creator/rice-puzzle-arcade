# Original game music

Three AI-composed instrumental scores are synthesized locally by `node scripts/music.mjs`. The score, oscillator synthesis and generated PCM WAV files are in this repository. No third-party recordings, samples, lyrics or reference songs were used. This provenance does not make a legal guarantee about copyright status.

- Grid Foundry: warm plucked pattern, 96 BPM, 40-second loop.
- Merge Drift: soft bell pattern, 80 BPM, 48-second loop.
- Color Cascade: bright mallet pattern, 104 BPM, approximately 37-second loop.

Music defaults on during active gameplay, fades in at low volume, and has an independent saved Settings toggle. It pauses on menus, results, pause, background, consent/ad presentation and transitions. Sound effects retain their separate preference. Older saves gain the music preference without losing progress. No network or music subscription is needed.

Verification October 18: all three browser players decoded their respective WAV, advanced playback at volume 0.32 with looping enabled, and paused at volume zero when Settings opened. Muting prevented playback. Storage migration and persistence are unit tested. Native APK rebuild is tracked separately; browser audio evidence is not proof of Android speaker quality.

Android emulator verification: Grid Foundry and Merge Drift both showed an active music AudioTrack during gameplay and a paused track after opening Settings or pausing. Grid music-off preference survived force-stop and restart; music was restored on afterward.

All three Android APK/AAB builds passed (arm64-v8a and x86_64, internal test ads). Color Cascade also started its music AudioTrack during a normal round and paused it when backgrounded. APK SHA-256 receipts:

- d34bca4bd91d0fd2b06508119c4d4ea262e67e90d451b954f46b88c3bcb644e9  grid-foundry-internal-test.apk
- af6a535fda7bf8c380711922308f97c4e09fcad30144256e2a1a36b5be4f69e7  merge-drift-internal-test.apk
- 9c40138eaa9421dfd52d2fd8ca58a007e9f4f27d2499ed5e3bcd892ba579b001  color-cascade-internal-test.apk
