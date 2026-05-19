import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_codex/core/cubits/theme/theme_cubit.dart';
import 'package:test_codex/core/utils/app_colors.dart';
import 'package:test_codex/core/utils/route_names.dart';
import 'package:test_codex/core/widgets/app_background.dart';
import 'package:test_codex/core/widgets/app_bottom_nav_bar.dart';
import 'package:test_codex/features/settings/domain/entities/settings_user_entity.dart';
import 'package:test_codex/features/settings/presentation/models/settings_profile_update_data.dart';
import 'package:test_codex/features/settings/presentation/cubits/settings/settings_cubit.dart';
import 'package:test_codex/features/settings/presentation/widgets/settings_edit_profile_sheet.dart';
import 'package:test_codex/features/settings/presentation/widgets/settings_header.dart';
import 'package:test_codex/features/settings/presentation/widgets/settings_logout_button.dart';
import 'package:test_codex/features/settings/presentation/widgets/settings_profile_card.dart';
import 'package:test_codex/features/settings/presentation/widgets/settings_section.dart';
import 'package:test_codex/features/settings/presentation/widgets/settings_tile.dart';

class SettingsViewBody extends StatelessWidget {
  const SettingsViewBody({required this.user, super.key});

  final SettingsUserEntity? user;

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().state.isDark;
    return AppBackground(
      useRegisterColor: true,
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SettingsHeader(user: user),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () =>
                        context.read<SettingsCubit>().getCurrentUser(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                      children: [
                        SettingsProfileCard(
                          user: user,
                          onEditProfile: () => _showEditProfileSheet(context),
                        ),
                        const SizedBox(height: 24),
                        const SettingsSection(
                          title: 'Account',
                          tiles: [
                            SettingsTile(
                              icon: Icons.lock_outline,
                              title: 'Privacy',
                            ),
                            SettingsTile(
                              icon: Icons.security_outlined,
                              title: 'Security',
                            ),
                            SettingsTile(
                              icon: Icons.password,
                              title: 'Change Password',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SettingsSection(
                          title: 'Appearance',
                          tiles: [
                            SettingsTile(
                              icon: Icons.dark_mode_outlined,
                              title: 'Dark Mode',
                              hasSwitch: true,
                              switchValue: isDark,
                              onSwitchChanged: (value) => context
                                  .read<ThemeCubit>()
                                  .changeTheme(isDark: value),
                            ),
                            const SettingsTile(
                              icon: Icons.wallpaper_outlined,
                              title: 'Chat Wallpaper',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const SettingsSection(
                          title: 'Notifications',
                          tiles: [
                            SettingsTile(
                              icon: Icons.notifications_none,
                              title: 'Messages',
                              hasSwitch: true,
                              switchValue: true,
                            ),
                            SettingsTile(
                              icon: Icons.groups_outlined,
                              title: 'Groups',
                              hasSwitch: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const SettingsSection(
                          title: 'Support',
                          tiles: [
                            SettingsTile(
                              icon: Icons.help_outline,
                              title: 'Help & Support',
                            ),
                          ],
                        ),
                        const SizedBox(height: 34),
                        SettingsLogoutButton(
                          onPressed: () =>
                              context.read<SettingsCubit>().logout(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            AppBottomNavBar(
              selectedIndex: 2,
              onItemSelected: (index) {
                if (index == 0) {
                  Navigator.pushReplacementNamed(context, RouteNames.home);
                } else if (index == 1) {
                  Navigator.pushReplacementNamed(context, RouteNames.groups);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditProfileSheet(BuildContext context) async {
    final result = await showModalBottomSheet<SettingsProfileUpdateData>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => SettingsEditProfileSheet(user: user),
    );
    if (result == null || !context.mounted) {
      return;
    }
    await context.read<SettingsCubit>().updateProfile(
      name: result.name,
      imagePath: result.imagePath,
      deletePhoto: result.deletePhoto,
    );
  }
}
