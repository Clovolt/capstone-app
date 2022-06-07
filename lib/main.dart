import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_waveform/just_waveform.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key,}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Capstone',),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title,}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final player = AudioPlayer();

  bool init = false;
  bool isRecording = false;
  bool isListening = false;
  bool isThereNewRecord = false;
  bool connectionError = false;
  List<int> savedData = [];
  List<int> waveformData = [];
  String state = "Not Recording";
  String filePath = '/storage/emulated/0/Capstone/recordedFile.wav';
  String waveformPath = '/storage/emulated/0/Capstone/waveform1.wave';
  late Socket socket;

  late Duration? fileDuration;
  late Duration? currentDuration;

  double sliderValue = 0.0;

  late Stream<WaveformProgress> progressStream;

  void startRecording() async {

    try {
      socket = await Socket
          .connect('35.198.127.205', 1337);
    } catch (e) {
      setState(() {
        connectionError = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()))
        );
      });
      print('ERROR: $e');

    }

    if (!connectionError) {
      print('connected');

      setState(() {
        state = "Recording";
        isRecording = true;
      });

      socket.listen((List<int> dataStream) {
        savedData.addAll(dataStream);
      });


      await Future.delayed(const Duration(seconds: 10));
      await socket.close();
      print('Disconnected!');
      print("Data length: ${savedData.length}");

      await save(savedData, 44100);
      savedData.clear();

      // Try to load audio from a source and catch any errors.
      try {
        await player.setFilePath(filePath);
        print('Just Audio initialized!');
      } catch (e) {
        print("Error loading audio source: $e");
      }

      setState(() {
        state = "Recording finished and file created successfully!";
        isRecording = false;
      });
    }
  }

  Future<void> save(List<int> data, int sampleRate) async {
    setState(() {
      isThereNewRecord = true;
    });

    File recordedFile = File(filePath);

    List<int> data1 = [];

    for (int i = 0; i < data.length - 1; i+=2) {

      int a = ((data[i + 1] << 8) | (data[i]));


      data1.add(a & 0x00FF);
      data1.add((a & 0xFF00) >> 8);

      if (i >= data.length - 2) break;
    }

    var channels = 1;

    int byteRate = ((16 * sampleRate * channels) / 8).round();

    var size = data.length;

    var fileSize = size + 36;

    Uint16List header = Uint16List.fromList([
      // "RIFF"
      82, 73, 70, 70,
      fileSize & 0xff,
      (fileSize >> 8) & 0xff,
      (fileSize >> 16) & 0xff,
      (fileSize >> 24) & 0xff,
      // WAVE
      87, 65, 86, 69,
      // fmt
      102, 109, 116, 32,
      // fmt chunk size 16
      16, 0, 0, 0,
      // Type of format
      1, 0,
      // One channel
      channels, 0,
      // Sample rate
      sampleRate & 0xff,
      (sampleRate >> 8) & 0xff,
      (sampleRate >> 16) & 0xff,
      (sampleRate >> 24) & 0xff,
      // Byte rate
      byteRate & 0xff,
      (byteRate >> 8) & 0xff,
      (byteRate >> 16) & 0xff,
      (byteRate >> 24) & 0xff,
      // Uhm
      ((16 * channels) / 8).round(), 0,
      // bitsize
      16, 0,
      // "data"
      100, 97, 116, 97,
      size & 0xff,
      (size >> 8) & 0xff,
      (size >> 16) & 0xff,
      (size >> 24) & 0xff,
      ...data1
    ]);
    recordedFile.writeAsBytesSync(header, flush: true);

    progressStream.listen((waveformProgress) {
      if ((100 * waveformProgress.progress).toInt() == 100) print('Progress: %${(100 * waveformProgress.progress).toInt()}');
      if (waveformProgress.waveform != null) {
        waveformData.clear();
        waveformData = waveformProgress.waveform!.data;
      }
    });
  }

  _initPlayer() async {
    // Inform the operating system of our app's audio attributes etc.
    // We pick a reasonable default for an app that plays speech.
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    // Listen to errors during playback.
    player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
          print('A stream error occurred: $e');
        });

    player.durationStream.listen((event) {
      fileDuration = event;
    });

    player.positionStream.listen((event) {
      currentDuration = event;
      setState(() {
        if (currentDuration == player.duration) {
          player.seek(Duration.zero);
          player.stop();
          setState(() {
            isListening = false;
          });
        }
      });
    },);

    // Try to load audio from a source and catch any errors.
    try {
      await player.setFilePath(filePath);
      print('Just Audio initialized!');
    } catch (e) {
      print("Error loading audio source: $e");
    }

    setState(() {
      init = true;
    });
  }

  checkFile () async {
    File newFile = File(filePath);

    bool isFileExist = await newFile.exists();

    if(!isFileExist) {

      var channels = 1;
      int sampleRate = 44100;
      int byteRate = ((16 * sampleRate * channels) / 8).round();

      var size = 0;

      var fileSize = size + 36;

      Uint8List header = Uint8List.fromList([
        // "RIFF"
        82, 73, 70, 70,
        fileSize & 0xff,
        (fileSize >> 8) & 0xff,
        (fileSize >> 16) & 0xff,
        (fileSize >> 24) & 0xff,
        // WAVE
        87, 65, 86, 69,
        // fmt
        102, 109, 116, 32,
        // fmt chunk size 16
        16, 0, 0, 0,
        // Type of format
        1, 0,
        // One channel
        channels, 0,
        // Sample rate
        sampleRate & 0xff,
        (sampleRate >> 8) & 0xff,
        (sampleRate >> 16) & 0xff,
        (sampleRate >> 24) & 0xff,
        // Byte rate
        byteRate & 0xff,
        (byteRate >> 8) & 0xff,
        (byteRate >> 16) & 0xff,
        (byteRate >> 24) & 0xff,
        // Uhm
        ((16 * channels) / 8).round(), 0,
        // bitsize
        16, 0,
        // "data"
        100, 97, 116, 97,
        size & 0xff,
        (size >> 8) & 0xff,
        (size >> 16) & 0xff,
        (size >> 24) & 0xff,
      ]);

      newFile.writeAsBytesSync(header, flush: true);
      print('created');
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkFile();

    _initPlayer();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    progressStream = JustWaveform.extract(
      audioInFile: File(filePath),
      waveOutFile: File(waveformPath),
      zoom: const WaveformZoom.pixelsPerSecond(100),
    );

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: init
      ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              height: 200,
              padding: const EdgeInsets.only(bottom: 50),
              width: double.maxFinite,
              child: StreamBuilder<WaveformProgress>(
                stream: progressStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: Theme.of(context).textTheme.headline6,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  final waveform = snapshot.data?.waveform;
                  if (waveform == null) {
                    return const Center();
                  }
                  return AudioWaveformWidget(
                    waveform: waveform,
                    start: Duration.zero,
                    duration: waveform.duration,
                    strokeWidth: 1.5,
                    pixelsPerStep: 2.5,
                    scale: 75,
                  );
                },
              ),
            ),
            Slider(
              value: fileDuration!.inMilliseconds == 0 ? 0 : currentDuration!.inMilliseconds / fileDuration!.inMilliseconds,
              onChanged: (value) {
                setState(() {
                  player.seek(Duration(milliseconds: (fileDuration!.inMilliseconds * value).toInt()));
                });
              },
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                const Expanded(flex: 1, child: SizedBox(),),
                Expanded(flex: 1, child: IconButton(
                  icon: isListening ? const Icon(Icons.pause) : const Icon(Icons.play_arrow),
                  onPressed: () {
                    if (isListening) {
                      setState(() {
                        isListening = false;
                      });
                      player.stop();
                    } else {
                      setState(() {
                        isListening = true;
                      });
                      player.play();
                    }
                  },
                ),),
                Expanded(flex: 1, child: Row(
                  children: [
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(player.duration! < const Duration(seconds: 1) ? "" : player.duration!.toString().split('.')[0]),
                    ),
                  ],
                ),),
              ],
            ),

          ],
        ),
      )
      : const Center(
          child: SizedBox(
            height: 50,
            width: 50,
            child: CircularProgressIndicator()
          )
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: startRecording,
        label: isRecording
            ? Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(right: 10),
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    )
                  ),
                  const Text('Recording')],
              )
            : const Text('Start recording'),
      ),
    );
  }
}

