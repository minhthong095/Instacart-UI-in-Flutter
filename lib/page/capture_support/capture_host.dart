import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

typedef CaptureScrollableBuilder = Widget Function(
  BuildContext context,
  ScrollController controller,
);

/// Assemble the real screen's fixed regions and its main vertical scroll view.
/// Debug exports reuse these painted layers and the device's viewport metrics.
class CaptureHost extends StatefulWidget {
  const CaptureHost.eager({
    super.key,
    required this.screenId,
    required this.backgroundColor,
    required WidgetBuilder this.contentBuilder,
    this.headerBuilder,
    this.footerBuilder,
    this.overlayBuilder,
    this.overlayHeight = 0,
    this.controller,
    this.prepareCapture,
  }) : scrollableBuilder = null;

  const CaptureHost.lazy({
    super.key,
    required this.screenId,
    required this.backgroundColor,
    required CaptureScrollableBuilder this.scrollableBuilder,
    this.headerBuilder,
    this.footerBuilder,
    this.controller,
    this.prepareCapture,
  }) : contentBuilder = null,
       overlayBuilder = null,
       overlayHeight = 0;

  final String screenId;
  final Color backgroundColor;
  final WidgetBuilder? contentBuilder;
  final CaptureScrollableBuilder? scrollableBuilder;
  final WidgetBuilder? headerBuilder;
  final WidgetBuilder? footerBuilder;

  /// Eager-mode fixed transparent overlay, composited once at export bottom.
  final WidgetBuilder? overlayBuilder;
  final double overlayHeight;
  final ScrollController? controller;

  /// Precache asynchronous screen assets here. Lazy items should use the same
  /// cache; arbitrary Futures and native platform views cannot be inferred.
  final Future<void> Function()? prepareCapture;

  @override
  State<CaptureHost> createState() => _CaptureHostState();
}

class _CaptureHostState extends State<CaptureHost> {
  final _header = GlobalKey();
  final _body = GlobalKey();
  final _viewport = GlobalKey();
  final _footer = GlobalKey();
  final _overlay = GlobalKey();
  late final ScrollController _ownedController = ScrollController();
  ScrollController get controller => widget.controller ?? _ownedController;
  bool _capturing = false;
  bool _disposing = false;

  void _setCapturing(bool value) {
    if (mounted && !_disposing) setState(() => _capturing = value);
  }

  @override
  void initState() {
    super.initState();
    if (kDebugMode) CaptureService._register(this);
  }

  @override
  void didUpdateWidget(CaptureHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_capturing) {
      CaptureService._invalidate(this, 'The screen rebuilt during capture.');
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    CaptureService._invalidate(this, 'Hot reload interrupted the capture.');
  }

  @override
  void dispose() {
    _disposing = true;
    CaptureService._hosts.remove(this);
    CaptureService._invalidate(this, 'The capture screen was disposed.');
    _ownedController.dispose();
    super.dispose();
  }

  Widget _boundary(GlobalKey key, Widget child) =>
      kDebugMode ? _RegionBoundary(key: key, child: child) : child;

  @override
  Widget build(BuildContext context) {
    final content = widget.contentBuilder;
    final scrollable = content == null
        ? widget.scrollableBuilder!(context, controller)
        : SingleChildScrollView(
            controller: controller,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: _boundary(_body, content(context)),
          );
    return IgnorePointer(
      ignoring: _capturing,
      child: TickerMode(
        enabled: !_capturing,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.headerBuilder != null)
                  _boundary(_header, widget.headerBuilder!(context)),
                Expanded(child: _boundary(_viewport, scrollable)),
                if (widget.footerBuilder != null)
                  _boundary(_footer, widget.footerBuilder!(context)),
              ],
            ),
            if (widget.overlayBuilder != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: widget.overlayHeight,
                child: _boundary(_overlay, widget.overlayBuilder!(context)),
              ),
          ],
        ),
      ),
    );
  }
}

/// A single debug extension shared by every mounted CaptureHost.
/// Public request() also lets Flutter tests exercise the real export protocol.
class CaptureService {
  static const extension = 'ext.imageToFlutter.capture';
  static final _hosts = <_CaptureHostState>{};
  static bool _registered = false;
  static _CaptureTransaction? _active;
  static int _sequence = 0;
  static final _completed = <String, Map<String, Object?>>{};

