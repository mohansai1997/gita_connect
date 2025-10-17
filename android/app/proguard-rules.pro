# Flutter Local Notifications ProGuard Rules
-keep class com.dexterous.** { *; }
-keep class androidx.work.** { *; }

# Keep notification classes
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.InputMerger
-keep class androidx.work.impl.** { *; }

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep generic signatures for proper serialization
-keepattributes Signature
-keepattributes *Annotation*

# Fix for TypeToken issue
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Keep notification related classes
-keep class android.app.Notification { *; }
-keep class android.app.NotificationManager { *; }
-keep class android.app.NotificationChannel { *; }