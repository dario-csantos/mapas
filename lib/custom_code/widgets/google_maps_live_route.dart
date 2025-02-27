// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom widgets

import 'index.dart'; // Imports other custom widgets
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/update_navigator_mode_action.dart'; // Se você usa a Custom Action
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:wakelock_plus/wakelock_plus.dart';

class GoogleMapsLiveRoute extends StatefulWidget {
  const GoogleMapsLiveRoute({
    super.key,
    this.width,
    this.height,
    required this.initialLocation,
    required this.updateIntervalSeconds,
    required this.minDistanceFilter,
    required this.userRouteColor,
    required this.routeColor,
    required this.showSpeed,
    required this.showTraffic,
    required this.initialZoom,
    required this.mapTilt,
    required this.showMarkersLocations,
    required this.showUserRoute,
    required this.showPolylineSavedRoute,
    this.markerLocations = const [],
    this.polylineSavedRoute = const [],
  });

  final double? width;
  final double? height;
  final LatLng initialLocation;
  final int updateIntervalSeconds;
  final double minDistanceFilter;
  final Color userRouteColor;
  final Color routeColor;
  final bool showSpeed;
  final bool showTraffic;
  final double initialZoom;
  final double mapTilt;
  final bool showMarkersLocations;
  final bool showUserRoute;
  final bool showPolylineSavedRoute;
  final List<LatLng> markerLocations;
  final List<LatLng> polylineSavedRoute;

  @override
  State<GoogleMapsLiveRoute> createState() => _GoogleMapsLiveRouteState();
}

class _GoogleMapsLiveRouteState extends State<GoogleMapsLiveRoute> {
  gmaps.GoogleMapController? _mapController;
  Set<gmaps.Polyline> _polylines = {};
  List<gmaps.LatLng> _userRoutePoints = [];
  StreamSubscription<Position>? _positionStream;
  Timer? _updateTimer;
  gmaps.LatLng? _currentPosition;
  double _currentSpeed = 0.0;
  double _currentHeading = 0.0;
  double _currentZoom = 16.0;

  bool _showTraffic = false;
  bool _showSavedRoute = false;
  bool _showMarkers = false;
  bool _showUserRoute = false;

  bool _navigatorMode = false; // false => modo normal, true => modo navegador
  bool _trackingMode = false; // indica se rastreamento está ativo
  bool _isTrackingPaused = false; // indica se está pausado
  double _distanceTraveled = 0.0; // Distância total percorrida (em KM)
  gmaps.LatLng? _lastPosition; // Última posição registrada
  int _elapsedSecondsNavigator = 0; // Tempo decorrido (em segundos)
  Timer? _timerNavigatorMode; // Timer para atualizar o tempo

  // Variáveis para controle de pausa automática
  DateTime? _stoppedTimestamp;
  DateTime? _movingTimestamp;

