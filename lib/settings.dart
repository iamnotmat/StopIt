import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'main.dart';
import 'Save/save_workout.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/stopit_backup.json');
  }

  Future<void> backupData() async {
    // Convert the workout data to a JSON-encodable format
    List jsonData = workouts.map((workout) => workout.toJson()).toList();

    // Convert the JSON data to a string
    String jsonString = jsonEncode(jsonData);

    // Save the data to a file
    final file = await _localFile;
    await file.writeAsString(jsonString);

    final snackBar = SnackBar(
      content: Text('Data backed up successfully.'),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> downloadBackup() async {
    try {
      final file = await _localFile;
      String backupData = await file.readAsString();

      final directory = await DownloadsPath.downloadsDirectory();
      final backupFile = File('${directory!.path}/stopit_backup.json');
      await backupFile.writeAsString(backupData);

      final snackBar = SnackBar(
        content: Text('Backup file downloaded to Downloads folder.'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } on PlatformException catch (e) {
      print("Error: ${e.message}");
      final snackBar = SnackBar(
        content: Text('Error while downloading backup.'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> restoreData() async {
    // Read the JSON data from the file
    final file = await _localFile;
    String jsonString = await file.readAsString();

    // Convert the JSON data to a List of Map<String, dynamic>
    List<Map<String, dynamic>> jsonData =
        jsonDecode(jsonString).cast<Map<String, dynamic>>();

    // Convert the JSON data back to Workout objects
    List backedupWorkouts =
        jsonData.map((data) => Workout.fromJson(data)).toList();

    // Save the data to GetStorage
    for (Workout workout in backedupWorkouts) {
      // Update Id
      workout.Id = nextWorkoutId;
      nextWorkoutId++;

      // Update index
      workout.index = workouts.length;

      // Save the workout
      workouts.add(workout);
      await savePersistant(workout);
    }

    final snackBar = SnackBar(
      content: Text('Data restored successfully.'),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> restoreFromFile() async {
    try {
      // Continue with the file picking and restore process
      try {
        // Open the file picker to select a .json file
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json'],
        );

        // Check if a file was selected
        if (result != null && result.files.isNotEmpty) {
          String filePath = result.files.first.path!;
          File selectedFile = File(filePath);

          // Read the JSON data from the selected file
          String jsonString = await selectedFile.readAsString();

          // Convert the JSON data to a List of Map<String, dynamic>
          List<Map<String, dynamic>> jsonData =
              jsonDecode(jsonString).cast<Map<String, dynamic>>();

          // Convert the JSON data back to Workout objects
          List backedupWorkouts =
              jsonData.map((data) => Workout.fromJson(data)).toList();

          // Save the data to GetStorage
          for (Workout workout in backedupWorkouts) {
            // Update Id
            workout.Id = nextWorkoutId;
            nextWorkoutId++;

            // Update index
            workout.index = workouts.length;

            // Save the workout
            workouts.add(workout);
            await savePersistant(workout);
          }

          // Refresh the UI or do any necessary updates after restoring data
          setState(() {
            // Perform UI updates here if needed
          });

          // After restoring data, show a success message
          final snackBar = SnackBar(
            content: Text('Data restored successfully.'),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        } else {
          // If no file was selected, show an error message
          final snackBar = SnackBar(
            content: Text('No file selected for restore.'),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      } catch (e) {
        // Handle any potential errors during file selection or reading
        print("Error: $e");
        final snackBar = SnackBar(
          content: Text('Error while restoring data.'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      // Handle any potential errors during file selection or reading
      print("Error: $e");
      final snackBar = SnackBar(
        content: Text('Error while restoring data.'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Color(0xff252525),
      ),
      body: Material(
        type: MaterialType.transparency,
        child: Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Color(0xff252525),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {
                  backupData();
                },
                child: Text(
                  'Backup Data',
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
              SizedBox(
                height: 16.0,
              ),
              ElevatedButton(
                onPressed: () {
                  restoreData();
                },
                child: Text(
                  'Restore Data',
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
              SizedBox(
                height: 16.0,
              ),
              ElevatedButton(
                onPressed: () {
                  downloadBackup();
                },
                child: Text(
                  'Download Backup',
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
              SizedBox(
                height: 16.0,
              ),
              ElevatedButton(
                onPressed: () {
                  restoreFromFile();
                },
                child: Text(
                  'Restore from File',
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
              SizedBox(
                height: 16.0,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: FutureBuilder<String>(
                    future: _localFile.then((file) => file.readAsString()),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text("Error reading backup data.");
                      } else {
                        return Text(
                          snapshot.data ?? '',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
