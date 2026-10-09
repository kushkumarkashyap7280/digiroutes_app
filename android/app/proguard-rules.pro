# Flutter's release build shrinks/renames code with R8. The QR scanner
# (mobile_scanner → ML Kit barcode + CameraX) initialises through reflection and
# component registrars, so R8 must not rename or strip these classes —
# otherwise scanning fails in release builds with a NullPointerException.
-keep class dev.steenbakker.mobile_scanner.** { *; }
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_** { *; }
-keep class com.google.android.odml.** { *; }
-keep class com.google.firebase.components.** { *; }
-keep class * implements com.google.firebase.components.ComponentRegistrar
-keep class androidx.camera.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.odml.**
