import 'package:flutter/material.dart';
import 'Save/save_workout.dart';
import 'edit_workout.dart';
import 'play.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await loadPersistant(workouts); // Load workouts from SharedPreferences

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainWidget(),
    );
  }
}

List<Workout> workouts = [];
int nextWorkoutId = 0; // Track the next available workout ID

class MainWidget extends StatefulWidget {
  @override
  _MainWidgetState createState() => _MainWidgetState();

  static _MainWidgetState of(BuildContext context) =>
      context.findAncestorStateOfType<_MainWidgetState>()!;
}

class _MainWidgetState extends State<MainWidget> {
  @override
  void initState() {
    super.initState();
    loadPersistant(workouts);
  }

  void addWorkout() {
    setState(() {
      final workout = Workout(
        key: UniqueKey(),
        Id: nextWorkoutId,
        index: workouts.length,
        name: 'Workout ${nextWorkoutId + 1}',
        sets: [],
        nextSetId: 0,
      );
      nextWorkoutId++;
      workouts.add(workout);
      savePersistant(workout);
    });
  }

  void duplicateWorkout(BuildContext context, Workout workout) {
    setState(() {
      final duplicatedWorkout = Workout(
        key: UniqueKey(),
        Id: nextWorkoutId,
        index: workouts.length,
        name: 'Workout ${nextWorkoutId + 1}',
        sets: List.from(workout.sets),
        nextSetId: workout.nextSetId,
      );
      nextWorkoutId++;
      workouts.add(duplicatedWorkout);
      savePersistant(duplicatedWorkout);
    });
  }

  void removeWorkout(BuildContext context, Workout workout) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Theme(
          data: ThemeData.dark().copyWith(
            // Define the background color for the AlertDialog
            scaffoldBackgroundColor: Colors.grey[800],
            // Define the primary color (text and buttons) for the AlertDialog
            primaryColor: Colors.orange,
            // Define the accent color (used for secondary button color)
            hintColor: Colors.orange,
            // Define the shape of the AlertDialog (rounded corners)
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
          child: AlertDialog(
            title: Text('Confirm Removal'),
            content: Text('Are you sure you want to remove this workout?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the alert dialog
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    workouts.remove(workout);
                    removePersistant(workout);
                  });
                  Navigator.of(context).pop(); // Close the alert dialog
                },
                child: Text('Remove'),
              ),
            ],
          ),
        );
      },
    );
  }

  void onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final workout = workouts.removeAt(oldIndex);
      workouts.insert(newIndex, workout);
      for (var i = 0; i < workouts.length; i++) {
        workouts[i].index = i;
      }
      reorderWorkouts(oldIndex, newIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: EdgeInsets.all(16.0),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color(0xff252525),
        ),
        child: Column(
          children: [
            Container(
              height:
                  100, // Adjust the height as needed for the logo and settings wheel
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Add your logo widget here
                  Image.asset(
                    'assets/Logo.png',
                    width: 80,
                    height: 50,
                  ),

                  // // Add your settings wheel widget here
                  // IconButton(
                  //   icon: Icon(
                  //     Icons.settings,
                  //     color: Colors.white,
                  //   ),
                  //   onPressed: () {
                  //     // Handle settings button press
                  //   },
                  // ),
                ],
              ),
            ),
            SizedBox(
                height: 16.0), // Add spacing between the header and the list
            Expanded(
              child: ReorderableListView(
                onReorder: onReorder,
                children: workouts,
              ),
            ),
            SizedBox(
                height: 16.0), // Add spacing between the list and the button
            SizedBox(
              width: double.infinity, // Make the button occupy the entire width
              child: ElevatedButton(
                onPressed: addWorkout,
                child: Text(
                  'Add Workout',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[850],
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  primary: Colors.orange[900],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Workout extends StatefulWidget {
  final int Id;
  String name;
  int index;
  final List<WorkoutSet> sets;
  int nextSetId;

  Workout({
    required Key key, // Add a Key parameter to the constructor
    required this.Id,
    required this.name,
    required this.index,
    List<WorkoutSet>? sets,
    required this.nextSetId,
  })  : sets = sets ?? [],
        super(key: key); // Pass the key to the super constructor

  @override
  _WorkoutState createState() => _WorkoutState();
}

class _WorkoutState extends State<Workout> {
  bool isExpanded = false;

  void editWorkout(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutDesignPage(workoutId: widget.Id),
      ),
    );
  }

  void playWorkout(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayWorkoutPage(workoutId: widget.Id),
      ),
    );
  }

  void toggleExpansion() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(8.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.orange[800],
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: toggleExpansion,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isExpanded)
            Column(
              children: [
                Container(
                  margin: EdgeInsets.only(top: 8.0),
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: IconButton(
                          icon: Icon(Icons.remove_circle),
                          onPressed: () {
                            // Call the removeWorkout method from the parent widget
                            // and pass the workout to be removed.
                            MainWidget.of(context)
                                .removeWorkout(context, widget);
                          },
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            editWorkout(context, widget.index);
                          },
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: IconButton(
                          icon: Icon(Icons.play_arrow),
                          onPressed: () {
                            playWorkout(context, widget.index);
                          },
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: IconButton(
                          icon:
                              Icon(Icons.copy), // Add the copy (duplicate) icon
                          onPressed: () {
                            // Call the duplicateWorkout method from the parent widget
                            // and pass the workout to be duplicated.
                            MainWidget.of(context)
                                .duplicateWorkout(context, widget);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 8.0,
                ),
                for (var set in widget.sets)
                  SizedBox(
                    width: 200.0, // Specify a fixed width for the container
                    child: Container(
                      margin: EdgeInsets.only(top: 8.0),
                      padding: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Text('$set'),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
