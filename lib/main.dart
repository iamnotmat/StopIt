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
        name: 'Workout ${workouts.length}',
      );
      nextWorkoutId++;
      workouts.add(workout);
      savePersistant(workout);
    });
  }

  void removeWorkout(Workout workout) {
    setState(() {
      workouts.remove(workout);
      removePersistant(workout);
    });
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
                  Icon(
                    Icons.ac_unit, // Replace with your logo icon
                    size: 50,
                    color: Colors.white,
                  ),
                  // Add your settings wheel widget here
                  IconButton(
                    icon: Icon(
                      Icons.settings,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      // Handle settings button press
                    },
                  ),
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

  Workout({
    required Key key, // Add a Key parameter to the constructor
    required this.Id,
    required this.name,
    required this.index,
    List<WorkoutSet>? sets,
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
                            MainWidget.of(context).removeWorkout(widget);
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
                    ],
                  ),
                ),
                SizedBox(
                  height: 8.0,
                ),
                for (var set in widget.sets)
                  SizedBox(
                    width: 150.0, // Specify a fixed height for the container
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
