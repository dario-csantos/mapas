import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/instant_timer.dart';
import 'home_page_widget.dart' show HomePageWidget;
import 'package:flutter/material.dart';

class HomePageModel extends FlutterFlowModel<HomePageWidget> {
  ///  Local state fields for this page.

  bool showTransito = false;

  bool? showSpeed = false;

  bool showRouteUser = false;

  bool showLocations = false;

  LatLng? casa;

  ///  State fields for stateful widgets in this page.

  InstantTimer? instantTimer;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  TrakingDriverRow? valueInsert;
  // State field(s) for SwitchTransito widget.
  bool? switchTransitoValue;
  // State field(s) for SwitchRoutesSave widget.
  bool? switchRoutesSaveValue;
  // State field(s) for SwitchMarkers widget.
  bool? switchMarkersValue;
  // State field(s) for SwitchRastro widget.
  bool? switchRastroValue;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    instantTimer?.cancel();
  }
}
