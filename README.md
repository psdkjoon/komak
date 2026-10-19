# komak

psdk komak - learn small things, a little at a time.

## Run

```
flutter pub get
flutter run
```

## Release

```
bash scripts/bump_version.sh 1.1.0
git commit -am "Release 1.1.0" && git push
```

CI builds the Android APKs, the Linux AppImages and the Windows installer, then publishes them to GitHub Releases as `v1.1.0`. Installed copies find the new version through the `VERSION` file on `main`.

## Icons and fonts

Edit `assets/icons/icon_mocha.svg` and `icon_latte.svg`, then run `python3 scripts/generate_icons.py`.

After adding translations, rebuild the bundled fonts with `python3 scripts/subset_fonts.py --src <folder with the original Noto fonts> --cjk jp`.

## Languages

The app ships in Persian (`fa`), English (`en`), Japanese (`ja`) and Russian (`ru`). Every screen is translated, including About and the app name itself. Write new text in English and add it to `strings_fa.dart`, `strings_ja.dart` and `strings_ru.dart`. `flutter test` fails when a language is missing a string.

Set the translated app name first: the first entry in each `lib/localization/strings_*.dart` file, and `app_name` in `android/app/src/main/res/values-fa`, `values-ja` and `values-ru`.

## Building this app with Claude

Do not design from memory. Before writing any screen:

1. Use the best UI and UX plugin available in Claude's plugins (design critique, accessibility review, UX copy, design system) to decide how each screen should look and behave.
2. Use the best Flutter plugins (the official Flutter and Dart skills first, then the strongest community ones) to decide what to build and how. Read the matching skill before writing that kind of code.
3. Build the screen, then review it with the same plugins before calling it done. Check it in all four languages, in Mocha and Latte, and in right-to-left Persian.
4. Where a plugin disagrees with the flutter-base README (third-party packages, comments, state management), the flutter-base README wins.

See the flutter-base README for the structure and the conventions this project follows.
