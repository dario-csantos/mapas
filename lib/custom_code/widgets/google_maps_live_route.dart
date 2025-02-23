// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
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
    this.initialLocation,
    required this.updateIntervalSeconds, // Intervalo de atualização
    required this.minDistanceFilter, // Distância mínima
    required this.routeColor, // Cor da linha
    required this.showSpeed, // Exibir velocidade
    required this.initialZoom, // Zoom inicial
  });

  final double? width;
  final double? height;
  final LatLng? initialLocation;
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
  Set<gmaps.Marker> _markers = {}; // Ícone de posição
  List<gmaps.LatLng> _routePoints = [];
  StreamSubscription<Position>? _positionStream;
  Timer? _updateTimer;
  gmaps.LatLng? _lastValidPosition; // Última posição válida
  double _currentSpeed = 0.0; // Velocidade do usuário em km/h
  gmaps.LatLng? _currentPosition; // Posição inicial

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

  /// Obtém a posição inicial do usuário e define no mapa
  Future<void> _getInitialPosition() async {
    if (widget.initialLocation == null) return;

    setState(() {
      _currentPosition = gmaps.LatLng(
          widget.initialLocation!.latitude, widget.initialLocation!.longitude);
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

  /// Inicia o rastreamento da localização do usuário com atualização baseada em tempo e distância
  Future<void> _startTracking() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print("❌ Permissão negada. Não será possível rastrear o trajeto.");
      return;
    }

    // Obtém a posição inicial do usuário e configura no mapa
    await _getInitialPosition();

    // Inicia o rastreamento contínuo
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1,
      ),
    ).listen((Position newPosition) {
      _updateUserLocation(newPosition);
    });

    // Atualiza por tempo também
    _updateTimer = Timer.periodic(
        Duration(seconds: widget.updateIntervalSeconds), (timer) async {
      Position newPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      _updateUserLocation(newPosition);
    });
  }

  /// Atualiza a posição do usuário, velocidade e desenha a linha do trajeto
  void _updateUserLocation(Position position) {
    final gmaps.LatLng newPosition =
        gmaps.LatLng(position.latitude, position.longitude);

    // Calcula a velocidade (conversão de m/s para km/h)
    double speedKmH = position.speed * 3.6;

    // Se o GPS não fornecer velocidade, usa 0 km/h como fallback
    if (speedKmH.isNaN || speedKmH < 0) {
      speedKmH = 0.0;
    }

    // Debugging: Mostra a velocidade no console
    print(
        "📍 Nova posição: $newPosition, Velocidade: ${speedKmH.toStringAsFixed(1)} km/h");

    setState(() {
      _currentSpeed = speedKmH;
    });

    // Se já existe uma última posição válida, verificamos a distância
    if (_lastValidPosition != null) {
      double distance = Geolocator.distanceBetween(
        _lastValidPosition!.latitude,
        _lastValidPosition!.longitude,
        newPosition.latitude,
        newPosition.longitude,
      );

      // Se a distância for menor que o mínimo definido pelo usuário, ignora a atualização
      if (distance < widget.minDistanceFilter) {
        return;
      }
    }

    // Atualiza a última posição válida
    _lastValidPosition = newPosition;

    setState(() {
      _routePoints.add(newPosition);

      // Atualiza o marcador da posição do usuário
      _markers = {
        gmaps.Marker(
          markerId: const gmaps.MarkerId("user_position"),
          position: newPosition,
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
              gmaps.BitmapDescriptor.hueBlue),
        ),
      };

      // Atualiza a linha do trajeto com a cor escolhida pelo usuário
      _polylines = {
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId("tracking_route"),
          points: _routePoints,
          color: widget.routeColor,
          width: 5,
        )
      };
    });

    // Move a câmera para a nova posição do usuário
    _mapController.animateCamera(gmaps.CameraUpdate.newLatLng(newPosition));
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
