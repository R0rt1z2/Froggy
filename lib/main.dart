import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/gestures.dart'
    show kBackMouseButton, kForwardMouseButton;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/settings.dart';
import 'services/system_status_service.dart';
import 'services/update_service.dart';
import 'services/window_service.dart';
import 'state/settings_controller.dart';
import 'state/weather_controller.dart';
import 'ui/foreground.dart';
import 'ui/froggy_view.dart';
import 'ui/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _budgetImageCache();
  runApp(const FroggyApp());
}

void _budgetImageCache() {
  PaintingBinding.instance.imageCache
    ..maximumSize = 12
    ..maximumSizeBytes = 80 << 20;
}

@pragma('vm:entry-point')
void dreamMain() {
  WidgetsFlutterBinding.ensureInitialized();
  _budgetImageCache();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const FroggyApp(screensaver: true));
}

class FroggyApp extends StatefulWidget {
  const FroggyApp({super.key, this.screensaver = false});

  final bool screensaver;

  @override
  State<FroggyApp> createState() => _FroggyAppState();
}

class _FroggyAppState extends State<FroggyApp> with WidgetsBindingObserver {
  late final SettingsController _settings;
  late final WeatherController _weather;
  bool _isTv = false;

  @override
  void initState() {
    super.initState();
    _settings = SettingsController();
    _weather = WeatherController(
      settings: _settings,
      allowLocationPrompt: !widget.screensaver,
    );
    _settings.addListener(_applyWakelock);
    WidgetsBinding.instance.addObserver(this);
    _detectTv();
    _boot();

    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _weather.setActive(isForeground(state));
  }

  void _applyWakelock() {
    if (widget.screensaver) return;
    WindowService.setKeepAwake(_settings.settings.kioskMode);
  }

  Future<void> _detectTv() async {
    final tv = await SystemStatusService().isTelevision();
    if (mounted && tv) setState(() => _isTv = tv);
  }

