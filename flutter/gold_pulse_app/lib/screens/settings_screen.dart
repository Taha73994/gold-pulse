import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/api.dart';
import '../core/theme.dart';
import '../widgets/app_header.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _api =
      TextEditingController(text: AppScope.of(context).api.baseUrl);
  bool _testing = false;
  String? _testMessage;
  bool? _testOk;

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    final state = AppScope.of(context);
    setState(() {
      _testing = true;
      _testMessage = null;
    });
    final saved = state.api.baseUrl;
    state.api.baseUrl = _api.text.trim();
    final ok = await state.testConnection();
    state.api.baseUrl = saved;
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testOk = ok;
      _testMessage = ok ? state.l.connected : state.l.connectionFailed;
    });
  }

  Future<void> _saveApi() async {
    final state = AppScope.of(context);
    await state.setApiBase(_api.text);
    if (!mounted) return;
    setState(() {
      _testOk = true;
      _testMessage = state.l.saved;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(state.l.saved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = state.l;
    final c = AppColors.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(title: l.settings),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
                children: [
                  _Section(
                    title: l.language,
                    icon: Icons.translate_rounded,
                    child: _Segmented(
                      options: [
                        (l.arabic, !state.en),
                        (l.english, state.en),
                      ],
                      onTap: (index) => state.setLanguage(index == 0 ? 'ar' : 'en'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    title: l.theme,
                    icon: Icons.palette_outlined,
                    child: _Segmented(
                      options: [
                        (l.systemTheme, state.themeMode == ThemeMode.system),
                        (l.lightTheme, state.themeMode == ThemeMode.light),
                        (l.darkTheme, state.themeMode == ThemeMode.dark),
                      ],
                      onTap: (index) => state.setThemeMode(
                        index == 0
                            ? ThemeMode.system
                            : index == 1
                                ? ThemeMode.light
                                : ThemeMode.dark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    title: l.autoRefresh,
                    icon: Icons.autorenew_rounded,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.autoRefreshNote,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              height: 1.5,
                              color: c.muted,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: state.autoRefresh,
                          activeThumbColor: c.gold,
                          onChanged: state.setAutoRefresh,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    title: l.apiBase,
                    icon: Icons.dns_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _api,
                          keyboardType: TextInputType.url,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12.5,
                          ),
                          decoration: InputDecoration(
                            hintText: l.apiHint,
                            prefixIcon: const Icon(Icons.link_rounded, size: 18),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _testing ? null : _test,
                                child: _testing
                                    ? const SizedBox(
                                        width: 15,
                                        height: 15,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(l.testConnection),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton(
                                onPressed: _testing ? null : _saveApi,
                                child: Text(l.save),
                              ),
                            ),
                          ],
                        ),
                        if (_testMessage != null) ...[
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              Icon(
                                _testOk == true
                                    ? Icons.check_circle_rounded
                                    : Icons.error_outline_rounded,
                                size: 14,
                                color: _testOk == true ? c.green : c.red,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  _testMessage!,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 10.5,
                                    color: _testOk == true ? c.green : c.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 7),
                        Text(
                          l.offlineHint,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 10,
                            height: 1.5,
                            color: c.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    title: l.privacy,
                    icon: Icons.privacy_tip_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.privacyNote,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            height: 1.6,
                            color: c.muted,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: c.surfaceAlt,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.fingerprint_rounded, size: 15, color: c.gold),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  state.deviceId,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 10,
                                    color: c.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _reset(context, state),
                    icon: const Icon(Icons.restart_alt_rounded, size: 17),
                    label: Text(l.resetSettings),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.red,
                      side: BorderSide(color: c.red.withValues(alpha: 0.4)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      '${l.version} ${state.config.version} · ${l.developer}: ${l.owner}',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        color: c.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reset(BuildContext context, AppState state) async {
    final l = state.l;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.resetSettings, style: const TextStyle(fontFamily: 'Cairo')),
        content: Text(
          l.resetConfirm,
          style: const TextStyle(fontFamily: 'Cairo', height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.ok),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await state.resetSettings();
      if (!context.mounted) return;
      _api.text = ApiClient.defaultBaseUrl;
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: c.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 15, color: c.gold),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: c.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          child,
        ],
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final List<(String, bool)> options;
  final ValueChanged<int> onTap;

  const _Segmented({required this.options, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: options.asMap().entries.map((entry) {
          final active = entry.value.$2;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: active ? c.gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  entry.value.$1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: active ? const Color(0xFF191305) : c.muted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
