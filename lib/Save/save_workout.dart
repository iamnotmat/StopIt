import '../main.dart';
import '../edit_workout.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class saveWorkout {
  static late SharedPreferences prefs;

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }

  // Save the workout to the device
  static Future<void> save(Key? key) {
    Workout workout = workouts.firstWhere((element) => element.key == key);

    // Save the name of the workout
    prefs.setString('workout${workout.key}name', workout.name);

    // Save the index
    prefs.setInt('workout${workout.key}index', workout.index);

    // Save the sets
    for (int i = 0; i < workout.sets.length; i++) {
      prefs.setString('workout${workout.key}set${i}name', workout.sets[i].name);
      prefs.setInt('workout${workout.key}set${i}repetitions',
          workout.sets[i].repetitions);

      for (int j = 0; j < workout.sets[i].intervals.length; j++) {
        prefs.setString('workout${workout.key}set${i}interval${j}name',
            workout.sets[i].intervals[j].name);

        // Save repetitions
        prefs.setInt('workout${workout.key}set${i}interval${j}repetitions',
            workout.sets[i].intervals[j].repetitions);

        if (workout.sets[i].intervals[j].duration != null) {
          // Save time
          prefs.setInt('workout${workout.key}set${i}interval${j}time',
              workout.sets[i].intervals[j].duration);
        } else {
          // Save reps
          prefs.setInt('workout${workout.key}set${i}interval${j}reps',
              workout.sets[i].intervals[j].reps);
        }
      }
    }

    return Future.value();
  }
}
