// lib/features/settings/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/profile_avatar.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/user_service.dart';
import '../../../core/utils/logger.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  String? _profileImageUrl;
  File? _newProfileImage;

  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null) {
      setState(() {
        _nameController.text = user.name;
        _emailController.text = user.email;
        _phoneController.text = user.phoneNumber ?? '';
        _profileImageUrl = user.profilePicture;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final imagePicker = ImagePicker();
      final pickedFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _newProfileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      Logger.error('Error al seleccionar imagen', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateProfileImage() async {
    if (_newProfileImage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user != null) {
        final updatedImageUrl = await _userService.updateProfilePicture(
          user.id,
          _newProfileImage!.path,
        );

        if (updatedImageUrl != null) {
          setState(() {
            _profileImageUrl = updatedImageUrl;
            _newProfileImage = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Imagen de perfil actualizada')),
          );
        }
      }
    } catch (e) {
      Logger.error('Error al actualizar foto de perfil', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar foto: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfileChanges() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Actualizar foto si se seleccionó una nueva
        if (_newProfileImage != null) {
          await _updateProfileImage();
        }

        // Actualizar datos del perfil
        final settingsProvider =
            Provider.of<SettingsProvider>(context, listen: false);
        final success = await settingsProvider.updateUserProfile(
          name: _nameController.text,
          email: _emailController.text,
          phoneNumber: _phoneController.text,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil actualizado con éxito')),
          );
          setState(() {
            _isEditing = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${settingsProvider.error}')),
          );
        }
      } catch (e) {
        Logger.error('Error al guardar cambios del perfil', error: e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar cambios: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Usuario no encontrado'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _loadUserData(); // Recargar datos originales
                  _newProfileImage = null;
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Foto de perfil
                  Center(
                    child: Stack(
                      children: [
                        // Avatar
                        ProfileAvatar(
                          imageUrl: _newProfileImage?.path ?? _profileImageUrl,
                          name: user.name,
                          radius: 60,
                          editable: _isEditing,
                          onImageSelected: _isEditing
                              ? (File image) {
                                  setState(() {
                                    _newProfileImage = image;
                                  });
                                }
                              : null,
                        ),

                        // Botón para cambiar foto (visible solo en modo edición)
                        if (_isEditing && _newProfileImage == null)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: InkWell(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
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
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Formulario
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Nombre
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                            prefixIcon: Icon(Icons.person),
                          ),
                          readOnly: !_isEditing,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'El nombre es obligatorio';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Correo electrónico
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          readOnly: !_isEditing,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'El correo electrónico es obligatorio';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Ingrese un correo electrónico válido';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Teléfono
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono',
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          readOnly: !_isEditing,
                        ),

                        const SizedBox(height: 16),

                        // Campo de solo lectura para el rol
                        TextFormField(
                          initialValue: _getRoleName(user.role),
                          decoration: const InputDecoration(
                            labelText: 'Rol',
                            prefixIcon: Icon(Icons.work),
                          ),
                          readOnly: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botón para guardar cambios (visible solo en modo edición)
                  if (_isEditing)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfileChanges,
                        child: const Text('Guardar cambios'),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  String _getRoleName(String roleCode) {
    switch (roleCode) {
      case 'admin':
        return 'Administrador';
      case 'inspector':
        return 'Inspector';
      case 'guard':
        return 'Guardia';
      case 'visitor':
        return 'Visitante';
      default:
        return roleCode;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
