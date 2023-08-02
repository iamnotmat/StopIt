import 'package:flutter/material.dart';
import 'Save/save_workout.dart';
import 'main.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workout App',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: WorkoutDesignPage(workoutId: 0),
    );
  }
}

List<WorkoutSet> sets = []; // Initialize the sets list
int _workoutId = 0;

class WorkoutDesignPage extends StatefulWidget {
  final int workoutId; // Add the workout index parameter

  WorkoutDesignPage({required this.workoutId});

  @override
  _WorkoutDesignPageState createState() => _WorkoutDesignPageState();
}

class _WorkoutDesignPageState extends State<WorkoutDesignPage> {
  TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Retrieve the selected workout using the provided workout index
    final selectedWorkout =
        workouts.firstWhere((workout) => workout.Id == widget.workoutId);
    // Initialize the sets list with the sets from the selected workout
    sets = selectedWorkout.sets.cast<WorkoutSet>();
    nameController.text = selectedWorkout.name;

    _workoutId = widget.workoutId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize:
            Size.fromHeight(80), // Set the preferred height of the AppBar
        child: AppBar(
          title: Align(
            alignment:
                Alignment.bottomLeft, // Align the label to the bottom left
            child: TextFormField(
              controller: nameController,
              style: TextStyle(
                color: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  workouts
                      .firstWhere((workout) => workout.Id == widget.workoutId)
                      .name = value;
                  savePersistant(workouts
                      .firstWhere((workout) => workout.Id == widget.workoutId));
                });
              },
              decoration: InputDecoration(
                labelText: 'Workout Name',
                labelStyle: TextStyle(color: Colors.white),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFff0000)),
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFaf0404)),
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 5, horizontal: 20),
              ),
            ),
          ),
          toolbarHeight: 60, // Reduce the height of the AppBar
          backgroundColor: Color(0xFF252525),
        ),
      ),
      body: ReorderableListView(
        padding: EdgeInsets.symmetric(vertical: 10),
        children: sets
            .asMap()
            .map((index, set) => MapEntry(
                  index,
                  SetWidget(
                    key: UniqueKey(),
                    set: set,
                    workoutId: widget.workoutId, // Pass the workoutId parameter
                    onDelete: () {
                      setState(() {
                        removeSet(
                            workouts.firstWhere(
                                (workout) => workout.Id == widget.workoutId),
                            set);
                      });
                    },
                  ),
                ))
            .values
            .toList(),
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final set = sets.removeAt(oldIndex);
            sets.insert(newIndex, set);
            for (int i = 0; i < sets.length; i++) {
              sets[i].index = i;
            }
            savePersistant(workouts
                .firstWhere((workout) => workout.Id == widget.workoutId));
          });
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            sets.add(WorkoutSet(
                key: UniqueKey(),
                Id: workouts
                    .firstWhere((workout) => workout.Id == widget.workoutId)
                    .nextSetId,
                index: sets.length,
                nextIntervalId: 0));
            workouts
                .firstWhere((workout) => workout.Id == widget.workoutId)
                .nextSetId++;
            savePersistant(workouts
                .firstWhere((workout) => workout.Id == widget.workoutId));
          });
        },
        child: Icon(Icons.add),
        backgroundColor: Color(0xFFFF0000),
      ),
      backgroundColor: Color(0xFF414141),
    );
  }
}

class WorkoutSet {
  final int Id;
  int index;
  String name = '';
  List<WorkoutInterval> intervals = [];
  int repetitions = 1;
  int nextIntervalId = 0;

  WorkoutSet(
      {required Key key,
      required this.Id,
      required this.index,
      this.name = '',
      this.repetitions = 1,
      List<WorkoutInterval>? intervals,
      required this.nextIntervalId})
      : intervals = intervals ?? [];

  WorkoutSet.fromJson(Map<String, dynamic> json)
      : Id = json['Id'],
        index = json['index'],
        name = json['name'],
        intervals = json['intervals']
            .map<WorkoutInterval>(
                (interval) => WorkoutInterval.fromJson(interval))
            .toList(),
        repetitions = json['repetitions'],
        nextIntervalId = json['nextIntervalId'];

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'intervals': intervals.map((interval) => interval.toJson()).toList(),
      'repetitions': repetitions,
    };
  }

  @override
  String toString() {
    String intervalsText = '';
    for (WorkoutInterval interval in intervals) {
      intervalsText += '   • ${interval.toString()}\n';
    }
    return '• $name (x$repetitions)\n$intervalsText';
  }
}

class SetWidget extends StatefulWidget {
  final Key? key;
  final WorkoutSet set;
  final int workoutId; // Add the workoutId parameter
  final VoidCallback onDelete;

  const SetWidget({
    this.key,
    required this.set,
    required this.workoutId, // Pass the workoutId parameter
    required this.onDelete,
  });

  @override
  _SetWidgetState createState() => _SetWidgetState();
}

