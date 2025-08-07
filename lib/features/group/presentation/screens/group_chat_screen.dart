import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:frosthub/api/frostcore_api.dart';
import 'package:frosthub/constant/api_constant.dart';

class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({super.key});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _chatController = TextEditingController();
  late IO.Socket socket;

  String? _groupId;
  String? _userId;
  String? _token;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    socket.disconnect();
    socket.dispose();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');

    if (_token == null) return;

    try {
      final user = await FrostCoreAPI.getUserProfile(_token!);
      _groupId = user['groupId'];
      _userId = user['_id'];

      if (_groupId == null) return;

      await _fetchMessages();
      _setupSocket();
    } catch (e) {
      print('❌ Error initializing chat: $e');
    }
  }

  Future<void> _fetchMessages() async {
    final url = Uri.parse('$apiBaseUrl/api/chats/$_groupId');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $_token',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List messagesData = data['messages'];

      setState(() {
        _messages = messagesData
            .map<Map<String, dynamic>>((msg) => Map<String, dynamic>.from(msg))
            .toList();
      });
    } else {
      print('❌ Failed to fetch messages: ${response.body}');
    }
  }

  void _setupSocket() {
    socket = IO.io(apiBaseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print('🟢 Socket connected');
      socket.emit('join-group', _groupId);
    });

    socket.on('new-message', (data) {
      setState(() {
        _messages.add(Map<String, dynamic>.from(data));
      });
    });

    socket.onDisconnect((_) {
      print('🔴 Socket disconnected');
    });
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _groupId == null || _token == null) return;

    try {
      final url = Uri.parse('$apiBaseUrl/api/chats');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'groupId': _groupId, 'message': text}),
      );

      if (response.statusCode == 201) {
        _chatController.clear();
      } else {
        print('❌ Send message failed: ${response.body}');
      }
    } catch (e) {
      print('❌ Exception while sending message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Group Chat')),
      body: _groupId == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['sender']['_id'] == _userId;

                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 14),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue : Colors.grey.shade300,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: Radius.circular(isMe ? 12 : 0),
                              bottomRight: Radius.circular(isMe ? 0 : 12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Text(
                                  msg['sender']['nickname']?.isNotEmpty == true
                                      ? msg['sender']['nickname']
                                      : msg['sender']['username'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              Text(
                                msg['message'],
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendMessage,
                      )
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
