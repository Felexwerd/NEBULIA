# NEBULIA

NEBULIA — anime fantasy idle village-management RPG prototype for Android, made with Godot 4. The gameplay direction focuses on growing a settlement, passive production, character collection, relationships, quests, and resource management, inspired by the genre of games such as Isekai: Slow Life. Character names and assets are original/placeholders.

## Current playable prototype
- Village screen with upgradeable tavern, farm, and workshop.
- Passive gold income, food from the farm, and wood from the workshop.
- Gold, food, wood, crystals, building levels, and settlement progression.
- Character collection with Eliana and Liara, profiles, affection, and gifts.
- Recruitment hall that spends crystals and prioritizes undiscovered characters.
- Quest board and resource trading.
- Local save file with periodic autosave and save on exit.

## Get an Android APK
1. Open the repository: https://github.com/Felexwerd/NEBULIA
2. Go to **Actions**.
3. Select **Build NEBULIA Android APK**.
4. If it has not run yet, click **Run workflow** and choose the `main` branch.
5. Open the completed run and download the artifact named **NEBULIA-Android-debug**.
6. Extract the ZIP and install `NEBULIA-debug.apk` on an Android device. If Android blocks installation, allow installs from that source in system settings.

The workflow also runs automatically when relevant game files change. The APK is a debug build for testing, not a Play Store release.

## Run in Godot
Open the repository folder in Godot 4.4 or compatible Godot 4.x and run `scenes/main.tscn`.

## Known limitations
This is still an early prototype. Character portraits are temporary symbols rather than final anime illustrations, recruitment currently uses the small starter roster, and there is no full story chapter system, character animation rig, sound design, or comprehensive device testing yet. The GitHub Actions APK workflow must complete successfully before an installable artifact is available.
