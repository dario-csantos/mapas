// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// CUSTOM ACTION: updateNavigatorModeAction
// Parâmetro: newValue (bool) - novo valor para a variável isNavigatorMode
// Retorna: o mesmo valor (bool) após a atualização

Future<bool> updateNavigatorModeAction(bool newValue) async {
  // Atualiza a variável global definida no FlutterFlow
  // Certifique-se de que a variável "isNavigatorMode" esteja criada no App State
  FFAppState().isNavigatorMode = newValue;
  return newValue;
}
