import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRooms();
    _loadPendingRequests();
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
      _myRooms = await Future.wait(myRoomsQuery.docs.map((doc) async {
        final roomData = doc.data() as Map<String, dynamic>;
        final creator = await _getUserData(roomData['createdBy'] ?? '');
        return {
          'id': doc.id, 
          ...roomData,
          'createdByUser': creator,
        };
      }));

      // Load all public rooms
      final publicRoomsQuery = await _firestore.collection('rooms')
          .where('isPublic', isEqualTo: true)
          .get();
          
      _allPublicRooms = await Future.wait(publicRoomsQuery.docs.map((doc) async {
        final roomData = doc.data() as Map<String, dynamic>;
        final creator = await _getUserData(roomData['createdBy'] ?? '');
        return {
          'id': doc.id, 
          ...roomData,
          'createdByUser': creator,
        };
      }));

      // Filter public rooms user isn't a member of
      _publicRooms = _allPublicRooms.where((room) => 
          !(room['members'] as List).contains(user.uid)).toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load rooms: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _getUserData(String userId) async {
    try {
      if (userId.isEmpty) return _defaultUserData(userId);
      
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return _defaultUserData(userId);
      
      final userData = userDoc.data() as Map<String, dynamic>?;
      return {
        'username': userData?['username']?.toString() ?? 'Unknown',
        'email': userData?['email']?.toString() ?? '',
        'uid': userData?['uid']?.toString() ?? userId,
      };
    } catch (e) {
      return _defaultUserData(userId);
    }
  }

  Map<String, dynamic> _defaultUserData(String userId) {
    return {
      'username': 'Unknown',
      'email': '',
      'uid': userId,
    };
  }

  Future<void> _loadPendingRequests() async {
  final user = _auth.currentUser;
  if (user == null) return;

  try {
    final roomsWithRequests = await _firestore.collection('rooms')
        .where('admins', arrayContains: user.uid)
        .where('pendingRequests', isNotEqualTo: [])
        .get();

    _pendingRequests = [];
    for (var room in roomsWithRequests.docs) {
      final roomData = room.data() as Map<String, dynamic>;
      final pendingRequests = roomData['pendingRequests'] as List<dynamic>? ?? [];
      
      for (var userId in pendingRequests) {
        final userIdStr = userId.toString();
        final userDoc = await _firestore.collection('users').doc(userIdStr).get();
        final userData = userDoc.data() as Map<String, dynamic>?;
        
        _pendingRequests.add({
          'roomId': room.id,
          'roomTitle': roomData['title']?.toString() ?? 'Untitled Room',
          'userId': userIdStr,
          'username': userData?['username']?.toString() ?? 'Unknown User',
          'email': userData?['email']?.toString() ?? '',
        });
      }
    }
    setState(() {});
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error loading requests: $e')),
    );
  }
}

  Future<void> _createRoom({
    required String title,
    required String description,
    required String subject,
    required int maxMembers,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to create a room')),
      );
      return;
    }

    try {
      await _firestore.collection('rooms').add({
        'title': title,
        'description': description,
        'subject': subject,
        'maxMembers': maxMembers,
        'isPublic': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': user.uid,
        'members': [user.uid],
        'admins': [user.uid],
        'pendingRequests': [],
        'messages': [],
      });

      await _loadRooms();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room "$title" created successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create room: $e')),
      );
    }
  }

  Future<void> _requestToJoinRoom(String roomId) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to join a room')),
      );
      return;
    }

    try {
      final roomDoc = await _firestore.collection('rooms').doc(roomId).get();
      if (!roomDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Room does not exist')),
        );
        return;
      }

      final roomData = roomDoc.data() as Map<String, dynamic>;
      final members = roomData['members'] as List<dynamic>;
      final pendingRequests = roomData['pendingRequests'] as List<dynamic>;
      
      // Check if already a member
      if (members.contains(user.uid)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You are already a member of this room')),
        );
        return;
      }

      // Check if already requested
      if (pendingRequests.contains(user.uid)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You already have a pending request for this room')),
        );
        return;
      }

      await _firestore.collection('rooms').doc(roomId).update({
        'pendingRequests': FieldValue.arrayUnion([user.uid]),
      });

      // Add notification for the room admin
      final adminId = roomData['createdBy']?.toString() ?? '';
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      
      await _firestore.collection('notifications').add({
        'userId': adminId,
        'type': 'room_request',
        'roomId': roomId,
        'roomTitle': roomData['title']?.toString() ?? 'Untitled Room',
        'requesterId': user.uid,
        'requesterUsername': userData?['username']?.toString() ?? 'Unknown',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Join request sent to room admin')),
      );
      await _loadRooms();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error requesting to join: $e')),
      );
    }
  }

  Widget _buildRoomCard(Map<String, dynamic> room, bool isMyRoom) {
    final user = _auth.currentUser;
    final isMember = (room['members'] as List).contains(user?.uid);
    final isAdmin = (room['admins'] as List).contains(user?.uid);
    final currentMembers = (room['members'] as List).length;
    final maxMembers = room['maxMembers'] as int? ?? 50;
    final createdBy = room['createdByUser'] as Map<String, dynamic>? ?? _defaultUserData('');

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                    room['title']?.toString() ?? 'Untitled Room',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isAdmin)
                  Chip(
                    label: Text('Admin', style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.blue,
                  ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              room['description']?.toString() ?? '',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(room['subject']?.toString() ?? 'General'),
                  backgroundColor: Colors.blue[50],
                ),
                Chip(
                  avatar: Icon(Icons.people, size: 16),
                  label: Text('$currentMembers/$maxMembers'),
                ),
                Chip(
                  avatar: Icon(Icons.person, size: 16),
                  label: Text('Created by: ${createdBy['username']}'),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (isMyRoom)
              ElevatedButton.icon(
                icon: Icon(Icons.chat),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoomChatScreen(
                        roomId: room['id']?.toString() ?? '',
                        roomTitle: room['title']?.toString() ?? 'Study Room',
                        isAdmin: isAdmin,
                      ),
                    ),
                  );
                },
                label: Text('Enter Room'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 40),
                ),
              ),
            if (!isMyRoom && !isMember && currentMembers < maxMembers)
              ElevatedButton.icon(
                icon: Icon(Icons.group_add),
                onPressed: () => _requestToJoinRoom(room['id']?.toString() ?? ''),
                label: Text('Request to Join'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 40),
                ),
              ),
            if (!isMyRoom && !isMember && currentMembers >= maxMembers)
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Room is full', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  Future<void> _approveRequest(String roomId, String userId) async {
    try {
      final roomRef = _firestore.collection('rooms').doc(roomId);
      
      await _firestore.runTransaction((transaction) async {
        final roomDoc = await transaction.get(roomRef);
        
        if (!roomDoc.exists) {
          throw Exception('Room does not exist');
        }
        
        final roomData = roomDoc.data()!;
        final pendingRequests = List<String>.from(roomData['pendingRequests']);
        final members = List<String>.from(roomData['members']);
        final maxMembers = roomData['maxMembers'] ?? 50;
        
        if (members.length >= maxMembers) {
          throw Exception('Room is already at maximum capacity');
        }
        
        if (pendingRequests.contains(userId)) {
          transaction.update(roomRef, {
            'pendingRequests': FieldValue.arrayRemove([userId]),
            'members': FieldValue.arrayUnion([userId]),
          });
        }
      });

      // Add notification for the approved user
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'room_approval',
        'roomId': roomId,
        'roomTitle': (await _firestore.collection('rooms').doc(roomId).get()).data()?['title'] ?? 'Study Room',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      await _loadPendingRequests();
      await _loadRooms();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request approved - user added to room')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving request: $e')),
      );
    }
  }


  Future<void> _rejectRequest(String roomId, String userId) async {
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'pendingRequests': FieldValue.arrayRemove([userId]),
      });

      // Add notification for the rejected user
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'room_rejection',
        'roomId': roomId,
        'roomTitle': (await _firestore.collection('rooms').doc(roomId).get()).data()?['title'] ?? 'Study Room',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      await _loadPendingRequests();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request rejected')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting request: $e')),
      );
    }
  }


