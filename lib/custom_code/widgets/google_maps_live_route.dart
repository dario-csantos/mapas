// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class GoogleMapsLiveRoute extends StatefulWidget {
  const GoogleMapsLiveRoute({
    super.key,
    this.width,
    this.height,
    required this.updateIntervalSeconds, // Intervalo de atualização
    required this.minDistanceFilter, // Distância mínima
    required this.routeColor, // Cor da linha
    required this.showSpeed, // Exibir velocidade
    required this.initialZoom, // Zoom inicial
  });

  final double? width;
  final double? height;
  final int updateIntervalSeconds; // Tempo de atualização
  final double minDistanceFilter; // Distância mínima em metros
  final Color routeColor; // Cor da linha da rota
  final bool showSpeed; // Exibir velocidade do usuário
  final double initialZoom; // Zoom inicial do mapa

  @override
  State<GoogleMapsLiveRoute> createState() => _GoogleMapsLiveRouteState();
}

class _GoogleMapsLiveRouteState extends State<GoogleMapsLiveRoute> {
  late gmaps.GoogleMapController _mapController;
  Set<gmaps.Polyline> _polylines = {};
  Set<gmaps.Marker> _markers = {};
  List<gmaps.LatLng> _routePoints = [];
  StreamSubscription<Position>? _positionStream;
  Timer? _updateTimer;
  gmaps.LatLng? _lastValidPosition;
  double _currentSpeed = 0.0;
  gmaps.LatLng? _currentPosition;
  double _currentHeading = 0.0;
  double _currentZoom = 16.0; // Mantém o zoom do usuário

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }

  /// Obtém a posição inicial e configura a câmera no mapa
  Future<void> _getInitialPosition() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    setState(() {
      _currentPosition = gmaps.LatLng(position.latitude, position.longitude);
    });

    _mapController.animateCamera(
      gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(
          target: _currentPosition!,
          zoom: widget.initialZoom,
        ),
      ),
    );
  }

  /// Inicia o rastreamento da localização do usuário
  Future<void> _startTracking() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print("❌ Permissão negada. Não será possível rastrear o trajeto.");
      return;
    }

    await _getInitialPosition();

    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1,
      ),
    ).listen((Position newPosition) {
      _updateUserLocation(newPosition);
    });

    _updateTimer = Timer.periodic(
        Duration(seconds: widget.updateIntervalSeconds), (timer) async {
      Position newPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      _updateUserLocation(newPosition);
    });
  }

  /// Atualiza a posição do usuário, velocidade e faz o mapa girar
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
      _routePoints.add(newPosition);
      _lastValidPosition = newPosition;

      _markers = {
        gmaps.Marker(
          markerId: const gmaps.MarkerId("user_position"),
          position: newPosition,
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
              gmaps.BitmapDescriptor.hueBlue),
        ),
      };

      _polylines = {
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId("tracking_route"),
          points: _routePoints,
          color: widget.routeColor,
          width: 5,
        ),
      };
    });

    _mapController!.animateCamera(
      gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(
          target: newPosition,
          zoom: _currentZoom, // Mantém o zoom do usuário
          bearing: _currentHeading, // Gira o mapa na direção do usuário
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: widget.width ?? double.infinity,
          height: widget.height ?? double.infinity,
          child: gmaps.GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              if (_currentPosition != null) {
                _mapController.animateCamera(
                  gmaps.CameraUpdate.newCameraPosition(
                    gmaps.CameraPosition(
                      target: _currentPosition!,
                      zoom: widget.initialZoom,
                    ),
                  ),
                );
              }
            },
            initialCameraPosition: gmaps.CameraPosition(
              target: _currentPosition ?? gmaps.LatLng(0.0, 0.0),
              zoom: widget.initialZoom,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: false,
            compassEnabled: true,
            trafficEnabled: false,
          ),
        ),

        // Exibição da velocidade corrigida
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
      ],
    );
  }
}
