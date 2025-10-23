# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# TensorFlow Lite specific rules
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.**
-dontwarn org.tensorflow.lite.gpu.**

# Keep native methods used by TensorFlow Lite
-keepclasseswithmembers class * {
    native <methods>;
}

# Keep all classes that extend TensorBuffer or implement NativeHandle
-keep public class * extends org.tensorflow.lite.support.common.TensorBuffer {
    public <init>(...);
}

-keep public class * implements org.tensorflow.lite.support.common.NativeHandle {
    public <init>(...);
}

# Firebase specific rules
-keep class io.flutter.plugins.firebase.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Google Play Services - Dynamic Features / Deferred Components
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Flutter deferred components
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# Generic Flutter keep rules
-keep class io.flutter.** { *; }
-keep class androidx.** { *; }

# Keep all enums
-keep enum * { *; }

# Keep all annotations
-keepattributes *Annotation*