void _showCreateRoomDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController maxMembersController = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create New Study Room'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Room Title*',
                  hintText: 'e.g. Advanced Calculus Study Group',
                  border: OutlineInputBorder(),
                ),
                maxLength: 50,
              ),
              SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Description*',
                  hintText: 'Describe the purpose of this room',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 200,
              ),
              SizedBox(height: 16),
              TextField(
                controller: subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject*',
                  hintText: 'e.g. Mathematics, Physics, etc.',
                  border: OutlineInputBorder(),
                ),
                maxLength: 30,
              ),
              SizedBox(height: 16),
              TextField(
                controller: maxMembersController,
                decoration: InputDecoration(
                  labelText: 'Max Members*',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isEmpty || 
                  descController.text.isEmpty ||
                  subjectController.text.isEmpty ||
                  maxMembersController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please fill all required fields')),
                );
                return;
              }

              final maxMembers = int.tryParse(maxMembersController.text) ?? 10;
              if (maxMembers < 2 || maxMembers > 50) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Max members must be between 2 and 50')),
                );
                return;
              }

              _createRoom(
                title: titleController.text.trim(),
                description: descController.text.trim(),
                subject: subjectController.text.trim(),
                maxMembers: maxMembers,
              );
              Navigator.pop(context);
            },
            child: Text('Create Room'),
          ),
        ],
      ),
    );
  }

