import 'package:flutter/material.dart';
import '../models/heart_valve_entry.dart';
import '../services/database_helper.dart';

class EntryProvider with ChangeNotifier {
  List<HeartValveEntry> _entries = [];
  bool _isLoading = false;

  // Monthly stats
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  int _monthlyTotal = 0;
  Map<String, int> _modelBreakdown = {};

  List<HeartValveEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;
  int get monthlyTotal => _monthlyTotal;
  Map<String, int> get modelBreakdown => _modelBreakdown;

  EntryProvider() {
    loadEntries();
  }

  Future<void> loadEntries() async {
    _isLoading = true;
    notifyListeners();

    _entries = await DatabaseHelper.instance.getAllEntries();
    
    await _calculateMonthlyStats();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _calculateMonthlyStats() async {
    // Get entries for the selected month
    final monthlyEntries = await DatabaseHelper.instance.getEntriesForMonth(_selectedYear, _selectedMonth);
    
    _monthlyTotal = monthlyEntries.length;
    
    // Reset breakdown
    _modelBreakdown = {};
    
    // Calculate breakdown
    for (var entry in monthlyEntries) {
      _modelBreakdown[entry.model] = (_modelBreakdown[entry.model] ?? 0) + 1;
    }
  }

  Future<void> addEntry(HeartValveEntry entry) async {
    await DatabaseHelper.instance.insertEntry(entry);
    await loadEntries(); // Reload to refresh list and stats
  }

  Future<void> updateEntry(HeartValveEntry entry) async {
    await DatabaseHelper.instance.updateEntry(entry);
    await loadEntries();
  }

  Future<void> deleteEntry(int id) async {
    await DatabaseHelper.instance.deleteEntry(id);
    await loadEntries();
  }

  void changeMonthYear(int year, int month) {
    _selectedYear = year;
    _selectedMonth = month;
    loadEntries();
  }
}
