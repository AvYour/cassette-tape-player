import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/spotify_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const CassettePlayerApp());
}

class CassettePlayerApp extends StatelessWidget {
  const CassettePlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cassette Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF221F1C),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFAF6F0),
      ),
      home: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  final SpotifyService _spotifyService = SpotifyService();

  @override
  void dispose() {
    _spotifyService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreen(spotifyService: _spotifyService);
  }
}
