import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // SystemChrome için eklendi
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'contact_screen.dart';
import 'sudoku_screen.dart';
import 'statistics_screen.dart';
import 'how_to_play_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ekran yönünü dikey olarak sabitle
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await MobileAds.instance.initialize();

  final prefs = await SharedPreferences.getInstance();
  final String? savedLanguage = prefs.getString('languageCode');

  runApp(SudokuApp(initialLocale: savedLanguage != null ? Locale(savedLanguage) : null));
}

class SudokuApp extends StatefulWidget {
  final Locale? initialLocale;

  const SudokuApp({Key? key, this.initialLocale}) : super(key: key);

  @override
  _SudokuAppState createState() => _SudokuAppState();
}

class _SudokuAppState extends State<SudokuApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    // Kaydedilmiş bir dil varsa onu kullan, yoksa varsayılan olarak İngilizce
    _locale = widget.initialLocale ?? Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    setState(() {
      _locale = locale;
    });

    // Dil tercihini kaydet
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sudoku Go',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.blue,
          textTheme: ButtonTextTheme.primary,
        ),
      ),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('tr', ''),
        Locale('en', ''),
      ],
      locale: _locale,
      home: HomeScreen(setLocale: setLocale),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Function(Locale) setLocale;

  const HomeScreen({Key? key, required this.setLocale}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<bool> _hasSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('gameState');
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _changeLanguage(Locale locale) async {
    widget.setLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    // Ekran boyutlarını al
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    // Sistem font ölçeğini al (büyük yazı tipi ayarı için)
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    // Ekran boyutuna göre dinamik değerler
    final bool isLargeDevice = screenWidth > 400;

    // Font boyutlarını ve spacing'leri hesapla
    final double titleFontSize = (isLargeDevice ? 40.0 : 32.0) / textScaleFactor;
    final double buttonFontSize = (isLargeDevice ? 20.0 : 16.0) / textScaleFactor;
    final double logoSize = screenWidth * 0.4; // Ekran genişliğinin %40'ı

    // Dikey spacing'leri hesapla
    final double topSpacing = screenHeight * 0.05;
    final double logoSpacing = screenHeight * 0.03;
    final double buttonSpacing = screenHeight * 0.02;
    final double bottomSpacing = screenHeight * 0.02;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.appTitle,
          style: TextStyle(
            fontSize: buttonFontSize * 1.2,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<Locale>(
            icon: Icon(Icons.language),
            onSelected: _changeLanguage,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
              PopupMenuItem<Locale>(
                value: Locale('tr', ''),
                child: Row(
                  children: [
                    Text('🇹🇷', style: TextStyle(fontSize: buttonFontSize)),
                    SizedBox(width: 10),
                    Text('Türkçe', style: TextStyle(fontSize: buttonFontSize * 0.8)),
                  ],
                ),
              ),
              PopupMenuItem<Locale>(
                value: Locale('en', ''),
                child: Row(
                  children: [
                    Text('🇬🇧', style: TextStyle(fontSize: buttonFontSize)),
                    SizedBox(width: 10),
                    Text('English', style: TextStyle(fontSize: buttonFontSize * 0.8)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            children: <Widget>[
              SizedBox(height: topSpacing),
              Image.asset(
                'assets/sudoku_logo.png',
                width: logoSize,
                height: logoSize,
              ),
              SizedBox(height: logoSpacing),
              Text(
                AppLocalizations.of(context)!.sudoku,
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => _navigateTo(context, SudokuScreen()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.15,
                          vertical: screenHeight * 0.015,
                        ),
                        minimumSize: Size(screenWidth * 0.6, 0),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.newGame,
                        style: TextStyle(fontSize: buttonFontSize),
                      ),
                    ),
                    SizedBox(height: buttonSpacing),
                    FutureBuilder<bool>(
                      future: _hasSavedGame(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data == true) {
                          return ElevatedButton(
                            onPressed: () => _navigateTo(context, SudokuScreen(continueGame: true)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.15,
                                vertical: screenHeight * 0.015,
                              ),
                              minimumSize: Size(screenWidth * 0.6, 0),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.continueGame,
                              style: TextStyle(fontSize: buttonFontSize),
                            ),
                          );
                        }
                        return SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.bar_chart,
                        size: isLargeDevice ? 30 : 24,
                        color: Colors.blue
                    ),
                    onPressed: () => _navigateTo(context, StatisticsScreen()),
                  ),
                  SizedBox(width: screenWidth * 0.05),
                  IconButton(
                    icon: Icon(Icons.mail,
                        size: isLargeDevice ? 30 : 24,
                        color: Colors.blue
                    ),
                    onPressed: () => _navigateTo(context, ContactScreen()),
                  ),
                  SizedBox(width: screenWidth * 0.05),
                  IconButton(
                    icon: Icon(Icons.help,
                        size: isLargeDevice ? 30 : 24,
                        color: Colors.blue
                    ),
                    onPressed: () => _navigateTo(context, HowToPlayScreen()),
                  ),
                ],
              ),
              SizedBox(height: bottomSpacing),
            ],
          ),
        ),
      ),
    );
  }
}