class _SetWidgetState extends State<SetWidget> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _repetitionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.set.name;
    _repetitionsController.text = widget.set.repetitions.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      key: UniqueKey(),
      margin: EdgeInsets.all(10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      color: Color(0xFF252525),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: TextFormField(
              controller: _nameController,
              style: TextStyle(color: Colors.white),
              onChanged: (value) {},
              onEditingComplete: () {
                setState(() {
                  widget.set.name = _nameController.text;
                  savePersistant(workouts
                      .firstWhere((workout) => workout.Id == widget.workoutId));
                });
              },
              decoration: InputDecoration(
                labelText: 'Set Name',
                labelStyle: TextStyle(color: Colors.white),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFff0000)),
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFaf0404)),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.white),
              onPressed: () {
                setState(() {
                  widget.onDelete();
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Repetitions:',
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(width: 10),
              IconButton(
                icon: Icon(Icons.remove, color: Colors.white),
                onPressed: () {
                  setState(() {
                    if (widget.set.repetitions > 0) {
                      widget.set.repetitions--;
                      _repetitionsController.text =
                          widget.set.repetitions.toString();
                    }
                    savePersistant(workouts.firstWhere(
                        (workout) => workout.Id == widget.workoutId));
                  });
                },
              ),
              SizedBox(
                width: 50,
                child: TextFormField(
                  textAlign: TextAlign.center,
                  controller: _repetitionsController,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      widget.set.repetitions = int.tryParse(value) ?? 1;
                      savePersistant(workouts.firstWhere(
                          (workout) => workout.Id == widget.workoutId));
                    });
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Color(0xFF414141),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  setState(() {
                    widget.set.repetitions++;
                    _repetitionsController.text =
                        widget.set.repetitions.toString();
                    savePersistant(workouts.firstWhere(
                        (workout) => workout.Id == widget.workoutId));
                  });
                },
              ),
            ],
          ),
          ReorderableListView(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: widget.set.intervals
                .asMap()
                .map((index, interval) => MapEntry(
                      index,
                      IntervalWidget(
                        key: UniqueKey(),
                        interval: interval,
                        onDelete: () {
                          setState(() {
                            removeInterval(
                                workouts.firstWhere((workout) =>
                                    workout.Id == widget.workoutId),
                                widget.set,
                                interval);
                          });
                        },
                      ),
                    ))
                .values
                .toList(),
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final interval = widget.set.intervals.removeAt(oldIndex);
                widget.set.intervals.insert(newIndex, interval);

                for (int i = 0; i < widget.set.intervals.length; i++) {
                  widget.set.intervals[i].index = i;
                }
                savePersistant(workouts
                    .firstWhere((workout) => workout.Id == widget.workoutId));
              });
            },
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  WorkoutInterval interval = WorkoutInterval(
                    key: UniqueKey(),
                    Id: widget.set.nextIntervalId,
                    index: widget.set.intervals.length,
                  );
                  widget.set.intervals.add(interval);
                  widget.set.nextIntervalId++;
                  savePersistant(workouts
                      .firstWhere((workout) => workout.Id == widget.workoutId));
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFaf0404),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Add Interval'),
            ),
          ),
        ],
      ),
    );
  }
}

class WorkoutInterval {
  int Id;
  int index;
  String name = '';
  String type = "Time";
  int duration = 0; // in seconds
  int reps = 0;

  WorkoutInterval({
    required Key key,
    required this.Id,
    required this.index,
    this.type = "Time",
    this.duration = 0,
    this.reps = 0,
    this.name = '',
  });

  WorkoutInterval.fromJson(Map<String, dynamic> json)
      : Id = json['Id'],
        name = json['name'],
        type = json['type'],
        duration = json['duration'] as int,
        reps = json['reps'] as int,
        index = json['index'];

  Map<String, dynamic> toJson() {
    return {
      'Id': Id,
      'name': name,
      'type': type,
      'duration': duration,
      'reps': reps,
      'index': index,
    };
  }

  @override
  String toString() {
    if (type == "Time") {
      return '$name: $duration sec';
    } else {
      return '$name: $reps reps';
    }
  }
}

class IntervalWidget extends StatefulWidget {
  final WorkoutInterval interval;
  final VoidCallback onDelete;

  const IntervalWidget(
      {Key? key, required this.interval, required this.onDelete})
      : super(key: key);

  @override
  _IntervalWidgetState createState() => _IntervalWidgetState();
}

class _IntervalWidgetState extends State<IntervalWidget> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _durationController = TextEditingController();
  TextEditingController _repsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.interval.name;
    _durationController.text = widget.interval.duration.toString();
    _repsController.text = widget.interval.reps.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      color: Color(0xFF252525),
      child: ListTile(
        leading: IconButton(
          icon: Icon(Icons.delete),
          color: Colors.white,
          onPressed: () {
            setState(() {
              widget.onDelete();
            });
          },
        ),
        title: TextFormField(
          style: TextStyle(color: Colors.white),
          controller: _nameController,
          onChanged: (value) {
            setState(() {
              widget.interval.name = value;
              savePersistant(
                  workouts.firstWhere((workout) => workout.Id == _workoutId));
            });
          },
          decoration: InputDecoration(
            labelText: 'Interval Name',
            labelStyle: TextStyle(color: Colors.white),
          ),
        ),
        subtitle: Row(
          children: [
            Text('Type:', style: TextStyle(color: Colors.white)),
            SizedBox(width: 10),
            DropdownButton<String>(
              value: widget.interval.type,
              onChanged: (value) {
                setState(() {
                  widget.interval.type = value!;
                  savePersistant(workouts
                      .firstWhere((workout) => workout.Id == _workoutId));
                });
              },
              items: [
                DropdownMenuItem(
                  child: Text(
                    'Time',
                    style: TextStyle(
                        color: Colors.white), // Set the text color to white
                  ),
                  value: 'Time',
                ),
                DropdownMenuItem(
                  child: Text(
                    'Reps',
                    style: TextStyle(
                        color: Colors.white), // Set the text color to white
                  ),
                  value: 'Reps',
                ),
              ],
              dropdownColor: Color(0xFF252525),
              underline: Container(),
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: widget.interval.type == "Time"
                    ? _durationController
                    : _repsController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    if (widget.interval.type == "Time") {
                      widget.interval.duration = int.tryParse(value) ?? 0;
                    } else {
                      widget.interval.reps = int.tryParse(value) ?? 0;
                    }
                    savePersistant(workouts
                        .firstWhere((workout) => workout.Id == _workoutId));
                  });
                },
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color(0xFF414141),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
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
