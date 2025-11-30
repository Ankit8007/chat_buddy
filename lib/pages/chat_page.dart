import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:chat_buddy/constants/constants.dart';
import 'package:chat_buddy/models/models.dart';
import 'package:chat_buddy/pages/pages.dart';
import 'package:chat_buddy/providers/providers.dart';
import 'package:chat_buddy/utils/utilities.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.arguments});

  final ChatPageArguments arguments;

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  late final String _currentUserId;

  List<QueryDocumentSnapshot> _listMessage = [];
  int _limit = 20;
  final _limitIncrement = 20;
  String _groupChatId = "";

  bool _isShowSticker = false;

  final _chatInputController = TextEditingController();
  final _listScrollController = ScrollController();
  final _focusNode = FocusNode();

  late final _chatProvider = context.read<ChatProvider>();
  late final _authProvider = context.read<AuthProvider>();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _listScrollController.addListener(_scrollListener);
    _readLocal();
  }

  void _scrollListener() {
    if (!_listScrollController.hasClients) return;
    if (_listScrollController.offset >= _listScrollController.position.maxScrollExtent &&
        !_listScrollController.position.outOfRange &&
        _limit <= _listMessage.length) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      // Hide sticker when keyboard appear
      setState(() {
        _isShowSticker = false;
      });
    }
  }

  void _readLocal() {
    if (_authProvider.userFirebaseId?.isNotEmpty == true) {
      _currentUserId = _authProvider.userFirebaseId!;
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginPage()),
        (_) => false,
      );
    }
    String peerId = widget.arguments.peerId;
    if (_currentUserId.compareTo(peerId) > 0) {
      _groupChatId = '$_currentUserId-$peerId';
    } else {
      _groupChatId = '$peerId-$_currentUserId';
    }

    _chatProvider.updateDataFirestore(
      FirestoreConstants.pathUserCollection,
      _currentUserId,
      {FirestoreConstants.chattingWith: peerId},
    );
  }

  void _getSticker() {
    // Hide keyboard when sticker appear
    _focusNode.unfocus();
    setState(() {
      _isShowSticker = !_isShowSticker;
    });
  }

  void _onSendMessage(String content, int type) {
    if(_isShowSticker){
      setState(() {
        _isShowSticker = false;
      });
    }
    if (content.trim().isNotEmpty) {
      _chatInputController.clear();
      _chatProvider.sendMessage(content, type, _groupChatId, _currentUserId, widget.arguments.peerId);
      if (_listScrollController.hasClients) {
        _listScrollController.animateTo(0, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } else {
      Fluttertoast.showToast(msg: 'Nothing to send', backgroundColor: ColorConstants.greyColor);
    }
  }

  Widget _buildItemMessage(int index, DocumentSnapshot? document) {
    if (document == null) return SizedBox.shrink();
    final messageChat = MessageChat.fromDocument(document);
    if (messageChat.idFrom == _currentUserId) {
      // Right (my message)
      return Row(
        children: [
          messageChat.type == TypeMessage.text
              // Text
              ? Container(
                  child: Text(
                    messageChat.content,
                    style: TextStyle(color: ColorConstants.primaryColor),
                  ),
                  padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                  width: 200,
                  decoration: BoxDecoration(color: ColorConstants.greyColor2, borderRadius: BorderRadius.circular(8)),
                  margin: EdgeInsets.only(bottom: _isLastMessageRight(index) ? 20 : 10, right: 10),
                )
              : messageChat.type == TypeMessage.image
                  // Image
                  ? Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                      child: GestureDetector(
                        child: Image.network(
                          messageChat.content,
                          loadingBuilder: (_, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              decoration: BoxDecoration(
                                color: ColorConstants.greyColor2,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                              ),
                              width: 200,
                              height: 200,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: ColorConstants.themeColor,
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) {
                            return Image.asset(
                              'images/img_not_available.jpeg',
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            );
                          },
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullPhotoPage(
                                url: messageChat.content,
                              ),
                            ),
                          );
                        },
                      ),
                      margin: EdgeInsets.only(bottom: _isLastMessageRight(index) ? 20 : 10, right: 10),
                    )
                  // Sticker
                  : Container(
                      child: Image.asset(
                        'images/${messageChat.content}.gif',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                      margin: EdgeInsets.only(bottom: _isLastMessageRight(index) ? 20 : 10, right: 10),
                    ),
        ],
        mainAxisAlignment: MainAxisAlignment.end,
      );
    } else {
      // Left (peer message)
      return Container(
        child: Column(
          children: [
            Row(
              children: [
                ClipOval(
                  child: _isLastMessageLeft(index)
                      ? Image.network(
                          widget.arguments.peerAvatar,
                          loadingBuilder: (_, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                color: ColorConstants.themeColor,
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) {
                            return Icon(
                              Icons.account_circle,
                              size: 35,
                              color: ColorConstants.greyColor,
                            );
                          },
                          width: 35,
                          height: 35,
                          fit: BoxFit.cover,
                        )
                      : Container(width: 35),
                ),
                messageChat.type == TypeMessage.text
                    ? Container(
                        child: Text(
                          messageChat.content,
                          style: TextStyle(color: Colors.white),
                        ),
                        padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                        width: 200,
                        decoration:
                            BoxDecoration(color: ColorConstants.primaryColor, borderRadius: BorderRadius.circular(8)),
                        margin: EdgeInsets.only(left: 10),
                      )
                    : messageChat.type == TypeMessage.image
                        ? Container(
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                            child: GestureDetector(
                              child: Image.network(
                                messageChat.content,
                                loadingBuilder: (_, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: ColorConstants.greyColor2,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8),
                                      ),
                                    ),
                                    width: 200,
                                    height: 200,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: ColorConstants.themeColor,
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'images/img_not_available.jpeg',
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FullPhotoPage(url: messageChat.content),
                                  ),
                                );
                              },
                            ),
                            margin: EdgeInsets.only(left: 10),
                          )
                        : Container(
                            child: Image.asset(
                              'images/${messageChat.content}.gif',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                            margin: EdgeInsets.only(bottom: _isLastMessageRight(index) ? 20 : 10, right: 10),
                          ),
              ],
            ),

            // Time
            _isLastMessageLeft(index)
                ? Container(
                    child: Text(
                      DateFormat('dd MMM kk:mm')
                          .format(DateTime.fromMillisecondsSinceEpoch(int.parse(messageChat.timestamp))),
                      style: TextStyle(color: ColorConstants.greyColor, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                    margin: EdgeInsets.only(left: 50, top: 5, bottom: 5),
                  )
                : SizedBox.shrink()
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        margin: EdgeInsets.only(bottom: 10),
      );
    }
  }

  bool _isLastMessageLeft(int index) {
    if ((index > 0 && _listMessage[index - 1].get(FirestoreConstants.idFrom) == _currentUserId) || index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool _isLastMessageRight(int index) {
    if ((index > 0 && _listMessage[index - 1].get(FirestoreConstants.idFrom) != _currentUserId) || index == 0) {
      return true;
    } else {
      return false;
    }
  }

  void _onBackPress() {
    _chatProvider.updateDataFirestore(
      FirestoreConstants.pathUserCollection,
      _currentUserId,
      {FirestoreConstants.chattingWith: null},
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onBackPress();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFd5daf6),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          title:  Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: widget.arguments.peerAvatar.isNotEmpty
                    ? NetworkImage(widget.arguments.peerAvatar)
                    : null,
                child: widget.arguments.peerAvatar.isEmpty
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.arguments.peerNickname,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    'Online',
                    style: TextStyle(color: Colors.black, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          actions: const[
             Padding(
               padding: EdgeInsets.only(right: 16),
               child: Icon(Icons.more_horiz),
             ),
          ],
        ),// outer bg
        body: Center(
          child: Container(
            margin: EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.6,2],
                colors: [
                  Color(0xFFd5daf6),
                  Color(0xffc5bbfb),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  // color: Colors.black26,
                  color:  Color(0xffb4a8f6),
                  blurStyle: BlurStyle.outer,
                  blurRadius: 50
                )
              ]
            ),
            child: Column(
              children: [ // new header
                Expanded(child: _buildListMessage()),
                if (_isShowSticker) _buildStickers(),
                _buildInputBubbleBar(), // new input
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBubbleBar() {
    final bottomSpace = MediaQuery.of(context).viewPadding.bottom;
    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        padding:  EdgeInsets.fromLTRB(12, 8, 12,
            bottomSpace >=10 ? 0 : 10
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file, color: Color(0xFF3F4EC9)),
                onPressed: _getSticker
              ),
              Expanded(
                child: TextField(
                  controller: _chatInputController,
                  focusNode: _focusNode,
                  onTapOutside: (_) => Utilities.closeKeyboard(),
                  onSubmitted: (_) =>
                      _onSendMessage(_chatInputController.text, TypeMessage.text),
                  decoration: const InputDecoration.collapsed(
                    hintText: 'Type your message...',
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF3A3A3A),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF3F4EC9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                  onPressed: () =>
                      _onSendMessage(_chatInputController.text, TypeMessage.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildStickers() {
    return Container(
      child: Column(
        children: [
          Row(
            children: [
              _buildItemSticker("mimi1"),
              _buildItemSticker("mimi2"),
              _buildItemSticker("mimi3"),
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: [
              _buildItemSticker("mimi4"),
              _buildItemSticker("mimi5"),
              _buildItemSticker("mimi6"),
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: [
              _buildItemSticker("mimi7"),
              _buildItemSticker("mimi8"),
              _buildItemSticker("mimi9"),
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          )
        ],
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: ColorConstants.greyColor2, width: 0.5)),
        color: Colors.white,
      ),
      padding: EdgeInsets.symmetric(vertical: 8),
    );
  }

  Widget _buildItemSticker(String stickerName) {
    return TextButton(
      onPressed: () => _onSendMessage(stickerName, TypeMessage.sticker),
      child: Image.asset(
        'images/$stickerName.gif',
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildListMessage() {
    return _groupChatId.isNotEmpty
          ? StreamBuilder<QuerySnapshot>(
              stream: _chatProvider.getChatStream(_groupChatId, _limit),
              builder: (_, snapshot) {
                if (snapshot.hasData) {
                  _listMessage = snapshot.data!.docs;
                  if (_listMessage.length > 0) {
                    return ListView.builder(
                      padding: EdgeInsets.all(10),
                      itemBuilder: (_, index) => _buildItemMessage(index, snapshot.data?.docs[index]),
                      itemCount: snapshot.data?.docs.length,
                      reverse: true,
                      controller: _listScrollController,
                    );
                  } else {
                    return Center(child: Text("No message here yet..."));
                  }
                } else {
                  return Center(
                    child: CircularProgressIndicator(
                      color: ColorConstants.themeColor,
                    ),
                  );
                }
              },
            )
          : Center(
              child: CircularProgressIndicator(
                color: ColorConstants.themeColor,
              ),
            );
  }

  @override
  void dispose() {
    _chatInputController.dispose();
    _listScrollController
      ..removeListener(_scrollListener)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

class ChatPageArguments {
  final String peerId;
  final String peerAvatar;
  final String peerNickname;

  ChatPageArguments({required this.peerId, required this.peerAvatar, required this.peerNickname});
}
