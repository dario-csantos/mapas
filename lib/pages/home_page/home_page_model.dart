import '/flutter_flow/flutter_flow_util.dart';
import 'home_page_widget.dart' show HomePageWidget;
import 'package:flutter/material.dart';

class HomePageModel extends FlutterFlowModel<HomePageWidget> {
  ///  Local state fields for this page.

  bool showTransito = false;

  bool? showSpeed = false;

  bool showRouteUser = false;

  bool showLocations = false;

  LatLng? casa;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