  Future<void> _boot() async {
    await _settings.load();
    await _weather.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
      builder: (context, child) {
        Widget result = Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
          },
          child: child!,
        );
        if (_isTv) {
          result = MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(navigationMode: NavigationMode.directional),
            child: result,
          );
        }
        return result;
      },
      home: widget.screensaver
          ? ScreensaverScreen(weather: _weather, settings: _settings)
          : HomeScreen(weather: _weather, settings: _settings),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.weather, required this.settings});

  final WeatherController weather;
  final SettingsController settings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _kRotateHintDismissed = 'rotate_hint_dismissed';

  final _updates = UpdateService();
  bool _locationWarningDismissed = false;
  bool? _rotateHintDismissed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
    if (kIsWeb) _loadRotateHint();
  }

  Future<void> _loadRotateHint() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool(_kRotateHintDismissed) ?? false;
    if (mounted) setState(() => _rotateHintDismissed = dismissed);
  }

  Future<void> _dismissRotateHint() async {
    setState(() => _rotateHintDismissed = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRotateHintDismissed, true);
  }

  bool _isMobilePortrait(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.height <= size.width) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void dispose() {
    _updates.dispose();
    super.dispose();
  }

  Future<void> _checkForUpdate() async {
    if (!widget.settings.settings.checkUpdatesOnStartup) return;
    final version = await WindowService.appVersion();
    if (version == null || version.isEmpty || !mounted) return;
    final info = await _updates.check(version);
    if (info == null || !info.updateAvailable || !mounted) return;
    if (!widget.settings.settings.checkUpdatesOnStartup) return;
    if (await _updates.skippedVersion() == info.latestVersion || !mounted) {
      return;
    }
    _showUpdateDialog(info);
  }

  void _showUpdateDialog(UpdateInfo info) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Froggy v${info.latestVersion} is available — '
                'you have v${info.currentVersion}.'),
            if (info.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: SingleChildScrollView(
                  child: Text(
                    info.notes,
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _updates.skipVersion(info.latestVersion);
              Navigator.pop(ctx);
            },
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _startUpdate(info);
            },
            child: Text(info.apkUrl != null ? 'Update' : 'View'),
          ),
        ],
      ),
    );
  }

  Future<void> _startUpdate(UpdateInfo info) async {
    if (info.apkUrl == null) {
      await WindowService.openUrl(info.releaseUrl);
      return;
    }
    final ok = await WindowService.installUpdate(info.apkUrl!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Downloading update…' : 'Could not start the update'),
      ),
    );
  }

  void _onSwipe(double velocity, {required bool forwardWhenNegative}) {
    if (velocity.abs() < 200) return;
    widget.weather.cycleLocation(
      forward: forwardWhenNegative ? velocity < 0 : velocity > 0,
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          SettingsScreen(settings: widget.settings, weather: widget.weather),
    ));
  }

  KeyEventResult _handleKey(BuildContext context, KeyEvent event) {
    final k = event.logicalKey;
    final isSelect = k == LogicalKeyboardKey.select ||
        k == LogicalKeyboardKey.enter ||
        k == LogicalKeyboardKey.numpadEnter ||
        k == LogicalKeyboardKey.gameButtonA ||
        k == LogicalKeyboardKey.contextMenu;
    final isScene = k == LogicalKeyboardKey.arrowLeft ||
        k == LogicalKeyboardKey.arrowRight;
    final isLocation = k == LogicalKeyboardKey.arrowUp ||
        k == LogicalKeyboardKey.arrowDown;
    if (!isSelect && !isScene && !isLocation) return KeyEventResult.ignored;
    if (event is KeyDownEvent) {
      if (isSelect) {
        _openSettings(context);
      } else if (isScene) {
        widget.weather.cycleScene();
      } else if (widget.weather.canCycleLocations) {
        widget.weather.cycleLocation(forward: k == LogicalKeyboardKey.arrowDown);
      } else {
        widget.weather.refresh();
      }
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final weather = widget.weather;
    final settings = widget.settings;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) => _handleKey(context, event),
        child: ListenableBuilder(
        listenable: Listenable.merge([weather, settings]),
        builder: (context, _) {
          if (!weather.ready) return const SplashScreen();
          final kiosk = settings.settings.kioskMode;
          final swipe = weather.canCycleLocations
              ? settings.settings.locationSwipe
              : LocationSwipe.off;
          final overlayPad =
              (MediaQuery.sizeOf(context).height * 0.06).clamp(16.0, 32.0);
          return Listener(
            onPointerDown: (e) {
              if (!weather.canCycleLocations) return;
              if (e.buttons & kBackMouseButton != 0) {
                weather.cycleLocation(forward: false);
              } else if (e.buttons & kForwardMouseButton != 0) {
                weather.cycleLocation(forward: true);
              }
            },
            child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: weather.cycleScene,
                onDoubleTap: weather.refresh,
                onLongPress: () => _openSettings(context),
                onHorizontalDragEnd: swipe == LocationSwipe.horizontal
                    ? (d) => _onSwipe(d.primaryVelocity ?? 0,
                        forwardWhenNegative: true)
                    : null,
                onVerticalDragEnd: swipe == LocationSwipe.vertical
                    ? (d) => _onSwipe(d.primaryVelocity ?? 0,
                        forwardWhenNegative: false)
                    : null,
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
                      padding: kIsWeb
                          ? EdgeInsets.only(
                              right: overlayPad, bottom: overlayPad)
                          : const EdgeInsets.all(8),
                      child: IconButton(
                        padding: kIsWeb ? EdgeInsets.zero : null,
                        constraints: kIsWeb ? const BoxConstraints() : null,
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
              if (kIsWeb &&
                  weather.locationDenied &&
                  !_locationWarningDismissed)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: _LocationWarning(
                      onRetry: weather.refresh,
                      onDismiss: () =>
                          setState(() => _locationWarningDismissed = true),
                    ),
                  ),
                ),
              if (kIsWeb &&
                  _rotateHintDismissed == false &&
                  _isMobilePortrait(context))
                _RotateHint(onDismiss: _dismissRotateHint),
              if (!kiosk &&
                  settings.settings.showLocationArrows &&
                  weather.canCycleLocations)
                _LocationArrows(
                  onBack: () => weather.cycleLocation(forward: false),
                  onForward: () => weather.cycleLocation(forward: true),
                ),
            ],
          ),
          );
        },
        ),
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

class _LocationArrows extends StatelessWidget {
  const _LocationArrows({required this.onBack, required this.onForward});

  final VoidCallback onBack;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _EdgeArrow(
              icon: Icons.chevron_left,
              tooltip: 'Previous location',
              onPressed: onBack,
            ),
            _EdgeArrow(
              icon: Icons.chevron_right,
              tooltip: 'Next location',
              onPressed: onForward,
            ),
          ],
        ),
      ),
    );
  }
}

class _EdgeArrow extends StatefulWidget {
  const _EdgeArrow({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  State<_EdgeArrow> createState() => _EdgeArrowState();
}

class _EdgeArrowState extends State<_EdgeArrow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: _hover ? 0.85 : 0.22,
        child: IconButton(
          icon: Icon(widget.icon),
          color: Colors.white,
          iconSize: 44,
          tooltip: widget.tooltip,
          onPressed: widget.onPressed,
        ),
      ),
    );
  }
}

class _RotateHint extends StatelessWidget {
  const _RotateHint({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.82),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.screen_rotation,
                    color: Colors.white, size: 48),
                const SizedBox(height: 20),
                const Text(
                  'Froggy looks best in landscape',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Rotate your phone sideways for the full view.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onDismiss,
                  child: const Text('Got it'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationWarning extends StatelessWidget {
  const _LocationWarning({required this.onRetry, required this.onDismiss});

  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_off, color: Colors.amber, size: 22),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Location is blocked, so this is your approximate area. '
                  'Allow location in your browser, then Retry.',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                tooltip: 'Dismiss',
                onPressed: onDismiss,
              ),
            ],
          ),
        ),
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
