# MergeMint 2048 — Eight⁸ Studio

A polished, swipe-based 2048 number puzzle. The original gameplay layout and tile colors are preserved; the app label, launcher icon, branding, and About dialog are updated.

## Build APK with GitHub Actions

1. Upload all project files to the root of your GitHub repository.
2. Open **Settings → Secrets and variables → Actions → New repository secret**.
3. Create exactly one secret named `SIGNING_PASSWORD` and set its value to a strong password.
4. Open **Actions → Build signed release APK → Run workflow**.
5. Download the `MergeMint-2048-release` artifact.

**Important:** this workflow creates a signing keystore during each run using `SIGNING_PASSWORD`, so no other secrets are required. Because the keystore is generated anew each run, APKs from later runs will have a different signing key and cannot be installed as updates over a previous release. Keep the APK from the run you publish.

The application ID is `studio.eight8.mergemint2048`.

## About

MergeMint 2048 is a number puzzle game inspired by classic 2048 gameplay. Swipe to move tiles, merge matching numbers, and try to reach 2048. Created by Eight⁸ Studio.

Rubika: @Studio_Eight8  
Developer: @Hesam23799

## License

This project started from an existing Flutter 2048 implementation. Review the included LICENSE and ensure its terms and attribution are followed before publishing.
