import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:chat_buddy/constants/constants.dart';
import 'package:chat_buddy/models/models.dart';
import 'package:chat_buddy/pages/pages.dart';
import 'package:chat_buddy/providers/providers.dart';
import 'package:chat_buddy/utils/utils.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final _listScrollController = ScrollController();

  int _limit = 20;
  final _limitIncrement = 20;
  String _textSearch = "";
  final ValueNotifier<bool> _isSearching = ValueNotifier(false);

  late final _authProvider = context.read<AuthProvider>();
  late final _homeProvider = context.read<HomeProvider>();
  late final String _currentUserId;

  final _searchDebouncer = Debouncer(milliseconds: 300);
  final _btnClearController = StreamController<bool>.broadcast();
  final _searchBarController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (_authProvider.userFirebaseId?.isNotEmpty == true) {
      _currentUserId = _authProvider.userFirebaseId!;
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginPage()),
        (_) => false,
      );
    }
    _registerNotification();
    _configLocalNotification();
    _listScrollController.addListener(_scrollListener);
    _readLocal();
  }
  late final _settingProvider = context.read<SettingProvider>();

  void _readLocal() {
    setState(() {
      _avatarUrl = _settingProvider.getPref(FirestoreConstants.photoUrl) ?? "";
    });
  }

  void _registerNotification() {
    _firebaseMessaging.requestPermission();

    FirebaseMessaging.onMessage.listen((message) {
      print('onMessage: $message');
      if (message.notification != null) {
        _showNotification(message.notification!);
      }
      return;
    });

    _firebaseMessaging.getToken().then((token) {
      print('push token: $token');
      if (token != null) {
        _homeProvider.updateDataFirestore(FirestoreConstants.pathUserCollection, _currentUserId, {'pushToken': token});
      }
    }).catchError((err) {
    });
  }

  void _configLocalNotification() {
    final initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    final initializationSettingsIOS = DarwinInitializationSettings();
    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _scrollListener() {
    if (_listScrollController.offset >= _listScrollController.position.maxScrollExtent &&
        !_listScrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  void _showNotification(RemoteNotification remoteNotification) async {
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      Platform.isAndroid ? 'com.dfa.flutterchatdemo' : 'com.duytq.flutterchatdemo',
      'Flutter chat demo',
      playSound: true,
      enableVibration: true,
      importance: Importance.max,
      priority: Priority.high,
    );
    final iOSPlatformChannelSpecifics = DarwinNotificationDetails();
    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    print(remoteNotification);

    await _flutterLocalNotificationsPlugin.show(
      0,
      remoteNotification.title,
      remoteNotification.body,
      platformChannelSpecifics,
      payload: null,
    );
  }

  String _avatarUrl = '';

  @override
  Widget build(BuildContext context) {
    return  Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Color(0xffc5bbfb),
          Color(0xFFd5daf6)
        ])
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
          appBar: AppBar(
            leading: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 10),
              child: SizedBox(
                width: 70,
                height: 70,
                child: GestureDetector(
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsPage()));
                  },
                  child: ClipOval(
                    child: (_avatarUrl.isNotEmpty
                        ? Image.network(
                      _avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.account_circle,
                        color: ColorConstants.greyColor,
                      ),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            color: ColorConstants.themeColor,
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    )
                        : Icon(
                      Icons.account_circle,
                      size: 70,
                      color: ColorConstants.greyColor,
                    ))
                  ),
                ),
              ),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            centerTitle: true,
            title: ValueListenableBuilder<bool>(
                valueListenable: _isSearching,
              builder: (_, isSearching, __) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isSearching ?
                  _buildSearchBarNew()
                      :
                  const Text(
                    'Contact',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
            ),
            iconTheme: const IconThemeData(color: Colors.black87),
            actions:  [
            GestureDetector(
              onTap: (){
                _isSearching.value = !_isSearching.value;
                _searchBarController.clear();
                _textSearch = '';
              },
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: ValueListenableBuilder<bool>(
                  valueListenable: _isSearching,
                  builder: (_, isSearching, __) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isSearching ?
                      Icon(Icons.close, color: Colors.black54) : Icon(Icons.search, color: Colors.black54)
                    );
                  },
                ),
              ),
            ),
            ],
          ),
          body: Container(
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF5F1FF),
                  Color(0xFFFFFFFF),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: _buildContentCard(), // new wrapper
          ),
        ),
    );
  }

  Widget _buildContentCard() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _homeProvider.getStreamFireStore(
              FirestoreConstants.pathUserCollection,
              _limit,
              _textSearch,
            ),
            builder: (_, snapshot) {
              if (snapshot.hasData) {
                if ((snapshot.data?.docs.length ?? 0) > 0) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (_, index) =>
                        _buildItemNew(snapshot.data?.docs[index]),
                    itemCount: snapshot.data?.docs.length,
                    controller: _listScrollController,
                  );
                } else {
                  return const Center(child: Text('No users'));
                }
              } else {
                return Center(
                  child: CircularProgressIndicator(
                    color: ColorConstants.themeColor,
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBarNew() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              textInputAction: TextInputAction.search,
              controller: _searchBarController,
              decoration: const InputDecoration.collapsed(
                hintText: 'Search',
              ),
              onChanged: (value) {
                _searchDebouncer.run(() {
                  if (value.isNotEmpty) {
                    _btnClearController.add(true);
                    setState(() => _textSearch = value);
                  } else {
                    _btnClearController.add(false);
                    setState(() => _textSearch = '');
                  }
                });
              },
            ),
          ),
          StreamBuilder<bool>(
            stream: _btnClearController.stream,
            builder: (_, snapshot) {
              return snapshot.data == true
                  ? GestureDetector(
                onTap: () {
                  _searchBarController.clear();
                  _btnClearController.add(false);
                  setState(() => _textSearch = '');
                },
                child: const Icon(Icons.clear_rounded,
                    color: Colors.grey, size: 18),
              )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemNew(DocumentSnapshot? document) {
    if (document == null) return const SizedBox.shrink();

    final userChat = UserChat.fromDocument(document);
    if (userChat.id == _currentUserId) return const SizedBox.shrink();
    return InkWell(
      onTap: () {
        if (Utilities.isKeyboardShowing(context)) {
          Utilities.closeKeyboard();
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPage(
              arguments: ChatPageArguments(
                peerId: userChat.id,
                peerAvatar: userChat.photoUrl,
                peerNickname: userChat.nickname,
              ),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.grey.shade300,
              backgroundImage:
              userChat.photoUrl.isNotEmpty ? NetworkImage(userChat.photoUrl) : null,
              child: userChat.photoUrl.isEmpty
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userChat.nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    userChat.aboutMe.isNotEmpty
                        ? userChat.aboutMe
                        : 'Last seen recently',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _btnClearController.close();
    _searchBarController.dispose();
    _listScrollController
      ..removeListener(_scrollListener)
      ..dispose();
    super.dispose();
  }
}
