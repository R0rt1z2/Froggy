import 'package:flutter/material.dart';

import '../models/settings.dart';
import '../services/geocoding_service.dart';
import '../services/system_status_service.dart';
import '../state/settings_controller.dart';
import '../state/weather_controller.dart';
import 'froggy_view.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.weather,
  });

  final SettingsController settings;
  final WeatherController weather;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showPreview = true;

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset settings?'),
        content: const Text(
            'Restore all settings to defaults. Saved locations are kept.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok == true) widget.settings.resetToDefaults();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _Preview(settings: widget.settings, weather: widget.weather);
    final controls = _Controls(settings: widget.settings);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Reset to defaults',
            onPressed: _confirmReset,
          ),
          IconButton(
            icon: Icon(_showPreview ? Icons.visibility_off : Icons.visibility),
            tooltip: _showPreview ? 'Hide preview' : 'Show preview',
            onPressed: () => setState(() => _showPreview = !_showPreview),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            if (!_showPreview) return controls;
            if (c.maxWidth > c.maxHeight) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                      child: Padding(
                          padding: const EdgeInsets.all(12), child: preview)),
                  Expanded(child: controls),
                ],
              );
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: AspectRatio(aspectRatio: 2, child: preview),
                ),
                Expanded(child: controls),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.settings, required this.weather});

  final SettingsController settings;
  final WeatherController weather;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: RepaintBoundary(
        child: ListenableBuilder(
          listenable: Listenable.merge([weather, settings]),
          builder: (context, _) => FroggyView(
            scene: weather.scene,
            weather: weather.weather,
            settings: settings.settings,
            locationName: weather.locationName,
            showTopBar: false,
          ),
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final s = settings.settings;
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            LayoutBuilder(
              builder: (context, c) {
                final units = _unitsBlock(context, s);
                final time = _timeBlock(context, s);
                if (c.maxWidth >= 360) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: units),
                      Expanded(child: time),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [units, time],
                );
              },
            ),
            const SizedBox(height: 8),
            _sectionTitle(context, 'Timing'),
            ListTile(
              dense: true,
              title: const Text('Weather refresh'),
              trailing: Text('${s.refreshMinutes} min'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Slider(
                value: s.refreshMinutes.toDouble(),
                min: 5,
                max: 120,
                divisions: 23,
                label: '${s.refreshMinutes} min',
                onChanged: (v) => settings.setRefreshMinutes(v.round()),
              ),
            ),
            ListTile(
              dense: true,
              title: const Text('Scene rotation'),
              trailing: Text(
                  s.rotateMinutes == 0 ? 'Off' : '${s.rotateMinutes} min'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Slider(
                value: s.rotateMinutes.toDouble(),
                min: 0,
                max: 60,
                divisions: 60,
                label: s.rotateMinutes == 0 ? 'Off' : '${s.rotateMinutes} min',
                onChanged: (v) => settings.setRotateMinutes(v.round()),
              ),
            ),
            const Divider(),
            _sectionTitle(context, 'Text shadow'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Slider(
                value: s.textShadow,
                min: 0,
                max: 1,
                divisions: 10,
                label: '${(s.textShadow * 100).round()}%',
                onChanged: settings.setTextShadow,
              ),
            ),
            const Divider(),
            _sectionTitle(context, 'Display'),
            SwitchListTile(
              title: const Text('Show date'),
              value: s.showDate,
              onChanged: settings.setShowDate,
            ),
            SwitchListTile(
              title: const Text('Show location'),
              subtitle: const Text('Place name at the top'),
              value: s.showLocation,
              onChanged: settings.setShowLocation,
            ),
            const Divider(),
            _sectionTitle(context, 'Dimming'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SegmentedButton<DimMode>(
                  segments: const [
                    ButtonSegment(value: DimMode.off, label: Text('Off')),
                    ButtonSegment(value: DimMode.auto, label: Text('Auto')),
                    ButtonSegment(
                        value: DimMode.scheduled, label: Text('Custom')),
                  ],
                  selected: {s.dimMode},
                  onSelectionChanged: (set) => settings.setDimMode(set.first),
                ),
              ),
            ),
            if (s.dimMode != DimMode.off)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text('Level'),
                    Expanded(
                      child: Slider(
                        value: s.nightDim,
                        min: 0,
                        max: 1,
                        divisions: 10,
                        label: '${(s.nightDim * 100).round()}%',
                        onChanged: settings.setNightDim,
                      ),
                    ),
                  ],
                ),
              ),
            if (s.dimMode == DimMode.scheduled) ...[
              ListTile(
                dense: true,
                leading: const Icon(Icons.bedtime_outlined),
                title: const Text('From'),
                trailing: Text(_fmtTime(context, s.dimStart)),
                onTap: () =>
                    _pickTime(context, s.dimStart, settings.setDimStart),
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.wb_sunny_outlined),
                title: const Text('To'),
                trailing: Text(_fmtTime(context, s.dimEnd)),
                onTap: () => _pickTime(context, s.dimEnd, settings.setDimEnd),
              ),
            ],
            const Divider(),
            _sectionTitle(context, 'Status icons'),
            SwitchListTile(
              title: const Text('Show status icons'),
              value: s.showStatus,
              onChanged: settings.setShowStatus,
            ),
            if (s.showStatus) ...[
              SwitchListTile(
                title: const Text('Wi-Fi'),
                value: s.showWifi,
                onChanged: settings.setShowWifi,
              ),
              SwitchListTile(
                title: const Text('Bluetooth'),
                value: s.showBluetooth,
                onChanged: settings.setShowBluetooth,
              ),
              SwitchListTile(
                title: const Text('Music'),
                value: s.showMusic,
                onChanged: settings.setShowMusic,
              ),
              if (s.showMusic)
                SwitchListTile(
                  title: const Text('Show music title'),
                  subtitle: const Text('Track name (needs notification access)'),
                  value: s.showMusicTitle,
                  onChanged: settings.setShowMusicTitle,
                ),
              if (s.showMusic && s.showMusicTitle)
                const _NotificationAccessTile(),
            ],
            const Divider(),
            _sectionTitle(context, 'Kiosk mode'),
            SwitchListTile(
              title: const Text('Kiosk mode'),
              subtitle: const Text(
                  'Always-on display for devices without a screensaver. Hides '
                  'the settings button (long-press the screen to reopen) and '
                  'keeps the screen on.'),
              value: s.kioskMode,
              onChanged: settings.setKioskMode,
            ),
            const Divider(),
            _sectionTitle(context, 'Location'),
            RadioGroup<String>(
              groupValue: s.locationMode == LocationMode.automatic
                  ? 'auto'
                  : (s.selected?.id ?? 'auto'),
              onChanged: (v) {
                if (v == null) return;
                if (v == 'auto') {
                  settings.setLocationMode(LocationMode.automatic);
                } else {
                  settings.selectLocation(v);
                }
              },
              child: Column(
                children: [
                  const RadioListTile<String>(
                    title: Text('Automatic'),
                    subtitle: Text('Detect from network / GPS'),
                    value: 'auto',
                  ),
                  for (final loc in s.savedLocations)
                    RadioListTile<String>(
                      title: Text(loc.name),
                      subtitle: loc.region == null ? null : Text(loc.region!),
                      value: loc.id,
                      secondary: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Remove',
                        onPressed: () => settings.removeLocation(loc.id),
                      ),
                    ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_location_alt_outlined),
              title: const Text('Add location'),
              onTap: () => _addLocation(context),
            ),
          ],
        );
      },
    );
  }

  Widget _unitsBlock(BuildContext context, Settings s) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Units'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<TempUnit>(
                segments: const [
                  ButtonSegment(value: TempUnit.celsius, label: Text('°C')),
                  ButtonSegment(value: TempUnit.fahrenheit, label: Text('°F')),
                ],
                selected: {s.unit},
                onSelectionChanged: (set) => settings.setUnit(set.first),
              ),
            ),
          ),
        ],
      );

  Widget _timeBlock(BuildContext context, Settings s) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Time format'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<ClockFormat>(
                segments: const [
                  ButtonSegment(value: ClockFormat.h24, label: Text('24h')),
                  ButtonSegment(value: ClockFormat.h12, label: Text('12h')),
                ],
                selected: {s.hourFormat},
                onSelectionChanged: (set) => settings.setClockFormat(set.first),
              ),
            ),
          ),
        ],
      );

  String _fmtTime(BuildContext context, int minutes) {
    final t = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    return t.format(context);
  }

  Future<void> _pickTime(
      BuildContext context, int minutes, void Function(int) onPicked) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (picked != null) onPicked(picked.hour * 60 + picked.minute);
  }

  Future<void> _addLocation(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _AddLocationScreen(settings: settings),
    ));
  }

  Widget _sectionTitle(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 1.0,
              ),
        ),
      );
}

