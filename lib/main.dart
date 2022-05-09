import 'dart:ffi';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_waveform/just_waveform.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';
import 'package:capstone_app/cantinaBandTest.dart';



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
  bool connectionError = false;
  List<int> savedData = [];
  String state = "Not Recording";
  late Socket socket;

  late Duration? fileDuration;
  late Duration? currentDuration;
  double sliderValue = 0.0;

  void startRecording() async {

    try {
      socket = await Socket
          .connect('3.121.188.154', 1337);
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
        print(dataStream);
        savedData.addAll(dataStream);
      });


      await Future.delayed(const Duration(seconds: 5));
      await socket.close();
      print('Disconnected!');
      print("Data length: ${savedData.length}");
      //print(savedData);
      await save(savedData, 44100);
      savedData.clear();

      // Try to load audio from a source and catch any errors.
      try {
        await player.setFilePath("/storage/emulated/0/Capstone/recordedFile.wav");
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
    File recordedFile = File("/storage/emulated/0/Capstone/recordedFile.wav");

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
      ...data
    ]);
    recordedFile.writeAsBytesSync(header, flush: true);

    /////////
    File recordedFile2 = File("/storage/emulated/0/Capstone/recordedFile2.wav");

    List<int> data2 = [];

    for (int i = 0; i < data.length; i++) {
      data2.add(data[i] * 2);
    }

    var size2 = data2.length;

    var fileSize2 = size2 + 36;

    Uint16List header2 = Uint16List.fromList([
      // "RIFF"
      82, 73, 70, 70,
      fileSize2 & 0xff,
      (fileSize2 >> 8) & 0xff,
      (fileSize2 >> 16) & 0xff,
      (fileSize2 >> 24) & 0xff,
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
      size2 & 0xff,
      (size2 >> 8) & 0xff,
      (size2 >> 16) & 0xff,
      (size2 >> 24) & 0xff,
      ...data2
    ]);
    recordedFile2.writeAsBytesSync(header2, flush: true);

    /////////
    File recordedFile3 = File("/storage/emulated/0/Capstone/recordedFile3.wav");

    List<int> data3 = [];

    for (int i = 0; i < data.length; i+=2) {
      int a = ((data[i] << 8) | data[i+1]);
      data3.add(a);
    }

    var size3 = data3.length;

    var fileSize3 = size3 + 36;

    sampleRate = (sampleRate / 2).round();



    Uint16List header3 = Uint16List.fromList([
      // "RIFF"
      82, 73, 70, 70,
      fileSize3 & 0xff,
      (fileSize3 >> 8) & 0xff,
      (fileSize3 >> 16) & 0xff,
      (fileSize3 >> 24) & 0xff,
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
      size3 & 0xff,
      (size3 >> 8) & 0xff,
      (size3 >> 16) & 0xff,
      (size3 >> 24) & 0xff,
      ...data3
    ]);
    recordedFile3.writeAsBytesSync(header3, flush: true);

    print(data[data.length-2]);
    print(data[data.length-1]);
    print(data3[data3.length-1]);

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
        //print(Duration(milliseconds: (fileDuration!.inMilliseconds * (currentDuration!.inMilliseconds / fileDuration!.inMilliseconds)).toInt()).toString());
        print(player.position);

        if (currentDuration == player.duration) {
          player.seek(Duration.zero);
          player.stop();
          setState(() {
            isListening = false;
          });
        }
      });
    },);

    player.setVolume(1);

    // Try to load audio from a source and catch any errors.
    try {
      await player.setFilePath("/storage/emulated/0/Capstone/recordedFile.wav");
      print('Just Audio initialized!');
    } catch (e) {
      print("Error loading audio source: $e");
    }

    setState(() {
      init = true;
    });
  }

  checkFile () async {
    File newFile = File("/storage/emulated/0/Capstone/recordedFile.wav");

    bool isFileExist = await newFile.exists();

    print(isFileExist);

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
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: init
      ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
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
                      child: Text(player.duration!.toString().split('.')[0]),
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
