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
  int currentIntervalIndex = 0;
  bool isTimerRunning = false;
  bool isTimerPaused = false;
  int secondsRemaining = 0;
  Timer? intervalTimer;
  bool isRepsInterval = false; // Flag to track "reps" intervals

  @override
  void initState() {
    super.initState();
    // Assuming you have a workouts list with Workout objects
    if (widget.workoutKey != null) {
      final Workout? workout = workouts.firstWhere(
        (workout) => workout.key == widget.workoutKey,
        orElse: null,
      );
      if (workout != null) {
        sets = workout.sets;
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
      final currentInterval =
          sets[currentSetIndex].intervals[currentIntervalIndex];
      secondsRemaining = currentInterval.duration;
      isRepsInterval = currentInterval.type == IntervalType.reps;
    });

    intervalTimer?.cancel(); // Cancel the existing timer

    if (!isRepsInterval) {
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
      if (currentIntervalIndex < sets[currentSetIndex].intervals.length - 1) {
        // Move to the next interval
        currentIntervalIndex++;
        startIntervalTimer();
      } else if (currentSetIndex < sets.length - 1) {
        // Move to the next set
        currentSetIndex++;
        currentIntervalIndex = 0;
        startIntervalTimer();
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
      if (currentSetIndex > 0) {
        currentSetIndex--;
        currentIntervalIndex = 0;
        startIntervalTimer();
      }
    });
  }

  void navigateToNextSet() {
    setState(() {
      if (currentSetIndex < sets.length - 1) {
        currentSetIndex++;
        currentIntervalIndex = 0;
        startIntervalTimer();
      }
    });
  }

  void navigateToPreviousInterval() {
    setState(() {
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
      if (currentIntervalIndex < sets[currentSetIndex].intervals.length - 1) {
        currentIntervalIndex++;
        startIntervalTimer();
      } else if (currentSetIndex < sets.length - 1) {
        currentSetIndex++;
        currentIntervalIndex = 0;
        startIntervalTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Play Workout'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workout Name',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text(
                      'Set ${currentSetIndex + 1}/${sets.length}',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Interval ${currentIntervalIndex + 1}/${sets[currentSetIndex].intervals.length}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: navigateToPreviousSet,
                      icon: Icon(Icons.skip_previous),
                    ),
                    IconButton(
                      onPressed: navigateToPreviousInterval,
                      icon: Icon(Icons.navigate_before),
                    ),
                    IconButton(
                      onPressed: navigateToNextInterval,
                      icon: Icon(Icons.navigate_next),
                    ),
                    IconButton(
                      onPressed: navigateToNextSet,
                      icon: Icon(Icons.skip_next),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            isTimerRunning && !isRepsInterval
                ? Text(
                    secondsRemaining.toString(),
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  )
                : SizedBox(),
            isTimerRunning && isRepsInterval
                ? Text(
                    'Reps: ${secondsRemaining.toString()}',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  )
                : SizedBox(),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: isTimerRunning ? pauseTimer : startWorkout,
              child: Text(isTimerRunning ? 'Pause' : 'Start Workout'),
            ),
            SizedBox(height: 16),
            isTimerPaused
                ? ElevatedButton(
                    onPressed: resumeTimer,
                    child: Text('Resume'),
                  )
                : SizedBox(),
          ],
        ),
      ),
    );
  }
}