class _NotificationAccessTile extends StatefulWidget {
  const _NotificationAccessTile();

  @override
  State<_NotificationAccessTile> createState() =>
      _NotificationAccessTileState();
}

class _NotificationAccessTileState extends State<_NotificationAccessTile>
    with WidgetsBindingObserver {
  final _service = SystemStatusService();
  bool _granted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final g = await _service.hasNotificationAccess();
    if (mounted) setState(() => _granted = g);
  }

  @override
  Widget build(BuildContext context) {
    if (_granted) return const SizedBox.shrink();
    return ListTile(
      leading: const Icon(Icons.notifications_off_outlined),
      title: const Text('Notification access'),
      subtitle: const Text('Needed to read the track title'),
      trailing: TextButton(
        onPressed: _service.openNotificationAccess,
        child: const Text('Grant'),
      ),
    );
  }
}

class _AddLocationScreen extends StatefulWidget {
  const _AddLocationScreen({required this.settings});

  final SettingsController settings;

  @override
  State<_AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<_AddLocationScreen> {
  final _geocoder = GeocodingService();
  final _field = TextEditingController();
  List<SavedLocation> _results = const [];
  bool _loading = false;
  String? _error;

  Future<void> _search() async {
    final q = _field.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await _geocoder.search(q);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
        if (results.isEmpty) _error = 'No matches found';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Search failed — check your connection';
      });
    }
  }

  @override
  void dispose() {
    _geocoder.dispose();
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add location')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _field,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'City name',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    tooltip: 'Search',
                    onPressed: _search,
                  ),
                ),
                onSubmitted: (_) => _search(),
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(
              child: ListView(
                children: [
                  for (final r in _results)
                    ListTile(
                      title: Text(r.name),
                      subtitle: r.region == null ? null : Text(r.region!),
                      onTap: () {
                        widget.settings.addLocation(r);
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
