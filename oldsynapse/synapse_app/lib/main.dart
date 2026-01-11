import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme/app_theme.dart';
import 'providers/news_provider.dart';
import 'ui/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en_US', null);
  runApp(const SynapseApp());
}

class SynapseApp extends StatelessWidget {
  const SynapseApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NewsProvider(),
      child: Consumer<NewsProvider>(
        builder: (context, newsProvider, child) {
          return MaterialApp(
            title: 'Synapse',
            debugShowCheckedModeBanner: false,
            themeMode: newsProvider.themeMode,
            theme: AppTheme.lightTheme.copyWith(
              textTheme: GoogleFonts.robotoTextTheme(AppTheme.lightTheme.textTheme),
            ),
            darkTheme: AppTheme.darkTheme.copyWith(
              textTheme: GoogleFonts.robotoTextTheme(AppTheme.darkTheme.textTheme),
            ),
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
