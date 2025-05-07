import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LecturesScreen extends StatefulWidget {
  @override
  _LecturesScreenState createState() => _LecturesScreenState();
}

class _LecturesScreenState extends State<LecturesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customTitleController = TextEditingController();
  final TextEditingController _customUrlController = TextEditingController();
  final TextEditingController _customChannelController = TextEditingController();
  List<Subject> _filteredSubjects = [];
  bool _isSearching = false;
  String? _selectedSubject;

  final List<Subject> _subjects = [
    Subject(
      name: 'Data Structures and Algorithms',
      description: 'Learn fundamental data structures and algorithms',
      playlists: [
        Playlist(
          title: 'DSA by Abdul Bari',
          url: 'https://www.youtube.com/playlist?list=PLDN4rrl48XKpZkf03iYFl-O29szjTrs_O',
          channel: 'Abdul Bari',
        ),
        Playlist(
          title: 'DSA by CodeWithHarry',
          url: 'https://www.youtube.com/playlist?list=PLu0W_9lII9ahIappRPN0MCAgtOu3lQjQi',
          channel: 'CodeWithHarry',
        ),
      ],
      icon: Icons.data_array,
      color: Colors.blue,
    ),
    Subject(
      name: 'Object-Oriented Programming',
      description: 'Master OOP concepts and design patterns',
      playlists: [
        Playlist(
          title: 'OOP by Telusko',
          url: 'https://www.youtube.com/playlist?list=PLsyeobzWxl7oZ-fxDYkOToURHhMuWD1BK',
          channel: 'Telusko',
        ),
        Playlist(
          title: 'OOP by Kunal Kushwaha',
          url: 'https://www.youtube.com/playlist?list=PL9gnSGHSqcnr_DxHsP7AW9ftq0AtAyYqJ',
          channel: 'Kunal Kushwaha',
        ),
      ],
      icon: Icons.code,
      color: Colors.green,
    ),
    Subject(
      name: 'Database Management Systems',
      description: 'Learn SQL, database design, and management',
      playlists: [
        Playlist(
          title: 'DBMS by Gate Smashers',
          url: 'https://www.youtube.com/playlist?list=PLxCzCOWd7aiFAN6I8CuViBuCdJgiOkT2Y',
          channel: 'Gate Smashers',
        ),
        Playlist(
          title: 'SQL by freeCodeCamp',
          url: 'https://www.youtube.com/watch?v=HXV3zeQKqGY',
          channel: 'freeCodeCamp',
        ),
      ],
      icon: Icons.storage,
      color: Colors.orange,
    ),
    Subject(
      name: 'Operating Systems',
      description: 'Understand OS concepts and internals',
      playlists: [
        Playlist(
          title: 'OS by Gate Smashers',
          url: 'https://www.youtube.com/playlist?list=PLxCzCOWd7aiGz9donHRrE9I3Mwn6XdP8p',
          channel: 'Gate Smashers',
        ),
        Playlist(
          title: 'OS by Neso Academy',
          url: 'https://www.youtube.com/playlist?list=PLBlnK6fEyqRiVhbXDGLXDk_OQAeuVcp2O',
          channel: 'Neso Academy',
        ),
      ],
      icon: Icons.computer,
      color: Colors.purple,
    ),
    Subject(
      name: 'Computer Networks',
      description: 'Learn networking protocols and concepts',
      playlists: [
        Playlist(
          title: 'CN by Gate Smashers',
          url: 'https://www.youtube.com/playlist?list=PLxCzCOWd7aiGFBD2-2joCpWOLUrDLvVV_',
          channel: 'Gate Smashers',
        ),
        Playlist(
          title: 'CN by Neso Academy',
          url: 'https://www.youtube.com/playlist?list=PLBlnK6fEyqRgMCUAG0XRw78UA8qnv6jEx',
          channel: 'Neso Academy',
        ),
      ],
      icon: Icons.lan,
      color: Colors.red,
    ),
    Subject(
      name: 'Software Engineering',
      description: 'Software development lifecycle and methodologies',
      playlists: [
        Playlist(
          title: 'SE by Gate Smashers',
          url: 'https://www.youtube.com/playlist?list=PLxCzCOWd7aiEed7SKZBnC6ypFDWYLRvB2',
          channel: 'Gate Smashers',
        ),
        Playlist(
          title: 'SE by Neso Academy',
          url: 'https://www.youtube.com/playlist?list=PLBlnK6fEyqRj9lld8sWIUNwlKfdUoPd1Y',
          channel: 'Neso Academy',
        ),
      ],
      icon: Icons.engineering,
      color: Colors.teal,
    ),
    Subject(
      name: 'Machine Learning',
      description: 'AI and ML concepts, algorithms, and applications',
      playlists: [
        Playlist(
          title: 'ML by Krish Naik',
          url: 'https://www.youtube.com/playlist?list=PLZoTAELRMXVPBTrWtJin3z8Wk6GQb_0B5',
          channel: 'Krish Naik',
        ),
        Playlist(
          title: 'ML by CodeWithHarry',
          url: 'https://www.youtube.com/playlist?list=PLu0W_9lII9ai6fAMHp-acBmJONT7Y4BSG',
          channel: 'CodeWithHarry',
        ),
      ],
      icon: Icons.psychology,
      color: Colors.pink,
    ),
    Subject(
      name: 'Web Development',
      description: 'Frontend and backend web development',
      playlists: [
        Playlist(
          title: 'Web Dev by Traversy Media',
          url: 'https://www.youtube.com/playlist?list=PLillGF-RfqbYeckUaD1z6nviTp31GLTH8',
          channel: 'Traversy Media',
        ),
        Playlist(
          title: 'Web Dev by CodeWithHarry',
          url: 'https://www.youtube.com/playlist?list=PLu0W_9lII9agiCUZYRsvtGTXdxkzPyItg',
          channel: 'CodeWithHarry',
        ),
      ],
      icon: Icons.web,
      color: Colors.indigo,
    ),
    Subject(
      name: 'Mobile Development',
      description: 'Android and iOS app development',
      playlists: [
        Playlist(
          title: 'Flutter by The Net Ninja',
          url: 'https://www.youtube.com/playlist?list=PL4cUxeGkcC9jLYyp2Aoh6hcWuxFDX6PBJ',
          channel: 'The Net Ninja',
        ),
        Playlist(
          title: 'Android by CodeWithHarry',
          url: 'https://www.youtube.com/playlist?list=PLu0W_9lII9aiL0kysYlfSOUgY5rN1ShDd',
          channel: 'CodeWithHarry',
        ),
      ],
      icon: Icons.phone_android,
      color: Colors.deepPurple,
    ),
    Subject(
      name: 'Cloud Computing',
      description: 'AWS, Azure, and cloud services',
      playlists: [
        Playlist(
          title: 'AWS by freeCodeCamp',
          url: 'https://www.youtube.com/watch?v=3hLmDS179YE',
          channel: 'freeCodeCamp',
        ),
        Playlist(
          title: 'Cloud by Simplilearn',
          url: 'https://www.youtube.com/playlist?list=PLEiEAq2VkUULlNtIFhEQHo8gacvme35rz',
          channel: 'Simplilearn',
        ),
      ],
      icon: Icons.cloud,
      color: Colors.cyan,
    ),
    Subject(
      name: 'Cybersecurity',
      description: 'Network security and ethical hacking',
      playlists: [
        Playlist(
          title: 'Cyber Security by Simplilearn',
          url: 'https://www.youtube.com/playlist?list=PLEiEAq2VkUUIk2HnEsNx9e8QnCG6qgqA5',
          channel: 'Simplilearn',
        ),
        Playlist(
          title: 'Ethical Hacking by freeCodeCamp',
          url: 'https://www.youtube.com/watch?v=3Kq1MIfTWCE',
          channel: 'freeCodeCamp',
        ),
      ],
      icon: Icons.security,
      color: Colors.amber,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _filteredSubjects = _subjects;
    _loadCustomPlaylists();
  }

  Future<void> _loadCustomPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final customPlaylistsJson = prefs.getString('custom_playlists');
    if (customPlaylistsJson != null) {
      final List<dynamic> customPlaylists = jsonDecode(customPlaylistsJson);
      for (var playlist in customPlaylists) {
        final subject = _subjects.firstWhere(
          (s) => s.name == playlist['subject'],
          orElse: () => Subject(
            name: playlist['subject'],
            description: 'Custom playlists',
            playlists: [],
            icon: Icons.playlist_add,
            color: Colors.grey,
          ),
        );
        subject.playlists.add(Playlist(
          title: playlist['title'],
          url: playlist['url'],
          channel: playlist['channel'],
        ));
      }
      setState(() {
        _filteredSubjects = _subjects;
      });
    }
  }

  Future<void> _saveCustomPlaylist(String subject, Playlist playlist) async {
    final prefs = await SharedPreferences.getInstance();
    final customPlaylistsJson = prefs.getString('custom_playlists');
    List<dynamic> customPlaylists = [];
    if (customPlaylistsJson != null) {
      customPlaylists = jsonDecode(customPlaylistsJson);
    }
    customPlaylists.add({
      'subject': subject,
      'title': playlist.title,
      'url': playlist.url,
      'channel': playlist.channel,
    });
    await prefs.setString('custom_playlists', jsonEncode(customPlaylists));
  }

  void _showAddPlaylistDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add Custom Playlist'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Select Subject',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedSubject,
                  items: _subjects.map((subject) {
                    return DropdownMenuItem(
                      value: subject.name,
                      child: Text(subject.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSubject = value;
                    });
                  },
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _customTitleController,
                  decoration: InputDecoration(
                    labelText: 'Playlist Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _customUrlController,
                  decoration: InputDecoration(
                    labelText: 'YouTube URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _customChannelController,
                  decoration: InputDecoration(
                    labelText: 'Channel Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _customTitleController.clear();
                _customUrlController.clear();
                _customChannelController.clear();
                _selectedSubject = null;
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_selectedSubject == null ||
                    _customTitleController.text.isEmpty ||
                    _customUrlController.text.isEmpty ||
                    _customChannelController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please fill in all fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final newPlaylist = Playlist(
                  title: _customTitleController.text,
                  url: _customUrlController.text,
                  channel: _customChannelController.text,
                );

                // Find the subject and add the playlist
                final subject = _subjects.firstWhere(
                  (s) => s.name == _selectedSubject,
                  orElse: () => Subject(
                    name: _selectedSubject!,
                    description: 'Custom playlists',
                    playlists: [],
                    icon: Icons.playlist_add,
                    color: Colors.grey,
                  ),
                );

                // Add the playlist to the subject
                subject.playlists.add(newPlaylist);

                // Save to SharedPreferences
                await _saveCustomPlaylist(_selectedSubject!, newPlaylist);

                // Clear the form
                _customTitleController.clear();
                _customUrlController.clear();
                _customChannelController.clear();
                _selectedSubject = null;

                // Update the UI
                this.setState(() {
                  _filteredSubjects = _subjects;
                });

                // Close the dialog
                Navigator.pop(context);

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Playlist added successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text('Add Playlist'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      )) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch $url'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching URL: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterSubjects(String query) {
    setState(() {
      _filteredSubjects = _subjects.where((subject) {
        return subject.name.toLowerCase().contains(query.toLowerCase()) ||
            subject.description.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Engineering Lectures',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddPlaylistDialog,
            tooltip: 'Add Custom Playlist',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search subjects...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: _filterSubjects,
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _filteredSubjects.length,
              itemBuilder: (context, index) {
                final subject = _filteredSubjects[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    leading: Icon(subject.icon, color: subject.color),
                    title: Text(
                      subject.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(subject.description),
                    children: [
                      ...subject.playlists.map((playlist) {
                        return ListTile(
                          title: Text(playlist.title),
                          subtitle: Text('Channel: ${playlist.channel}'),
                          trailing: Icon(Icons.play_circle_outline),
                          onTap: () => _launchURL(playlist.url),
                        );
                      }).toList(),
                      if (subject.playlists.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No playlists available',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPlaylistDialog,
        child: Icon(Icons.add),
        tooltip: 'Add Custom Playlist',
      ),
    );
  }
}

class Subject {
  final String name;
  final String description;
  final List<Playlist> playlists;
  final IconData icon;
  final Color color;

  Subject({
    required this.name,
    required this.description,
    required this.playlists,
    required this.icon,
    required this.color,
  });
}

class Playlist {
  final String title;
  final String url;
  final String channel;

  Playlist({
    required this.title,
    required this.url,
    required this.channel,
  });
} 