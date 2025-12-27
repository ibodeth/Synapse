import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'http_overrides.dart';

import 'ui/home_page.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // HTTP Sertifika hatalarını yoksay (Bazı kurumsal ağlar veya eski siteler için)
  HttpOverrides.global = MyHttpOverrides();
  
  // Tarih formatlarını yükle
  await initializeDateFormatting('tr_TR', null);

  // Tam Ekran Modu (Alt butonları ve üst barı gizle)
  // immersiveSticky: Ekrana dokunulsa bile barlar geri gelmez, kenardan kaydırınca gelir ve sonra tekrar gizlenir.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Uygulamanın sadece dikey modda çalışmasını zorunlu kıl (İsteğe bağlı, tasarımın bozulmaması için iyidir)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const SynapseApp());
}

class SynapseApp extends StatelessWidget {
  const SynapseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synapse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.interTextTheme(),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
