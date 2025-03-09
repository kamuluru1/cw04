import 'package:flutter/material.dart';
import 'database_helper.dart';


class Plan {
  int? id;
  String name;
  String description;
  DateTime date;
  bool completed;
  String priority;

  Plan({
    this.id,
    required this.name,
    required this.description,
    required this.date,
    this.completed = false,
    required this.priority,
  });
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adoption and Travel Plans',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PlanManagerScreen(),
    );
  }
}

class PlanManagerScreen extends StatefulWidget {
  @override
  _PlanManagerScreenState createState() => _PlanManagerScreenState();
}

class _PlanManagerScreenState extends State<PlanManagerScreen> {
  List<Plan> _plans = [];
  DateTime _selectedDate = DateTime.now();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    await _dbHelper.init();
  }

  void _addPlan(Plan plan) {
    setState(() {
      _plans.add(plan);
      _sortPlans();
    });
  }

  void _updatePlan(Plan plan) {
    setState(() {
      int index = _plans.indexWhere((p) => p.id == plan.id);
      if (index != -1) {
        _plans[index] = plan;
        _sortPlans();
      }
    });
  }

  void _deletePlan(Plan plan) {
    setState(() {
      _plans.removeWhere((p) => p.id == plan.id);
    });
  }

  void _togglePlanCompletion(Plan plan) {
    setState(() {
      plan.completed = !plan.completed;
    });
  }

  void _sortPlans() {
    _plans.sort((a, b) => _priorityValue(b.priority).compareTo(_priorityValue(a.priority)));
  }

  int _priorityValue(String priority) {
    switch (priority) {
      case 'High':
        return 3;
      case 'Medium':
        return 2;
      case 'Low':
      default:
        return 1;
    }
  }

  Future<void> _showPlanDialog({Plan? plan}) async {
    final isEditing = plan != null;
    final TextEditingController nameController = TextEditingController(text: plan?.name ?? '');
    final TextEditingController descriptionController = TextEditingController(text: plan?.description ?? '');
    DateTime selectedDate = plan?.date ?? DateTime.now();
    String selectedPriority = plan?.priority ?? 'Low';

    await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setModalState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Plan' : 'Create Plan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Plan Name'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: 'Description'),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text("Date: ${selectedDate.toLocal()}".split(' ')[0]),
                        Spacer(),
                        TextButton(
                          child: Text("Select Date"),
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null && picked != selectedDate) {
                              setModalState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                        )
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text("Priority: "),
                        DropdownButton<String>(
                          value: selectedPriority,
                          items: <String>['Low', 'Medium', 'High'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              setModalState(() {
                                selectedPriority = newValue;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text("Cancel"),
                  onPressed: () { Navigator.of(context).pop(); },
                ),
                ElevatedButton(
                  child: Text(isEditing ? "Update" : "Create"),
                  onPressed: () {
                    final newPlan = Plan(
                      id: plan?.id,
                      name: nameController.text,
                      description: descriptionController.text,
                      date: selectedDate,
                      completed: plan?.completed ?? false,
                      priority: selectedPriority,
                    );
                    if (isEditing) {
                      _updatePlan(newPlan);
                    } else {
                      _addPlan(newPlan);
                    }
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          });
        }
    );
  }

  Widget _buildPlanItem(Plan plan) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        _togglePlanCompletion(plan);
        return false;
      },
      child: GestureDetector(
        onLongPress: () => _showPlanDialog(plan: plan),
        onDoubleTap: () => _deletePlan(plan),
        child: Container(
          padding: EdgeInsets.all(8),
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: plan.completed ? Colors.green[100] : Colors.red[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            title: Text(plan.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.description),
                Text("Date: ${plan.date.toLocal()}".split(' ')[0]),
                Text("Priority: ${plan.priority}"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDraggablePlanTemplate(String planType) {
    return Draggable<String>(
      data: planType,
      feedback: Material(
        child: Container(
          padding: EdgeInsets.all(8),
          color: Colors.blue,
          child: Text(planType, style: TextStyle(color: Colors.white)),
        ),
      ),
      childWhenDragging: Container(
        padding: EdgeInsets.all(8),
        color: Colors.grey,
        child: Text(planType),
      ),
      child: Container(
        padding: EdgeInsets.all(8),
        color: Colors.blue,
        child: Text(planType, style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildCalendarDragTarget() {
    return DragTarget<String>(
      onAccept: (planType) {
        _showPlanDialog();
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          height: 100,
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            border: Border.all(color: Colors.orange),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Text("Drop here to assign plan date")),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _sortPlans();
    return Scaffold(
      appBar: AppBar(
        title: Text("Adoption and Travel Plans"),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDraggablePlanTemplate("Adoption"),
              _buildDraggablePlanTemplate("Travel"),
              ElevatedButton(
                onPressed: () => _showPlanDialog(),
                child: Text("Create Plan"),
              ),
            ],
          ),
          _buildCalendarDragTarget(),
          Expanded(
            child: ListView.builder(
              itemCount: _plans.length,
              itemBuilder: (context, index) {
                final plan = _plans[index];
                return _buildPlanItem(plan);
              },
            ),
          )
        ],
      ),
    );
  }
}

