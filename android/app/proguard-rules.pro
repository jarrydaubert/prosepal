# ==============================================================================
# Prosepal ProGuard Rules
# ==============================================================================
# These rules ensure proper obfuscation while keeping necessary classes intact.
# R8 (Android's code shrinker) uses these to optimize and protect the app.

# ------------------------------------------------------------------------------
# Flutter Framework
# ------------------------------------------------------------------------------
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# ------------------------------------------------------------------------------
# Google Play Core (Deferred Components / Split APKs)
# ------------------------------------------------------------------------------
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# ------------------------------------------------------------------------------
# Firebase (Analytics, Crashlytics, AI)
# ------------------------------------------------------------------------------
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keepattributes *Annotation*
-keepattributes Signature

# ------------------------------------------------------------------------------
# RevenueCat (In-App Purchases)
# ------------------------------------------------------------------------------
-keep class com.revenuecat.purchases.** { *; }

# ------------------------------------------------------------------------------
# Google Sign-In
# ------------------------------------------------------------------------------
-keep class com.google.android.gms.auth.** { *; }

# ------------------------------------------------------------------------------
# Supabase / GoTrue (Authentication)
# ------------------------------------------------------------------------------
-keep class io.supabase.** { *; }

# ------------------------------------------------------------------------------
# Security Hardening
# ------------------------------------------------------------------------------
# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
}

# Obfuscate enum names for additional protection
-obfuscationdictionary proguard-dict.txt
-classobfuscationdictionary proguard-dict.txt
-packageobfuscationdictionary proguard-dict.txt

# Keep source file names for crash reports (but obfuscate everything else)
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# ------------------------------------------------------------------------------
# Prevent Serialization Issues
# ------------------------------------------------------------------------------
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
