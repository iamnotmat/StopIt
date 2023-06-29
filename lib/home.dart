import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'main.dart';

void main() {
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

class MainWidget extends StatefulWidget {
  @override
  _MainWidgetState createState() => _MainWidgetState();
}

class _MainWidgetState extends State<MainWidget> {
  List<Workout> workouts = [];

  @override
  void initState() {
    super.initState();
    // fetchWorkouts();
  }

  // void fetchWorkouts() async {
  //   DatabaseHelper databaseHelper = DatabaseHelper();
  //   List<Map<String, dynamic>> workoutMaps = await databaseHelper.getWorkouts();
  //   setState(() {
  //     workouts = workoutMaps.map((map) {
  //       return Workout(
  //         key: UniqueKey(),
  //         index: map['id'],
  //         removeWorkout: removeWorkout,
  //         name: map['name'], // Pass the name from the database
  //       );
  //     }).toList();
  //   });
  // }

  void addWorkout() {
    setState(() {
      workouts.add(Workout(
        key: UniqueKey(),
        index: workouts.length, // Assign the index of the workout
        removeWorkout: removeWorkout,
        name: 'Workout ${workouts.length}',
      ));
    });

    // // Add the workout to the database
    // DatabaseHelper databaseHelper = DatabaseHelper();
    // databaseHelper.initDb().then((db) {
    //   db!.insert(
    //     'workouts',
    //     {
    //       'name': 'Workout ${workouts.length}',
    //     },
    //   );
    // });
  }

  void removeWorkout(Workout workout) {
    setState(() {
      workouts.remove(workout);
    });

    // Remove the workout from the database
    // DatabaseHelper databaseHelper = DatabaseHelper();
    // databaseHelper.deleteWorkout(workout.index);
  }

  void onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final workout = workouts.removeAt(oldIndex);
      workouts.insert(newIndex, workout);
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
                children: workouts.map((workout) {
                  return workout;
                }).toList(),
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
  Workout({
    Key? key,
    required this.index,
    required this.removeWorkout,
    required this.name,
  }) : super(key: key);

  final int index;
  final String name;
  final Function(Workout) removeWorkout;

  @override
  _WorkoutState createState() => _WorkoutState();
}

class _WorkoutState extends State<Workout> {
  bool isExpanded = false;

  void editWorkout() {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //       builder: (context) => EditPage(workoutIndex: widget.index)),
    // );
  }

  void toggleExpansion() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  void removeWorkout() {
    widget.removeWorkout(this.widget);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: widget.key,
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
                Icon(
                  isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                ),
                Text(widget.name),
              ],
            ),
          ),
          if (isExpanded)
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
                    child: Text('Workout Content'),
                  ),
                  IconButton(
                    icon: Icon(Icons.remove_circle),
                    onPressed: removeWorkout,
                  ),
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: editWorkout,
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }
}
