import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habit_tracker/main.dart';
import 'package:habit_tracker/screens/login_screen.dart';
import 'package:habit_tracker/services/databaseservice.dart';
import 'package:habit_tracker/widgets/study_room.dart';
import '../widgets/habit_list.dart';
import '../widgets/pomodoro_timer.dart';
import '../widgets/notes_widget.dart';
import '../widgets/profile_header.dart';
import 'dart:math' as math;
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
late ConfettiController _confettiController;
 @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(firestoreServiceProvider);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _confettiController.play();
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Welcome back! 🎉',
              style: GoogleFonts.poppins(),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: isDesktop
                ? _buildDesktopLayout(colorScheme)
                : _buildMobileLayout(colorScheme),
          ),
          bottomNavigationBar: isDesktop ? null : _buildBottomNav(colorScheme),
          appBar: isDesktop
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(kToolbarHeight),
                  child: _buildAppbar(colorScheme),
                )
              : null,
        ),
        // Top center confetti
          if (mounted) ...[
          // Top center confetti with optimized parameters
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: math.pi/2,
              maxBlastForce: 5, // Reduced force
              minBlastForce: 2,
              emissionFrequency: 0.05, // Reduced frequency
              numberOfParticles: 50, // Reduced particles
              gravity: 0.05,
              shouldLoop: false,
              colors: [
                colorScheme.primary,
                colorScheme.secondary,
                colorScheme.tertiary,
                Colors.pink,
              Colors.yellow,
              Colors.blue,
              ],
           
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 0,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              maxBlastForce: 100,
              minBlastForce: 80,
              gravity: 0.2,
              shouldLoop: false,
              colors: [
                colorScheme.primary,
                colorScheme.secondary,
                colorScheme.tertiary,
                Colors.pink,
              Colors.yellow,
              Colors.blue,
              ],
          
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: math.pi,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              maxBlastForce: 100,
              minBlastForce: 80,
              gravity: 0.2,
              shouldLoop: false,
              colors: [
                colorScheme.primary,
                colorScheme.secondary,
                colorScheme.tertiary,
                Colors.pink,
              Colors.yellow,
              Colors.blue,
              ],
           
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildAppbar(ColorScheme colorScheme) {
    return AppBar(
      title:  Text('Habit Tracker',style: GoogleFonts.poppins(),),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            Theme.of(context).brightness == Brightness.dark
                ? Icons.light_mode
                : Icons.dark_mode,
            color: colorScheme.onPrimaryContainer,
          ),
          onPressed: () {
            ref.read(themeProvider.notifier).state =
                Theme.of(context).brightness == Brightness.dark
                    ? ThemeMode.light
                    : ThemeMode.dark;
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          hoverColor: Colors.red,
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );
          },
        ),  
      ],
    );
  }

 Widget _buildDesktopLayout(ColorScheme colorScheme) {
  return Row(
    children: [
      SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.8),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Add this
              children: [
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: ProfileHeader(),
                ),
                const SizedBox(height: 24),
                _buildDesktopNav(colorScheme),
              ],
            ),
          ),
        ),
      ),
      Expanded(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: _buildCurrentPage(colorScheme),
          ),
        ),
      ),
    ],
  );
}
  Widget _buildMobileLayout(ColorScheme colorScheme) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.9),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _getPageTitle(),
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    Theme.of(context).brightness == Brightness.dark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                  padding: const EdgeInsets.all(8),
                  onPressed: () {
                    ref.read(themeProvider.notifier).state =
                        Theme.of(context).brightness == Brightness.dark
                            ? ThemeMode.light
                            : ThemeMode.dark;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.logout_rounded,
                    color: colorScheme.error,
                    size: 22,
                  ),
                  padding: const EdgeInsets.all(8),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Text(
                          'Logout',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        content: Text(
                          'Are you sure you want to logout?',
                          style: GoogleFonts.poppins(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.error,
                              foregroundColor: colorScheme.onError,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Logout',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      if (_currentIndex == 0) ...[
        const ProfileHeader(),
      ],
    ],
  ),
)
        ),
        // Page Content
        Expanded(
          child: _buildCurrentPage(colorScheme),
        ),
      ],
    );
  }



  Widget _buildDesktopNav(ColorScheme colorScheme) {
    final destinations = [
      ('Home', Icons.home_outlined, Icons.home),
      ('Timer', Icons.timer_outlined, Icons.timer),
      ('Notes', Icons.note_outlined, Icons.note),
        ('Study Room', Icons.groups_outlined, Icons.groups),
    ];

    return ListView.builder(
      shrinkWrap: true,
      itemCount: destinations.length,
      itemBuilder: (context, index) {
        final (label, icon, selectedIcon) = destinations[index];

        final isSelected = _currentIndex == index;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onPrimaryContainer,
              ),
              title: Text(
                label,
                
                style: GoogleFonts.poppins(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onPrimaryContainer,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              onTap: () => setState(() => _currentIndex = index),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
           NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Study Room',
          ),
        ],
      ),
    );
  }


    Widget _buildCurrentPage(ColorScheme colorScheme) {
    switch (_currentIndex) {
      case 0:
        return const HabitList();
      case 1:
        return const PomodoroTimer();
      case 2:
        return const NotesWidget();
      case 3:
      return const StudyRoom();
      default:
        return const SizedBox.shrink();
    }
  }

  String _getPageTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Your Habits';

      case 1:
        return 'Focus Timer';


      case 2:
        return 'Notes';

        case 3:
        return 'Study Room';

      default:
        return '';
    }
  }
}
