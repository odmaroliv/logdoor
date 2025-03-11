import 'package:geolocator/geolocator.dart';
import '../utils/logger.dart';

class GeolocationService {
  static final GeolocationService _instance = GeolocationService._internal();
  factory GeolocationService() => _instance;

  Position? _lastKnownPosition;

  GeolocationService._internal();

  // Verificar permisos de ubicación
  Future<bool> _checkPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar si el servicio de ubicación está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Logger.warning('Servicios de ubicación deshabilitados');
      return false;
    }

    // Verificar permisos
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Logger.warning('Permisos de ubicación denegados');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Logger.warning('Permisos de ubicación denegados permanentemente');
      return false;
    }

    return true;
  }

  // Obtener ubicación actual
  Future<Position> getCurrentLocation() async {
    try {
      final hasPermission = await _checkPermission();
      if (!hasPermission) {
        throw Exception('No hay permisos para acceder a la ubicación');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _lastKnownPosition = position;

      Logger.info(
          'Ubicación obtenida: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      Logger.error('Error al obtener ubicación', error: e);
      rethrow;
    }
  }

  // Obtener última ubicación conocida
  Future<Map<String, dynamic>> getLastKnownLocation() async {
    try {
      if (_lastKnownPosition != null) {
        return {
          'latitude': _lastKnownPosition!.latitude,
          'longitude': _lastKnownPosition!.longitude,
        };
      }

      // Intentar obtener la última ubicación del dispositivo
      final position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        _lastKnownPosition = position;
        return {
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
      }

      // Si no hay ubicación anterior, intentar obtener la actual
      try {
        final currentPosition = await getCurrentLocation();
        return {
          'latitude': currentPosition.latitude,
          'longitude': currentPosition.longitude,
        };
      } catch (e) {
        // Devolver una ubicación por defecto
        return {
          'latitude': 0,
          'longitude': 0,
        };
      }
    } catch (e) {
      Logger.error('Error al obtener última ubicación conocida', error: e);
      return {
        'latitude': 0,
        'longitude': 0,
      };
    }
  }

  // Calcular distancia entre dos ubicaciones
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}
