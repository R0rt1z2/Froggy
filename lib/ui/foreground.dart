import 'package:flutter/widgets.dart';

bool isForeground(AppLifecycleState state) =>
    state == AppLifecycleState.resumed || state == AppLifecycleState.inactive;

mixin ForegroundAware<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  bool _foreground = true;

  bool get foreground => _foreground;

  void onForegroundChanged(bool foreground);

  @override
  void initState() {
    super.initState();
    final binding = WidgetsBinding.instance;
    _foreground =
        isForeground(binding.lifecycleState ?? AppLifecycleState.resumed);
    binding.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final next = isForeground(state);
    if (next == _foreground || !mounted) return;
    setState(() => _foreground = next);
    onForegroundChanged(next);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
