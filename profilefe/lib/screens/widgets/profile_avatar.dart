import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../models/user.dart';

class ProfileAvatar extends StatefulWidget {
  final User user;
  final double radius;
  final VoidCallback? onTap;
  final bool showEditButton;
  final Function(Uint8List?)? onImageUpdated;

  const ProfileAvatar({
    Key? key,
    required this.user,
    this.radius = 60,
    this.onTap,
    this.showEditButton = false,
    this.onImageUpdated,
  }) : super(key: key);

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  bool isLoadingNetworkImage = false;
  Uint8List? _cachedNetworkImage;

  @override
  void initState() {
    super.initState();
    if (widget.user.avatar?.url != null) {
      _preloadNetworkImage();
    }
  }

  @override
  void didUpdateWidget(ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.avatar?.url != widget.user.avatar?.url) {
      _preloadNetworkImage();
    }
  }

  Future<void> _preloadNetworkImage() async {
    if (!mounted || widget.user.avatar?.url == null) return;
    setState(() => isLoadingNetworkImage = true);
    
    try {
      final response = await http.get(
        Uri.parse(widget.user.avatar!.url),
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _cachedNetworkImage = response.bodyBytes;
            isLoadingNetworkImage = false;
          });
          widget.onImageUpdated?.call(_cachedNetworkImage);
        }
      } else {
        throw Exception('Failed to load image');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cachedNetworkImage = null;
          isLoadingNetworkImage = false;
        });
      }
    }
  }

  Widget _getProfileImage() {
    if (isLoadingNetworkImage) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: Theme.of(context).primaryColor,
        ),
      );
    }
    
    if (_cachedNetworkImage != null) {
      return ClipOval(
        child: Image.memory(
          _cachedNetworkImage!,
          fit: BoxFit.cover,
          width: widget.radius * 2,
          height: widget.radius * 2,
        ),
      );
    }
    
    return Icon(
      Icons.person,
      size: widget.radius,
      color: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onTap,
          child: CircleAvatar(
            radius: widget.radius,
            backgroundColor: Colors.grey[300],
            child: _getProfileImage(),
          ),
        ),
        if (widget.showEditButton)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }
}