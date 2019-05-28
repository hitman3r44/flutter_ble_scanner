# Flutter BLE Scanner

Flutter BLE Scanner application.

## Table of Contents

- [Technology](#technology)
- [Instruction](#instruction)
- [Installation](#installation)
- [How to build production app for android & ios](#How_to_build_production_app_for_android_&_ios)
- [Important Command](#important-command)
- [Important Links](#important-links)

## Technology

- Flutter
- Firebase

## Instruction

See the documentation/Mobile Applications.pdf for details information

1. SCAN all nearby BLE devices and show the information as it is in this project
2. If we already save with our custom name show "custom_name" on the top and change the button text
to "EDIT"
3. If we yet not save our custom name tap to "Connect" button and go to second state
4. In the second state show all the information what we get from scanning and add those fields:
    - TextField:
        - Name
        - Password (Validate/ Use password field)
        - Re-Type Password (Validate/ Use password field)
        - Change Password (Validate/ Use password field)
    - Button:
        - Save
        - Edit
    - Toggle Button:
        - Open
        - Close
        - Stop

## Installation

[WRITE DOWN HOW TO INSTALL THIS APPLICATION IN MY LOCAL MACHINE]

## How to build production app for android & ios

[WRITE DOWN ALL THE COMMANDS AND INSTRUCTION TO BUILD PRODUCTION APP]

Review the default App Manifest file AndroidManifest.xml located in <app dir>/android/app/src/main and verify the values are correct, especially:

- `application:` Edit the android:label in the application tag to reflect the final name of the app.

- `uses-permission:` Remove the android.permission.INTERNET permission if your application code does not need Internet access. The standard template includes this tag to enable communication between Flutter tools and a running app.


Review the default Gradle build file file build.gradle located in <app dir>/android/app and verify the values are correct, especially:

- defaultConfig:

   - `applicationId:` Specify the final, unique (Application Id)appid

   - `versionCode & versionName:` Specify the internal app version number, and the version number display string. You can do this by setting the version property in the pubspec.yaml file. Consult the version information guidance in the versions documentation.

   - `minSdkVersion & targetSdkVersion:` Specify the minimum API level, and the API level on which the app is designed to run. Consult the API level section in the versions documentation for details.


To publish on the Play store, you need to give your app a digital signature. Use the following instructions to sign your app.


If you have an existing keystore, skip to the next step. If not, create one by running the following at the command line: keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key

Note: Keep this file private; do not check it into public source control.

Note: keytool might not be in your path. It is part of the Java JDK, which is installed as part of Android Studio. For the concrete path, run flutter doctor -v and see the path printed after ‘Java binary at:’, and then use that fully qualified path replacing java with keytool.


Create a file named <app dir>/android/key.properties that contains a reference to your keystore:
```
storePassword=<password from previous step>
keyPassword=<password from previous step>
keyAlias=key
storeFile=<location of the key store file, e.g. /Users/<user name>/key.jks>
``` 

[Configure Gradle for Signing](https://flutter.dev/docs/deployment/android#configure-signing-in-gradle)


This section describes how to build a release APK. If you completed the signing steps in the previous section, the release APK will be signed.

Using the command line:

1. cd <app dir> (replace <app dir> with your application’s directory).
2. Run flutter build apk (flutter build defaults to --release).
The release APK for your app is created at <app dir>/build/app/outputs/apk/release/app-release.apk.


Follow these steps to install the APK built in the previous step on a connected Android device.

Using the command line:

1. Connect your Android device to your computer with a USB cable.
2. cd <app dir> where <app dir> is your application directory.
3. Run flutter install .

For detailed instructions on publishing the release version of an app to the Google Play Store, 
see the [Google Play publishing documentation](https://developer.android.com/distribute/best-practices/launch).




## Important Command

```bash
flutter upgrade
flutter packages get
```

## Important Links

 - [Flutter Blue Plugin](https://github.com/pauldemarco/flutter_blue)