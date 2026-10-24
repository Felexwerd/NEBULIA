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
An installable APK is not checked into source control. Unity's Android build needs a locally activated Unity Editor or a properly configured Unity build service. The old Godot workflow does not build this Unity project.
