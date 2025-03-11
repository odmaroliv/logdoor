import 'dart:io';

import '../api/pocketbase_client.dart';
import '../models/user.dart';
import '../utils/logger.dart';
import 'offline_sync_service.dart';

class UserService {
  final PocketBaseClient _pbClient = PocketBaseClient();
  final OfflineSyncService _offlineSyncService = OfflineSyncService();

  // Obtener lista de usuarios
  Future<List<User>> getUsers({
    String? role,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      // Construir filtro
      String filter = '';
      if (role != null) filter = 'role = "$role"';

      // Obtener usuarios
      final records = await _pbClient.getRecords(
        'users',
        page: page,
        perPage: perPage,
        filter: filter,
      );

      return records.map((record) => User.fromRecord(record)).toList();
    } catch (e) {
      Logger.error('Error al obtener usuarios', error: e);
      rethrow;
    }
  }

  // Obtener usuario por ID
  Future<User?> getUserById(String userId) async {
    try {
      final record = await _pbClient.getRecord('users', userId);
      return User.fromRecord(record);
    } catch (e) {
      Logger.error('Error al obtener usuario por ID', error: e);
      return null;
    }
  }

  // Crear nuevo usuario
  Future<User> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
  }) async {
    try {
      final userData = {
        'name': name,
        'email': email,
        'password': password,
        'passwordConfirm': password, // PocketBase requiere confirmación
        'role': role,
        'phoneNumber': phoneNumber,
      };

      final record = await _pbClient.createRecord('users', userData);
      return User.fromRecord(record);
    } catch (e) {
      Logger.error('Error al crear usuario', error: e);
      rethrow;
    }
  }

  // Actualizar usuario
  Future<User> updateUser({
    required String userId,
    String? name,
    String? email,
    String? phoneNumber,
    String? role,
    Map<String, dynamic>? biometricData,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (name != null) updateData['name'] = name;
      if (email != null) updateData['email'] = email;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (role != null) updateData['role'] = role;
      if (biometricData != null) updateData['biometricData'] = biometricData;

      final record = await _pbClient.updateRecord('users', userId, updateData);
      return User.fromRecord(record);
    } catch (e) {
      Logger.error('Error al actualizar usuario', error: e);
      rethrow;
    }
  }

  // Actualizar contraseña
  Future<bool> updatePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final updateData = {
        'oldPassword': currentPassword,
        'password': newPassword,
        'passwordConfirm': newPassword,
      };

      await _pbClient.updateRecord('users', userId, updateData);
      return true;
    } catch (e) {
      Logger.error('Error al actualizar contraseña', error: e);
      return false;
    }
  }

  // Actualizar foto de perfil
  Future<String?> updateProfilePicture(String userId, String imagePath) async {
    try {
      final imageFile = File(imagePath);

      if (await imageFile.exists()) {
        final formData = <String, dynamic>{};

        await _pbClient.createRecordWithFiles('users', {
          'id': userId
        }, {
          'profilePicture': [imageFile]
        });

        // Obtener URL de la imagen actualizada
        final user = await getUserById(userId);
        return user?.profilePicture;
      }

      return null;
    } catch (e) {
      Logger.error('Error al actualizar foto de perfil', error: e);
      return null;
    }
  }
}
