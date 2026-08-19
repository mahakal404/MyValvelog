import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/heart_valve_entry.dart';
import '../providers/entry_provider.dart';
import 'entry_form_screen.dart';

class EntryDetailScreen extends StatefulWidget {
  final HeartValveEntry entry;

  const EntryDetailScreen({super.key, required this.entry});

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  // --- AdMob Variables ---
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  
  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-8923815584192096/8166475603'
      : 'ca-app-pub-3940256099942544/2934735716';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    final screenWidth = MediaQuery.of(context).size.width.truncate();
    
    final size = await AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.portrait,
      screenWidth,
    );

    if (size == null) return;

    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          if (mounted) {
            setState(() => _isAdLoaded = true);
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('EntryDetail BannerAd failed. Code: ${error.code}, Message: ${error.message}');
          ad.dispose();
        },
      ),
    );

    await _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    EntryProvider provider,
    int id,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this entry?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      provider.deleteEntry(id);
      if (!context.mounted) return;
      Navigator.pop(context); // Go back to dashboard
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Entry deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EntryProvider>(
      builder: (context, provider, child) {
        final currentEntry = provider.entries
            .cast<HeartValveEntry?>()
            .firstWhere((e) => e?.id == widget.entry.id, orElse: () => null);

        if (currentEntry == null) {
          return const Scaffold(body: Center(child: Text('Entry not found')));
        }

        return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            title: const Text('Entry Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EntryFormScreen(entryToEdit: currentEntry),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () =>
                    _confirmDelete(context, provider, currentEntry.id!),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailRow('Model', currentEntry.model),
                    const Divider(),
                    _buildDetailRow('Serial No.', currentEntry.serialNo),
                    const Divider(),
                    _buildDetailRow('Batch No.', currentEntry.batchNo),
                    const Divider(),
                    _buildDetailRow('Job Card No', currentEntry.jobCardNo),
                    const Divider(),
                    _buildDetailRow('Size', currentEntry.size),
                    const Divider(),
                    _buildDetailRow('Quantity', currentEntry.quantity.toString()),
                    const Divider(),
                    _buildDetailRow('Status', currentEntry.status),
                    const Divider(),
                    _buildDetailRow('Assembly', currentEntry.assembly),
                    const Divider(),
                    _buildDetailRow('Section', currentEntry.section),
                    const Divider(),
                    _buildDetailRow('Signature', currentEntry.sign),
                    const Divider(),
                    _buildDetailRow(
                      'Take Time',
                      DateFormat('MMM dd, yyyy - hh:mm a')
                          .format(currentEntry.takeTime),
                    ),
                    const Divider(),
                    _buildDetailRow(
                      'Submit Time',
                      DateFormat('MMM dd, yyyy - hh:mm a')
                          .format(currentEntry.submitTime),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: _isAdLoaded && _bannerAd != null
              ? SafeArea(
                  child: SizedBox(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}
