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

  LatLng? _locations2 = LatLng(37.13406299999999, -8.5443944);
  LatLng? get locations2 => _locations2;
  set locations2(LatLng? value) {
    _locations2 = value;
  }

  LatLng? _CoordCasa = LatLng(37.1358268, -8.5430254);
  LatLng? get CoordCasa => _CoordCasa;
  set CoordCasa(LatLng? value) {
    _CoordCasa = value;
  }

  bool _showRouteSave = false;
  bool get showRouteSave => _showRouteSave;
  set showRouteSave(bool value) {
    _showRouteSave = value;
  }
}
