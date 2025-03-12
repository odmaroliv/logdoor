import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/access.dart';
import '../utils/logger.dart';

class QRService {
  static final QRService _instance = QRService._internal();
  factory QRService() => _instance;

  // Clave secreta almacenada de forma segura
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  final String _keyName = 'qr_encryption_key';

  QRService._internal();

  // Método para generar un código QR encriptado para un acceso
  Future<String> generateSecureQRCode(Access access) async {
    try {
      // Obtener o generar la clave de encriptación
      final encryptionKey = await _getOrCreateEncryptionKey();

      // Crear datos para incluir en el QR
      final qrData = {
        'id': access.id,
        'accessCode': access.accessCode,
        'timestamp': access.timestamp.millisecondsSinceEpoch,
        'userId': access.userId,
        'warehouseId': access.warehouseId,
        'type': access.accessType,
      };

      // Convertir datos a JSON
      final jsonData = json.encode(qrData);

      // Encriptar datos
      final encryptedData = _encryptData(jsonData, encryptionKey);

      // Generar firma para verificar autenticidad
      final signature = _generateSignature(jsonData, encryptionKey);

      // Crear datos finales del QR (encriptados + firma)
      final qrContent = {
        'data': encryptedData,
        'sig': signature,
        'v': 1, // Versión del formato para compatibilidad futura
      };

      // Devolver contenido final del QR
      return json.encode(qrContent);
    } catch (e) {
      Logger.error('Error al generar QR seguro', error: e);
      // En caso de error, usar el código de acceso normal
      return access.accessCode;
    }
  }

  // Método para verificar y decodificar un código QR encriptado
  Future<Map<String, dynamic>?> verifyAndDecodeQR(String qrContent) async {
    try {
      // Intentar parsear el QR como JSON
      final Map<String, dynamic> qrData = json.decode(qrContent);

      // Verificar si el QR es del formato seguro
      if (!qrData.containsKey('data') ||
          !qrData.containsKey('sig') ||
          !qrData.containsKey('v')) {
        // No es un QR seguro, podría ser un código de acceso normal
        return {'accessCode': qrContent};
      }

      // Obtener la clave de encriptación
      final encryptionKey = await _getOrCreateEncryptionKey();

      // Desencriptar datos
      final encryptedData = qrData['data'];
      final decryptedJson = _decryptData(encryptedData, encryptionKey);

      // Verificar firma
      final providedSignature = qrData['sig'];
      final calculatedSignature =
          _generateSignature(decryptedJson, encryptionKey);

      if (providedSignature != calculatedSignature) {
        Logger.warning('Firma QR inválida, posible manipulación');
        return null;
      }

      // Convertir a mapa y devolver
      return json.decode(decryptedJson);
    } catch (e) {
      Logger.error('Error al verificar QR', error: e);

      // Si no se puede decodificar, asumir que es un código de acceso normal
      try {
        return {'accessCode': qrContent};
      } catch (_) {
        return null;
      }
    }
  }

  // Método privado para obtener o crear la clave de encriptación
  Future<String> _getOrCreateEncryptionKey() async {
    // Intentar obtener la clave existente
    String? key = await _secureStorage.read(key: _keyName);

    // Si no existe, crear una nueva
    if (key == null) {
      // Generar una clave aleatoria de 32 caracteres (AES-256)
      final keyGenerator = encrypt.Key.fromSecureRandom(32);
      key = base64.encode(keyGenerator.bytes);

      // Guardar la clave
      await _secureStorage.write(key: _keyName, value: key);
    }

    return key;
  }

  // Encriptar datos usando AES
  String _encryptData(String plainText, String key) {
    final keyBytes = base64.decode(key);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(encrypt.Key(keyBytes), mode: encrypt.AESMode.cbc),
    );

    // Generar un IV aleatorio para mayor seguridad
    final iv = encrypt.IV.fromSecureRandom(16);

    // Encriptar
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // Devolver texto encriptado con IV incluido (necesario para desencriptar)
    return '${base64.encode(iv.bytes)}:${encrypted.base64}';
  }

  // Desencriptar datos
  String _decryptData(String encryptedText, String key) {
    // Separar IV y texto encriptado
    final parts = encryptedText.split(':');
    final ivString = parts[0];
    final dataString = parts[1];

    // Preparar para desencriptar
    final keyBytes = base64.decode(key);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(encrypt.Key(keyBytes), mode: encrypt.AESMode.cbc),
    );
    final iv = encrypt.IV(base64.decode(ivString));

    // Desencriptar
    final decrypted = encrypter.decrypt(
      encrypt.Encrypted(base64.decode(dataString)),
      iv: iv,
    );

    return decrypted;
  }

  // Generar firma para verificar integridad
  String _generateSignature(String data, String key) {
    final hmac = Hmac(sha256, utf8.encode(key));
    final digest = hmac.convert(utf8.encode(data));
    return digest.toString();
  }
}
