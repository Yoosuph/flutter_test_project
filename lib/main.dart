import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const TodoApp(),
    ),
  );
}

// Theme Provider for Dark Mode
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        textTheme: GoogleFonts.poppinsTextTheme(),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF764ba2),
          secondary: Color(0xFF667eea),
        ),
      );

  ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF764ba2),
          secondary: Color(0xFF667eea),
          surface: Color(0xFF1E1E1E),
          background: Color(0xFF121212),
        ),
      );
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'TaskMaster',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
        );
      },
    );
  }
}

// Splash Screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const TodoListPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1a1a2e),
                    const Color(0xFF16213e),
                    const Color(0xFF0f3460),
                  ]
                : [
                    const Color(0xFF667eea),
                    const Color(0xFF764ba2),
                    const Color(0xFFf093fb),
                  ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'TaskMaster',
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Organize your life',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

enum TodoPriority { high, medium, low }
enum TodoCategory { work, personal, shopping, health, other }
enum RecurringType { none, daily, weekly, monthly }

class Subtask {
  String id;
  String title;
  bool isCompleted;

  Subtask({
    String? id,
    required this.title,
    this.isCompleted = false,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
      };

  factory Subtask.fromJson(Map<String, dynamic> json) => Subtask(
        id: json['id'],
        title: json['title'],
        isCompleted: json['isCompleted'],
      );
}

class Todo {
  String id;
  String title;
  bool isCompleted;
  final DateTime createdAt;
  DateTime? dueDate;
  TimeOfDay? dueTime;
  TodoPriority priority;
  TodoCategory category;
  List<Subtask> subtasks;
  RecurringType recurring;
  int sortOrder;

  Todo({
    String? id,
    required this.title,
    this.isCompleted = false,
    DateTime? createdAt,
    this.dueDate,
    this.dueTime,
    this.priority = TodoPriority.medium,
    this.category = TodoCategory.personal,
    List<Subtask>? subtasks,
    this.recurring = RecurringType.none,
    this.sortOrder = 0,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now(),
        subtasks = subtasks ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'dueTime': dueTime != null ? '${dueTime!.hour}:${dueTime!.minute}' : null,
        'priority': priority.index,
        'category': category.index,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'recurring': recurring.index,
        'sortOrder': sortOrder,
      };

  factory Todo.fromJson(Map<String, dynamic> json) {
    TimeOfDay? time;
    if (json['dueTime'] != null) {
      final parts = json['dueTime'].split(':');
      time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    return Todo(
      id: json['id'],
      title: json['title'],
      isCompleted: json['isCompleted'],
      createdAt: DateTime.parse(json['createdAt']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      dueTime: time,
      priority: TodoPriority.values[json['priority'] ?? 1],
      category: TodoCategory.values[json['category'] ?? 1],
      subtasks: json['subtasks'] != null
          ? (json['subtasks'] as List)
              .map((s) => Subtask.fromJson(s))
              .toList()
          : [],
      recurring: RecurringType.values[json['recurring'] ?? 0],
      sortOrder: json['sortOrder'] ?? 0,
    );
  }

  double get subtaskProgress {
    if (subtasks.isEmpty) return 0;
    final completed = subtasks.where((s) => s.isCompleted).length;
    return completed / subtasks.length;
  }
}

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage>
    with TickerProviderStateMixin {
  final List<Todo> _todos = [];
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  late ConfettiController _confettiController;
  late SharedPreferences _prefs;

  TodoPriority _selectedPriority = TodoPriority.medium;
  TodoCategory _selectedCategory = TodoCategory.personal;
  DateTime? _selectedDueDate;
  TimeOfDay? _selectedDueTime;
  RecurringType _selectedRecurring = RecurringType.none;
  String _searchQuery = '';
  TodoCategory? _filterCategory;
  TodoPriority? _filterPriority;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _loadTodos();
    _checkRecurringTasks();
  }

  Future<void> _loadTodos() async {
    _prefs = await SharedPreferences.getInstance();
    final String? todosJson = _prefs.getString('todos');
    if (todosJson != null) {
      final List<dynamic> decoded = json.decode(todosJson);
      setState(() {
        _todos.clear();
        _todos.addAll(decoded.map((item) => Todo.fromJson(item)).toList());
        _todos.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      });
    }
  }

  Future<void> _saveTodos() async {
    final String encoded =
        json.encode(_todos.map((t) => t.toJson()).toList());
    await _prefs.setString('todos', encoded);
  }

  void _checkRecurringTasks() {
    final now = DateTime.now();
    bool hasChanges = false;

    for (var todo in _todos) {
      if (todo.recurring != RecurringType.none &&
          todo.isCompleted &&
          todo.dueDate != null) {
        DateTime nextDate;

        switch (todo.recurring) {
          case RecurringType.daily:
            nextDate = todo.dueDate!.add(const Duration(days: 1));
            break;
          case RecurringType.weekly:
            nextDate = todo.dueDate!.add(const Duration(days: 7));
            break;
          case RecurringType.monthly:
            nextDate = DateTime(
              todo.dueDate!.year,
              todo.dueDate!.month + 1,
              todo.dueDate!.day,
            );
            break;
          default:
            continue;
        }

        if (nextDate.isBefore(now) || nextDate.isAtSameMomentAs(now)) {
          todo.isCompleted = false;
          todo.dueDate = nextDate;
          hasChanges = true;
        }
      }
    }

    if (hasChanges) {
      _saveTodos();
      setState(() {});
    }
  }

  void _addTodo() {
    if (_textController.text.trim().isEmpty) return;

    HapticFeedback.mediumImpact();
    setState(() {
      final newTodo = Todo(
        title: _textController.text.trim(),
        priority: _selectedPriority,
        category: _selectedCategory,
        dueDate: _selectedDueDate,
        dueTime: _selectedDueTime,
        recurring: _selectedRecurring,
        sortOrder: _todos.length,
      );
      _todos.add(newTodo);
      _textController.clear();
      _selectedDueDate = null;
      _selectedDueTime = null;
      _selectedPriority = TodoPriority.medium;
      _selectedRecurring = RecurringType.none;
    });
    _saveTodos();
  }

  void _toggleTodo(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _todos[index].isCompleted = !_todos[index].isCompleted;
      if (_todos[index].isCompleted) {
        _confettiController.play();
      }
    });
    _saveTodos();
  }

  void _deleteTodo(int index) {
    final deletedTodo = _todos[index];
    HapticFeedback.mediumImpact();
    setState(() {
      _todos.removeAt(index);
    });
    _saveTodos();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task deleted',
            style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: const Color(0xFF764ba2),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _todos.insert(index, deletedTodo);
            });
            _saveTodos();
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _editTodo(int index) {
    final todo = _todos[index];
    _textController.text = todo.title;
    _selectedPriority = todo.priority;
    _selectedCategory = todo.category;
    _selectedDueDate = todo.dueDate;
    _selectedDueTime = todo.dueTime;
    _selectedRecurring = todo.recurring;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddTaskBottomSheet(
        context,
        isEditing: true,
        onSave: () {
          setState(() {
            todo.title = _textController.text.trim();
            todo.priority = _selectedPriority;
            todo.category = _selectedCategory;
            todo.dueDate = _selectedDueDate;
            todo.dueTime = _selectedDueTime;
            todo.recurring = _selectedRecurring;
          });
          _saveTodos();
          _textController.clear();
          Navigator.pop(context);
        },
      ),
    );
  }

  List<Todo> get _filteredTodos {
    return _todos.where((todo) {
      final matchesSearch =
          todo.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _filterCategory == null || todo.category == _filterCategory;
      final matchesPriority =
          _filterPriority == null || todo.priority == _filterPriority;
      return matchesSearch && matchesCategory && matchesPriority;
    }).toList();
  }

  Color _getPriorityColor(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.high:
        return Colors.red;
      case TodoPriority.medium:
        return Colors.orange;
      case TodoPriority.low:
        return Colors.green;
    }
  }

  IconData _getCategoryIcon(TodoCategory category) {
    switch (category) {
      case TodoCategory.work:
        return Icons.work_rounded;
      case TodoCategory.personal:
        return Icons.person_rounded;
      case TodoCategory.shopping:
        return Icons.shopping_cart_rounded;
      case TodoCategory.health:
        return Icons.favorite_rounded;
      case TodoCategory.other:
        return Icons.more_horiz_rounded;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _searchController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredTodos;
    final completedCount = _todos.where((t) => t.isCompleted).length;
    final totalCount = _todos.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF1a1a2e),
                        const Color(0xFF16213e),
                        const Color(0xFF0f3460),
                      ]
                    : [
                        const Color(0xFF667eea),
                        const Color(0xFF764ba2),
                        const Color(0xFFf093fb),
                      ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header Section
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Tasks',
                                  style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getGreeting(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                // Theme Toggle
                                IconButton(
                                  onPressed: () {
                                    Provider.of<ThemeProvider>(context,
                                            listen: false)
                                        .toggleTheme();
                                  },
                                  icon: Icon(
                                    isDark
                                        ? Icons.light_mode_rounded
                                        : Icons.dark_mode_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                // Statistics Button
                                IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            StatisticsPage(todos: _todos),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.bar_chart_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                if (totalCount > 0)
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 60,
                                        height: 60,
                                        child: CircularProgressIndicator(
                                          value: progress,
                                          strokeWidth: 5,
                                          backgroundColor:
                                              Colors.white.withOpacity(0.3),
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                  Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${(progress * 100).toInt()}%',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (totalCount > 0)
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Total',
                                  totalCount.toString(),
                                  Icons.list_alt_rounded,
                                  Colors.white.withOpacity(0.2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Done',
                                  completedCount.toString(),
                                  Icons.check_circle_rounded,
                                  Colors.white.withOpacity(0.2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Active',
                                  (totalCount - completedCount).toString(),
                                  Icons.pending_rounded,
                                  Colors.white.withOpacity(0.2),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search tasks...',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 15,
                          ),
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.white),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Filter Chips
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        _buildFilterChip(
                          'All',
                          _filterCategory == null && _filterPriority == null,
                          () {
                            setState(() {
                              _filterCategory = null;
                              _filterPriority = null;
                            });
                          },
                        ),
                        ...TodoCategory.values.map((cat) => _buildFilterChip(
                              cat.name[0].toUpperCase() + cat.name.substring(1),
                              _filterCategory == cat,
                              () {
                                setState(() {
                                  _filterCategory =
                                      _filterCategory == cat ? null : cat;
                                });
                              },
                            )),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Todo List with ReorderableListView
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1E1E)
                            : const Color(0xFFF8F9FA),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: filteredList.isEmpty
                          ? _buildEmptyState()
                          : ReorderableListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: filteredList.length,
                              onReorder: (oldIndex, newIndex) {
                                setState(() {
                                  if (newIndex > oldIndex) {
                                    newIndex -= 1;
                                  }
                                  final item = filteredList.removeAt(oldIndex);
                                  filteredList.insert(newIndex, item);

                                  // Update sort orders
                                  for (int i = 0; i < filteredList.length; i++) {
                                    filteredList[i].sortOrder = i;
                                  }
                                  _saveTodos();
                                });
                              },
                              itemBuilder: (context, index) {
                                final todo = filteredList[index];
                                final actualIndex = _todos.indexOf(todo);
                                return _buildTodoItem(
                                    todo, actualIndex, index);
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.2,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskBottomSheet(context),
        backgroundColor: const Color(0xFF764ba2),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Task',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white
                : Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: isSelected ? const Color(0xFF764ba2) : Colors.white,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddTaskBottomSheet(BuildContext context,
      {bool isEditing = false, VoidCallback? onSave}) {
    return StatefulBuilder(
      builder: (context, setModalState) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A2A2A)
              : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isEditing ? 'Edit Task' : 'New Task',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _textController,
                  autofocus: true,
                  style: GoogleFonts.poppins(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'What needs to be done?',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF764ba2)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Priority',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: TodoPriority.values.map((priority) {
                    final isSelected = _selectedPriority == priority;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setModalState(() {
                            _selectedPriority = priority;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _getPriorityColor(priority).withOpacity(0.2)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? _getPriorityColor(priority)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              priority.name[0].toUpperCase() +
                                  priority.name.substring(1),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? _getPriorityColor(priority)
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Category',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TodoCategory.values.map((category) {
                    final isSelected = _selectedCategory == category;
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          _selectedCategory = category;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF764ba2).withOpacity(0.2)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF764ba2)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getCategoryIcon(category),
                              size: 18,
                              color: isSelected
                                  ? const Color(0xFF764ba2)
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              category.name[0].toUpperCase() +
                                  category.name.substring(1),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? const Color(0xFF764ba2)
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Due Date & Time
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Color(0xFF764ba2),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (date != null) {
                            setModalState(() {
                              _selectedDueDate = date;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  color: Color(0xFF764ba2)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedDueDate == null
                                      ? 'Set date'
                                      : DateFormat('MMM dd, yyyy')
                                          .format(_selectedDueDate!),
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ),
                              if (_selectedDueDate != null)
                                GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      _selectedDueDate = null;
                                    });
                                  },
                                  child: const Icon(Icons.close,
                                      size: 20, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Color(0xFF764ba2),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (time != null) {
                            setModalState(() {
                              _selectedDueTime = time;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time,
                                  color: Color(0xFF764ba2)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedDueTime == null
                                      ? 'Set time'
                                      : _selectedDueTime!.format(context),
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ),
                              if (_selectedDueTime != null)
                                GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      _selectedDueTime = null;
                                    });
                                  },
                                  child: const Icon(Icons.close,
                                      size: 20, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Recurring
                Text(
                  'Repeat',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: RecurringType.values.map((type) {
                    final isSelected = _selectedRecurring == type;
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          _selectedRecurring = type;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF764ba2).withOpacity(0.2)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF764ba2)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          type.name[0].toUpperCase() + type.name.substring(1),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFF764ba2)
                                : Colors.grey,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isEditing && onSave != null) {
                        onSave();
                      } else {
                        _addTodo();
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF764ba2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isEditing ? 'Save Changes' : 'Add Task',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddTaskBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddTaskBottomSheet(context),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoItem(Todo todo, int actualIndex, int displayIndex) {
    final isOverdue = todo.dueDate != null &&
        todo.dueDate!.isBefore(DateTime.now()) &&
        !todo.isCompleted;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      key: ValueKey(todo.id),
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          dismissible: DismissiblePane(
            onDismissed: () => _deleteTodo(actualIndex),
          ),
          children: [
            SlidableAction(
              onPressed: (_) => _deleteTodo(actualIndex),
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              icon: Icons.delete_rounded,
              label: 'Delete',
              borderRadius: BorderRadius.circular(20),
            ),
          ],
        ),
        child: GestureDetector(
          onLongPress: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: Text('Edit Task',
                          style: GoogleFonts.poppins()),
                      onTap: () {
                        Navigator.pop(context);
                        _editTodo(actualIndex);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.checklist_rounded),
                      title: Text('Manage Subtasks',
                          style: GoogleFonts.poppins()),
                      onTap: () {
                        Navigator.pop(context);
                        _showSubtasksDialog(actualIndex);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete,
                          color: Colors.red),
                      title: Text('Delete',
                          style: GoogleFonts.poppins(color: Colors.red)),
                      onTap: () {
                        Navigator.pop(context);
                        _deleteTodo(actualIndex);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: isDark
                  ? (todo.isCompleted
                      ? Colors.grey.shade800
                      : const Color(0xFF2A2A2A))
                  : (todo.isCompleted
                      ? Colors.grey.shade300
                      : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: isOverdue
                  ? Border.all(color: Colors.red.shade300, width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _toggleTodo(actualIndex),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: todo.isCompleted
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF667eea),
                                        Color(0xFF764ba2),
                                      ],
                                    )
                                  : null,
                              border: Border.all(
                                color: todo.isCompleted
                                    ? Colors.transparent
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                            ),
                            child: todo.isCompleted
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  todo.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    decoration: todo.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationThickness: 2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getPriorityColor(todo.priority)
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        todo.priority.name[0].toUpperCase() +
                                            todo.priority.name.substring(1),
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: _getPriorityColor(todo.priority),
                                        ),
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getCategoryIcon(todo.category),
                                          size: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          todo.category.name[0].toUpperCase() +
                                              todo.category.name.substring(1),
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (todo.dueDate != null) ...[
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 12,
                                            color: isOverdue
                                                ? Colors.red
                                                : Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat('MMM dd')
                                                .format(todo.dueDate!),
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color: isOverdue
                                                  ? Colors.red
                                                  : Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (todo.dueTime != null) ...[
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            todo.dueTime!.format(context),
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (todo.recurring != RecurringType.none)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.repeat,
                                            size: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            todo.recurring.name,
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.drag_indicator_rounded,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                        ],
                      ),
                      if (todo.subtasks.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: todo.subtaskProgress,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF764ba2)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${todo.subtasks.where((s) => s.isCompleted).length}/${todo.subtasks.length} subtasks completed',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSubtasksDialog(int todoIndex) {
    final todo = _todos[todoIndex];
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Subtasks', style: GoogleFonts.poppins()),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: 'Add subtask...',
                          hintStyle: GoogleFonts.poppins(),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (controller.text.trim().isNotEmpty) {
                          setDialogState(() {
                            todo.subtasks.add(
                              Subtask(title: controller.text.trim()),
                            );
                            controller.clear();
                          });
                          setState(() {});
                          _saveTodos();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (todo.subtasks.isEmpty)
                  Text('No subtasks yet',
                      style: GoogleFonts.poppins(color: Colors.grey)),
                ...todo.subtasks.map((subtask) {
                  return CheckboxListTile(
                    title: Text(
                      subtask.title,
                      style: GoogleFonts.poppins(
                        decoration: subtask.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    value: subtask.isCompleted,
                    onChanged: (value) {
                      setDialogState(() {
                        subtask.isCompleted = value ?? false;
                      });
                      setState(() {});
                      _saveTodos();
                    },
                    secondary: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setDialogState(() {
                          todo.subtasks.remove(subtask);
                        });
                        setState(() {});
                        _saveTodos();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Done', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF667eea).withOpacity(0.2),
                  const Color(0xFF764ba2).withOpacity(0.2),
                ],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF667eea),
                    Color(0xFF764ba2),
                  ],
                ),
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _searchQuery.isNotEmpty ? 'No tasks found' : 'No tasks yet!',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search or filters'
                  : 'Tap the + button to add your first task',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning! ☀️';
    if (hour < 17) return 'Good afternoon! 🌤️';
    return 'Good evening! 🌙';
  }
}

// Statistics Page
class StatisticsPage extends StatelessWidget {
  final List<Todo> todos;

  const StatisticsPage({super.key, required this.todos});

  @override
  Widget build(BuildContext context) {
    final completedTasks = todos.where((t) => t.isCompleted).length;
    final totalTasks = todos.length;
    final completionRate =
        totalTasks > 0 ? (completedTasks / totalTasks * 100).toInt() : 0;

    // Category breakdown
    final categoryData = <TodoCategory, int>{};
    for (var todo in todos) {
      categoryData[todo.category] = (categoryData[todo.category] ?? 0) + 1;
    }

    // Priority breakdown
    final priorityData = <TodoPriority, int>{};
    for (var todo in todos) {
      priorityData[todo.priority] = (priorityData[todo.priority] ?? 0) + 1;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Statistics', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF764ba2),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Tasks',
                    totalTasks.toString(),
                    Icons.list_alt_rounded,
                    const Color(0xFF667eea),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Completed',
                    completedTasks.toString(),
                    Icons.check_circle_rounded,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Active',
                    (totalTasks - completedTasks).toString(),
                    Icons.pending_rounded,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Completion',
                    '$completionRate%',
                    Icons.percent_rounded,
                    const Color(0xFF764ba2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Category Breakdown
            Text(
              'Tasks by Category',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (categoryData.isEmpty)
              Center(
                child: Text(
                  'No tasks to display',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              )
            else
              ...categoryData.entries.map((entry) {
                final percentage =
                    totalTasks > 0 ? (entry.value / totalTasks * 100).toInt() : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key.name[0].toUpperCase() +
                                entry.key.name.substring(1),
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          Text(
                            '${entry.value} tasks ($percentage%)',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: entry.value / totalTasks,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF764ba2)),
                        minHeight: 8,
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 32),

            // Priority Breakdown
            Text(
              'Tasks by Priority',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (priorityData.isEmpty)
              Center(
                child: Text(
                  'No tasks to display',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              )
            else
              ...priorityData.entries.map((entry) {
                final percentage =
                    totalTasks > 0 ? (entry.value / totalTasks * 100).toInt() : 0;
                Color color;
                switch (entry.key) {
                  case TodoPriority.high:
                    color = Colors.red;
                    break;
                  case TodoPriority.medium:
                    color = Colors.orange;
                    break;
                  case TodoPriority.low:
                    color = Colors.green;
                    break;
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key.name[0].toUpperCase() +
                                entry.key.name.substring(1),
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          Text(
                            '${entry.value} tasks ($percentage%)',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: entry.value / totalTasks,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
