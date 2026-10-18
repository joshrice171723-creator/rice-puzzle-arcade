# Publisher site source

Six accessible, responsive, static routes: `/`, `/grid-foundry/`, `/merge-drift/`, `/color-cascade/`, `/privacy/`, `/support/`.

Run `node website/build.mjs` from the repository root to regenerate HTML after editing the content in that file. `style.css` is maintained directly. Serve the `website` directory at a domain root; root-relative URLs intentionally support a user-domain GitHub Pages site rather than a project subpath. Board art is labeled illustration, not a screenshot.

**Not published.** The planned domain is `https://joshrice171723-creator.github.io`. Domain ownership/deployment and the planned support issue tracker require live verification. Account setup and publication were deferred by the owner to focus on games. No personal support email has been confirmed or published.

## Deployment when resumed

1. Inventory existing owner-controlled Pages site before creating or replacing any repository. The planned public repository is `joshrice171723-creator.github.io`; keep app source in the private game repository.
2. Copy only generated website files and `style.css` to its root, excluding this README and the source generator if desired. Retain `.nojekyll`. Enable Pages on the correct branch and confirm HTTPS.
3. Verify all six routes, mobile layout, keyboard focus, privacy copy, and an actually usable support channel. The current support URL points to the planned public `rice-puzzle-arcade-site` issues repository and must be created or replaced with a verified public support route before release.
4. Obtain the exact publisher record from the owner's AdMob account. Only then create `app-ads.txt` in the same site root. No empty, fabricated, or sample publisher record is included.
5. Verify `/app-ads.txt` returns the exact owner record as text, link the same domain in each Play listing, and confirm AdMob's own verification status. An HTTP response alone does not establish approval.

Privacy source references were checked October 17, 2026: [Google SDK disclosures](https://developers.google.com/admob/android/privacy/play-data-disclosure), [UMP](https://developers.google.com/admob/android/privacy), [app-ads.txt](https://support.google.com/admob/answer/9363762). Reconcile with the final native dependency versions before publication.
