import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

class RoomChatScreen extends StatefulWidget {
  final String roomId;
  final String roomTitle;

  const RoomChatScreen({required this.roomId, required this.roomTitle});

  @override
  _RoomChatScreenState createState() => _RoomChatScreenState();
}

class _RoomChatScreenState extends State<RoomChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<types.Message> _messages = [];
  late String _currentUserId;
  late CollectionReference _messagesRef;

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid ?? '';
    _messagesRef = _firestore.collection('room_messages')
        .doc(widget.roomId)
        .collection('messages');
    _setupMessagesListener();
  }

  void _setupMessagesListener() {
    _messagesRef
      .orderBy('timestamp', descending: true) // Get newest messages first
      .snapshots()
      .listen((snapshot) {
        final messages = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final timestamp = data['timestamp'] as Timestamp?;
          
          if (data['isSystemMessage'] == true) {
            return types.SystemMessage(
              author: types.User(id: data['senderId'] as String),
              createdAt: timestamp?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
              id: doc.id,
              text: data['text'] as String,
            );
          }
          return types.TextMessage(
            author: types.User(id: data['senderId'] as String),
            createdAt: timestamp?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
            id: doc.id,
            text: data['text'] as String,
          );
        }).toList();

        if (mounted) {
          // Reverse the list to show newest at bottom
          setState(() => _messages = messages.toList());

        }
      });
  }

  void _handleSendPressed(types.PartialText message) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Optimistic update - add message immediately to local state
    final tempMessage = types.TextMessage(
      author: types.User(id: user.uid),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: message.text,
    );

    setState(() => _messages = [..._messages, tempMessage]);

    // Then send to Firestore
    await _messagesRef.add({
      'text': message.text,
      'senderId': user.uid,
      'senderName': user.displayName ?? 'Anonymous',
      'timestamp': FieldValue.serverTimestamp(),
      'isSystemMessage': false,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomTitle),
      ),
      body: Chat(
        messages: _messages,
        onSendPressed: _handleSendPressed,
        user: types.User(id: _currentUserId),
        theme: DefaultChatTheme(
          primaryColor: Colors.blue,
          secondaryColor: Colors.blue[100]!,
          inputBackgroundColor: Colors.white,
          inputTextColor: Colors.black,
          inputTextDecoration: InputDecoration(
            hintText: 'Type your message...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          sendButtonIcon: Icon(Icons.send, color: Colors.blue),
        ),
      ),
    );
  }
}