import 'package:flutter/material.dart';
import 'edit_workout.dart';
import 'main.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:porcupine_flutter/porcupine.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:porcupine_flutter/porcupine_error.dart';

class PlayWorkoutPage extends StatefulWidget {
  final Key? workoutKey;

  PlayWorkoutPage({this.workoutKey});

  @override
  _PlayWorkoutPageState createState() => _PlayWorkoutPageState();
}

class _PlayWorkoutPageState extends State<PlayWorkoutPage> {
  List<WorkoutSet> sets = [];
  int currentSetIndex = 0;
  int currentSetReps = 0;
  bool isTimerRunning = false;
  bool isTimerPaused = false;
  int secondsRemaining = 0;
  Timer? intervalTimer;
  int currentIntervalIndex = 0;
  bool isRepsInterval = false; // Flag to track "reps" intervals

  // Porcupine variables
  final String accessKey =
      "BIEPMllOI32xRmMX+nphrmhKeKBRq0OXvzULJTqCRLT2Of9IXDkt7g=="; // AccessKey obtained from Picovoice Console (https://console.picovoice.ai/)
  bool isError = false;
  String errorMessage = "";

  bool isDisabled = false;
  bool isProcessing = false;
  Color detectionColour = Color(0xff00e5c3);
  Color defaultColour = Color(0xfff5fcff);
  Color? backgroundColour;
  String currentKeyword = "StopIt";
  PorcupineManager? _porcupineManager;

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
      isDisabled = true;
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
        isDisabled = false;
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
      isDisabled = true;
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
        isDisabled = false;
      });
    }
  }

