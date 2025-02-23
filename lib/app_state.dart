import 'package:flutter/material.dart';
import 'backend/supabase/supabase.dart';
import 'flutter_flow/flutter_flow_util.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {}

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  List<String> _trajetoPontos = [];
  List<String> get trajetoPontos => _trajetoPontos;
  set trajetoPontos(List<String> value) {
    _trajetoPontos = value;
  }

  void addToTrajetoPontos(String value) {
    trajetoPontos.add(value);
  }

  void removeFromTrajetoPontos(String value) {
    trajetoPontos.remove(value);
  }

  void removeAtIndexFromTrajetoPontos(int index) {
    trajetoPontos.removeAt(index);
  }

  void updateTrajetoPontosAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    trajetoPontos[index] = updateFn(_trajetoPontos[index]);
  }

  void insertAtIndexInTrajetoPontos(int index, String value) {
    trajetoPontos.insert(index, value);
  }

  LatLng? _locations2 = LatLng(37.13617, -8.5376926);
  LatLng? get locations2 => _locations2;
  set locations2(LatLng? value) {
    _locations2 = value;
  }
}
