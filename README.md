name: pomodoro_app
description: تطبيق Pomodoro احترافي مع خلفية فيديو وإشعارات
publish_to: 'none' # لمنع النشر على pub.dev

version: 1.0.0+1

environment:
  sdk: ">=2.19.0 <3.0.0"
  flutter: ">=3.0.0"

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2
  shared_preferences: ^2.1.1
  flutter_local_notifications: ^13.0.0
  video_player: ^2.6.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.1

flutter:
  uses-material-design: true

  assets:
    - assets/video.mp4
