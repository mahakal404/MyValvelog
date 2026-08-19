import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class MediumRectangleAdWidget extends StatefulWidget {
  const MediumRectangleAdWidget({super.key});

  @override
  State<MediumRectangleAdWidget> createState() => _MediumRectangleAdWidgetState();
}

class _MediumRectangleAdWidgetState extends State<MediumRectangleAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  // Use real ad unit IDs for Medium Rectangle
  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-8923815584192096/8851203014' 
      : 'ca-app-pub-3940256099942544/2934735716';

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.mediumRectangle,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('MediumRectangleAd failed to load: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _bannerAd != null) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    
    // Placeholder space while loading
    return SizedBox(
      width: 300,
      height: 250,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
