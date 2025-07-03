# Keep proguard annotations
-keep class proguard.annotation.Keep { *; }
-keep class proguard.annotation.KeepClassMembers { *; }

# Keep Razorpay classes
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**
