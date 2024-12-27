import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habit_tracker/models/user_stats_model.dart';
import 'package:habit_tracker/services/stats_services.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

class ProfileHeader extends ConsumerWidget {
  const ProfileHeader({Key? key}) : super(key: key);

  

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width > 768;
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.primary;

    Stream<UserStatsModel> getUserStats() {
      return ref.read(statsServiceProvider).getUserStats();
    }

    return StreamBuilder<UserModel?>(
      stream: ref.read(userServiceProvider).getCurrentUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Something went wrong',
              style: GoogleFonts.poppins(color: colorScheme.error),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: color),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return Center(
            child: Text(
              'No user data found',
              style: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant),
            ),
          );
        }

        if (isDesktop) {
          return Card(
            margin: EdgeInsets.zero,
            elevation: 8,
            shadowColor: color.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surface,
                    colorScheme.surface.withOpacity(0.9),
                    colorScheme.surface.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color,
                              colorScheme.secondary,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 72,
                          backgroundColor: colorScheme.surface,
                          backgroundImage: user.profileImageUrl != null
                              ? NetworkImage(user.profileImageUrl!)
                              : null,
                          child: user.profileImageUrl == null
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 72,
                                  color: color,
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: -8,
                        right: -8,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: color,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.2),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.verified_rounded,
                            color: color,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    user.username,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.1),
                          colorScheme.secondary.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      user.email,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  StreamBuilder<UserStatsModel>(
                    stream: getUserStats(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
          
                      final stats = snapshot.data!;
                      
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatCard(
                              context,
                              '${stats.currentStreak}',
                              'Day Streak',
                              Icons.local_fire_department_rounded,
                            ),
                            const SizedBox(width: 16),
                            _buildStatCard(
                              context,
                              '${stats.completionRate.toStringAsFixed(0)}%',
                              'Completion',
                              Icons.check_circle_rounded,
                            ),
                            const SizedBox(width: 16),
                            _buildStatCard(
                              context,
                              '${stats.totalHabits}',
                              'Habits',
                              Icons.track_changes_rounded,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (user.description != null &&
                      user.description!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: color.withOpacity(0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.1),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Text(
                        user.description!,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: colorScheme.onSurface,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => _showEditProfileDialog(context, user, ref),
                    icon: Icon(Icons.edit_rounded, color: colorScheme.onPrimary),
                    label: Text(
                      'Edit Profile',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                      shadowColor: color.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Mobile version
        return GestureDetector(
          onTap: () => _showFullProfile(context, user, ref),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [color, colorScheme.secondary],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: colorScheme.surface,
                    backgroundImage: user.profileImageUrl != null
                        ? NetworkImage(user.profileImageUrl!)
                        : null,
                    child: user.profileImageUrl == null
                        ? Icon(
                            Icons.person_rounded,
                            size: 32,
                            color: color,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            size: 16,
                            color: color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '7 Day Streak',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _buildStatCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showFullProfile(BuildContext context, UserModel user, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [color, colorScheme.secondary],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: colorScheme.surface,
                backgroundImage: user.profileImageUrl != null
                    ? NetworkImage(user.profileImageUrl!)
                    : null,
                child: user.profileImageUrl == null
                    ? Icon(
                        Icons.person_rounded,
                        size: 48,
                        color: color,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              user.username,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            StreamBuilder<UserStatsModel>(
              stream: ref.read(statsServiceProvider).getUserStats(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final stats = snapshot.data!;
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMobileStatItem(
                      context,
                      '${stats.currentStreak}',
                      'Day Streak',
                      Icons.local_fire_department_rounded,
                    ),
                    _buildMobileStatItem(
                      context,
                      '${stats.completionRate.toStringAsFixed(0)}%',
                      'Completion',
                      Icons.check_circle_rounded,
                    ),
                    _buildMobileStatItem(
                      context,
                      '${stats.totalHabits}',
                      'Habits',
                      Icons.track_changes_rounded,
                    ),
                  ],
                );
              },
            ),
            if (user.description != null && user.description!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: color.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  user.description!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: colorScheme.onSurface,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showEditProfileDialog(context, user, ref);
              },
              icon: Icon(Icons.edit_rounded, color: colorScheme.onPrimary),
              label: Text(
                'Edit Profile',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimary,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: color.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

  }
  Widget _buildMobileStatItem(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.primary;

    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _showEditProfileDialog(
    BuildContext context,
    UserModel user,
    WidgetRef ref,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.primary;
    final usernameController = TextEditingController(text: user.username);
    final descriptionController = TextEditingController(text: user.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.outline,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: color,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.outline,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: color,
                    width: 2,
                  ),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onSurfaceVariant,
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(userServiceProvider).updateUserProfile(
                    username: usernameController.text,
                    description: descriptionController.text,
                  );
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}