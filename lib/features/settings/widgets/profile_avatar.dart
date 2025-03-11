// lib/features/settings/widgets/profile_avatar.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final Color? backgroundColor;
  final bool editable;
  final Function(File)? onImageSelected;

  const ProfileAvatar({
    Key? key,
    this.imageUrl,
    required this.name,
    this.radius = 40,
    this.backgroundColor,
    this.editable = false,
    this.onImageSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determinar el contenido del avatar
    Widget avatarContent;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      // Si hay URL de imagen, mostrar la imagen
      if (imageUrl!.startsWith('http')) {
        // Imagen remota
        avatarContent = CircleAvatar(
          radius: radius,
          backgroundImage: NetworkImage(imageUrl!),
          backgroundColor: Colors.transparent,
        );
      } else {
        // Imagen local
        avatarContent = CircleAvatar(
          radius: radius,
          backgroundImage: FileImage(File(imageUrl!)),
          backgroundColor: Colors.transparent,
        );
      }
    } else {
      // Si no hay imagen, mostrar las iniciales
      final initials = _getInitials(name);
      avatarContent = CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.7,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Si no es editable, retornar solo el avatar
    if (!editable) {
      return avatarContent;
    }

    // Si es editable, agregar botón para cambiar imagen
    return Stack(
      children: [
        avatarContent,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 2,
              ),
            ),
            child: InkWell(
              onTap: () => _pickImage(context),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final nameParts = name.trim().split(' ');
    if (nameParts.length > 1) {
      // Dos iniciales si hay nombre y apellido
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty) {
      // Una inicial si solo hay un nombre
      return nameParts[0][0].toUpperCase();
    }

    return '?';
  }

  Future<void> _pickImage(BuildContext context) async {
    if (onImageSelected == null) return;

    final imagePicker = ImagePicker();

    // Mostrar opciones para elegir imagen
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () async {
                Navigator.pop(context);
                final pickedFile = await imagePicker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
                _processSelectedImage(pickedFile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de la galería'),
              onTap: () async {
                Navigator.pop(context);
                final pickedFile = await imagePicker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );
                _processSelectedImage(pickedFile);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _processSelectedImage(XFile? pickedFile) {
    if (pickedFile != null && onImageSelected != null) {
      onImageSelected!(File(pickedFile.path));
    }
  }
}
