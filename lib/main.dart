import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'PlateSync',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme:
              ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 143, 84, 35)),
          scaffoldBackgroundColor: Color.fromARGB(223, 255, 208, 180),
        ),
        home: MyHomePage(),
      ),
    ),
  );
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  var exercises = <WordPair>[];

  var workoutGroups = <String, List<String>>{};

  MyAppState() {
    _loadExercises();
  }

  void _loadExercises() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String>? exerciseNames = prefs.getStringList('exercises');
    if (exerciseNames != null) {
      exercises = exerciseNames.map((name) => WordPair(name, '')).toList();
      notifyListeners();
    }
  }

  void _saveExercises() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String> exerciseNames =
        exercises.map((exercise) => exercise.asPascalCase).toList();

    prefs.setStringList('exercises', exerciseNames);
  }

  void addExercise() {
    exercises.add(current);

    _saveExercises();
    notifyListeners();
  }

  void addWorkoutGroup(String groupName, List<String> items) {
    workoutGroups[groupName] = items;
    notifyListeners();
  }

  void addItemToGroup(String groupName, String item) {
    if (workoutGroups.containsKey(groupName) &&
        (workoutGroups[groupName]?.length ?? 0) < 10) {
      workoutGroups[groupName]?.add(item);
      notifyListeners();
    } else {
      if (!workoutGroups.containsKey(groupName)) {
        print('Group $groupName does not exist.');
      } else {
        print('Cannot add more items. Maximum limit reached.');
      }
    }
  }

  void removeItemFromGroup(String groupName, String item) {
    if (workoutGroups.containsKey(groupName)) {
      workoutGroups[groupName]?.remove(item);
      notifyListeners();
    } else {
      print('Group $groupName does not exist.');
    }
  }

  void deleteWorkoutGroup(String groupName) {
    if (workoutGroups.containsKey(groupName)) {
      workoutGroups.remove(groupName);
      notifyListeners();
    } else {
      print('Group $groupName does not exist.');
    }
  }

  Map<String, List<String>> get getWorkoutGroups => workoutGroups;
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = CalendarPage();
        break;
      case 2:
        page = ChangeNotifierProvider(
          create: (context) => ExerciseState(),
          child: ExercisesPage(),
        );
        break;
      case 3:
        page = WorkoutsPage();
        break;
      case 4:
        page = RecommendationsPage();
        break;
      case 5:
        page = SharePage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            child: NavigationRail(
              extended: true,
              destinations: [
                NavigationRailDestination(
                  icon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.calendar_month),
                  label: Text('Calendar'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.sports_gymnastics_outlined),
                  label: Text('Exercises'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.list_alt),
                  label: Text('Workouts'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.check_box),
                  label: Text('Recommendations'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.share),
                  label: Text('Share'),
                ),
              ],
              selectedIndex: selectedIndex,
              onDestinationSelected: (value) {
                setState(() {
                  selectedIndex = value;
                });
              },
            ),
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: page,
            ),
          ),
        ],
      ),
    );
  }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.exercises.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'The meaning of life is not simply to exist, to survive, but to move ahead. To go up. To conquer.\nArnold Schwarzenegger, 7-time Mr. Olympia',
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  height: 450,
                  width: 500,
                  child: Image.asset(
                    'assets/images/PsLogo.png',
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          pair.asLowerCase,
          style: style,
          semanticsLabel: pair.asPascalCase,
        ),
      ),
    );
  }
}

class CalendarState extends ChangeNotifier {
  late Map<DateTime, List<String>> _events;

  CalendarState() {
    _events = {};
  }

  Map<DateTime, List<String>> get events => _events;

