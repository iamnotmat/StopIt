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
      int nextSetId = box.read('workout${workoutKey}nextSetId') ?? 0;
      List<dynamic> setKeys = box.read('workout${workoutKey}setKeys') ?? [];

      for (String setKey in setKeys) {
        String? setName = box.read('workout${workoutKey}set${setKey}name');
        int setId = box.read('workout${workoutKey}set${setKey}id') ?? 0;
        int setIndex = box.read('workout${workoutKey}set${setKey}index') ?? 0;
        int? setRepetitions =
            box.read('workout${workoutKey}set${setKey}repetitions');

        // Load nextIntervalId
        int nextIntervalId =
            box.read('workout${workoutKey}set${setKey}nextIntervalId') ?? 0;

        if (setName != null && setRepetitions != null) {
          List<WorkoutInterval> intervals = [];
          List<dynamic> intervalKeys =
              box.read('workout${workoutKey}set${setKey}intervalKeys') ?? [];

          for (String intervalKey in intervalKeys) {
            int intervalId = box.read(
                'workout${workoutKey}set${setKey}interval${intervalKey}id');
            int intervalIndex = box.read(
                'workout${workoutKey}set${setKey}interval${intervalKey}index');
            String intervalName = box.read(
                'workout${workoutKey}set${setKey}interval${intervalKey}name');
            int intervalDuration = box.read(
                'workout${workoutKey}set${setKey}interval${intervalKey}time');
            int intervalRepetitions = box.read(
                'workout${workoutKey}set${setKey}interval${intervalKey}reps');
            String intervalType = box.read(
                'workout${workoutKey}set${setKey}interval${intervalKey}type');

            WorkoutInterval interval = WorkoutInterval(
                key: UniqueKey(),
                Id: intervalId,
                name: intervalName,
                index: intervalIndex,
                duration: intervalDuration,
                reps: intervalRepetitions,
                type: intervalType);
            intervals.add(interval);
          }
          intervals.sort((a, b) => a.index.compareTo(b.index));

          WorkoutSet set = WorkoutSet(
              key: UniqueKey(),
              Id: setId,
              name: setName,
              repetitions: setRepetitions,
              index: setIndex,
              intervals: intervals,
              nextIntervalId: nextIntervalId);
          sets.add(set);
        } else {
          break;
        }
      }
      sets.sort((a, b) => a.index.compareTo(b.index));

      Workout workout = Workout(
        key: UniqueKey(),
        Id: int.parse(workoutKey),
        name: workoutName,
        index: workoutIndex,
        sets: sets,
        nextSetId: nextSetId,
      );
      workouts.add(workout);
    }
  }
  workouts.sort((a, b) => a.index.compareTo(b.index));
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

  // Save the nextSetId
  await box.write('workout${workout.Id}nextSetId', workout.nextSetId);

  // Save the setKeys
  final setKeys = workout.sets.map((set) => set.Id.toString()).toList();
  await box.write('workout${workout.Id}setKeys', setKeys);

  // Save the set
  for (int i = 0; i < setKeys.length; i++) {
    await box.write(
        'workout${workout.Id}set${setKeys[i]}name', workout.sets[i].name);
    await box.write(
        'workout${workout.Id}set${setKeys[i]}id', workout.sets[i].Id);
    await box.write(
        'workout${workout.Id}set${setKeys[i]}index', workout.sets[i].index);
    await box.write('workout${workout.Id}set${setKeys[i]}repetitions',
        workout.sets[i].repetitions);

    // Save the nextIntervalId
    await box.write('workout${workout.Id}set${setKeys[i]}nextIntervalId',
        workout.sets[i].nextIntervalId);

    // Save the intervalKeys
    final intervalKeys = workout.sets[i].intervals
        .map((interval) => interval.Id.toString())
        .toList();

    await box.write(
        'workout${workout.Id}set${setKeys[i]}intervalKeys', intervalKeys);

    // Save the interval
    for (int j = 0; j < intervalKeys.length; j++) {
      await box.write(
          'workout${workout.Id}set${setKeys[i]}interval${intervalKeys[j]}id',
          workout.sets[i].intervals[j].Id);
      await box.write(
          'workout${workout.Id}set${setKeys[i]}interval${intervalKeys[j]}index',
          workout.sets[i].intervals[j].index);
      await box.write(
          'workout${workout.Id}set${setKeys[i]}interval${intervalKeys[j]}name',
          workout.sets[i].intervals[j].name);
      await box.write(
          'workout${workout.Id}set${setKeys[i]}interval${intervalKeys[j]}type',
          workout.sets[i].intervals[j].type);

      await box.write(
          'workout${workout.Id}set${setKeys[i]}interval${intervalKeys[j]}time',
          workout.sets[i].intervals[j].duration);
      await box.write(
          'workout${workout.Id}set${setKeys[i]}interval${intervalKeys[j]}reps',
          workout.sets[i].intervals[j].reps);
    }
  }
}

