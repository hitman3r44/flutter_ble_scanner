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

## Important Command

```bash
flutter upgrade
flutter packages get
```

## Important Links

 - [Flutter Blue Plugin](https://github.com/pauldemarco/flutter_blue)