# AumLux

Operations app for an electrical contractor executing KSEB distribution works (transformers, poles, conductors, service lines). It covers workforce and attendance, worksheets with permit-to-work, ledger-based inventory, field registers, and the commercial pipeline (tenders, EMD/SD/BG, work orders, bills, GST).

**Platforms:** Android (field crews) and Web (office).

**Stack:** Flutter (Riverpod, go_router) on Supabase (Postgres with row-level security, Auth, Storage, Edge Functions); Firebase only for FCM push. English and Malayalam.

## Quick start

```bash
flutter pub get
flutter analyze
flutter test
flutter run                                   # staging backend
flutter run --dart-define=AUMLUX_ENV=production
```

For the local backend (Docker + Supabase CLI), see [docs/BACKEND.md](docs/BACKEND.md#local-development).

## Documentation

| Doc | What |
|---|---|
| [DESIGN.md](DESIGN.md) | Design system: tokens, components, accessibility and field-use rules. **Read this before building UI.** |
| [docs/REVAMP_PLAN.md](docs/REVAMP_PLAN.md) | Audit findings, target architecture, DB schema, delivery phases |
| [docs/BACKEND.md](docs/BACKEND.md) | Supabase setup, security model, push, Android signing, backups: the ops runbook |
| [docs/RELEASE_PROCESS.md](docs/RELEASE_PROCESS.md) | Branch flow `feature → staging → releases` and CI |
| [docs/archive/](docs/archive/) | Firestore-era docs, kept for migration reference only |

## Roles

`staff < supervisor < manager < coo < director`. A higher role can manage and approve the roles below it, within its organisational scope (team → section → organisation).

## License

Proprietary. All rights reserved.
