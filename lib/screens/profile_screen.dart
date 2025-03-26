import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Profile'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(),
            SizedBox(height: 24),

            _buildSectionTitle('Account Settings'),
            _buildSettingsCard(),
            SizedBox(height: 16),

            _buildSectionTitle('Study Statistics'),
            _buildStatsGrid(),
            SizedBox(height: 16),

            _buildSectionTitle('App Settings'),
            _buildSettingsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey.shade300,
          child: Icon(Icons.person, size: 50, color: Colors.black54),
        ),
        SizedBox(height: 16),
        Text(
          'John Doe',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Computer Science Student',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text('Edit Profile'),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildListTile(
              icon: Icons.email,
              title: 'Email',
              subtitle: 'john.doe@example.com',
              onTap: () {},
            ),
            Divider(),
            _buildListTile(
              icon: Icons.security,
              title: 'Password',
              subtitle: '••••••••',
              onTap: () {},
            ),
            Divider(),
            _buildListTile(
              icon: Icons.phone,
              title: 'Phone Number',
              subtitle: '+1 (555) 123-4567',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(
        title,
        style: TextStyle(color: Colors.black87),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.black54),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard('5', 'Current Streak'),
        _buildStatCard('27', 'Total Hours'),
        _buildStatCard('15', 'Sessions'),
        _buildStatCard('A', 'Avg. Grade'),
      ],
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsList() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          _buildListTile(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Enabled',
            onTap: () {},
          ),
          Divider(),
          _buildListTile(
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            subtitle: 'System Default',
            onTap: () {},
          ),
          Divider(),
          _buildListTile(
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: 'Contact us',
            onTap: () {},
          ),
          Divider(),
          _buildListTile(
            icon: Icons.logout,
            title: 'Log Out',
            subtitle: '',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