  static void _remember(_CaptureTransaction transaction) {
    _completed[transaction.id] = transaction.manifest();
    while (_completed.length > 8) {
      _completed.remove(_completed.keys.first);
    }
  }

  static void _register(_CaptureHostState host) {
    _hosts.add(host);
    if (_registered || !kDebugMode) return;
    developer.registerExtension(extension, (_, parameters) async {
      try {
        return developer.ServiceExtensionResponse.result(
          jsonEncode(await request(parameters)),
        );
      } catch (error) {
        return developer.ServiceExtensionResponse.error(
          developer.ServiceExtensionResponse.extensionError,
          error.toString(),
        );
      }
    });
    _registered = true;
  }

  static void _invalidate(_CaptureHostState host, String reason) {
    final active = _active;
    if (active != null && identical(active.host, host)) {
      active.invalidReason = reason;
      // Dispose/reassemble cannot await; next/finish still performs cleanup.
      unawaited(
        active.restore().whenComplete(() {
          _remember(active);
          if (identical(_active, active)) _active = null;
        }),
      );
    }
  }

  static Future<Map<String, Object?>> request(
    Map<String, String> parameters,
  ) async {
    if (!kDebugMode) {
      throw StateError('Capture is available only in debug mode.');
    }
    final action = parameters['action'] ?? 'list';
    if (action == 'list') {
      return {
        'screens': [
          for (final host in _hosts)
            if (host.mounted && ModalRoute.of(host.context)?.isCurrent != false)
              {
                'screenId': host.widget.screenId,
                'mode': host.widget.contentBuilder == null ? 'lazy' : 'eager',
              },
        ],
      };
    }
    if (action == 'begin') {
      if (_active != null) {
        throw StateError('Another capture is already active.');
      }
      final matches = _hosts
          .where(
            (host) =>
                host.mounted &&
                host.widget.screenId == parameters['screenId'] &&
                ModalRoute.of(host.context)?.isCurrent != false,
          )
          .toList();
      if (matches.length != 1) {
        throw StateError(
          'Expected one visible CaptureHost for ${parameters['screenId']}; found ${matches.length}.',
        );
      }
      final transaction = _CaptureTransaction(matches.single, '${++_sequence}');
      _active = transaction;
      try {
        return await transaction.begin();
      } catch (_) {
        await transaction.restore();
        _remember(transaction);
        _active = null;
        rethrow;
      }
    }
    final retained = _completed[parameters['captureId']];
    if (action == 'cancel' && retained != null) return retained;
    final transaction = _active;
    if (transaction == null || parameters['captureId'] != transaction.id) {
      throw StateError('Unknown capture transaction.');
    }
    if (action == 'finish' || action == 'cancel') {
      try {
        if (action == 'finish' && !transaction.complete) {
          throw StateError('Capture coverage is incomplete.');
        }
        await transaction.restore();
        return transaction.manifest();
      } finally {
        await transaction.restore();
        _remember(transaction);
        _active = null;
      }
    }
    if (action != 'next') throw ArgumentError('Unknown action: $action');
    try {
      return await transaction.next();
    } catch (_) {
      await transaction.restore();
      _remember(transaction);
      _active = null;
      rethrow;
    }
  }
}

class _Slice {
  const _Slice(this.key, this.bounds, this.y, this.region);
  final GlobalKey key;
  final Rect bounds;
  final int y;
  final String region;
}

class _CaptureTransaction {
  _CaptureTransaction(this.host, this.id);
  final _CaptureHostState host;
  final String id;
  final _clock = Stopwatch()..start();
  final _eagerSlices = <_Slice>[];
  final _offsets = <double>[];
  Timer? _lease;
  bool _busy = false;
  bool _restored = false;
  bool complete = false;
  String? invalidReason;
  late double ratio;
  late Size viewSize;
  late EdgeInsets viewPadding;
  double savedOffset = 0;
  bool _started = false;
  late ScrollController controller;
  int width = 0;
  int headerHeight = 0;
  int footerHeight = 0;
  int bodyHeight = 0;
  late double viewportHeight;
  late double textScale;
  late Brightness brightness;
  int _sliceIndex = 0;
  int _phase = 0;
  int _covered = 0;
  int _tileCount = 0;
  int _footerY = 0;
  double _nextOffset = 0;
  bool _bottom = false;
  ScrollHoldController? _scrollHold;

