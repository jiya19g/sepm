import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(context, theme, textColor, secondaryTextColor),
            const SizedBox(height: 32),
            
            _buildSectionTitle('Account Settings', textColor),
            _buildSettingsCard(context, cardColor, textColor, secondaryTextColor),
            const SizedBox(height: 24),
            
            _buildSectionTitle('Study Statistics', textColor),
            _buildStatsGrid(context, cardColor, textColor, secondaryTextColor),
            const SizedBox(height: 24),
            
            _buildSectionTitle('App Settings', textColor),
            _buildSettingsList(context, cardColor, textColor, secondaryTextColor),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, ThemeData theme, Color textColor, Color secondaryTextColor) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
          child: Icon(
            Icons.person,
            size: 50,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'John Doe',
          style: TextStyle(
            color: textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Computer Science Student',
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.tonal(
          onPressed: () {},
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Edit Profile'),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, Color cardColor, Color textColor, Color secondaryTextColor) {
    return Card(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildListTile(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: 'john.doe@example.com',
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            onTap: () {},
          ),
          const Divider(height: 0, indent: 16, endIndent: 16),
          _buildListTile(
            icon: Icons.lock_outlined,
            title: 'Password',
            subtitle: '••••••••',
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            onTap: () {},
          ),
          const Divider(height: 0, indent: 16, endIndent: 16),
          _buildListTile(
            icon: Icons.phone_outlined,
            title: 'Phone Number',
            subtitle: '+1 (555) 123-4567',
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color secondaryTextColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: secondaryTextColor),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: secondaryTextColor),
      ),
      trailing: Icon(Icons.chevron_right, color: secondaryTextColor),
      onTap: onTap,
      minVerticalPadding: 16,
    );
  }

  Widget _buildStatsGrid(BuildContext context, Color cardColor, Color textColor, Color secondaryTextColor) {
    return SizedBox(
      height: MediaQuery.of(context).size.width * 0.9, // Fixed height based on screen width
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 1.2, // Adjusted ratio
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          _buildStatCard('5', 'Current Streak', cardColor, textColor, secondaryTextColor),
          _buildStatCard('27', 'Total Hours', cardColor, textColor, secondaryTextColor),
          _buildStatCard('15', 'Sessions', cardColor, textColor, secondaryTextColor),
          _buildStatCard('A', 'Avg. Grade', cardColor, textColor, secondaryTextColor),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color cardColor, Color textColor, Color secondaryTextColor) {
    return Card(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, Color cardColor, Color textColor, Color secondaryTextColor) {
    return Card(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildListTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Enabled',
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            onTap: () {},
          ),
          const Divider(height: 0, indent: 16, endIndent: 16),
          _buildListTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            subtitle: 'System Default',
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            onTap: () {},
          ),
          const Divider(height: 0, indent: 16, endIndent: 16),
          _buildListTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Contact us',
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            onTap: () {},
          ),
          const Divider(height: 0, indent: 16, endIndent: 16),
          _buildListTile(
            icon: Icons.logout,
            title: 'Log Out',
            subtitle: '',
            textColor: Colors.red,
            secondaryTextColor: secondaryTextColor,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}