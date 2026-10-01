# Release Process

Two-step release cycle. The same commit is tested on staging and then promoted to production:

1. Merge feature work into `staging` through a PR. The PR runs `flutter analyze`/`flutter test`; the `Supabase` workflow runs lint and pgTAP.
2. A push to `staging`:
   - applies migrations to the **staging** Supabase project and deploys edge functions;
   - builds two sites from that commit, *staging* (staging project) and *production* (production project, release-signed), and uploads both as artifacts.
3. Test with the staging artifact (`aumlux-staging-<sha>`): install the APK and open `web/`.
4. Merge `staging` into `releases`. A push to `releases`:
   - applies the same migrations to the **production** project;
   - promotes the `aumlux-production-<sha>` artifact of the latest green staging run to GitHub Pages.

## Branch responsibilities

- Feature branches (`revamp/*`, `feat/*`): active development; PRs target `staging`.
- `staging`: integration plus test builds. Never deploys to users.
- `releases`: production. A push deploys the database and the site.

## Commands

```bash
git checkout staging
git merge --no-ff <feature-branch>
git push origin staging
```

After the staging build has been tested:

```bash
git checkout releases
git merge --no-ff staging
git push origin releases
```

## Forcing an app update

If a release changes the database in a way that older APKs can't handle, raise `min_app_build` after the release deploys. [docs/BACKEND.md → Android releases](BACKEND.md#android-releases) covers this, along with the signing secrets and the restore procedure.
