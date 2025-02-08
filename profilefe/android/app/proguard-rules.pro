# Keep rules for Razorpay
-keep class proguard.annotation.Keep { *; }
-keep class proguard.annotation.KeepClassMembers { *; }
-keep class com.razorpay.** { *; }
-keep class com.cashfree.pg.** { *; }

# General keep rules
-dontwarn com.razorpay.**
