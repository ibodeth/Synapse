import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  await initializeDateFormatting('en_US', null);

  String dateStr = "Thu, 11 Dec 2025 15:05:00 +0300";
  print("Testing string: '$dateStr'");

  try {
    DateTime d = HttpDate.parse(dateStr);
    print("HttpDate.parse success: $d");
  } catch (e) {
    print("HttpDate.parse failed: $e");
  }

  try {
     var d = DateFormat("EEE, d MMM yyyy HH:mm:ss Z", 'en_US').parse(dateStr);
     print("DateFormat success: $d");
  } catch(e) {
    print("DateFormat failed: $e");
  }
}
