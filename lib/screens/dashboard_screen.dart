import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'package:file_saver/file_saver.dart';
import 'package:printing/printing.dart';
import 'package:open_filex/open_filex.dart';
import '../providers/entry_provider.dart';
import '../providers/settings_provider.dart';
import '../services/database_helper.dart';
import '../services/pdf_helper.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'entry_form_screen.dart';
import 'entry_detail_screen.dart';
import 'settings_screen.dart';

import '../widgets/medium_rectangle_ad_widget.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DashboardContent();
  }
}

class _DashboardContent extends StatefulWidget {
  const _DashboardContent();

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  final GlobalKey _pdfKey = GlobalKey();
  final GlobalKey _addEntryKey = GlobalKey();

  bool _isGeneratingPdf = false;
  String _selectedModelFilter = 'All';
  String _selectedSizeFilter = 'All';

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
          if (mounted) setState(() => _isAdLoaded = true);
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('Dashboard BannerAd failed. Code: ${error.code}, Message: ${error.message}');
          ad.dispose();
        },
      ),
    );

    await _bannerAd!.load();
  }

  Future<String> _savePdfLocally(Uint8List bytes, String fileName) async {
    // file_saver handles extensions automatically, so strip it from the name
    final nameWithoutExt = fileName.endsWith('.pdf')
        ? fileName.substring(0, fileName.length - 4)
        : fileName;

    final savedPath = await FileSaver.instance.saveFile(
      name: nameWithoutExt,
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );

    return savedPath;
  }

  @override
  void initState() {
    super.initState();
    ShowcaseView.register();
    _checkShowcase();
  }

  @override
  void dispose() {
    ShowcaseView.get().unregister();
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _checkShowcase() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('hasSeenShowcase') ?? false;

    if (!hasSeen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ShowcaseView.get().startShowCase([_pdfKey, _addEntryKey]);
        }
      });
      await prefs.setBool('hasSeenShowcase', true);
    }
  }

  Future<void> _showReportDialog(BuildContext context) async {
    final List<ConnectivityResult> connectivityResult = await Connectivity()
        .checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none) ||
        connectivityResult.isEmpty) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              const Text(
                'No Internet Connection',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Please enable Wi-Fi or Cellular Data to generate, view, or download your PDF reports.',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Got It', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    final now = DateTime.now();
    int selectedMonth = now.month;
    int selectedYear = now.year;

    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const years = [2024, 2025, 2026, 2027, 2028, 2029, 2030];

    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Report Period'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Month Dropdown
                  DropdownButtonFormField<int>(
                    initialValue: selectedMonth,
                    decoration: const InputDecoration(
                      labelText: 'Month',
                      prefixIcon: Icon(Icons.calendar_month_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(12, (i) {
                      return DropdownMenuItem(
                        value: i + 1,
                        child: Text(monthNames[i]),
                      );
                    }),
                    onChanged: (v) => setDialogState(() => selectedMonth = v!),
                  ),
                  const SizedBox(height: 16),
                  // Year Dropdown
                  DropdownButtonFormField<int>(
                    initialValue: selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      prefixIcon: Icon(Icons.date_range_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: years.map((y) {
                      return DropdownMenuItem(
                        value: y,
                        child: Text(y.toString()),
                      );
                    }).toList(),
                    onChanged: (v) => setDialogState(() => selectedYear = v!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('Generate Report'),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    // ── Generate PDF bytes ────────────────────────────────────────────
    setState(() => _isGeneratingPdf = true);
    try {
      final settingsProvider = Provider.of<SettingsProvider>(
        context,
        listen: false,
      );
      final entries = await DatabaseHelper.instance.getEntriesForMonth(
        selectedYear,
        selectedMonth,
      );

      final pdfBytes = await PdfHelper.generateReport(
        entries: entries,
        operatorName: settingsProvider.userName,
        year: selectedYear,
        month: selectedMonth,
      );

      if (!context.mounted) return;

      final monthName = monthNames[selectedMonth - 1];
      final dynamicFileName =
          'MYValve_Report_${monthName}_$selectedYear.pdf';

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Center(child: Text('Report Ready!')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Your PDF report has been generated successfully.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Download Report'),
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    final nameWithoutExt = dynamicFileName.endsWith('.pdf')
                        ? dynamicFileName.substring(
                            0,
                            dynamicFileName.length - 4,
                          )
                        : dynamicFileName;
                    final path = await FileSaver.instance.saveAs(
                      name: nameWithoutExt,
                      bytes: pdfBytes,
                      fileExtension: 'pdf',
                      mimeType: MimeType.pdf,
                    );
                    if (path != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Report saved to device!'),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Share Report'),
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    await _savePdfLocally(pdfBytes, dynamicFileName);
                    await Printing.sharePdf(
                      bytes: pdfBytes,
                      filename: dynamicFileName,
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Report'),
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    final savedPath = await _savePdfLocally(
                      pdfBytes,
                      dynamicFileName,
                    );
                    await OpenFilex.open(savedPath);
                  },
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e')));
      }
    } finally {
      if (context.mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitBottomSheet();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MYValve Log'),
          elevation: 0,
          actions: [
            // ── PDF Report Button ──
            _isGeneratingPdf
                ? const Padding(
                    padding: EdgeInsets.all(14.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Showcase(
                    key: _pdfKey,
                    title: 'Export PDF',
                    description:
                        'Tap here to download your monthly production reports.',
                    child: IconButton(
                      icon: const Icon(Icons.picture_as_pdf),
                      tooltip: 'Download Monthly Report',
                      onPressed: () => _showReportDialog(context),
                    ),
                  ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              tooltip: 'Settings',
            ),
          ],
        ),
        body: Consumer<EntryProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                _buildSummaryCard(context, provider),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 0.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.filter_list),
                        tooltip: 'Filter Entries',
                        onPressed: () =>
                            _showFilterBottomSheet(context, provider),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: () {
                    if (provider.entries.isEmpty) {
                      return const Center(
                        child: Text('No entries yet. Add one!'),
                      );
                    }

                    final filteredEntries = provider.entries.where((entry) {
                      final matchModel =
                          _selectedModelFilter == 'All' ||
                          entry.model == _selectedModelFilter;
                      final matchSize =
                          _selectedSizeFilter == 'All' ||
                          entry.size == _selectedSizeFilter;
                      return matchModel && matchSize;
                    }).toList();

                    if (filteredEntries.isEmpty) {
                      return const Center(
                        child: Text('No entries match the selected filters.'),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: filteredEntries.length,
                      itemBuilder: (context, index) {
                        final entry = filteredEntries[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 6.0,
                          ),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.15),
                              child: Icon(
                                Icons.precision_manufacturing,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            title: Text(
                              entry.model,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'S/N: ${entry.serialNo} • Size: ${entry.size}',
                            ),
                            trailing: Text(
                              DateFormat('MMM dd').format(entry.timestamp),
                              style: const TextStyle(color: Colors.grey),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EntryDetailScreen(entry: entry),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  }(),
                ),
              ],
            );
          },
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Showcase(
            key: _addEntryKey,
            title: 'New Entry',
            description: 'Tap here to add a new MYValve Log record.',
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EntryFormScreen()),
                );
              },
              tooltip: 'Add Entry',
              child: const Icon(Icons.add),
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
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, EntryProvider provider) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${DateFormat('MMMM yyyy').format(DateTime(provider.selectedYear, provider.selectedMonth))} Production',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.calendar_today,
                    color: Colors.white70,
                    size: 20,
                  ),
                  onPressed: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime(
                        provider.selectedYear,
                        provider.selectedMonth,
                      ),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (selectedDate != null) {
                      provider.changeMonthYear(
                        selectedDate.year,
                        selectedDate.month,
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 0),
            Text(
              'Total: ${provider.monthlyTotal}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (provider.modelBreakdown.isNotEmpty)
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: provider.modelBreakdown.entries.map((e) {
                  return Chip(
                    label: Text(
                      '${e.key}: ${e.value}',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide.none,
                  );
                }).toList(),
              )
            else
              const Text(
                'No production data for this month.',
                style: TextStyle(color: Colors.white70),
              ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, EntryProvider provider) {
    final baseModels = [
      'All',
      'THV',
      'THV2',
      'THVA2',
      'THVP5',
      'Model 4',
      'Model 6',
    ];
    final baseSizes = [
      'All',
      '20',
      '21.5',
      '23',
      '24.5',
      '26',
      '27.5',
      '29',
      '30.5',
      '32',
      '35',
    ];

    // Combine predefined options with dynamically extracted unique options from current entries.
    final dynamicModels =
        provider.entries
            .map((e) => e.model)
            .where((m) => m.isNotEmpty && !baseModels.contains(m))
            .toSet()
            .toList()
          ..sort();
    final availableModels = [...baseModels, ...dynamicModels];

    final dynamicSizes =
        provider.entries
            .map((e) => e.size)
            .where((s) => s.isNotEmpty && !baseSizes.contains(s))
            .toSet()
            .toList()
          ..sort();
    final availableSizes = [...baseSizes, ...dynamicSizes];

    // If the currently selected filter is no longer in the available options, reset it.
    if (!availableModels.contains(_selectedModelFilter)) {
      _selectedModelFilter = 'All';
    }
    if (!availableSizes.contains(_selectedSizeFilter)) {
      _selectedSizeFilter = 'All';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            final currentMatchCount = provider.entries.where((e) {
              final matchModel =
                  _selectedModelFilter == 'All' ||
                  e.model == _selectedModelFilter;
              final matchSize =
                  _selectedSizeFilter == 'All' || e.size == _selectedSizeFilter;
              return matchModel && matchSize;
            }).length;

            return Padding(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
                bottom: MediaQuery.of(context).padding.bottom + 24.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Filter by Model',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: availableModels.map((model) {
                      final isSelected = _selectedModelFilter == model;
                      return ChoiceChip(
                        label: Text(model),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setSheetState(() => _selectedModelFilter = model);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Filter by Size',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: availableSizes.map((size) {
                      final isSelected = _selectedSizeFilter == size;
                      return ChoiceChip(
                        label: Text(size),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setSheetState(() => _selectedSizeFilter = size);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Selected: $_selectedModelFilter • Size: $_selectedSizeFilter',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total Matches: $currentMatchCount',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: currentMatchCount > 0
                                ? Colors.green.shade700
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSheetState(() {
                              _selectedModelFilter = 'All';
                              _selectedSizeFilter = 'All';
                            });
                          },
                          child: const Text('Clear Filters'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {}); // Update the main UI
                          },
                          child: const Text('Apply Filters'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showExitBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 24.0,
              horizontal: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MediumRectangleAdWidget(),
                const SizedBox(height: 24),
                const Text(
                  'Rate For Us',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => const Icon(
                      Icons.star_border,
                      size: 36,
                      color: Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Thanks for leaving a nice review!',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle rating logic here
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Rate',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          SystemNavigator.pop();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Later',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      // If the user dismisses the bottom sheet by clicking outside or swiping down,
      // it doesn't close the app by default.
      // If you want it to close the app on dismiss, uncomment the below line:
      // SystemNavigator.pop();
    });
  }
}
