import 'package:flutter/material.dart';
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
      home: WorkoutDesignPage(workoutKey: UniqueKey()),
    );
  }
}

List<WorkoutSet> sets = []; // Initialize the sets list

class WorkoutDesignPage extends StatefulWidget {
  Key? workoutKey; // Add the workout index parameter

  WorkoutDesignPage({this.workoutKey});

  @override
  _WorkoutDesignPageState createState() => _WorkoutDesignPageState();
}

class _WorkoutDesignPageState extends State<WorkoutDesignPage> {
  @override
  void initState() {
    super.initState();
    // Retrieve the selected workout using the provided workout index
    final selectedWorkout =
        workouts.firstWhere((workout) => workout.key == widget.workoutKey);
    // Initialize the sets list with the sets from the selected workout
    sets = selectedWorkout.sets.cast<WorkoutSet>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workout Design'),
        backgroundColor: Color(0xFF252525),
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
                    onDelete: () {
                      setState(() {
                        sets.removeAt(index);
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
          });
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            sets.add(WorkoutSet());
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
  String name = '';
  List<WorkoutInterval> intervals = [];
  int repetitions = 1;

  WorkoutSet({this.name = '', this.repetitions = 1});

  WorkoutSet.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        intervals = (json['intervals'] as List<dynamic>)
            .map((intervalJson) => WorkoutInterval.fromJson(intervalJson))
            .toList(),
        repetitions = json['repetitions'];

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
      intervalsText += '   ${interval.toString()}\n';
    }
    return 'Set Name: $name\nRepetitions: $repetitions\nIntervals:\n$intervalsText';
  }
}

class WorkoutInterval {
  String name = '';
  IntervalType type;
  int duration; // in seconds
  int reps;
  int repetitions = 1;

  WorkoutInterval({
    this.type = IntervalType.time,
    this.duration = 0,
    this.reps = 0,
    this.name = '',
    this.repetitions = 1,
  });

  WorkoutInterval.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        type = IntervalType.values[json['type']],
        duration = json['duration'],
        reps = json['reps'],
        repetitions = json['repetitions'];

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.index,
      'duration': duration,
      'reps': reps,
      'repetitions': repetitions,
    };
  }

  @override
  String toString() {
    String typeText = type == IntervalType.time ? 'Time' : 'Reps';
    if (type == IntervalType.time) {
      return '$name: $duration seconds';
    } else {
      return '$name: $reps reps';
    }
  }
}

enum IntervalType {
  time,
  reps,
}

class SetWidget extends StatefulWidget {
  final WorkoutSet set;
  final VoidCallback onDelete;

  const SetWidget({Key? key, required this.set, required this.onDelete})
      : super(key: key);

  @override
  _SetWidgetState createState() => _SetWidgetState();
}

class _SetWidgetState extends State<SetWidget> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _repetitionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.set.name;
    _repetitionsController.text = widget.set.repetitions.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      key: widget.key,
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
              onChanged: (value) {
                setState(() {
                  widget.set.name = value;
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
                            widget.set.intervals.removeAt(index);
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
              });
            },
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  widget.set.intervals
                      .add(WorkoutInterval(type: IntervalType.time));
                });
              },
              style: ElevatedButton.styleFrom(
                primary: Color(0xFFaf0404),
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
            DropdownButton<IntervalType>(
              value: widget.interval.type,
              onChanged: (value) {
                setState(() {
                  widget.interval.type = value!;
                });
              },
              items: IntervalType.values
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(
                          type == IntervalType.time ? 'Time' : 'Reps',
                          style: TextStyle(color: Colors.white),
                        ),
                      ))
                  .toList(),
              dropdownColor: Color(0xFF252525),
              underline: Container(),
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: widget.interval.type == IntervalType.time
                    ? _durationController
                    : _repsController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    if (widget.interval.type == IntervalType.time) {
                      widget.interval.duration = int.tryParse(value) ?? 0;
                    } else {
                      widget.interval.reps = int.tryParse(value) ?? 0;
                    }
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