// Stop processing
  Future<void> _stopProcessing() async {
    setState(() {
      isDisabled = true;
    });

    await _porcupineManager?.stop();

    setState(() {
      isDisabled = false;
      isProcessing = false;
    });
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

// Function called when wake word is detected
  void wakeWordCallback(int keywordIndex) {
    if (keywordIndex >= 0) {
      _stopProcessing();
      proceedToNextInterval();
    }
  }

  /////////////////////////////////////////////////////////////////

  @override
  void initState() {
    super.initState();
    if (widget.workoutKey != null) {
      final Workout? workout = workouts.firstWhere(
        (workout) => workout.key == widget.workoutKey,
        orElse: null,
      );
      if (workout != null) {
        sets = workout.sets;
        if (sets.isNotEmpty && sets[currentSetIndex].intervals.isNotEmpty) {
          currentSetReps = sets[currentSetIndex].repetitions;
        }
      }
    }
    loadNewKeyword(currentKeyword);
  }

  @override
  void dispose() {
    intervalTimer?.cancel();
    _porcupineManager
        ?.delete(); // Cancel Porcupine processing and release resources
    super.dispose();
  }

  void startIntervalTimer() {
    setState(() {
      isTimerRunning = true;
      final currentSet = sets[currentSetIndex];
      if (currentSet.intervals.isEmpty) {
        // No intervals defined, handle the case accordingly
        // For example, you could cancel the timer and perform any necessary actions
        intervalTimer?.cancel();
        proceedToNextInterval();
        return;
      }
      final currentInterval = currentSet.intervals[currentIntervalIndex];
      secondsRemaining = currentInterval.duration;
      isRepsInterval = currentInterval.type == IntervalType.reps;
    });

    // If there's no intervals
    if (sets[currentSetIndex].intervals.isEmpty) {
      // No intervals defined, handle the case accordingly
      // For example, you could cancel the timer and perform any necessary actions
      intervalTimer?.cancel();
      return;
    }

    if (isRepsInterval) {
      intervalTimer?.cancel(); // Cancel the existing timer

      _startProcessing(); // Start listening for the wake word
    } else {
      // For non-"reps" intervals, start the timer as before
      const oneSec = Duration(seconds: 1);
      intervalTimer = Timer.periodic(oneSec, (timer) {
        if (!isTimerPaused) {
          if (secondsRemaining > 0) {
            setState(() {
              secondsRemaining--;
            });
          } else {
            timer.cancel();
            proceedToNextInterval();
          }
        }
      });
    }
  }

  void proceedToNextInterval() {
    setState(() {
      if (isRepsInterval) {
        _stopProcessing();
      } else
        intervalTimer?.cancel();

      if (sets.isEmpty || sets[currentSetIndex].intervals.isEmpty) {
        // No sets available, workout completed
        currentSetIndex = 0;
        currentIntervalIndex = 0;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Workout Completed'),
            content: Text('Congratulations!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else if (currentIntervalIndex <
          sets[currentSetIndex].intervals.length - 1) {
        // Move to the next interval
        currentIntervalIndex++;
        startIntervalTimer();
      } else if (currentSetIndex == sets.length - 1 && currentSetReps > 1) {
        // Repeat the current set
        currentSetReps--;
        currentIntervalIndex = 0;
        startIntervalTimer();
      } else if (currentSetIndex < sets.length - 1) {
        if (currentSetReps > 1) {
          // Repeat the current set
          currentSetReps--;
          currentIntervalIndex = 0;
          startIntervalTimer();
        } else {
          // Move to the next set
          currentSetIndex++;
          currentSetReps = sets[currentSetIndex].repetitions;
          currentIntervalIndex = 0;
          startIntervalTimer();
        }
      } else {
        // Workout completed
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Workout Completed'),
            content: Text('Congratulations!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    });
  }

  void startWorkout() {
    currentSetIndex = 0;
    currentIntervalIndex = 0;
    startIntervalTimer();
  }

  void pauseTimer() {
    setState(() {
      isTimerPaused = true;
    });
  }

  void resumeTimer() {
    setState(() {
      isTimerPaused = false;
    });
  }

  void navigateToPreviousSet() {
    setState(() {
      if (isRepsInterval) {
        _stopProcessing();
      } else
        intervalTimer?.cancel();
      if (currentSetIndex > 0) {
        currentSetIndex--;
        currentIntervalIndex = 0;
        startIntervalTimer();
      }
    });
  }

  void navigateToPreviousInterval() {
    setState(() {
      if (isRepsInterval) {
        _stopProcessing();
      } else
        intervalTimer?.cancel();
      if (currentIntervalIndex > 0) {
        currentIntervalIndex--;
        startIntervalTimer();
      } else if (currentSetIndex > 0) {
        currentSetIndex--;
        currentIntervalIndex = sets[currentSetIndex].intervals.length - 1;
        startIntervalTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Define color constants
    final Color appBarColor = Color(0xFF252525);
    final Color primaryColor = Color(0xFFFF0000);
    final Color accentColor = Color(0xFFAF0404);
    final Color textColor = Color(0xFF414141);

    double progress = 0.0;
    if (sets.isNotEmpty) {
      int currentInterval = 0;

      for (var i = 0;
          i < currentSetIndex && sets[i].intervals.isNotEmpty;
          i++) {
        currentInterval += sets[i].intervals.length;
      }
      currentInterval += currentIntervalIndex + 1;

      int totalIntervals = 0;

      for (var i = 0; i < sets.length && sets[i].intervals.isNotEmpty; i++) {
        totalIntervals += sets[i].intervals.length;
      }

      progress = currentInterval / totalIntervals;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Play Workout'),
        backgroundColor: appBarColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  '${workouts.firstWhere((workout) => workout.key == widget.workoutKey).name}',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.height * 0.03,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text(
                        'Set ${currentSetIndex + 1}/${sets.length}',
                        style: TextStyle(fontSize: 16, color: textColor),
                      ),
                      SizedBox(height: 8),
                      Text(
                        sets.isNotEmpty &&
                                currentSetIndex < sets.length &&
                                sets[currentSetIndex].intervals.isNotEmpty
                            ? 'Interval ${currentIntervalIndex + 1}/${sets[currentSetIndex].intervals.length}'
                            : 'No intervals',
                        style: TextStyle(fontSize: 16, color: textColor),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: navigateToPreviousSet,
                        icon: Icon(Icons.skip_previous),
                        color: primaryColor,
                      ),
                      IconButton(
                        onPressed: navigateToPreviousInterval,
                        icon: Icon(Icons.navigate_before),
                        color: primaryColor,
                      ),
                      IconButton(
                        onPressed: proceedToNextInterval,
                        icon: Icon(Icons.navigate_next),
                        color: primaryColor,
                      ),
                      IconButton(
                        onPressed: proceedToNextInterval,
                        icon: Icon(Icons.skip_next),
                        color: primaryColor,
                      ),
                      SizedBox(width: 16),
                      CircularProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      )
                    ],
                  ),
                ],
              ),
              // Set and Interval name
              SizedBox(height: 50),
              sets.isNotEmpty && currentSetIndex < sets.length
                  ? Center(
                      child: Text(
                      sets[currentSetIndex].name,
                      style: TextStyle(
                          fontSize: MediaQuery.of(context).size.height * 0.03,
                          fontWeight: FontWeight.bold,
                          color: textColor),
                    ))
                  : SizedBox(),
              SizedBox(height: 16),
              sets.isNotEmpty &&
                      currentSetIndex < sets.length &&
                      sets[currentSetIndex].intervals.isNotEmpty &&
                      currentIntervalIndex <
                          sets[currentSetIndex].intervals.length
                  ? Center(
                      child: Text(
                      sets[currentSetIndex]
                          .intervals[currentIntervalIndex]
                          .name,
                      style: TextStyle(
                          fontSize: MediaQuery.of(context).size.height * 0.05,
                          color: textColor),
                    ))
                  : SizedBox(),
              SizedBox(height: 100),
              Center(
                child: isTimerRunning && !isRepsInterval
                    ? Text(
                        secondsRemaining.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.height * 0.1,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      )
                    : SizedBox(),
              ),
              Center(
                child: isTimerRunning && isRepsInterval
                    ? Column(
                        children: [
                          Text(
                            'Reps: ${sets[currentSetIndex].intervals[currentIntervalIndex].reps}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.height * 0.06,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      )
                    : SizedBox(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: sets.isNotEmpty
              ? currentSetIndex == 0 &&
                      currentIntervalIndex == 0 &&
                      !isTimerRunning
                  ? startWorkout
                  : isTimerPaused
                      ? resumeTimer
                      : pauseTimer
              : null,
          child: Text(
            currentSetIndex == 0 && currentIntervalIndex == 0 && !isTimerRunning
                ? 'Start Workout'
                : isTimerPaused
                    ? 'Resume'
                    : 'Pause',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            primary: primaryColor,
            minimumSize: Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
          ),
        ),
      ),
    );
  }
}
