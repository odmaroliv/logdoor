import 'package:connectivity_plus/connectivity_plus.dart';
import 'logger.dart';

class ConnectivityUtils {
  static final ConnectivityUtils _instance = ConnectivityUtils._internal();
  factory ConnectivityUtils() => _instance;

  ConnectivityUtils._internal();

  Future<bool> isConnected() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      Logger.error('Error al verificar conectividad', error: e);
      return false;
    }
  }

  Future<ConnectivityResult> checkConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      switch (result) {
        case ConnectivityResult.mobile:
          Logger.info('Conectado a red móvil');
          break;
        case ConnectivityResult.wifi:
          Logger.info('Conectado a WiFi');
          break;
        case ConnectivityResult.ethernet:
          Logger.info('Conectado a Ethernet');
          break;
        case ConnectivityResult.vpn:
          Logger.info('Conectado a VPN');
          break;
        case ConnectivityResult.bluetooth:
          Logger.info('Conectado a Bluetooth');
          break;
        case ConnectivityResult.other:
          Logger.info('Conectado a otra red');
          break;
        case ConnectivityResult.none:
          Logger.warning('Sin conexión a Internet');
          break;
      }
      return result;
    } catch (e) {
      Logger.error('Error al verificar tipo de conectividad', error: e);
      return ConnectivityResult.none;
    }
  }

  Stream<ConnectivityResult> onConnectivityChanged() {
    return Connectivity().onConnectivityChanged;
  }
}
