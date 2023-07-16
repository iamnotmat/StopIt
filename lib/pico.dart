import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';

import 'package:porcupine_flutter/porcupine.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:porcupine_flutter/porcupine_error.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final String accessKey =
      "BIEPMllOI32xRmMX+nphrmhKeKBRq0OXvzULJTqCRLT2Of9IXDkt7g=="; // AccessKey obtained from Picovoice Console (https://console.picovoice.ai/)

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late List<String> _keywords;

  bool isError = false;
  String errorMessage = "";

  bool isButtonDisabled = false;
  bool isProcessing = false;
  Color detectionColour = Color(0xff00e5c3);
  Color defaultColour = Color(0xfff5fcff);
  Color? backgroundColour;
  String currentKeyword = "StopIt";
  PorcupineManager? _porcupineManager;

  @override
  void initState() {
    super.initState();
    setState(() {
      isButtonDisabled = true;
      backgroundColour = defaultColour;
    });
    WidgetsBinding.instance.addObserver(this);

    loadNewKeyword(currentKeyword);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      await _stopProcessing();
      await _porcupineManager?.delete();
      _porcupineManager = null;
    }
  }

// Load new keyword
  Future<void> loadNewKeyword(String keyword) async {
    setState(() {
      isButtonDisabled = true;
    });

    if (isProcessing) {
      await _stopProcessing();
    }

    if (_porcupineManager != null) {
      await _porcupineManager?.delete();
      _porcupineManager = null;
    }
    try {
      var platform = (Platform.isAndroid) ? "android" : "ios";
      var keywordPath = "assets/keywords/$platform/${keyword}_$platform.ppn";

      _porcupineManager = await PorcupineManager.fromKeywordPaths(
          accessKey, [keywordPath], wakeWordCallback);

      setState(() {
        isError = false;
      });
    }
    // Catch errors
    on PorcupineInvalidArgumentException catch (ex) {
      errorCallback(PorcupineInvalidArgumentException(
          "${ex.message}\nEnsure your accessKey '$accessKey' is a valid access key."));
    } on PorcupineActivationException {
      errorCallback(
          PorcupineActivationException("AccessKey activation error."));
    } on PorcupineActivationLimitException {
      errorCallback(PorcupineActivationLimitException(
          "AccessKey reached its device limit."));
    } on PorcupineActivationRefusedException {
      errorCallback(PorcupineActivationRefusedException("AccessKey refused."));
    } on PorcupineActivationThrottledException {
      errorCallback(PorcupineActivationThrottledException(
          "AccessKey has been throttled."));
    } on PorcupineException catch (ex) {
      errorCallback(ex);
    } finally {
      setState(() {
        isButtonDisabled = false;
      });
    }
  }

// Function called when an error occurs
  void errorCallback(PorcupineException error) {
    setState(() {
      isError = true;
      errorMessage = error.message!;
    });
  }

// Function called when the start button is pressed
  Future<void> _startProcessing() async {
    setState(() {
      isButtonDisabled = true;
    });

    if (_porcupineManager == null) {
      await loadNewKeyword(currentKeyword);
    }

    try {
      await _porcupineManager?.start();
      setState(() {
        isProcessing = true;
      });
    } on PorcupineException catch (ex) {
      errorCallback(ex);
    } finally {
      setState(() {
        isButtonDisabled = false;
      });
    }
  }

// Stop processing
  Future<void> _stopProcessing() async {
    setState(() {
      isButtonDisabled = true;
    });

    await _porcupineManager?.stop();

    setState(() {
      isButtonDisabled = false;
      isProcessing = false;
    });
  }

// Build start button
  buildStartButton(BuildContext context) {
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      primary: picoBlue,
      shape: CircleBorder(),
      textStyle: TextStyle(color: Colors.white),
    );

    return Expanded(
      flex: 2,
      child: Container(
        child: SizedBox(
          width: 150,
          height: 150,
          child: ElevatedButton(
            style: buttonStyle,
            onPressed: isProcessing ? _stopProcessing : _startProcessing,
            child: Text(
              isProcessing ? "Stop" : "Start",
              style: TextStyle(fontSize: 30),
            ),
          ),
        ),
      ),
    );
  }

// Build error message
  buildErrorMessage(BuildContext context) {
    return Expanded(
        flex: 1,
        child: Container(
            alignment: Alignment.center,
            margin: EdgeInsets.only(left: 20, right: 20),
            decoration: !isError
                ? null
                : BoxDecoration(
                    color: Colors.red, borderRadius: BorderRadius.circular(5)),
            child: !isError
                ? null
                : Text(
                    errorMessage,
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  )));
  }

  String detectedWord = "";
// Function called when wake word is detected
  void wakeWordCallback(int keywordIndex) {
    if (keywordIndex >= 0) {
      setState(() {
        backgroundColour = detectionColour;
        detectedWord = "Mannaccia a te";
      });
      Future.delayed(const Duration(milliseconds: 1000), () {
        setState(() {
          backgroundColour = defaultColour;
          detectedWord = "";
        });
      });
    }
  }

// Build page
  Color picoBlue = Color.fromRGBO(55, 125, 255, 1);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        key: _scaffoldKey,
        backgroundColor: backgroundColour,
        appBar: AppBar(
          title: const Text('Porcupine Demo'),
          backgroundColor: picoBlue,
        ),
        body: Column(
          children: [
            buildStartButton(context),
            buildErrorMessage(context),
            SizedBox(
                height:
                    20), // Add a spacing between the existing widgets and the detected word
            Text(
              detectedWord, // Display the detected word
              style: TextStyle(fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }
}
