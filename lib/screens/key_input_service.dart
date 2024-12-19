import 'package:flutter/services.dart';

class NumericInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Yalnızca sayısal karakterlere izin ver
    if (newValue.text.isEmpty || RegExp(r'^[0-9]+$').hasMatch(newValue.text)) {
      return newValue;
    }
    // Geçersiz karakterler bulunursa eski değeri koru
    return oldValue;
  }
}