  _RegionRenderer _boundary(GlobalKey key) {
    final object = key.currentContext?.findRenderObject();
    if (object is! _RegionRenderer || !object.attached || !object.hasSize) {
      throw StateError('The capture region is not mounted and laid out.');
    }
    return object;
  }

  void _check() {
    if (invalidReason != null) throw StateError(invalidReason!);
    if (!host.mounted || host._disposing) {
      throw StateError('CaptureHost was disposed.');
    }
    if (_clock.elapsed > const Duration(seconds: 120)) {
      throw StateError('Capture exceeded two minutes.');
    }
    final view = View.of(host.context);
    if (view.devicePixelRatio != ratio ||
        view.physicalSize / ratio != viewSize ||
        MediaQuery.viewPaddingOf(host.context) != viewPadding ||
        MediaQuery.viewInsetsOf(host.context) != EdgeInsets.zero ||
        MediaQuery.textScalerOf(host.context).scale(14) / 14 != textScale ||
        MediaQuery.platformBrightnessOf(host.context) != brightness) {
      throw StateError('Device metrics changed or the keyboard is open.');
    }
    if (host.controller != controller || controller.positions.length != 1) {
      throw StateError('Capture requires one attached main scroll position.');
    }
    if (ModalRoute.of(host.context)?.isCurrent == false) {
      throw StateError('The capture screen is no longer the current route.');
    }
  }

  Future<void> _frame() {
    WidgetsBinding.instance.scheduleFrame();
    return WidgetsBinding.instance.endOfFrame.timeout(
      const Duration(seconds: 10),
    );
  }

  Future<void> _settle() async {
    _check();
    // Two laid-out frames resolve viewport corrections after jumpTo().
    await _frame();
    await _frame();
    while (PaintingBinding.instance.imageCache.pendingImageCount > 0) {
      _check();
      await Future<void>.delayed(const Duration(milliseconds: 16));
      await _frame();
    }
    _check();
  }

  Future<Map<String, Object?>> begin() async {
    final view = View.of(host.context);
    ratio = view.devicePixelRatio;
    viewSize = view.physicalSize / ratio;
    viewPadding = MediaQuery.viewPaddingOf(host.context);
    textScale = MediaQuery.textScalerOf(host.context).scale(14) / 14;
    brightness = MediaQuery.platformBrightnessOf(host.context);
    controller = host.controller;
    if (controller.positions.length != 1 ||
        controller.position.axis != Axis.vertical ||
        controller.position.axisDirection != AxisDirection.down) {
      throw StateError(
        'Supply a single, non-reversed vertical scroll controller.',
      );
    }
    savedOffset = controller.offset;
    _check();
    _started = true;
    host._setCapturing(true);
    _lease = Timer(const Duration(seconds: 120), () {
      invalidReason = 'Capture client timed out.';
      unawaited(
        restore().whenComplete(() {
          CaptureService._remember(this);
          if (identical(CaptureService._active, this)) {
            CaptureService._active = null;
          }
        }),
      );
    });
    await host.widget.prepareCapture?.call().timeout(
      const Duration(seconds: 30),
    );
    await _settle();
    _rejectUnsupportedContent();
    if (controller.position.minScrollExtent.abs() > .0001) {
      throw StateError('Capture requires a zero-origin main scroll extent.');
    }
    final viewport = _boundary(host._viewport);
    width = (viewport.size.width * ratio).round();
    viewportHeight = viewport.size.height;
    if (width != (viewSize.width * ratio).round()) {
      throw StateError('CaptureHost must span the device width.');
    }
    headerHeight = host.widget.headerBuilder == null
        ? 0
        : (_boundary(host._header).size.height * ratio).round();
    footerHeight = host.widget.footerBuilder == null
        ? 0
        : (_boundary(host._footer).size.height * ratio).round();
    bodyHeight = 0;
    if (host.widget.contentBuilder != null) {
      bodyHeight =
          (math.max(_boundary(host._body).size.height, viewportHeight) * ratio)
              .ceil();
      _appendRegion(host._header, headerHeight, 0, 'header');
      _appendRegion(host._body, bodyHeight, headerHeight, 'body');
      _appendRegion(
        host._footer,
        footerHeight,
        headerHeight + bodyHeight,
        'footer',
      );
    }
    return {...manifest(), 'captureId': id};
  }