class AudioWaveformWidget extends StatefulWidget {
  final Color waveColor;
  final double scale;
  final double strokeWidth;
  final double pixelsPerStep;
  final Waveform waveform;
  final Duration start;
  final Duration duration;

  const AudioWaveformWidget({
    Key? key,
    required this.waveform,
    required this.start,
    required this.duration,
    this.waveColor = Colors.blue,
    this.scale = 1.0,
    this.strokeWidth = 5.0,
    this.pixelsPerStep = 8.0,
  }) : super(key: key);

  @override
  _AudioWaveformState createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<AudioWaveformWidget> {
  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: CustomPaint(
        painter: AudioWaveformPainter(
          waveColor: widget.waveColor,
          waveform: widget.waveform,
          start: widget.start,
          duration: widget.duration,
          scale: widget.scale,
          strokeWidth: widget.strokeWidth,
          pixelsPerStep: widget.pixelsPerStep,
        ),
      ),
    );
  }
}

class AudioWaveformPainter extends CustomPainter {
  final double scale;
  final double strokeWidth;
  final double pixelsPerStep;
  final Paint wavePaint;
  final Waveform waveform;
  final Duration start;
  final Duration duration;

  AudioWaveformPainter({
    required this.waveform,
    required this.start,
    required this.duration,
    Color waveColor = Colors.blue,
    this.scale = 1.0,
    this.strokeWidth = 5.0,
    this.pixelsPerStep = 8.0,
  }) : wavePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..strokeCap = StrokeCap.round
    ..color = waveColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (duration == Duration.zero) return;

    double width = size.width;
    double height = size.height;

    final waveformPixelsPerWindow = waveform.positionToPixel(duration).toInt();
    final waveformPixelsPerDevicePixel = waveformPixelsPerWindow / width;
    final waveformPixelsPerStep = waveformPixelsPerDevicePixel * pixelsPerStep;
    final sampleOffset = waveform.positionToPixel(start);
    final sampleStart = -sampleOffset % waveformPixelsPerStep;
    for (var i = sampleStart.toDouble();
    i <= waveformPixelsPerWindow + 1.0;
    i += waveformPixelsPerStep) {
      final sampleIdx = (sampleOffset + i).toInt();
      final x = i / waveformPixelsPerDevicePixel;
      final minY = normalise(waveform.getPixelMin(sampleIdx), height);
      final maxY = normalise(waveform.getPixelMax(sampleIdx), height);
      canvas.drawLine(
        Offset(x + strokeWidth / 2, max(strokeWidth * 0.75, minY)),
        Offset(x + strokeWidth / 2, min(height - strokeWidth * 0.75, maxY)),
        wavePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AudioWaveformPainter oldDelegate) {
    return false;
  }

  double normalise(int s, double height) {
    if (waveform.flags == 0) {
      final y = 32768 + (scale * s).clamp(-32768.0, 32767.0).toDouble();
      return height - 1 - y * height / 65536;
    } else {
      final y = 128 + (scale * s).clamp(-128.0, 127.0).toDouble();
      return height - 1 - y * height / 256;
    }
  }
}
