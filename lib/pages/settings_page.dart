import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chat_buddy/constants/constants.dart';
import 'package:chat_buddy/providers/providers.dart';
import 'package:provider/provider.dart';

import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _controllerNickname;
  late final TextEditingController _controllerAboutMe;
  String _nickname = '';
  String _aboutMe = '';
  String _avatarUrl = '';
  File? _avatarFile;
  late final _settingProvider = context.read<SettingProvider>();

  late final _authProvider = context.read<AuthProvider>();

  final _focusNodeNickname = FocusNode();
  final _focusNodeAboutMe = FocusNode();

  @override
  void initState() {
    super.initState();
    _readLocal();
  }

  void _readLocal() {
    setState(() {
      _nickname = _settingProvider.getPref(FirestoreConstants.nickname) ?? "";
      _aboutMe = _settingProvider.getPref(FirestoreConstants.aboutMe) ?? "";
      _avatarUrl = _settingProvider.getPref(FirestoreConstants.photoUrl) ?? "";
    });

    _controllerNickname = TextEditingController(text: _nickname);
    _controllerAboutMe = TextEditingController(text: _aboutMe);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF1E345C),
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1E345C)),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xffc5bbfb), // your theme gradient
                  Color(0xFFd5daf6),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: _buildContent(),   // new extracted content
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignOut() async {
    await _authProvider.handleSignOut();
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage()),
          (_) => false,
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          Column(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A64D8), Color(0xFF2C3AA8)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: _avatarFile == null
                        ? (_avatarUrl.isNotEmpty
                        ? Image.network(
                      _avatarUrl,
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.account_circle,
                        size: 80,
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
                      size: 80,
                      color: ColorConstants.greyColor,
                    ))
                        : Image.file(
                      _avatarFile!,
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
          const SizedBox(height: 24),

          // Nickname
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Nickname',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E345C),
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            enabled: false,
            readOnly: true,
            controller: _controllerNickname,
            style: TextStyle(color: Colors.black),

            decoration: InputDecoration(
              hintText: 'Enter your nickname',
              filled: true,
              fillColor: const Color(0xFFF5F5F9),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),

            ),
          ),
          const SizedBox(height: 18),

          // About me
          Visibility(
            visible: false,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'About me',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E345C),
                ),
              ),
            ),
          ),
          const SizedBox(height: 34),

          // Update button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _handleSignOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A64D8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  void dispose() {
    _controllerNickname.dispose();
    _controllerAboutMe.dispose();
    _focusNodeNickname.dispose();
    _focusNodeAboutMe.dispose();
    super.dispose();
  }
}
