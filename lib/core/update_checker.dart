import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'theme/app_theme.dart';

/// Sideloaded-APK update check: DigiRoutes isn't on the Play Store, so
/// there's no store-side update mechanism. Instead we compare the running
/// app's version against the latest GitHub Release for this repo, and if
/// it's newer, offer to download + hand the APK to Android's own installer.
///
/// Installing over the current app (rather than uninstalling first) is what
/// keeps the user's session — that only works because every release is
/// signed with the same keystore in CI (see .github/workflows/build-apk.yml).
class UpdateInfo {
  final String version;
  final String apkUrl;
  final String notes;
  const UpdateInfo(
      {required this.version, required this.apkUrl, required this.notes});
}

class UpdateChecker {
  UpdateChecker._();

  static const _releasesUrl =
      'https://api.github.com/repos/kushkumarkashyap7280/digiroutes_app/releases/latest';

  static Future<UpdateInfo?> check() async {
    try {
      final res = await http.get(Uri.parse(_releasesUrl), headers: {
        'Accept': 'application/vnd.github+json'
      }).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final tag = (json['tag_name'] as String?)?.trim();
      if (tag == null || tag.isEmpty) return null;
      final remoteVersion = tag.startsWith('v') ? tag.substring(1) : tag;

      final current = await PackageInfo.fromPlatform();
      if (!_isNewer(remoteVersion, current.version)) return null;

      final assets = (json['assets'] as List?) ?? const [];
      String? apkUrl;
      for (final a in assets) {
        final map = a as Map<String, dynamic>;
        if ((map['name'] as String? ?? '').endsWith('.apk')) {
          apkUrl = map['browser_download_url'] as String?;
          break;
        }
      }
      if (apkUrl == null) return null;

      return UpdateInfo(
        version: remoteVersion,
        apkUrl: apkUrl,
        notes: (json['body'] as String?)?.trim() ?? '',
      );
    } catch (_) {
      // Offline, rate-limited, or GitHub is unreachable — never block the
      // app over this, just skip the check silently.
      return null;
    }
  }

  static bool _isNewer(String remote, String current) {
    List<int> parts(String v) =>
        v.split('.').map((p) => int.tryParse(p.trim()) ?? 0).toList();
    final r = parts(remote);
    final c = parts(current);
    for (var i = 0; i < r.length || i < c.length; i++) {
      final rv = i < r.length ? r[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (rv != cv) return rv > cv;
    }
    return false;
  }
}

/// Checks for an update and, if one exists, shows a simple prompt. Safe to
/// call on every app launch — silently does nothing when there's no update
/// or the check fails.
Future<void> maybePromptUpdate(BuildContext context) async {
  final info = await UpdateChecker.check();
  if (info == null || !context.mounted) return;

  final shouldUpdate = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Update available',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      content: Text(
        'DigiRoutes v${info.version} is available. Update now to get the '
        'latest fixes and features.',
        style: GoogleFonts.outfit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Later', style: GoogleFonts.outfit()),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('Update', style: GoogleFonts.outfit()),
        ),
      ],
    ),
  );

  if (shouldUpdate == true && context.mounted) {
    await _downloadAndInstall(context, info);
  }
}

Future<void> _downloadAndInstall(BuildContext context, UpdateInfo info) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      content: Row(
        children: [
          const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 16),
          Expanded(
              child: Text('Downloading update…', style: GoogleFonts.outfit())),
        ],
      ),
    ),
  );

  try {
    final res = await http.get(Uri.parse(info.apkUrl));
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/digiroutes-update.apk');
    await file.writeAsBytes(res.bodyBytes);

    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    await OpenFilex.open(file.path);
  } catch (_) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Update download failed. Try again later.',
            style: GoogleFonts.outfit()),
        backgroundColor: AppTheme.danger,
      ));
    }
  }
}
