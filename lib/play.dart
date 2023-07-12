import 'dart:async';
import 'package:flutter/material.dart';
import 'edit_workout.dart';
import 'main.dart';

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
        if (sets.isNotEmpty) {
          currentSetReps = sets[currentSetIndex].repetitions;
        }
      }
    }
  }

  @override
  void dispose() {
    intervalTimer?.cancel();
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
      if (sets.isEmpty) {
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
      // Stop timer if it's running
      intervalTimer?.cancel();
      if (currentSetIndex > 0) {
        currentSetIndex--;
        currentIntervalIndex = 0;
        startIntervalTimer();
      }
    });
  }

  void navigateToNextSet() {
    setState(() {
      // Stop timer if it's running
      intervalTimer?.cancel();
      if (currentSetReps > 1) {
        currentSetReps--;
        currentIntervalIndex = 0;
        startIntervalTimer();
      } else if (currentSetIndex < sets.length - 1) {
        currentSetIndex++;
        currentSetReps = sets[currentSetIndex].repetitions;
        currentIntervalIndex = 0;
        startIntervalTimer();
      }
    });
  }

  void navigateToPreviousInterval() {
    setState(() {
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

  void navigateToNextInterval() {
    setState(() {
      intervalTimer?.cancel();
      if (currentIntervalIndex < sets[currentSetIndex].intervals.length - 1) {
        currentIntervalIndex++;
        startIntervalTimer();
      } else if (currentSetReps > 1) {
        currentSetReps--;
        currentIntervalIndex = 0;
        startIntervalTimer();
      } else if (currentSetIndex < sets.length - 1) {
        currentSetIndex++;
        currentSetReps = sets[currentSetIndex].repetitions;
        currentIntervalIndex = 0;
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
              Text(
                '${workouts.firstWhere((workout) => workout.key == widget.workoutKey).name}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
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
                        sets.isNotEmpty && currentSetIndex < sets.length
                            ? 'Interval ${currentIntervalIndex + 1}/${sets[currentSetIndex].intervals.length}'
                            : 'No intervals available',
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
                        onPressed: navigateToNextInterval,
                        icon: Icon(Icons.navigate_next),
                        color: primaryColor,
                      ),
                      IconButton(
                        onPressed: navigateToNextSet,
                        icon: Icon(Icons.skip_next),
                        color: primaryColor,
                      ),
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
                    ? Text(
                        'Reps: ${sets[currentSetIndex].intervals[currentIntervalIndex].reps}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: MediaQuery.of(context).size.height * 0.06,
                            fontWeight: FontWeight.bold,
                            color: textColor),
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
