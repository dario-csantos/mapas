import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/instant_timer.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'home_page_model.dart';
export 'home_page_model.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  static String routeName = 'HomePage';
  static String routePath = '/homePage';

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  late HomePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  LatLng? currentUserLocationValue;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomePageModel());

    getCurrentUserLocation(defaultLocation: LatLng(0.0, 0.0), cached: true)
        .then((loc) => safeSetState(() => currentUserLocationValue = loc));
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserLocationValue == null) {
      return Container(
        color: FlutterFlowTheme.of(context).primaryBackground,
        child: Center(
          child: SizedBox(
            width: 50.0,
            height: 50.0,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                FlutterFlowTheme.of(context).primary,
              ),
            ),
          ),
        ),
      );
    }

    return FutureBuilder<List<TrakingDriverRow>>(
      future: TrakingDriverTable().queryRows(
        queryFn: (q) => q,
      ),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FlutterFlowTheme.of(context).primary,
                  ),
                ),
              ),
            ),
          );
        }
        List<TrakingDriverRow> homePageTrakingDriverRowList = snapshot.data!;

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            appBar: AppBar(
              backgroundColor: FlutterFlowTheme.of(context).secondary,
              automaticallyImplyLeading: false,
              title: Text(
                'GPS MCBDA 1.0.3',
                style: FlutterFlowTheme.of(context).headlineMedium.override(
                      fontFamily: 'Inter Tight',
                      color: Colors.white,
                      fontSize: 22.0,
                      letterSpacing: 0.0,
                    ),
              ),
              actions: [],
              centerTitle: false,
              elevation: 2.0,
            ),
            body: SafeArea(
              top: true,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 700.0,
                          child: custom_widgets.GoogleMapsLiveRoute(
                            width: double.infinity,
                            height: 700.0,
                            updateIntervalSeconds: 2,
                            minDistanceFilter: 3.0,
                            routeColor: FlutterFlowTheme.of(context).error,
                            showSpeed: true,
                            initialZoom: 17.0,
                            showMarkers: true,
                            markerType: 'single',
                            initialLocation: currentUserLocationValue!,
                            markerLocations: functions.converteStringLatLng(
                                homePageTrakingDriverRowList
                                    .map((e) => e.location)
                                    .withoutNulls
                                    .toList()),
                            polylineRota: functions.converteStringLatLng(
                                homePageTrakingDriverRowList
                                    .map((e) => e.location)
                                    .withoutNulls
                                    .toList()),
                          ),
                        ),
                        Align(
                          alignment: AlignmentDirectional(-0.97, 0.71),
                          child: FFButtonWidget(
                            onPressed: () async {
                              _model.instantTimer?.cancel();
                            },
                            text: 'Stop',
                            options: FFButtonOptions(
                              height: 40.0,
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 0.0, 16.0, 0.0),
                              iconPadding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 0.0),
                              color: FlutterFlowTheme.of(context).primary,
                              textStyle: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .override(
                                    fontFamily: 'Inter Tight',
                                    color: Colors.white,
                                    letterSpacing: 0.0,
                                  ),
                              elevation: 0.0,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                        Align(
                          alignment: AlignmentDirectional(-0.99, 0.58),
                          child: FFButtonWidget(
                            onPressed: () async {
                              currentUserLocationValue =
                                  await getCurrentUserLocation(
                                      defaultLocation: LatLng(0.0, 0.0));
                              _model.instantTimer = InstantTimer.periodic(
                                duration: Duration(milliseconds: 1000),
                                callback: (timer) async {
                                  currentUserLocationValue =
                                      await getCurrentUserLocation(
                                          defaultLocation: LatLng(0.0, 0.0));
                                  _model.valueInsert =
                                      await TrakingDriverTable().insert({
                                    'location':
                                        currentUserLocationValue?.toString(),
                                  });
                                  FFAppState().addToTrajetoPontos(
                                      currentUserLocationValue!.toString());
                                  safeSetState(() {});
                                },
                                startImmediately: true,
                              );

                              safeSetState(() {});
                            },
                            text: 'Start',
                            options: FFButtonOptions(
                              height: 40.0,
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 0.0, 16.0, 0.0),
                              iconPadding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 0.0),
                              color: FlutterFlowTheme.of(context).primary,
                              textStyle: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .override(
                                    fontFamily: 'Inter Tight',
                                    color: Colors.white,
                                    letterSpacing: 0.0,
                                  ),
                              elevation: 0.0,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
