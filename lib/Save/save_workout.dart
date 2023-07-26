import '../main.dart';
import '../edit_workout.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

// Create an instance of GetStorage to use throughout the application
final box = GetStorage();

Future<List<dynamic>> _initWorkoutKeys() async {
  await GetStorage.init(); // Initialize GetStorage

  // Clear storage
  // await box.erase();

  // Return workoutKeys as List<int>
  return box.read('workoutKeys') ?? [];
}

Future<void> loadPersistant(List<Workout> workouts) async {
  List<dynamic> workoutKeys = await _initWorkoutKeys();
  nextWorkoutId = box.read('nextWorkoutId') ?? 0;

  // Clear the existing workouts list to avoid duplicates
  workouts.clear();

  for (String workoutKey in workoutKeys) {
    String? workoutName = box.read('workout${workoutKey}name');
    int? workoutIndex = box.read('workout${workoutKey}index');

    if (workoutName != null && workoutIndex != null) {
      List<WorkoutSet> sets = [];

      for (int i = 0;; i++) {
        String? setName = box.read('workout${workoutKey}set${i}name');
        int? setRepetitions =
            box.read('workout${workoutKey}set${i}repetitions');

        if (setName != null && setRepetitions != null) {
          List<WorkoutInterval> intervals = [];

          for (int j = 0;; j++) {
            String? intervalName =
                box.read('workout${workoutKey}set${i}interval${j}name');
            String? intervalType =
                box.read('workout${workoutKey}set${i}interval${j}type');

            if (intervalName != null) {
              int intervalDuration =
                  box.read('workout${workoutKey}set${i}interval${j}time');
              int intervalReps =
                  box.read('workout${workoutKey}set${i}interval${j}reps');

              // Check if intervalType is null and provide a default value if needed
              String type =
                  intervalType ?? ''; // Change the default value accordingly

              WorkoutInterval interval;
              if (type == 'Time') {
                interval = WorkoutInterval(
                  name: intervalName,
                  type: type,
                  duration: intervalDuration,
                );
              } else {
                interval = WorkoutInterval(
                  name: intervalName,
                  type: type,
                  reps: intervalReps,
                );
              }

              intervals.add(interval);
            } else {
              break;
            }
          }

          WorkoutSet set = WorkoutSet(
            name: setName,
            repetitions: setRepetitions,
            intervals: intervals,
          );
          sets.add(set);
        } else {
          break;
        }
      }

      Workout workout = Workout(
        key: UniqueKey(),
        Id: int.parse(workoutKey),
        name: workoutName,
        index: workoutIndex,
        sets: sets,
      );
      workouts.add(workout);
    }
  }
//  workouts.sort((a, b) => a.index.compareTo(b.index));
}

// Save the workout to the device
Future<void> savePersistant(Workout workout) async {
  final workoutKeys = workouts.map((workout) => workout.Id.toString()).toList();
  await box.write('workoutKeys', workoutKeys);

  await box.write('nextWorkoutId', nextWorkoutId);

  // Save the name of the workout
  await box.write('workout${workout.Id}name', workout.name);

  // Save the index
  await box.write('workout${workout.Id}index', workout.index);

  // Save the sets
  for (int i = 0; i < workout.sets.length; i++) {
    await box.write('workout${workout.Id}set${i}name', workout.sets[i].name);
    await box.write(
        'workout${workout.Id}set${i}repetitions', workout.sets[i].repetitions);

    for (int j = 0; j < workout.sets[i].intervals.length; j++) {
      await box.write('workout${workout.Id}set${i}interval${j}name',
          workout.sets[i].intervals[j].name);

      await box.write('workout${workout.Id}set${i}interval${j}type',
          workout.sets[i].intervals[j].type);

      // Save time
      await box.write('workout${workout.Id}set${i}interval${j}time',
          workout.sets[i].intervals[j].duration!);

      // Save reps
      await box.write('workout${workout.Id}set${i}interval${j}reps',
          workout.sets[i].intervals[j].reps!);
    }
  }
}

Future<void> removePersistant(Workout workout) async {
  final workoutKeys = workouts.map((workout) => workout.Id.toString()).toList();
  await box.write('workoutKeys', workoutKeys);

  await box.remove('workout${workout.Id}name');
  await box.remove('workout${workout.Id}index');

  for (int i = 0; i < workout.sets.length; i++) {
    await box.remove('workout${workout.Id}set${i}name');
    await box.remove('workout${workout.Id}set${i}repetitions');

    for (int j = 0; j < workout.sets[i].intervals.length; j++) {
      await box.remove('workout${workout.Id}set${i}interval${j}name');
      await box.remove('workout${workout.Id}set${i}interval${j}reps');

      await box.remove('workout${workout.Id}set${i}interval${j}type');

      if (workout.sets[i].intervals[j].duration != null) {
        await box.remove('workout${workout.Id}set${i}interval${j}time');
      } else {
        await box.remove('workout${workout.Id}set${i}interval${j}reps');
      }
    }
  }
}

// Remove Set
Future<void> removeSet(Workout workout, WorkoutSet set) async {
  for (int i = 0; i < workout.sets.length; i++) {
    if (workout.sets[i] == set) {
      await box.remove('workout${workout.Id}set${i}name');
      await box.remove('workout${workout.Id}set${i}repetitions');

      for (int j = 0; j < workout.sets[i].intervals.length; j++) {
        await box.remove('workout${workout.Id}set${i}interval${j}name');
        await box.remove('workout${workout.Id}set${i}interval${j}reps');

        await box.remove('workout${workout.Id}set${i}interval${j}type');

        if (workout.sets[i].intervals[j].duration != null) {
          await box.remove('workout${workout.Id}set${i}interval${j}time');
        } else {
          await box.remove('workout${workout.Id}set${i}interval${j}reps');
        }
      }
    }
  }
}

// Remove Interval
Future<void> removeInterval(
    Workout workout, WorkoutSet set, WorkoutInterval interval) async {
  for (int i = 0; i < workout.sets.length; i++) {
    if (workout.sets[i] == set) {
      for (int j = 0; j < workout.sets[i].intervals.length; j++) {
        if (workout.sets[i].intervals[j] == interval) {
          await box.remove('workout${workout.Id}set${i}interval${j}name');
          await box.remove('workout${workout.Id}set${i}interval${j}reps');

          await box.remove('workout${workout.Id}set${i}interval${j}type');

          await box.remove('workout${workout.Id}set${i}interval${j}time');

          await box.remove('workout${workout.Id}set${i}interval${j}reps');
        }
      }
    }
  }
}
