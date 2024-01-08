// CHB.dart
// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:thesismob/frames/CHB/CHB.dart';

class HistoryManager {
  static final HistoryManager _instance = HistoryManager._internal();
  List<Calculation> _calculations = [];

  factory HistoryManager() {
    return _instance;
  }

  HistoryManager._internal();

  List<Calculation> get calculations => _calculations;

  void addCalculation(Calculation calculation) {
    _calculations.add(calculation);
  }

  List<Calculation> getCalculationsByType(String calculatorType) {
    return _calculations.where((calculation) {
      return calculation.calculatorType == calculatorType;
    }).toList();
  }

  List<Calculation> getCalculationsByDate(DateTime date) {
    return _calculations.where((calculation) {
      return calculation.date.year == date.year &&
          calculation.date.month == date.month &&
          calculation.date.day == date.day;
    }).toList();
  }
}