Future<void> removePersistant(Workout workout) async {
  final workoutKeys = workouts.map((workout) => workout.Id.toString()).toList();
  await box.write('workoutKeys', workoutKeys);

  await box.remove('workout${workout.Id}name');
  await box.remove('workout${workout.Id}index');
  await box.remove('workout${workout.Id}nextSetId');

  // Save indexes again
  for (int i = 0; i < workouts.length; i++) {
    await box.write('workout${workouts[i].Id}index', i);
  }

  for (int i = 0; i < workout.sets.length; i++) {
    int setId = workout.sets[i].Id;
    await box.remove('workout${workout.Id}set${setId}name');
    await box.remove('workout${workout.Id}set${setId}index');
    await box.remove('workout${workout.Id}set${setId}repetitions');
    await box.remove('workout${workout.Id}set${setId}nextIntervalId');

    for (int j = 0; j < workout.sets[i].intervals.length; j++) {
      int intervalId = workout.sets[i].intervals[j].Id;
      await box
          .remove('workout${workout.Id}set${setId}interval${intervalId}name');
      await box
          .remove('workout${workout.Id}set${setId}interval${intervalId}index');
      await box
          .remove('workout${workout.Id}set${setId}interval${intervalId}type');
      await box
          .remove('workout${workout.Id}set${setId}interval${intervalId}time');
      await box
          .remove('workout${workout.Id}set${setId}interval${intervalId}reps');
    }
  }
}

// Remove Set
Future<void> removeSet(Workout workout, WorkoutSet set) async {
  for (int i = 0; i < workout.sets.length; i++) {
    if (workout.sets[i].Id == set.Id) {
      await box.remove('workout${workout.Id}set${i}name');
      await box.remove('workout${workout.Id}set${i}index');
      await box.remove('workout${workout.Id}set${i}repetitions');
      await box.remove('workout${workout.Id}set${i}nextIntervalId');

      for (int j = 0; j < workout.sets[i].intervals.length; j++) {
        await box.remove('workout${workout.Id}set${i}interval${j}id');
        await box.remove('workout${workout.Id}set${i}interval${j}index');
        await box.remove('workout${workout.Id}set${i}interval${j}name');
        await box.remove('workout${workout.Id}set${i}interval${j}type');
        await box.remove('workout${workout.Id}set${i}interval${j}time');
        await box.remove('workout${workout.Id}set${i}interval${j}reps');
      }
    }
  }

  // Remove from the list
  workout.sets.remove(set);

  final setKeys = workout.sets.map((set) => set.Id.toString()).toList();
  await box.write('workout${workout.Id}setKeys', setKeys);
}

// Remove Interval
Future<void> removeInterval(
    Workout workout, WorkoutSet set, WorkoutInterval interval) async {
  for (int i = 0; i < workout.sets.length; i++) {
    if (workout.sets[i].Id == set.Id) {
      for (int j = 0; j < workout.sets[i].intervals.length; j++) {
        if (workout.sets[i].intervals[j] == interval) {
          await box.remove('workout${workout.Id}set${i}interval${j}id');
          await box.remove('workout${workout.Id}set${i}interval${j}index');
          await box.remove('workout${workout.Id}set${i}interval${j}name');
          await box.remove('workout${workout.Id}set${i}interval${j}type');
          await box.remove('workout${workout.Id}set${i}interval${j}time');
          await box.remove('workout${workout.Id}set${i}interval${j}reps');
        }
      }
      workout.sets[i].intervals.remove(interval);
    }
  }

  final intervalKeys =
      set.intervals.map((interval) => interval.Id.toString()).toList();
  await box.write('workout${workout.Id}set${set.Id}intervalKeys', intervalKeys);
}

// Reorder workouts
Future<void> reorderWorkouts(int oldIndex, int newIndex) async {
  if (newIndex > oldIndex) {
    newIndex -= 1;
  }

  for (int i = 0; i < workouts.length; i++) {
    await box.write('workout${workouts[i].Id}index', i);
  }
}
