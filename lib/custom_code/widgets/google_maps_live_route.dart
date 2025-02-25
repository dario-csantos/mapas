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
import 'index.dart'; // Imports other custom widgets

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
  bool _navigatorMode = false; // false = standby, true = navigator

  // Controlador para o DraggableScrollableSheet (Flutter 3.7+)
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    // Mantém a tela ligada
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
        List<gmaps.LatLng> convertedPoints = widget.polylineSavedRoute
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
    LocationPermission permission = await Geolocator.requestPermission();
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
        Position newPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
        _updateUserLocation(newPosition);
      },
    );
  }

  void _updateUserLocation(Position position) async {
    final gmaps.LatLng newPosition =
        gmaps.LatLng(position.latitude, position.longitude);

    double speedKmH = position.speed * 3.6;
    if (speedKmH.isNaN || speedKmH < 0) {
      speedKmH = 0.0;
    }

    double heading = position.heading;
    if (heading.isNaN || heading < 0) {
      heading = _currentHeading;
    }

    if (_mapController != null) {
      _currentZoom = await _mapController!.getZoomLevel();
    }

    setState(() {
      _currentSpeed = speedKmH;
      _currentHeading = heading;
      _currentPosition = newPosition;
      _userRoutePoints.add(newPosition);

      _updateUserPolyline();
    });

    // Se estiver no modo navegador, atualiza a câmera
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

  // Altera o ícone do marcador do usuário conforme o modo navegador
  Set<gmaps.Marker> _buildMarkerUser() {
    return {
      gmaps.Marker(
        markerId: const gmaps.MarkerId("user_position"),
        position: _currentPosition ??
            gmaps.LatLng(
              widget.initialLocation.latitude,
              widget.initialLocation.longitude,
            ),
        // Se estiver no modo navegador, muda a cor para verde; senão, azul
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

  Set<gmaps.Marker> _buildMarkers() {
    if (!_showMarkers) return {};
    return widget.markerLocations.map((location) {
      return gmaps.Marker(
        markerId: gmaps.MarkerId(location.toString()),
        position: gmaps.LatLng(location.latitude, location.longitude),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
          gmaps.BitmapDescriptor.hueRed,
        ),
      );
    }).toSet();
  }

  // Função que alterna o modo navegador e ajusta a câmera
  void _toggleNavigatorMode() {
    setState(() {
      _navigatorMode = !_navigatorMode;
    });
    if (_navigatorMode) {
      // Ativa o modo navegador: ajusta a câmera com zoom predefinido e tilt
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
      // Desativa o modo navegador: ajusta a câmera para tilt 0
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

            // Se estiver no modo navigator, adiciona padding no topo pra “empurrar” o usuário pra baixo
            padding: _navigatorMode
                ? const EdgeInsets.only(top: 200)
                : EdgeInsets.zero,

            markers: _buildMarkerUser().union(_buildMarkers()),
            polylines: _polylines,
            myLocationEnabled: false,
            compassEnabled: true,
            trafficEnabled: _showTraffic,
          ),

          // Velocidade
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

          // Zoom
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

          // DRAGGABLE SHEET (Painel estilo Waze)
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.12,
            minChildSize: 0.12,
            maxChildSize: 0.5,
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
                      // Barra de puxar
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

                      // Linha principal com o botão "Navegar"
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _navigatorMode ? Colors.red : Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            minimumSize: const Size(300,
                                56), // 300 de largura e 56 de altura mínima
                          ),
                          onPressed: () {
                            _toggleNavigatorMode();
                          },
                          icon: const Icon(
                            Icons.navigation,
                            color: Colors.white,
                          ),
                          label: Text(
                            _navigatorMode ? "Navegando" : "Navegar",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Outras linhas com botões de rota, marcadores, etc.
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
                            child: Icon(_showSavedRoute
                                ? Icons.route
                                : Icons.route_outlined),
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
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
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
                      const SizedBox(height: 24),
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
