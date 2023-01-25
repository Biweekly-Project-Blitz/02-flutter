import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        textTheme: Typography.whiteMountainView,
        primarySwatch: Colors.green,
        primaryColor: Colors.green,
        backgroundColor: const Color(0xff282d39),
        scaffoldBackgroundColor: const Color(0xff282d39),
      ),
      themeMode: ThemeMode.dark,
      home: const MyHomePage(title: 'A fuckin PHONE APP'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double maxVolume = 0;
  int _counter = 0;
  final recorder = FlutterSoundRecorder();
  bool isRecorderReady = false;

  final streamUpdateMs = 200;

  final maxVolumeDecayPerSec = 5;

  final volumePointSecondsKeep = 5;
  final volumePoints = <FlSpot>[];
  final List<Color> lineColorGradient = [
    const Color(0xff23b6e6),
    const Color(0xff02d39a),
  ];

  @override
  void initState() {
    super.initState();
    volumePoints.add(FlSpot(0, 0));
    initRecorder();
  }

  @override
  void dispose() {
    recorder.closeRecorder();
    super.dispose();
  }

  Future initRecorder() async {
    final status = await Permission.microphone.request();

    if (status != PermissionStatus.granted) {
      throw 'Microphone permission not granted';
    }

    await recorder.openRecorder();

    isRecorderReady = true;
    recorder.setSubscriptionDuration(
      Duration(milliseconds: streamUpdateMs),
    );

    recorder.onProgress?.listen(handleRecordingStream);
  }

  void handleRecordingStream(RecordingDisposition snapshot) {
    final volume = snapshot.decibels ?? 0.0;
    final duration = snapshot.duration.inMilliseconds;

    final volumePointCount = (volumePointSecondsKeep * 1000) / streamUpdateMs;
    while (volumePoints.length > volumePointCount) {
      volumePoints.removeAt(0);
    }

    final newMaxVolume = max(volume, maxVolume - (maxVolumeDecayPerSec * (streamUpdateMs / 1000)));

    setState(() {
      volumePoints.add(FlSpot(duration.toDouble(), volume));
      maxVolume = newMaxVolume;
    });
  }

  Future record() async {
    if (!isRecorderReady) {
      return;
    }

    volumePoints.clear();
    volumePoints.add(FlSpot(0, 0));

    await recorder.startRecorder(toFile: 'audio');
  }

  Future stop() async {
    if (!isRecorderReady) {
      return;
    }

    final path = await recorder.stopRecorder();
    final audioFile = File(path!);
    print("Recorded audio: $audioFile");
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Container(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 20,
                maxY: 75,
                minX: volumePoints.first.x,
                maxX: volumePoints.last.x,
                lineTouchData: LineTouchData(enabled: false),
                clipData: FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                ),
                lineBarsData: [
                  volumeLine(volumePoints),
                ],
                titlesData: FlTitlesData(
                  show: false,
                ),
              ),
              swapAnimationDuration: Duration(milliseconds: 150), // Optional
              swapAnimationCurve: Curves.linear, // Optional
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                StreamBuilder<RecordingDisposition>(
                  stream: recorder.onProgress,
                  builder: (context, snapshot) {
                    final volume = (snapshot.hasData ? snapshot.data!.decibels : 0.0) ?? 0.0;
                    final duration = snapshot.hasData ? snapshot.data!.duration.inMilliseconds : 0.0;

                    return Text("${volume} db");
                  },
                ),
                Text(
                  '${maxVolume.toInt()}',
                  style: Theme.of(context).textTheme.headline4,
                )
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Record',
        child: Icon(recorder.isRecording ? Icons.stop : Icons.mic),
        onPressed: () async {
          if (recorder.isRecording) {
            await stop();
          } else {
            await record();
          }

          setState(() {});
        },
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  LineChartBarData volumeLine(List<FlSpot> points) {
    return LineChartBarData(
      spots: points,
      dotData: FlDotData(
        show: false,
      ),
      gradient: LinearGradient(
        colors: lineColorGradient,
        stops: const [0.1, 1.0],
      ),
      barWidth: 4,
      isCurved: true,
    );
  }
}
