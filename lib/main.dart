import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/window_service.dart';
import 'state/settings_controller.dart';
import 'state/weather_controller.dart';
import 'ui/froggy_view.dart';
import 'ui/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FroggyApp());
}

@pragma('vm:entry-point')
void dreamMain() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const FroggyApp(screensaver: true));
}

class FroggyApp extends StatefulWidget {
  const FroggyApp({super.key, this.screensaver = false});

  final bool screensaver;

  @override
  State<FroggyApp> createState() => _FroggyAppState();
}

class _FroggyAppState extends State<FroggyApp> {
  late final SettingsController _settings;
  late final WeatherController _weather;

  @override
  void initState() {
    super.initState();
    _settings = SettingsController();
    _weather = WeatherController(
      settings: _settings,
      allowLocationPrompt: !widget.screensaver,
    );
    _settings.addListener(_applyWakelock);
    _boot();

    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _applyWakelock() {
    if (widget.screensaver) return;
    WindowService.setKeepAwake(_settings.settings.kioskMode);
  }

  Future<void> _boot() async {
    await _settings.load();
    await _weather.init();
  }

  @override
  void dispose() {
    _settings.removeListener(_applyWakelock);
    if (!widget.screensaver) WindowService.setKeepAwake(false);
    _weather.dispose();
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Google's Weather Frog (Froggy)",
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: widget.screensaver
          ? ScreensaverScreen(weather: _weather, settings: _settings)
          : HomeScreen(weather: _weather, settings: _settings),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.weather, required this.settings});

  final WeatherController weather;
  final SettingsController settings;

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SettingsScreen(settings: settings, weather: weather),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListenableBuilder(
        listenable: Listenable.merge([weather, settings]),
        builder: (context, _) {
          if (!weather.ready) return const SplashScreen();
          final kiosk = settings.settings.kioskMode;
          return Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: weather.cycleScene,
                onDoubleTap: weather.refresh,
                onLongPress: () => _openSettings(context),
                child: RepaintBoundary(
                  child: FroggyView(
                    scene: weather.scene,
                    weather: weather.weather,
                    settings: settings.settings,
                    locationName: weather.locationName,
                  ),
                ),
              ),
              if (!kiosk)
                SafeArea(
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: IconButton(
                        icon: const Icon(Icons.settings),
                        color: Colors.white,
                        iconSize: 28,
                        tooltip: 'Settings',
                        onPressed: () => _openSettings(context),
                      ),
                    ),
                  ),
                ),
              if (weather.loading && !kiosk)
                const Positioned(
                  top: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class ScreensaverScreen extends StatelessWidget {
  const ScreensaverScreen({
    super.key,
    required this.weather,
    required this.settings,
  });

  final WeatherController weather;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListenableBuilder(
        listenable: Listenable.merge([weather, settings]),
        builder: (context, _) {
          if (!weather.ready) return const SplashScreen();
          return RepaintBoundary(
            child: FroggyView(
              scene: weather.scene,
              weather: weather.weather,
              settings: settings.settings,
              locationName: weather.locationName,
            ),
          );
        },
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 112,
            height: 112,
            child: Image(
              image: AssetImage('assets/app_icon.png'),
              filterQuality: FilterQuality.medium,
            ),
          ),
          SizedBox(height: 24),
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white30,
            ),
          ),
        ],
      ),
    );
  }
}
