import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/shop_owner_theme.dart';
import 'dialogs.dart';

/// Photos are saved inside a Firestore document, so they are kept small.
const int kMaxPhotoBytes = 300 * 1024;

/// What the owner chose in the photo sheet.
class PhotoChoice {
  /// A new photo was taken or picked.
  const PhotoChoice.picked(String uri)
      : dataUri = uri,
        removed = false;

  /// "Remove photo" was chosen.
  const PhotoChoice.removed()
      : dataUri = null,
        removed = true;

  /// The new photo as a `data:image/...;base64,` text. Null when removed.
  final String? dataUri;
  final bool removed;
}

/// Shows "Take a photo / Choose from gallery / Remove photo" and returns the
/// result. Returns null when the owner cancels or the photo cannot be used.
///
/// Used for product photos and for the owner's profile photo.
Future<PhotoChoice?> choosePhoto(
  BuildContext context, {
  required bool canRemove,
}) async {
  final messenger = ScaffoldMessenger.of(context);

  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.of(sheetContext).pop('camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.of(sheetContext).pop('gallery'),
          ),
          if (canRemove)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: ShopColors.error),
              title: const Text('Remove photo'),
              onTap: () => Navigator.of(sheetContext).pop('remove'),
            ),
        ],
      ),
    ),
  );
  if (choice == null) return null;
  if (choice == 'remove') return const PhotoChoice.removed();

  try {
    // The picker shrinks the photo so it fits inside a Firestore document.
    final file = await ImagePicker().pickImage(
      source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 480,
      maxHeight: 480,
      imageQuality: 70,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    if (bytes.length > kMaxPhotoBytes) {
      showAppMessage(
        messenger,
        'That photo is too large. Please choose a different one.',
        isError: true,
      );
      return null;
    }
    return PhotoChoice.picked('data:image/jpeg;base64,${base64Encode(bytes)}');
  } catch (error) {
    debugPrint('Picking a photo failed: $error');
    showAppMessage(
      messenger,
      'Could not open the camera or gallery.',
      isError: true,
    );
    return null;
  }
}
