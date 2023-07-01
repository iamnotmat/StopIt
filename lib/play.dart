import 'dart:async';

import 'package:flutter/material.dart';
import 'edit_workout.dart';
import 'main.dart';

class PlayWorkoutPage extends StatefulWidget {
  final Workout workout;

  PlayWorkoutPage({required this.workout});

  @override
  _PlayWorkoutPageState createState() => _PlayWorkoutPageState();
}

class _PlayWorkoutPageState extends State<PlayWorkoutPage> {
  int currentSetIndex = 0;
  int currentIntervalIndex = 0;
  bool isTimerRunning = false;
  int timerDuration = 0;
  Timer? timer;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startTimer(int duration) {
    timer?.cancel();
    setState(() {
      isTimerRunning = true;
      timerDuration = duration;
    });

    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (timerDuration > 0) {
          timerDuration--;
        } else {
          if (currentIntervalIndex <
              widget.workout.sets[currentSetIndex].intervals.length - 1) {
            currentIntervalIndex++;
            timerDuration = widget.workout.sets[currentSetIndex]
                .intervals[currentIntervalIndex].duration;
          } else {
            if (currentSetIndex < widget.workout.sets.length - 1) {
              currentSetIndex++;
              currentIntervalIndex = 0;
              timerDuration = widget.workout.sets[currentSetIndex]
                  .intervals[currentIntervalIndex].duration;
            } else {
              stopTimer();
            }
          }
        }
      });
    });
  }

  void stopTimer() {
    timer?.cancel();
    setState(() {
      isTimerRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Handle the case where the workout has no sets
    if (widget.workout.sets.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.workout.name),
        ),
        body: Center(
          child: Text('No sets in this workout'),
        ),
      );
    }

    final currentSet = widget.workout.sets[currentSetIndex];
    final currentInterval = currentSet.intervals[currentIntervalIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workout.name),
      ),
      body: ListView.builder(
        itemCount: widget.workout.sets.length,
        itemBuilder: (context, index) {
          final set = widget.workout.sets[index];
          return ListTile(
            title: Text('Set ${index + 1}: ${set.name}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Repetitions: ${set.repetitions}'),
                Text('Intervals:'),
                for (var interval in set.intervals)
                  ListTile(
                    title: Text(interval.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Type: ${interval.type == IntervalType.time ? "Time" : "Reps"}'),
                        if (interval.type == IntervalType.time)
                          Text('Duration: ${interval.duration} seconds'),
                        if (interval.type == IntervalType.reps)
                          Text('Reps: ${interval.reps}'),
                        if (interval == currentInterval)
                          Column(
                            children: [
                              if (interval.type == IntervalType.time)
                                Text(
                                  'Time Remaining: $timerDuration seconds',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              if (interval.type == IntervalType.reps)
                                Text(
                                  'Reps Remaining: ${interval.reps}',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: isTimerRunning
                                    ? stopTimer
                                    : () => startTimer(interval.duration),
                                child: Text(isTimerRunning ? 'Stop' : 'Start'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
