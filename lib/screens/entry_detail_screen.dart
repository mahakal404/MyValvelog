import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/heart_valve_entry.dart';
import '../providers/entry_provider.dart';
import 'entry_form_screen.dart';
import '../widgets/banner_ad_widget.dart';

class EntryDetailScreen extends StatelessWidget {
  final HeartValveEntry entry;

  const EntryDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    // We use Consumer to watch the entry in case it gets edited.
    // If it's not in the list (deleted), we could just fall back or pop.
    return Consumer<EntryProvider>(
      builder: (context, provider, child) {
        // Find the current version of the entry
        final currentEntry = provider.entries
            .cast<HeartValveEntry?>()
            .firstWhere((e) => e?.id == entry.id, orElse: () => null);

        if (currentEntry == null) {
          // If deleted or not found, show empty and maybe pop
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
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
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
                          _buildDetailRow(
                            'Job Card No',
                            currentEntry.jobCardNo,
                          ),
                          const Divider(),
                          _buildDetailRow('Size', currentEntry.size),
                          const Divider(),
                          _buildDetailRow(
                            'Quantity',
                            currentEntry.quantity.toString(),
                          ),
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
                            DateFormat(
                              'MMM dd, yyyy - hh:mm a',
                            ).format(currentEntry.takeTime),
                          ),
                          const Divider(),
                          _buildDetailRow(
                            'Submit Time',
                            DateFormat(
                              'MMM dd, yyyy - hh:mm a',
                            ).format(currentEntry.submitTime),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SafeArea(child: BannerAdWidget()),
            ],
          ),
        );
      },
    );
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
}