  void _rejectUnsupportedContent() {
    void visit(Element element) {
      if (element.widget is UiKitView ||
          element.widget is AndroidView ||
          element.widget is PlatformViewSurface) {
        throw StateError('Native platform views require a native screenshot.');
      }
      final render = element is RenderObjectElement
          ? element.renderObject
          : null;
      if (render is RenderSliverPinnedPersistentHeader ||
          render is RenderSliverFloatingPersistentHeader) {
        throw StateError(
          'Pinned/floating slivers need an explicit capture adapter.',
        );
      }
      element.visitChildren(visit);
    }

    (host.context as Element).visitChildren(visit);
  }

  void _appendRegion(GlobalKey key, int height, int y, String region) {
    const sliceHeight = 2048;
    for (var start = 0; start < height; start += sliceHeight) {
      final count = math.min(sliceHeight, height - start);
      _eagerSlices.add(
        _Slice(
          key,
          Rect.fromLTWH(0, start / ratio, width / ratio, count / ratio),
          y + start,
          region,
        ),
      );
    }
  }

  Future<Map<String, Object?>> _encode(_Slice slice, {int cropTop = 0}) async {
    _check();
    if (++_tileCount > 128) throw StateError('Capture exceeded 128 slices.');
    final boundary = _boundary(slice.key);
    if (boundary.debugNeedsPaint) await _settle();
    var image = await boundary.export(slice.bounds, ratio);
    if (host.widget.overlayBuilder != null) {
      final overlay = _boundary(host._overlay);
      final total = headerHeight + bodyHeight + footerHeight;
      final overlayY = total - (overlay.size.height * ratio).round();
      if (slice.y + image.height > overlayY) {
        final layerImage = await overlay.export(
          Offset.zero & overlay.size,
          ratio,
        );
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawImage(image, Offset.zero, Paint());
        canvas.drawImage(
          layerImage,
          Offset(0, (overlayY - slice.y).toDouble()),
          Paint(),
        );
        final picture = recorder.endRecording();
        final composed = await picture.toImage(image.width, image.height);
        picture.dispose();
        layerImage.dispose();
        image.dispose();
        image = composed;
      }
    }
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('PNG encoding failed.');
      return {
        'done': false,
        'region': slice.region,
        'y': slice.y,
        'cropTop': cropTop,
        'width': image.width,
        'height': image.height,
        'png': base64Encode(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        ),
      };
    } finally {
      image.dispose();
    }
  }

  Future<void> _jumpTo(double target) async {
    for (var attempt = 0; attempt < 8; attempt++) {
      _scrollHold?.cancel();
      _scrollHold = null;
      final position = controller.position;
      controller.jumpTo(
        target.clamp(position.minScrollExtent, position.maxScrollExtent),
      );
      _scrollHold = controller.position.hold(() {});
      await _settle();
      // A lazy list's estimated max extent can shrink after its last items
      // lay out. Bouncing physics must not leave overscroll in the export.
      final actual = controller.position;
      target = actual.pixels.clamp(
        actual.minScrollExtent,
        actual.maxScrollExtent,
      );
      if ((target - actual.pixels).abs() < .0001) return;
    }
    throw StateError('The lazy scroll extent did not stabilize.');
  }

  Future<Map<String, Object?>> next() async {
    if (_busy) throw StateError('A capture request is already running.');
    _busy = true;
    try {
      _check();
      if (host.widget.contentBuilder != null) {
        if (_sliceIndex == _eagerSlices.length) {
          complete = true;
          return {'done': true, ...manifest()};
        }
        return await _encode(_eagerSlices[_sliceIndex++]);
      }
      if (_phase == 0) {
        _phase = 1;
        if (headerHeight > 0) {
          return await _encode(
            _Slice(
              host._header,
              Rect.fromLTWH(0, 0, width / ratio, headerHeight / ratio),
              0,
              'header',
            ),
          );
        }
      }
      if (_phase == 1 && !_bottom) {
        final requested = math.min(
          _nextOffset,
          controller.position.maxScrollExtent,
        );
        await _jumpTo(requested);
        _rejectUnsupportedContent();
        if ((_boundary(host._viewport).size.height - viewportHeight).abs() >
            .01) {
          throw StateError('The scroll viewport changed height.');
        }
        final position = controller.position;
        final offset = position.pixels;
        final start = (offset * ratio).round();
        final height = (viewportHeight * ratio).round();
        if (start > _covered) {
          throw StateError('A scroll correction left a coverage gap.');
        }
        _bottom = position.extentAfter <= .5 / ratio;
        if (_offsets.isNotEmpty && offset <= _offsets.last && !_bottom) {
          throw StateError('The lazy list stopped advancing before its end.');
        }
        final crop = math.max(0, _covered - start);
        _offsets.add(offset);
        _nextOffset = ((offset + viewportHeight * .8) * ratio).round() / ratio;
        if (crop < height) {
          final y = headerHeight + _covered;
          _covered = start + height;
          bodyHeight = _covered;
          return await _encode(
            _Slice(
              host._viewport,
              Rect.fromLTWH(0, 0, width / ratio, viewportHeight),
              y,
              'body',
            ),
            cropTop: crop,
          );
        }
      }
      if (_phase == 1) {
        if (!_bottom) throw StateError('Lazy content coverage is incomplete.');
        _phase = 2;
        _footerY = headerHeight + bodyHeight;
      }
      if (_phase == 2) {
        _phase = 3;
        if (footerHeight > 0) {
          return await _encode(
            _Slice(
              host._footer,
              Rect.fromLTWH(0, 0, width / ratio, footerHeight / ratio),
              _footerY,
              'footer',
            ),
          );
        }
      }
      complete = true;
      return {'done': true, ...manifest()};
    } finally {
      _busy = false;
    }
  }

  Map<String, Object?> manifest() => {
    'schemaVersion': 1,
    'screenId': host.widget.screenId,
    'backend': 'flutter-device-layers',
    'mode': host.widget.contentBuilder == null ? 'lazy' : 'eager',
    'systemChromeIncluded': false,
    'pixelRatio': ratio,
    'platform': defaultTargetPlatform.name,
    'platformBrightness': brightness.name,
    'textScale': textScale,
    'viewport': [viewSize.width, viewSize.height],
    'safeArea': [
      viewPadding.left,
      viewPadding.top,
      viewPadding.right,
      viewPadding.bottom,
    ],
    'background': host.widget.backgroundColor.toARGB32(),
    'outputDimensions': [width, headerHeight + bodyHeight + footerHeight],
    'fixedTopPixels': headerHeight,
    'fixedBottomPixels': footerHeight,
    'scrollOffsets': _offsets,
    'originalScrollOffset': savedOffset,
    'restored': _restored,
    'restoredScrollOffset':
        _restored && controller.hasClients && controller.positions.length == 1
        ? controller.offset
        : null,
    'complete': complete,
    'elapsedMilliseconds': _clock.elapsedMilliseconds,
  };

  Future<void>? _restoration;

  Future<void> restore() => _restoration ??= _restore();

  Future<void> _restore() async {
    _lease?.cancel();
    _scrollHold?.cancel();
    _scrollHold = null;
    if (_started && host.mounted && !host._disposing) {
      try {
        if (controller.hasClients && controller.positions.length == 1) {
          controller.jumpTo(
            savedOffset.clamp(
              controller.position.minScrollExtent,
              controller.position.maxScrollExtent,
            ),
          );
        }
      } finally {
        host._setCapturing(false);
      }
      await _frame();
    }
    _restored = true;
  }
}

class _RegionBoundary extends SingleChildRenderObjectWidget {
  const _RegionBoundary({super.key, required super.child});

  @override
  _RegionRenderer createRenderObject(BuildContext context) => _RegionRenderer();
}

class _RegionRenderer extends RenderRepaintBoundary {
  Future<ui.Image> export(Rect bounds, double ratio) async {
    if (debugNeedsPaint || layer is! OffsetLayer) {
      throw StateError('The capture region has not painted.');
    }
    final captureLayer = layer! as OffsetLayer;
    final builder = ui.SceneBuilder();
    final transform = Matrix4.diagonal3Values(ratio, ratio, 1)
      ..translateByDouble(
        -(bounds.left + captureLayer.offset.dx),
        -(bounds.top + captureLayer.offset.dy),
        0,
        1,
      );
    builder.pushTransform(transform.storage);
    final scene = captureLayer.buildScene(builder);
    try {
      // Bounds originate on physical-pixel boundaries. OffsetLayer.toImage
      // uses ceil(), which can add a row after floating-point subtraction.
      return await scene.toImage(
        (bounds.width * ratio).round(),
        (bounds.height * ratio).round(),
      );
    } finally {
      scene.dispose();
    }
  }
}
