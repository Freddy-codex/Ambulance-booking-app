import 'package:flutter/foundation.dart';

class DeliveryState with ChangeNotifier {
  bool _isDeliveryStarted = false;

  bool get isDeliveryStarted => _isDeliveryStarted;

  void startDelivery() {
    _isDeliveryStarted = true;
    notifyListeners();
  }

  void stopDelivery() {
    _isDeliveryStarted = false;
    notifyListeners();
  }
}
