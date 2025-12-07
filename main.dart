import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wakelock/wakelock.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(PomodoroApp());
}

class PomodoroApp extends StatefulWidget {
  @override
  State<PomodoroApp> createState() => _PomodoroAppState();
}

class _PomodoroAppState extends State<PomodoroApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomodoro Video',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.redAccent,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: PomodoroHome(),
    );
  }
}

class PomodoroHome extends StatefulWidget {
  @override
  State<PomodoroHome> createState() => _PomodoroHomeState();
}

class _PomodoroHomeState extends State<PomodoroHome> {
  // Settings
  int workMin = 25;
  int shortMin = 5;
  int longMin = 15;
  int cyclesBeforeLong = 4;
  double volume = 0.8;

  // State
  String phase = 'work';
  int cyclesDone = 0;
  late Timer? timer = null;
  int remainingSec = 0;
  bool running = false;

  // Video
  VideoPlayerController? _controller;
  bool bgMuted = true;
  bool bgLoop = true;
  String? videoPathOrUrl;

  // Notifications
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initNotifications();
    _setupInitialPhase();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);
    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('pomodoro_channel', 'Pomodoro',
            channelDescription: 'Pomodoro notifications',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true);
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, title, body, platformChannelSpecifics);
  }

  void _setupInitialPhase() {
    phase = 'work';
    remainingSec = workMin * 60;
    running = false;
  }

  Future<void> _loadSettings() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      workMin = p.getInt('workMin') ?? 25;
      shortMin = p.getInt('shortMin') ?? 5;
      longMin = p.getInt('longMin') ?? 15;
      cyclesBeforeLong = p.getInt('cyclesBeforeLong') ?? 4;
      volume = p.getDouble('volume') ?? 0.8;
      videoPathOrUrl = p.getString('video') ?? null;
    });
    if (videoPathOrUrl != null) _setVideo(videoPathOrUrl!, autoplay: false);
  }

  Future<void> _saveSettings() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('workMin', workMin);
    await p.setInt('shortMin', shortMin);
    await p.setInt('longMin', longMin);
    await p.setInt('cyclesBeforeLong', cyclesBeforeLong);
    await p.setDouble('volume', volume);
    if (videoPathOrUrl != null) await p.setString('video', videoPathOrUrl!);
  }

  void _startPhase(String newPhase, {bool autoStart = true}) {
    setState(() {
      phase = newPhase;
      remainingSec = (phase == 'work')
          ? workMin * 60
          : (phase == 'short' ? shortMin * 60 : longMin * 60);
      running = autoStart;
    });
    if (running) _startTimer();
    Wakelock.enable();
  }

  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        if (remainingSec > 0) {
          remainingSec--;
        } else {
          _onPhaseEnd();
        }
      });
    });
  }

  void _pauseTimer() {
    timer?.cancel();
    timer = null;
    setState(() {
      running = false;
    });
    Wakelock.disable();
  }

  void _onPhaseEnd() {
    _pauseTimer();
    _playBeep();
    _showNotification('انتهت الفترة', phase == 'work' ? 'حان وقت الاستراحة' : 'حان وقت العمل');
    if (phase == 'work') {
      cyclesDone++;
      if (cyclesDone % cyclesBeforeLong == 0) {
        _startPhase('long', autoStart: true);
      } else {
        _startPhase('short', autoStart: true);
      }
    } else {
      _startPhase('work', autoStart: true);
    }
    _saveSettings();
  }

  void _playBeep() {
    // Simple placeholder: use notification sound; playing custom short tones requires extra packages
  }

  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      String path = result.files.single.path!;
      setState(() {
        videoPathOrUrl = path;
      });
      await _setVideo(path, autoplay: true);
      await _saveSettings();
    }
  }

  Future<void> _setVideo(String src, {bool autoplay = true}) async {
    try {
      if (src.startsWith('http://') || src.startsWith('https://')) {
        _controller?.dispose();
        _controller = VideoPlayerController.network(src);
      } else {
        _controller?.dispose();
        _controller = VideoPlayerController.file(File(src));
      }
      await _controller!.initialize();
      _controller!.setLooping(bgLoop);
      _controller!.setVolume(bgMuted ? 0.0 : 1.0);
      if (autoplay) await _controller!.play();
      setState(() {});
    } catch (e) {
      print('Video error: $e');
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  String _formatTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final percent = ((1 - (remainingSec / ((phase == 'work') ? workMin * 60 : (phase == 'short' ? shortMin * 60 : longMin * 60))) ) * 100).clamp(0,100);
    return Scaffold(
      body: Stack(
        children: [
          // Background video
          if (_controller != null && _controller!.value.isInitialized)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              ),
            )
          else
            Positioned.fill(child: Container(color: Colors.black87)),
          // Overlay
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.45))),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pomodoro Timer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('دورات: $cyclesDone', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  SizedBox(height: 18),
                  // Timer Card
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(phase == 'work' ? 'عمل' : (phase == 'short' ? 'استراحة قصيرة' : 'استراحة طويلة')),
                          SizedBox(height: 12),
                          Text(_formatTime(remainingSec), style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('${percent.toStringAsFixed(0)}%', style: TextStyle(fontSize: 18)),
                          SizedBox(height: 16),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  if (!running) {
                                    if (remainingSec == 0) _startPhase('work', autoStart: true);
                                    else {
                                      setState(() {
                                        running = true;
                                      });
                                      _startTimer();
                                    }
                                  }
                                },
                                child: Text('ابدأ'),
                              ),
                              SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  if (running) _pauseTimer();
                                },
                                child: Text('إيقاف مؤقت'),
                              ),
                              SizedBox(width: 8),
                              OutlinedButton(onPressed: () {
                                _pauseTimer();
                                setState(() {
                                  cyclesDone = 0;
                                  _startPhase('work', autoStart: false);
                                  remainingSec = workMin * 60;
                                });
                              }, child: Text('إعادة')),
                              SizedBox(width: 8),
                              OutlinedButton(onPressed: _onPhaseEnd, child: Text('تخطي')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Settings & Video Controls
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _numberField('مدة العمل (دقائق)', workMin, (v) { setState(() { workMin = v; }); _saveSettings(); }),
                            _numberField('استراحة قصيرة', shortMin, (v) { setState(() { shortMin = v; }); _saveSettings(); }),
                            _numberField('استراحة طويلة', longMin, (v) { setState(() { longMin = v; }); _saveSettings(); }),
                            _numberField('دورات قبل طويلة', cyclesBeforeLong, (v) { setState(() { cyclesBeforeLong = v; }); _saveSettings(); }),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton.icon(onPressed: _pickVideo, icon: Icon(Icons.video_file), label: Text('اختر ملف فيديو')),
                            SizedBox(width: 8),
                            ElevatedButton.icon(onPressed: () async {
                              final url = await _showUrlInput();
                              if (url != null && url.isNotEmpty) {
                                videoPathOrUrl = url;
                                await _setVideo(url, autoplay: true);
                                await _saveSettings();
                              }
                            }, icon: Icon(Icons.link), label: Text('تحميل من رابط')),
                            SizedBox(width: 8),
                            OutlinedButton(onPressed: () {
                              setState(() {
                                bgMuted = !bgMuted;
                                _controller?.setVolume(bgMuted ? 0.0 : 1.0);
                              });
                            }, child: Text(bgMuted ? 'إلغاء الكتم' : 'كتم')),
                            SizedBox(width: 8),
                            OutlinedButton(onPressed: () {
                              setState(() {
                                bgLoop = !bgLoop;
                                _controller?.setLooping(bgLoop);
                              });
                            }, child: Text(bgLoop ? 'إيقاف التكرار' : 'تكرار')),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Text('مستوى الصوت'),
                            Expanded(
                              child: Slider(value: volume, min: 0.0, max: 1.0, onChanged: (v){ setState(()=> volume=v); _saveSettings();}),
                            )
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(onPressed: () { _saveSettings(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم الحفظ'))); }, child: Text('حفظ الإعدادات')),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _numberField(String label, int value, Function(int) onChanged) {
    final ctrl = TextEditingController(text: value.toString());
    return Container(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          SizedBox(height: 6),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            onSubmitted: (s) {
              final v = int.tryParse(s) ?? value;
              onChanged(v);
            },
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(),
            ),
          )
        ],
      ),
    );
  }

  Future<String?> _showUrlInput() async {
    String url = '';
    return await showDialog<String>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('أدخل رابط الفيديو'),
          content: TextField(
            onChanged: (v) => url = v,
            decoration: InputDecoration(hintText: 'https://...'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, null), child: Text('إلغاء')),
            TextButton(onPressed: () => Navigator.pop(context, url), child: Text('تحميل')),
          ],
        );
      }
    );
  }
}
