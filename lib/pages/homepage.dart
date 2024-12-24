import 'package:flutter/material.dart';
import 'package:habit_tracker/pages/habit_tracker_section.dart';
import 'package:provider/provider.dart';
import 'package:habit_tracker/backend/habit_database.dart';
import 'package:habit_tracker/services/auth_service.dart';
import 'package:habit_tracker/components/habit_ball.dart';
import 'package:habit_tracker/components/myheatmap.dart';
import 'package:habit_tracker/pages/notes_section.dart';
import 'package:habit_tracker/pages/pomodoro_timer.dart';

class ResponsiveHomePage extends StatefulWidget {
  const ResponsiveHomePage({Key? key}) : super(key: key);

  @override
  _ResponsiveHomePageState createState() => _ResponsiveHomePageState();
}

class _ResponsiveHomePageState extends State<ResponsiveHomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isDarkMode = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Productivity Hub'),
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
              onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => context.read<AuthService>().signOut(),
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return _buildMobileView();
            }
            return _buildDesktopView();
          },
        ),
      ),
    );
  }

   Widget _buildMobileView() {
    return Column(
      children: [
        _buildPageIndicator(),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() => _currentPage = index);
              });
            },
            children: [
              Consumer<HabitDatabase>(
                builder: (context, habitDb, child) {
                  // if (habitDb.isLoading) {
                  //   return const Center(child: CircularProgressIndicator());
                  // }
                  if (habitDb == null) {
                    return Center(child: Text('Unknown error'));
                  }
                  return const HabitTrackerSection();
                },
              ),
              const PomodoroSection(),
              const NotesSection(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopView() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Consumer<HabitDatabase>(
  builder: (context, habitDb, child) {
    // Defensive check: habitDb is null
    if (habitDb == null) {
      return const Center(child: Text('HabitDatabase is not available.'));
    }

    // // Show loading indicator
    // if (habitDb.isLoading) {
    //   return const Center(child: CircularProgressIndicator());
    // }

    // // Show error if any
    // if (habitDb.error != null) {
    //   return Center(child: Text(habitDb.error!));
    // }

    // Show habits (replace with HabitTrackerSection)
    return const HabitTrackerSection();
  },
),

        ),
        Expanded(
          flex: 2,
          child: Column(
            children: const [
              Expanded(child: PomodoroSection()),
              Expanded(child: NotesSection()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          height: 8,
          width: _currentPage == index ? 24 : 8,
          decoration: BoxDecoration(
            color: _currentPage == index ? Colors.green : Colors.grey,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}