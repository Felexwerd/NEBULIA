# NEBULIA: Echoes of Another World — playable prototype

This is a new game-first prototype, separate from the old button-based Android app.

## Current playable systems
- Hand-drawn procedural anime-fantasy village scene with paths, river, trees, four businesses, lanterns and a controllable hero.
- Touch/click movement through the village.
- Tap buildings to open a management panel, collect income, and upgrade production.
- Resource HUD and four navigation modes: Village, Heroes, Quests, World.
- Four original starter companions: Liora, Kael, Meiri and Celestra.
- Story journal and region map mockups as foundations for later gameplay.

## Build
The GitHub Actions workflow at .github/workflows/godot-android.yml exports build/NEBULIA.apk and uploads it as NEBULIA-Playable-Android-APK.

Engine: Godot 4.3, GDScript. This choice enables license-free cloud APK exports so the project can be built without Unity Hub or Android Studio installed locally.

This is a playable foundation, not a claim that the entire planned game is finished. Further milestones: proper illustrated character assets, animated residents, real quests, combat, persistent saves, and additional regions.
