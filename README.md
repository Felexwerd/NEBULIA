# NEBULIA

NEBULIA is an anime-fantasy village-management RPG for Android. The project is being rebuilt in **Unity 6.3 LTS** for a richer 2.5D village, flexible 3D exploration/combat, and a stronger mobile presentation.

## Engine direction
- **Primary rebuild:** `UnityProject/` — Unity 6.3 LTS, mobile-first 2.5D village, procedural environment, resource economy, upgrade/recruit UI.
- **Legacy reference:** root Godot files remain temporarily so existing work is not lost. New gameplay work should target Unity.

## Open the Unity project
1. Install Unity Hub and Unity Editor **6000.3.0f1** with Android Build Support, Android SDK & NDK Tools, and OpenJDK.
2. In Unity Hub, choose **Add project from disk** and select `UnityProject`.
3. Open `Assets/Scenes/Main.unity` and press Play.

The Unity folder contains an initial gameplay foundation, not a finished game. Final anime character illustrations/animation, story chapters, complete quest/relationship systems, day/night and weather, combat, save/load, and device testing remain to be built.

## Android APK
There is not yet a verified Unity APK artifact. Android export requires an activated Unity Editor or a configured Unity build service. The old Godot Actions workflow does not build the Unity project.
