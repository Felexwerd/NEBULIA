# NEBULIA — Unity rebuild

This folder is the new engine project for the Android anime-fantasy village RPG. The previous Godot project remains in the repository for reference; it has not been deleted.

## Engine
- Unity 6.3 LTS
- Android target
- Mobile-first UI with an orthographic 2.5D village view

## Open
1. Install Unity Hub from the official Unity website.
2. Install Unity Editor **6000.3.0f1** with **Android Build Support**, Android SDK & NDK Tools, and OpenJDK.
3. In Unity Hub choose **Add project from disk** and select this `UnityProject` folder.
4. Open `Assets/Scenes/Main.unity` and press Play.

## Current migration baseline
The main scene procedurally creates a stylized village, houses, river and bridge, trees, residents, a mobile HUD, resource income, tavern upgrades, quest/hero panels, and crystal recruitment. This is a foundation, not the finished game: final anime character art, animated characters, deeper story/quests, save system, weather/day-night, and proper combat still need to be implemented.

## Android builds
The GitHub Actions workflow **NEBULIA Unity Android APK** can build an APK manually. It requires Unity licensing credentials configured as repository Actions secrets:
- `UNITY_LICENSE` — Unity license file contents (or the license format accepted by GameCI)
- `UNITY_EMAIL` — Unity account email
- `UNITY_PASSWORD` — Unity account password

Open **Actions → NEBULIA Unity Android APK → Run workflow**. When the run succeeds, download the `NEBULIA-Android-APK` artifact from the run summary. Do not add credentials to repository files. If the secrets are not configured or the license cannot be activated, the workflow will fail before producing an APK.

The APK has not yet been built or runtime-tested in this repository. The old Godot workflow does not build this Unity project.