  void updateEvent(DateTime day, List<String> notes) {
    _events[day] = notes;
    notifyListeners();
  }
}

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late Map<DateTime, List<String>> _events;

  TextEditingController _eventController = TextEditingController();
  List<String> _selectedDayEvents = [];

  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.month;
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _events = {};
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedDayEvents = _events[selectedDay] ?? [];
    });
  }

  void _addNote() {
    if (_eventController.text.isNotEmpty) {
      setState(() {
        if (_events.containsKey(_selectedDay)) {
          _events[_selectedDay]!.add(_eventController.text);
        } else {
          _events[_selectedDay] = [_eventController.text];
        }
        _eventController.clear();
        _selectedDayEvents = _events[_selectedDay] ?? [];
      });
    }
  }

  void _editNote(String oldNote) {
    _eventController.text = oldNote;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Note'),
          content: TextFormField(
            controller: _eventController,
            decoration: InputDecoration(labelText: 'Edit Note'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedDayEvents[_selectedDayEvents.indexOf(oldNote)] =
                      _eventController.text;
                  _events[_selectedDay] = _selectedDayEvents;
                  _eventController.clear();
                  Navigator.of(context).pop();
                });
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteNote(String note) {
    setState(() {
      _selectedDayEvents.remove(note);
      if (_selectedDayEvents.isEmpty) {
        _events.remove(_selectedDay);
      } else {
        _events[_selectedDay] = _selectedDayEvents;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            eventLoader: (day) {
              return _events[day] ?? [];
            },
            onDaySelected: _onDaySelected,
            availableCalendarFormats: {CalendarFormat.month: ''},
          ),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: TextFormField(
              controller: _eventController,
              decoration: InputDecoration(labelText: 'Enter Note'),
              onChanged: (value) {},
            ),
          ),
          ElevatedButton(
            onPressed: _addNote,
            child: Text('Add Note'),
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _selectedDayEvents.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_selectedDayEvents[index]),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          _editNote(_selectedDayEvents[index]);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _deleteNote(_selectedDayEvents[index]);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _eventController.dispose();
    super.dispose();
  }
}

class Exercise {
  final String name;
  final int reps;
  final int sets;
  final double weight;
  final String notes;

  Exercise({
    required this.name,
    required this.reps,
    required this.sets,
    required this.weight,
    required this.notes,
  });
}

class ExerciseState extends ChangeNotifier {
  List<Exercise> _exercises = [];

  List<Exercise> get exercises => _exercises;

  void addExercise(Exercise exercise) {
    _exercises.add(exercise);
    notifyListeners();
  }

  void deleteExercise(Exercise exercise) {
    _exercises.remove(exercise);
    notifyListeners();
  }

  void updateExercise(Exercise oldExercise, Exercise newExercise) {
    final index = _exercises.indexOf(oldExercise);
    if (index != -1) {
      _exercises[index] = newExercise;
      notifyListeners();
    }
  }
}

class ExercisesPage extends StatefulWidget {
  @override
  _ExercisesPageState createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _setsController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var exerciseState = context.watch<ExerciseState>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Exercises'),
      ),
      body: Container(
        color: Colors.transparent,
        child: ListView.builder(
          itemCount: exerciseState.exercises.length,
          itemBuilder: (context, index) {
            var exercise = exerciseState.exercises[index];
            return ListTile(
              title: Text(exercise.name),
              subtitle: Text(
                'Reps: ${exercise.reps}, Sets: ${exercise.sets}, Weight: ${exercise.weight}, Notes: ${exercise.notes}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      _editExercise(context, exerciseState, exercise);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      exerciseState.deleteExercise(exercise);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return _buildAddExerciseDialog(context, exerciseState);
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildAddExerciseDialog(
      BuildContext context, ExerciseState exerciseState) {
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _repsController = TextEditingController();
    final TextEditingController _setsController = TextEditingController();
    final TextEditingController _weightController = TextEditingController();
    final TextEditingController _notesController = TextEditingController();

    return AlertDialog(
      title: Text('Add Exercise'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _repsController,
            decoration: InputDecoration(labelText: 'Reps (Numbers Only)'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _setsController,
            decoration: InputDecoration(labelText: 'Sets (Numbers Only)'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _weightController,
            decoration: InputDecoration(labelText: 'Weight (Numbers Only)'),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(labelText: 'Notes'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty &&
                _repsController.text.isNotEmpty &&
                _setsController.text.isNotEmpty &&
                _weightController.text.isNotEmpty) {
              if (_isNumeric(_repsController.text) &&
                  _isNumeric(_setsController.text) &&
                  _isNumeric(_weightController.text)) {
                var exercise = Exercise(
                  name: _nameController.text,
                  reps: int.parse(_repsController.text),
                  sets: int.parse(_setsController.text),
                  weight: double.parse(_weightController.text),
                  notes: _notesController.text,
                );
                exerciseState.addExercise(exercise);
                Navigator.pop(context);
              } else {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Invalid Input'),
                    content: Text(
                        'Please enter numeric values for Reps, Sets, and Weight.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }

  bool _isNumeric(String value) {
    if (value == null) {
      return false;
    }
    return double.tryParse(value) != null;
  }

  void _editExercise(
      BuildContext context, ExerciseState exerciseState, Exercise exercise) {
    _nameController.text = exercise.name;
    _repsController.text = exercise.reps.toString();
    _setsController.text = exercise.sets.toString();
    _weightController.text = exercise.weight.toString();
    _notesController.text = exercise.notes;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Exercise'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: _repsController,
                decoration: InputDecoration(labelText: 'Reps'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _setsController,
                decoration: InputDecoration(labelText: 'Sets'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _weightController,
                decoration: InputDecoration(labelText: 'Weight'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(labelText: 'Notes'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                var updatedExercise = Exercise(
                  name: _nameController.text,
                  reps: int.parse(_repsController.text),
                  sets: int.parse(_setsController.text),
                  weight: double.parse(_weightController.text),
                  notes: _notesController.text,
                );
                exerciseState.updateExercise(exercise, updatedExercise);
                Navigator.pop(context);
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }
}

class WorkoutsPage extends StatelessWidget {
  final TextEditingController _groupNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          WorkoutsDropDown(),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Create Group'),
                    content: TextField(
                      controller: _groupNameController,
                      decoration: InputDecoration(labelText: 'Group Name'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (_groupNameController.text.isNotEmpty) {
                            appState.addWorkoutGroup(
                              _groupNameController.text,
                              [],
                            );
                            _groupNameController.clear();
                            Navigator.pop(context);
                          }
                        },
                        child: Text('Create'),
                      ),
                    ],
                  );
                },
              );
            },
            child: Text('Create Group'),
          ),
        ],
      ),
    );
  }
}

class WorkoutsDropDown extends StatefulWidget {
  @override
  _WorkoutsDropDownState createState() => _WorkoutsDropDownState();
}

class _WorkoutsDropDownState extends State<WorkoutsDropDown> {
  String? selectedGroup;
  final TextEditingController _itemController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Column(
      children: [
        DropdownButton<String>(
          value: selectedGroup,
          hint: Text('Select a group'),
          onChanged: (newValue) {
            setState(() {
              selectedGroup = newValue;
            });
          },
          items: appState.workoutGroups.keys.map((String group) {
            return DropdownMenuItem<String>(
              value: group,
              child: Text(group),
            );
          }).toList(),
        ),
        SizedBox(height: 20),
        if (selectedGroup != null &&
            appState.workoutGroups.containsKey(selectedGroup))
          SizedBox(
            height: 300,
            child: Column(
              children: [
                TextField(
                  controller: _itemController,
                  decoration: InputDecoration(labelText: 'Add Item'),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    if (_itemController.text.isNotEmpty) {
                      appState.addItemToGroup(
                          selectedGroup!, _itemController.text);
                      _itemController.clear();
                    }
                  },
                  child: Text('Add Item'),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount:
                        appState.workoutGroups[selectedGroup]?.length ?? 0,
                    itemBuilder: (context, index) {
                      var item = appState.workoutGroups[selectedGroup]?[index];
                      return ListTile(
                        title: Text(item ?? ''),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            appState.removeItemFromGroup(selectedGroup!, item!);
                          },
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    appState.deleteWorkoutGroup(selectedGroup!);
                    selectedGroup = null;
                  },
                  child: Text('Delete Group'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class RecommendationsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Recommendations from the developer',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            'My name is Hunter Gohil, and I have been weightlifting for more than a decade. I have played soccer at the collegiate\nlevel, and I have always taken strength training, endurance training, and bodybuilding very seriously. \nHere are some exercises I find to be great for getting started in your lifing journey.',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage('assets/images/SoccerPic.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'General Information\nFor all exercises below, find a weight that makes you struggle without sacrificing form.\nUse a weight that is comfortable, and do three sets of each exercise. Do between 6-16 reps for each set.\nThe less reps per set, the more you will improve strength. The more reps per set, the more endurance will improve.\n\n',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          Text(
            'Split Recommendations\nAs a beginner, I would recommend lifting three times per week. Start with doing a Push Pull Legs split.\n Push means doing pushing exercises that use shoulders, triceps, and chest muscles.\nPull means utilizing pulling exercises that use the biceps, back, and delt muscles.\nLegs means doing exercises that target quads, hamstrings, glutes, and calves.\n\n',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          Text(
            'Push Day Recommendations',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.left,
          ),
          Text(
            'Bench Press - Great exercise to teach about the importance of form\nTricep Pushdown - Safe and extremely effective\nLateral Raises - Builds essential shoulder muscles quickly\n\n',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.left,
          ),
          Text(
            'Pull Day Recommendations',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          Text(
            'Bicep Curls - Simplest exercise, but the most effective\nBarbell Row - Great for building critical back muscles\nFace Pull - Gets the best tension through the delts\n\n',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.left,
          ),
          Text(
            'Leg Day Recommendations',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          Text(
            'Back Squat - Simplest exercise for building overall leg strength\nRDL - Builds the hamstrings better than any other exercise\nCalf Raises - Simply the best exercise for calf growth\n\n\n\n',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }
}

class SharePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Share PlateSync with your friends!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              'Help us grow by sharing PlateSync with your friends and family. You can also support us by leaving a rating on the Apple App Store or Google Play Store.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _copyToClipboard(
                    'Check out PlateSync - Your ultimate workout companion! Download it now from linktostore.com');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Message copied to clipboard'),
                  ),
                );
              },
              child: Text('Copy Message'),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }
}