Widget _buildRequestCard(Map<String, dynamic> request) {
  return Card(
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Room: ${request['roomTitle']?.toString() ?? 'Unknown Room'}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Divider(),
          SizedBox(height: 8),
          Text(
            'Request from:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 4),
          Text(
            request['username']?.toString() ?? 'Unknown User',
            style: TextStyle(fontSize: 16),
          ),
          Text(
            request['email']?.toString() ?? '',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _rejectRequest(
                  request['roomId']?.toString() ?? '',
                  request['userId']?.toString() ?? '',
                ),
                child: Text('Reject', style: TextStyle(color: Colors.red)),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _approveRequest(
                  request['roomId']?.toString() ?? '',
                  request['userId']?.toString() ?? '',
                ),
                child: Text('Approve'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                ),
              ),
            ],
          ),
        ],
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
            Tab(icon: Icon(Icons.group), text: 'My Rooms'),
            Tab(icon: Icon(Icons.public), text: 'Public Rooms'),
            Tab(
              icon: Stack(
                children: [
                  Icon(Icons.notifications),
                  if (_pendingRequests.isNotEmpty)
                    Positioned(
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          _pendingRequests.length.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              text: 'Requests',
            ),
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
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _showCreateRoomDialog,
                              child: Text('Create Your First Room'),
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
                // Public Rooms Tab
                Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search rooms by title, subject or description...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _publicRooms = _allPublicRooms.where((room) => 
                              room['title'].toLowerCase().contains(value.toLowerCase()) ||
                              room['description'].toLowerCase().contains(value.toLowerCase()) ||
                              room['subject'].toLowerCase().contains(value.toLowerCase())
                            ).toList();
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: _publicRooms.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    _searchController.text.isEmpty
                                        ? 'No public rooms available'
                                        : 'No rooms match your search',
                                    style: TextStyle(color: Colors.grey, fontSize: 18),
                                  ),
                                  if (_searchController.text.isEmpty)
                                    Padding(
                                      padding: EdgeInsets.only(top: 16),
                                      child: ElevatedButton(
                                        onPressed: _showCreateRoomDialog,
                                        child: Text('Create New Room'),
                                      ),
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

                // Requests Tab
                _pendingRequests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No pending requests',
                              style: TextStyle(color: Colors.grey, fontSize: 18),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPendingRequests,
                        child: ListView.builder(
                          padding: EdgeInsets.only(bottom: 80),
                          itemCount: _pendingRequests.length,
                          itemBuilder: (context, index) {
                            return _buildRequestCard(_pendingRequests[index]);
                          },
                        ),
                      ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateRoomDialog,
        icon: Icon(Icons.add),
        label: Text('Create Room'),
        tooltip: 'Create New Study Room',
      ),
    );
  }
}