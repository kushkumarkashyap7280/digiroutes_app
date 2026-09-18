import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'constants.dart';
import 'theme/app_theme.dart';

/// Shows a location the same way the DigiRoutes website does: Google's
/// no-API-key embeddable map (mirrors digiroute/components/MapPin.tsx),
/// loaded inside a real <iframe> — Google's embed refuses to render when
/// navigated to directly rather than embedded in a page. Requires no API
/// key and no billing.
class AppMapEmbed extends StatefulWidget {
  final double lat;
  final double lon;
  final double zoom;

  const AppMapEmbed({
    super.key,
    required this.lat,
    required this.lon,
    this.zoom = AppConstants.detailZoom,
  });

  @override
  State<AppMapEmbed> createState() => _AppMapEmbedState();
}

class _AppMapEmbedState extends State<AppMapEmbed> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.darkSurface2)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadHtmlString(_wrapperHtml(widget.lat, widget.lon, widget.zoom));
  }

  @override
  void didUpdateWidget(covariant AppMapEmbed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lat != widget.lat || oldWidget.lon != widget.lon) {
      setState(() => _loading = true);
      _controller.loadHtmlString(_wrapperHtml(widget.lat, widget.lon, widget.zoom));
    }
  }

  static String _wrapperHtml(double lat, double lon, double zoom) {
    final embedUrl = 'https://maps.google.com/maps?q=$lat,$lon'
        '&hl=en&z=${zoom.round()}&output=embed';
    return '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>html,body,iframe{margin:0;padding:0;width:100%;height:100%;border:0;display:block;}</style>
</head>
<body>
<iframe src="$embedUrl" loading="lazy" allowfullscreen referrerpolicy="no-referrer-when-downgrade"></iframe>
</body>
</html>
''';
  }

  /// Google's embed refuses to render outside a real `<iframe>`, and on
  /// Android the default "Surface" platform-view composition can draw the
  /// WebView's native surface above the rest of the Flutter UI regardless of
  /// widget stacking order (and can show a stale frame across reloads).
  /// Hybrid Composition composites the WebView within Flutter's own layer
  /// tree instead, so overlays (top bar, result cards, nav bar) stack
  /// correctly above it.
  Widget _buildWebView() {
    PlatformWebViewWidgetCreationParams params =
        PlatformWebViewWidgetCreationParams(controller: _controller.platform);
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewWidgetCreationParams
          .fromPlatformWebViewWidgetCreationParams(
        params,
        displayWithHybridComposition: true,
      );
    }
    return WebViewWidget.fromPlatformCreationParams(params: params);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: _buildWebView()),
        if (_loading)
          Positioned.fill(
            child: Container(
              color: AppTheme.darkSurface2,
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.orange),
              ),
            ),
          ),
      ],
    );
  }
}
