import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/main.dart';
import 'package:habit_tracker/services/databaseservice.dart';
import '../widgets/habit_list.dart';
import '../widgets/pomodoro_timer.dart';
import '../widgets/notes_widget.dart';
import '../widgets/profile_header.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Ensure safe access to the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(firestoreServiceProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      body: SafeArea(
        child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
      bottomNavigationBar: isDesktop ? null : _buildBottomNav(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        SizedBox(width: 300, child: _buildSidebar()),
        Expanded(child: _buildMainContent()),
        SizedBox(width: 300, child: _buildRightSidebar()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return IndexedStack(
      index: _currentIndex,
      children: [
        _buildMainContent(),
        _buildTimerPage(),
        _buildNotesPage(),
      ],
    );
  }

  Widget _buildSidebar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: const SingleChildScrollView(
        child: ProfileHeader(),
      ),
    );
  }

  Widget _buildMainContent() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('Your Habits'),
          floating: true,
          actions: [
            IconButton(
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              onPressed: () {
                ref.read(themeProvider.notifier).state =
                    Theme.of(context).brightness == Brightness.dark
                        ? ThemeMode.light
                        : ThemeMode.dark;
              },
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverToBoxAdapter(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: const HabitList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimerPage() {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          title: Text('Focus Timer'),
          pinned: true,
        ),
        SliverFillRemaining(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: const PomodoroTimer(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesPage() {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          title: Text('Notes'),
          pinned: true,
        ),
        SliverFillRemaining(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: const NotesWidget(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRightSidebar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: const SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: PomodoroTimer(),
            ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: NotesWidget(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) {
        setState(() => _currentIndex = index);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.timer_outlined),
          selectedIcon: Icon(Icons.timer),
          label: 'Timer',
        ),
        NavigationDestination(
          icon: Icon(Icons.note_outlined),
          selectedIcon: Icon(Icons.note),
          label: 'Notes',
        ),
      ],
    );
  }
}
