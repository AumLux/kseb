# Flutter and plugin consumer rules are applied automatically; keep only
# what R8 cannot see through reflection.

# Firebase Messaging (push) background handling.
-keep class com.google.firebase.messaging.** { *; }
-dontwarn com.google.firebase.**

# Play Core split-install classes referenced by the Flutter engine (unused).
-dontwarn com.google.android.play.core.**
