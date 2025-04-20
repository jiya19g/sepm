import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:badges/badges.dart' as badges;
import 'package:studybuddy_app/screens/RoomChatScreen.dart';

class StudyRoomScreen extends StatefulWidget {
  const StudyRoomScreen({Key? key}) : super(key: key);

  @override
  _StudyRoomScreenState createState() => _StudyRoomScreenState();
}

class _StudyRoomScreenState extends State<StudyRoomScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _myRooms = [];
  List<Map<String, dynamic>> _publicRooms = [];
  List<Map<String, dynamic>> _allPublicRooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Load user's rooms
      final myRoomsQuery = await _firestore.collection('rooms')
          .where('members', arrayContains: user.uid)
          .get();
      _myRooms = myRoomsQuery.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      // Load all public rooms
      final publicRoomsQuery = await _firestore.collection('rooms')
          .where('isPublic', isEqualTo: true)
          .get();
      _allPublicRooms = publicRoomsQuery.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      // Filter public rooms user isn't a member of
      _publicRooms = _allPublicRooms.where((room) => 
          !room['members'].contains(user.uid) && 
          room['createdBy'] != user.uid).toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load rooms: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createRoom({
    required String title,
    required List<String> tags,
    required bool isPublic,
    String? accessCode,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('rooms').add({
        'title': title,
        'tags': tags,
        'isPublic': isPublic,
        'accessCode': accessCode,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': user.uid,
        'members': [user.uid],
        'admins': [user.uid],
        'pendingRequests': [],
      });

      await _loadRooms();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room created successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create room: $e')),
      );
    }
  }

  Future<void> _joinRoom(String roomId, {String? accessCode}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final roomDoc = await _firestore.collection('rooms').doc(roomId).get();
      if (!roomDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Room not found')),
        );
        return;
      }

      final roomData = roomDoc.data()!;
      
      if (!roomData['isPublic']) {
        if (accessCode != roomData['accessCode']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid access code')),
          );
          return;
        }
        await _firestore.collection('rooms').doc(roomId).update({
          'members': FieldValue.arrayUnion([user.uid]),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joined private room successfully!')),
        );
      } else {
        if (roomData['pendingRequests'].contains(user.uid)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You already have a pending request')),
          );
          return;
        }
        
        await _firestore.collection('rooms').doc(roomId).update({
          'pendingRequests': FieldValue.arrayUnion([user.uid]),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Join request sent to room admin')),
        );
      }

      await _loadRooms();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining room: $e')),
      );
    }
  }

  Future<void> _deleteRoom(String roomId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final roomDoc = await _firestore.collection('rooms').doc(roomId).get();
      if (!roomDoc.exists) return;

      final roomData = roomDoc.data()!;
      if (!roomData['admins'].contains(user.uid)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Only admins can delete rooms')),
        );
        return;
      }

      await _firestore.collection('rooms').doc(roomId).delete();
      
      // Delete messages in batch
      final messages = await _firestore.collection('room_messages')
          .doc(roomId).collection('messages').get();
      
      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room deleted successfully')),
      );
      await _loadRooms();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting room: $e')),
      );
    }
  }

  String _generateAccessCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      6,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
  }

  void _showCreateRoomDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController tagsController = TextEditingController();
    bool isPublic = true;
    String? accessCode;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Create New Room'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Room Title*',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: tagsController,
                    decoration: InputDecoration(
                      labelText: 'Tags (comma separated)*',
                      hintText: 'math, calculus, homework',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Room Type:', style: TextStyle(fontSize: 16)),
                      ToggleButtons(
                        isSelected: [isPublic, !isPublic],
                        onPressed: (index) {
                          setState(() {
                            isPublic = index == 0;
                            if (!isPublic) {
                              accessCode = _generateAccessCode();
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        selectedColor: Colors.white,
                        fillColor: Colors.blue,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('Public'),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('Private'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!isPublic) ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Access Code: $accessCode',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Share this code with people you want to join',
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  if (titleController.text.isEmpty || tagsController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please fill all required fields')),
                    );
                    return;
                  }

                  final tags = tagsController.text
                      .split(',')
                      .map((tag) => tag.trim())
                      .where((tag) => tag.isNotEmpty)
                      .toList();

                  _createRoom(
                    title: titleController.text.trim(),
                    tags: tags,
                    isPublic: isPublic,
                    accessCode: accessCode,
                  );
                  Navigator.pop(context);
                },
                child: Text('Create', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showJoinPrivateRoomDialog() {
    final TextEditingController roomIdController = TextEditingController();
    final TextEditingController accessCodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Join Private Room'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: roomIdController,
              decoration: InputDecoration(
                labelText: 'Room ID',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: accessCodeController,
              decoration: InputDecoration(
                labelText: 'Access Code',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (roomIdController.text.isEmpty || 
                  accessCodeController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter both fields')),
                );
                return;
              }
              _joinRoom(
                roomIdController.text.trim(),
                accessCode: accessCodeController.text.trim(),
              );
              Navigator.pop(context);
            },
            child: Text('Join'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room, bool showDelete) {
    final isMember = room['members'].contains(_auth.currentUser?.uid);
    final isCreator = room['createdBy'] == _auth.currentUser?.uid;
    final isPublic = room['isPublic'] == true;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (isMember || isCreator) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RoomChatScreen(
                  roomId: room['id'],
                  roomTitle: room['title'],
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      room['title'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (showDelete && isCreator)
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteRoom(room['id']),
                    ),
                ],
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: room['tags'].map<Widget>((tag) => Chip(
                  label: Text(tag),
                  backgroundColor: Colors.blue[50],
                  labelStyle: TextStyle(color: Colors.blue),
                )).toList(),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    '${room['members'].length} members',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.lock, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    isPublic ? 'Public' : 'Private',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              SizedBox(height: 8),
              if (!isMember && !isCreator)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _joinRoom(room['id']),
                    child: Text('Request to Join'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Study Rooms'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'My Rooms'),
            Tab(text: 'Find Rooms'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // My Rooms Tab
                _myRooms.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.group, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'You have no rooms yet',
                              style: TextStyle(color: Colors.grey, fontSize: 18),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRooms,
                        child: ListView.builder(
                          padding: EdgeInsets.only(bottom: 80),
                          itemCount: _myRooms.length,
                          itemBuilder: (context, index) {
                            return _buildRoomCard(_myRooms[index], true);
                          },
                        ),
                      ),

                // Find Rooms Tab
                Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search rooms by title or tags...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          if (value.isEmpty) {
                            setState(() {
                              _publicRooms = _allPublicRooms.where((room) => 
                                !room['members'].contains(_auth.currentUser?.uid) && 
                                room['createdBy'] != _auth.currentUser?.uid
                              ).toList();
                            });
                          } else {
                            setState(() {
                              _publicRooms = _allPublicRooms.where((room) => 
                                (room['title'].toLowerCase().contains(value.toLowerCase()) ||
                                 room['tags'].any((tag) => tag.toLowerCase().contains(value.toLowerCase()))) &&
                                !room['members'].contains(_auth.currentUser?.uid) &&
                                room['createdBy'] != _auth.currentUser?.uid
                              ).toList();
                            });
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: _publicRooms.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'No rooms found',
                                    style: TextStyle(color: Colors.grey, fontSize: 18),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Try adjusting your search or create a new room',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadRooms,
                              child: ListView.builder(
                                padding: EdgeInsets.only(bottom: 80),
                                itemCount: _publicRooms.length,
                                itemBuilder: (context, index) {
                                  return _buildRoomCard(_publicRooms[index], false);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'join_private',
            mini: true,
            onPressed: _showJoinPrivateRoomDialog,
            child: Icon(Icons.vpn_key),
            tooltip: 'Join Private Room',
          ),
          SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'create_room',
            onPressed: _showCreateRoomDialog,
            child: Icon(Icons.add),
            tooltip: 'Create New Room',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}