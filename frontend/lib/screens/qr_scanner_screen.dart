import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/l10n.dart';

class QRScannerScreen extends StatefulWidget {
  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isScanned = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() {
          _isScanned = true;
        });
        cameraController.stop();
        Navigator.pop(context, barcode.rawValue);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<SettingsProvider>(context).languageCode;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.t('scanQr', lang)),
        actions: [
          IconButton(
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: cameraController,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                  default:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: cameraController,
              builder: (context, state, child) {
                switch (state.cameraDirection) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                  default:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: Theme.of(context).colorScheme.primary,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: MediaQuery.of(context).size.width * 0.8,
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                L10n.t('alignQr', lang),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// A simple overlay shape to highlight the scanning zone
class QrScannerOverlayShape extends ShapeBorder {
  QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path _getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return _getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderHeightSize = height / 2;
    final borderSize = cutOutSize / 2;

    var paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas
      ..drawRect(
        Rect.fromLTRB(
            rect.left, rect.top, rect.right, borderHeightSize - borderSize),
        paint,
      )
      ..drawRect(
        Rect.fromLTRB(rect.left, borderHeightSize + borderSize, rect.right,
            rect.bottom),
        paint,
      )
      ..drawRect(
        Rect.fromLTRB(rect.left, borderHeightSize - borderSize,
            borderWidthSize - borderSize, borderHeightSize + borderSize),
        paint,
      )
      ..drawRect(
        Rect.fromLTRB(borderWidthSize + borderSize, borderHeightSize - borderSize,
            rect.right, borderHeightSize + borderSize),
        paint,
      );

    paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final path = Path();

    // top left
    path.moveTo(borderWidthSize - borderSize, borderHeightSize - borderSize + borderLength);
    path.lineTo(borderWidthSize - borderSize, borderHeightSize - borderSize + borderRadius);
    path.arcToPoint(Offset(borderWidthSize - borderSize + borderRadius, borderHeightSize - borderSize),
        radius: Radius.circular(borderRadius));
    path.lineTo(borderWidthSize - borderSize + borderLength, borderHeightSize - borderSize);

    // top right
    path.moveTo(borderWidthSize + borderSize - borderLength, borderHeightSize - borderSize);
    path.lineTo(borderWidthSize + borderSize - borderRadius, borderHeightSize - borderSize);
    path.arcToPoint(Offset(borderWidthSize + borderSize, borderHeightSize - borderSize + borderRadius),
        radius: Radius.circular(borderRadius));
    path.lineTo(borderWidthSize + borderSize, borderHeightSize - borderSize + borderLength);

    // bottom right
    path.moveTo(borderWidthSize + borderSize, borderHeightSize + borderSize - borderLength);
    path.lineTo(borderWidthSize + borderSize, borderHeightSize + borderSize - borderRadius);
    path.arcToPoint(Offset(borderWidthSize + borderSize - borderRadius, borderHeightSize + borderSize),
        radius: Radius.circular(borderRadius));
    path.lineTo(borderWidthSize + borderSize - borderLength, borderHeightSize + borderSize);

    // bottom left
    path.moveTo(borderWidthSize - borderSize + borderLength, borderHeightSize + borderSize);
    path.lineTo(borderWidthSize - borderSize + borderRadius, borderHeightSize + borderSize);
    path.arcToPoint(Offset(borderWidthSize - borderSize, borderHeightSize + borderSize - borderRadius),
        radius: Radius.circular(borderRadius));
    path.lineTo(borderWidthSize - borderSize, borderHeightSize + borderSize - borderLength);

    canvas.drawPath(path, paint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      overlayColor: overlayColor,
      borderRadius: borderRadius * t,
      borderLength: borderLength * t,
      cutOutSize: cutOutSize * t,
    );
  }
}