  void _startTimerNavigatorMode() {
    _timerNavigatorMode?.cancel();
    _timerNavigatorMode = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_trackingMode && !_isTrackingPaused) {
        setState(() {
          _elapsedSecondsNavigator++;
        });
      }
    });
  }

  String _formatElapsedTimeNavigator() {
    int hours = _elapsedSecondsNavigator ~/ 3600;
    int minutes = (_elapsedSecondsNavigator % 3600) ~/ 60;
    int seconds = _elapsedSecondsNavigator % 60;

    if (hours > 0) {
      return "$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    } else {
      return "$minutes:${seconds.toString().padLeft(2, '0')}";
    }
  }

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _currentPosition = gmaps.LatLng(
      widget.initialLocation.latitude,
      widget.initialLocation.longitude,
    );

    _getInitialPosition();
    _startTracking();
    _loadPolylineSavedRoute();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _updateTimer?.cancel();
    _timerNavigatorMode?.cancel();
    super.dispose();
  }

  Future<void> _getInitialPosition() async {
    setState(() {
      _currentPosition = gmaps.LatLng(
        widget.initialLocation.latitude,
        widget.initialLocation.longitude,
      );
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (_mapController != null && _currentPosition != null) {
        _mapController!.animateCamera(
          gmaps.CameraUpdate.newCameraPosition(
            gmaps.CameraPosition(
              target: _currentPosition!,
              zoom: widget.initialZoom,
              tilt: widget.mapTilt,
            ),
          ),
        );
      }
    });
  }

  void _loadPolylineSavedRoute() {
    setState(() {
      _polylines.removeWhere((poly) => poly.polylineId.value == "saved_route");
      if (_showSavedRoute) {
        final convertedPoints = widget.polylineSavedRoute
            .map((latLng) => gmaps.LatLng(latLng.latitude, latLng.longitude))
            .toList();
        _polylines.add(
          gmaps.Polyline(
            polylineId: const gmaps.PolylineId("saved_route"),
            points: convertedPoints,
            color: widget.routeColor,
            width: 5,
          ),
        );
      }
    });
  }

  Future<void> _startTracking() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print("❌ Permissão negada.");
      return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1,
      ),
    ).listen((Position newPosition) {
      _updateUserLocation(newPosition);
    });

    _updateTimer = Timer.periodic(
      Duration(seconds: widget.updateIntervalSeconds),
      (timer) async {
        final newPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
        _updateUserLocation(newPosition);
      },
    );
  }

  void _updateUserLocation(Position position) async {
    final newPosition = gmaps.LatLng(position.latitude, position.longitude);

    // Converte a velocidade para km/h
    double speedKmH = position.speed * 3.6;
    if (speedKmH.isNaN || speedKmH < 0) speedKmH = 0.0;

    double heading = position.heading;
    if (heading.isNaN || heading < 0) heading = _currentHeading;

    if (_mapController != null) {
      _currentZoom = await _mapController!.getZoomLevel();
    }

    // Atualiza estado e rota
    setState(() {
      _currentSpeed = speedKmH;
      _currentHeading = heading;
      _currentPosition = newPosition;
      _userRoutePoints.add(newPosition);
      _updateUserPolyline();
      _lastPosition = newPosition;
    });

    // Lógica para auto pausa e retomada
    final now = DateTime.now();
    const speedThreshold = 1.0; // Abaixo de 1 km/h é considerado parado

    if (speedKmH < speedThreshold) {
      // Moto parada
      if (_stoppedTimestamp == null) {
        _stoppedTimestamp = now;
      }
      if (now.difference(_stoppedTimestamp!).inSeconds >= 5 &&
          !_isTrackingPaused) {
        setState(() {
          _isTrackingPaused = true;
        });
      }
      _movingTimestamp = null;
    } else {
      // Moto em movimento
      if (_movingTimestamp == null) {
        _movingTimestamp = now;
      }
      if (now.difference(_movingTimestamp!).inSeconds >= 5 &&
          _isTrackingPaused) {
        setState(() {
          _isTrackingPaused = false;
        });
      }
      _stoppedTimestamp = null;
    }

    // Se estiver no modo navegador, mantém a câmera seguindo o usuário
    if (_navigatorMode && _mapController != null) {
      _mapController!.animateCamera(
        gmaps.CameraUpdate.newCameraPosition(
          gmaps.CameraPosition(
            target: newPosition,
            zoom: _currentZoom,
            bearing: _currentHeading,
            tilt: widget.mapTilt,
          ),
        ),
      );
    }
  }

  void _updateUserPolyline() {
    setState(() {
      _polylines.removeWhere((poly) => poly.polylineId.value == "user_route");
      if (_showUserRoute) {
        _polylines.add(
          gmaps.Polyline(
            polylineId: const gmaps.PolylineId("user_route"),
            points: _userRoutePoints,
            color: widget.userRouteColor,
            width: 5,
          ),
        );
      }
    });
  }

  // Marker do usuário
  Set<gmaps.Marker> _buildMarkerUser() {
    return {
      gmaps.Marker(
        markerId: const gmaps.MarkerId("user_position"),
        position: _currentPosition ??
            gmaps.LatLng(
              widget.initialLocation.latitude,
              widget.initialLocation.longitude,
            ),
        icon: _navigatorMode
            ? gmaps.BitmapDescriptor.defaultMarkerWithHue(
                gmaps.BitmapDescriptor.hueGreen,
              )
            : gmaps.BitmapDescriptor.defaultMarkerWithHue(
                gmaps.BitmapDescriptor.hueBlue,
              ),
      ),
    };
  }

  // Marcadores extras
  Set<gmaps.Marker> _buildMarkers() {
    if (!_showMarkers) return {};
    return widget.markerLocations.map((loc) {
      return gmaps.Marker(
        markerId: gmaps.MarkerId(loc.toString()),
        position: gmaps.LatLng(loc.latitude, loc.longitude),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
          gmaps.BitmapDescriptor.hueRed,
        ),
      );
    }).toSet();
  }

  // Inicia modo navegador + rastreamento
  Future<void> _toggleNavigatorMode() async {
    setState(() {
      _navigatorMode = !_navigatorMode;
    });

    await updateNavigatorModeAction(_navigatorMode);

    if (_navigatorMode) {
      _trackingMode = true;
      _isTrackingPaused = false;
      _distanceTraveled = 0.0;
      _lastPosition = _currentPosition;
      _elapsedSecondsNavigator = 0;
      _startTimerNavigatorMode();

      if (_mapController != null && _currentPosition != null) {
        _mapController!.animateCamera(
          gmaps.CameraUpdate.newCameraPosition(
            gmaps.CameraPosition(
              target: _currentPosition!,
              zoom: widget.initialZoom,
              bearing: _currentHeading,
              tilt: widget.mapTilt,
            ),
          ),
        );
      }
    } else {
      _trackingMode = false;
      _isTrackingPaused = false;
      _timerNavigatorMode?.cancel();
      if (_mapController != null && _currentPosition != null) {
        _mapController!.animateCamera(
          gmaps.CameraUpdate.newCameraPosition(
            gmaps.CameraPosition(
              target: _currentPosition!,
              zoom: _currentZoom,
              bearing: _currentHeading,
              tilt: 0,
            ),
          ),
        );
      }
    }
    setState(() {});
  }

  // Função para pausar/continuar ou parar viagem
  void _toggleTracking() {
    setState(() {
      if (_trackingMode && !_isTrackingPaused) {
        _isTrackingPaused = true;
      } else if (_trackingMode && _isTrackingPaused) {
        _isTrackingPaused = false;
      } else {
        _trackingMode = true;
        _isTrackingPaused = false;
      }
    });
  }

  // "Parar viagem" => mostra popup e reseta o tracking
  void _stopTracking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Parar viagem?"),
          content: const Text("Deseja realmente parar o rastreamento?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _navigatorMode = false;
        _trackingMode = false;
        _isTrackingPaused = false;
        _distanceTraveled = 0.0;
      });

      await updateNavigatorModeAction(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // MAPA
          gmaps.GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              _loadPolylineSavedRoute();
            },
            initialCameraPosition: gmaps.CameraPosition(
              target: _currentPosition ??
                  gmaps.LatLng(
                    widget.initialLocation.latitude,
                    widget.initialLocation.longitude,
                  ),
              zoom: widget.initialZoom,
            ),
            padding: _navigatorMode
                ? const EdgeInsets.only(top: 200)
                : EdgeInsets.zero,
            markers: _buildMarkerUser().union(_buildMarkers()),
            polylines: _polylines,
            myLocationEnabled: false,
            compassEnabled: true,
            trafficEnabled: _showTraffic,
          ),

          // VELOCIDADE
          if (widget.showSpeed)
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${_currentSpeed.toStringAsFixed(1)} km/h",
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),

          // ZOOM
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Zoom: ${_currentZoom.toStringAsFixed(2)}",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),

          // DRAGGABLE SHEET
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.26,
            minChildSize: 0.12,
            maxChildSize: 0.29,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!_navigatorMode)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              minimumSize: const Size(300, 56),
                            ),
                            onPressed: () {
                              _toggleNavigatorMode();
                            },
                            icon: const Icon(
                              Icons.navigation,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Navegar",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      else
                        Column(
                          children: [
                            if (_trackingMode) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        "${_distanceTraveled.toStringAsFixed(1)}",
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 20),
                                      ),
                                      const Text(
                                        "km",
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        "${_currentSpeed.toStringAsFixed(1)} km/h",
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 20),
                                      ),
                                      const Text(
                                        "km/h",
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        _formatElapsedTimeNavigator(),
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 20),
                                      ),
                                      const Text(
                                        "tempo",
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (_trackingMode && !_isTrackingPaused)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 60,
                                  ),
                                  minimumSize: const Size(300, 56),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isTrackingPaused = true;
                                  });
                                },
                                child: const Text(
                                  "Pausar",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            else if (_trackingMode && _isTrackingPaused)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                        horizontal: 30,
                                      ),
                                      minimumSize: const Size(140, 56),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isTrackingPaused = false;
                                      });
                                    },
                                    child: const Text(
                                      "Continuar",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                        horizontal: 30,
                                      ),
                                      minimumSize: const Size(140, 56),
                                    ),
                                    onPressed: () {
                                      _stopTracking();
                                    },
                                    child: const Text(
                                      "Parar viagem",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              const SizedBox(),
                          ],
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          FloatingActionButton(
                            onPressed: () {
                              setState(() {
                                _showSavedRoute = !_showSavedRoute;
                              });
                              _loadPolylineSavedRoute();
                            },
                            child: Icon(
                              _showSavedRoute
                                  ? Icons.route
                                  : Icons.route_outlined,
                            ),
                            backgroundColor: Colors.green,
                            tooltip: "Mostrar/Ocultar Rota Salva",
                          ),
                          FloatingActionButton(
                            onPressed: () {
                              setState(() {
                                _showMarkers = !_showMarkers;
                              });
                            },
                            child: Icon(
                              _showMarkers
                                  ? Icons.location_on
                                  : Icons.location_off,
                            ),
                            backgroundColor: Colors.red,
                            tooltip: "Mostrar/Ocultar Marcadores",
                          ),
                          FloatingActionButton(
                            onPressed: () {
                              setState(() {
                                _showUserRoute = !_showUserRoute;
                              });
                              _updateUserPolyline();
                            },
                            child: Icon(
                              _showUserRoute
                                  ? Icons.timeline
                                  : Icons.timeline_outlined,
                            ),
                            backgroundColor: Colors.blue,
                            tooltip: "Mostrar/Ocultar Minha Rota",
                          ),
                          FloatingActionButton(
                            onPressed: () {
                              setState(() {
                                _showTraffic = !_showTraffic;
                              });
                            },
                            child: Icon(
                              _showTraffic
                                  ? Icons.traffic
                                  : Icons.traffic_outlined,
                            ),
                            backgroundColor: Colors.orange,
                            tooltip: "Mostrar/Ocultar Tráfego",
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
