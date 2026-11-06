# flutter_local_notifications stores scheduled notifications as JSON via
# Gson. R8 (on by default for Flutter release builds) strips the generic
# type info Gson needs to read them back, which makes
# pendingNotificationRequests / rescheduling after reboot crash with
# "java.lang.RuntimeException: Missing type parameter".
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class com.dexterous.** { *; }
