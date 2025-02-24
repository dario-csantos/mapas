// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom widgets

import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import 'dart:async';

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
    required this.showMarkers, // 🔥 Parâmetro corrigido
    required this.showUserRoute,
    required this.showSavedRoute,
    this.markerLocations = const [],
    this.polylineRota = const [],
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
  final bool showMarkers; // 🔥 Garantir que ele realmente funcione
  final bool showUserRoute;
  final bool showSavedRoute;
  final List<LatLng> markerLocations;
  final List<LatLng> polylineRota;

  @override
  State<GoogleMapsLiveRoute> createState() => _GoogleMapsLiveRouteState();
}

class _GoogleMapsLiveRouteState extends State<GoogleMapsLiveRoute> {
  gmaps.GoogleMapController? _mapController;
  Set<gmaps.Polyline> _polylines = {};
  Set<gmaps.Marker> _markers = {};
  List<gmaps.LatLng> _userRoutePoints = [];
  StreamSubscription<Position>? _positionStream;
  Timer? _updateTimer;
  gmaps.LatLng? _currentPosition;
  double _currentSpeed = 0.0;
  double _currentHeading = 0.0;
  double _currentZoom = 16.0;

  @override
  void initState() {
    super.initState();
    _getInitialPosition();
    _startTracking();
    _loadPolylineRota();
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
          widget.initialLocation.latitude, widget.initialLocation.longitude);
    });

    Future.delayed(Duration(milliseconds: 500), () {
      if (_mapController != null) {
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

  Future<void> _startTracking() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print("❌ Permissão negada.");
      return;
    }

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
      _userRoutePoints.add(newPosition);

      _markers.clear(); // 🔥 Limpa marcadores antigos
      if (widget.showMarkers) {
        _markers.add(
          gmaps.Marker(
            markerId: const gmaps.MarkerId("user_position"),
            position: newPosition,
            icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                gmaps.BitmapDescriptor.hueBlue),
          ),
        );
      }

      _updateUserPolyline();
    });

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

  void _updateUserPolyline() {
    if (!widget.showUserRoute) return;

    setState(() {
      _polylines.removeWhere((poly) => poly.polylineId.value == "user_route");
      _polylines.add(
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId("user_route"),
          points: _userRoutePoints,
          color: widget.userRouteColor,
          width: 5,
        ),
      );
    });
  }

  void _loadPolylineRota() {
    if (!widget.showSavedRoute) return;

    List<gmaps.LatLng> convertedPoints = widget.polylineRota
        .map((latLng) => gmaps.LatLng(latLng.latitude, latLng.longitude))
        .toList();

    setState(() {
      _polylines.removeWhere((poly) => poly.polylineId.value == "saved_route");
      _polylines.add(
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId("saved_route"),
          points: convertedPoints,
          color: widget.routeColor,
          width: 5,
        ),
      );
    });
  }

  Set<gmaps.Marker> _buildMarkers() {
    if (!widget.showMarkers) return {};

    return widget.markerLocations
        .map((location) => gmaps.Marker(
              markerId: gmaps.MarkerId(location.toString()),
              position: gmaps.LatLng(location.latitude, location.longitude),
            ))
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        gmaps.GoogleMap(
          onMapCreated: (controller) {
            _mapController = controller;
            _loadPolylineRota();
          },
          initialCameraPosition: gmaps.CameraPosition(
            target: _currentPosition ?? gmaps.LatLng(0.0, 0.0),
            zoom: widget.initialZoom,
          ),
          markers: _markers.union(_buildMarkers()),
          polylines: _polylines,
          myLocationEnabled: false,
          compassEnabled: true,
          trafficEnabled: widget.showTraffic,
        ),
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
