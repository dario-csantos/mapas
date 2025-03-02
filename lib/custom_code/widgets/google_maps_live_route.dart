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

import '/flutter_flow/lat_lng.dart'; // Para o tipo LatLng do FlutterFlow
import 'index.dart'; // Imports other custom widgets

import 'index.dart'; // Imports other custom widgets
import 'index.dart'; // Imports other custom widgets
import 'index.dart'; // Imports other custom widgets
import 'index.dart'; // Imports other custom widgets
import 'index.dart'; // Imports other custom widgets
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/update_navigator_mode_action.dart'; // Custom Action
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:wakelock_plus/wakelock_plus.dart';

class GoogleMapsLiveRoute extends StatefulWidget {
  const GoogleMapsLiveRoute({
    super.key,
    this.width,
    this.height,
    required this.initialLocation, // Tipo LatLng do FlutterFlow
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
    // Parâmetros para customizar a lógica de pausa/retomada (para teste):
    this.autoPauseDelaySeconds = 1, // 1 segundo para entrar em pausa
    this.maxPauseDurationMinutes =
        1, // (não usado) 1 minuto de pausa máxima (agora desabilitado)
    this.autoResumeDelayMinutes = 1, // 1 minuto em pausa para permitir retomar
    this.autoResumeMinDistance = 1.0, // 1 metro para retomar
    this.stopSpeedThreshold = 1.0, // 1 km/h como limiar para considerar parado
  });

  final double? width;
  final double? height;
  final LatLng initialLocation; // FlutterFlow LatLng
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
  final List<LatLng> markerLocations; // FlutterFlow LatLng
  final List<LatLng> polylineSavedRoute; // FlutterFlow LatLng

  // Parâmetros para customizar a lógica de pausa/retomada
  final int autoPauseDelaySeconds;
  final int maxPauseDurationMinutes;
  final int autoResumeDelayMinutes;
  final double autoResumeMinDistance;
  final double stopSpeedThreshold;

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

  // Estados de navegação/tracking
  bool _navigatorMode = false; // Inicialmente, modo normal (não navegador)
  bool _trackingMode = false; // Tracking inativo
  bool _isTrackingPaused = false; // Não está pausado

  double _distanceTraveled = 0.0; // Distância total (km)
  gmaps.LatLng? _lastPosition; // Última posição
  int _elapsedSecondsNavigator = 0; // Tempo decorrido (segundos)
  Timer? _timerNavigatorMode; // Timer para atualizar o tempo

  // Variáveis para controle de pausa automática
  DateTime? _stoppedTimestamp; // Momento em que o usuário parou
  DateTime? _pauseInitiatedTimestamp; // Momento de ativação da pausa automática
  gmaps.LatLng? _pauseStartPosition; // Posição quando a pausa iniciou

  gmaps.BitmapDescriptor? _customUserIcon;

  // Converte FlutterFlow LatLng para gmaps.LatLng
  gmaps.LatLng _convertLatLng(LatLng lfLatLng) {
    return gmaps.LatLng(lfLatLng.latitude, lfLatLng.longitude);
  }

  // Centraliza o mapa na localização atual
  Future<void> _centerMapOnUserLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print("❌ Permissão negada.");
      return;
    }
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    final latLng = gmaps.LatLng(position.latitude, position.longitude);
    setState(() {
      _currentPosition = latLng;
    });
    if (_mapController != null) {
      _mapController!.animateCamera(
        gmaps.CameraUpdate.newCameraPosition(
          gmaps.CameraPosition(
            target: latLng,
            zoom: 16.99,
          ),
        ),
      );
    }
  }

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
    // Ao iniciar, o mapa está em modo normal
    _currentPosition = _convertLatLng(widget.initialLocation);
    _getInitialPosition();
    _startTracking();
    _loadPolylineSavedRoute();
    _loadCustomUserIcon();
    _currentPosition = _convertLatLng(widget.initialLocation);
  }

  Future<void> _loadCustomUserIcon() async {
    final icon = await gmaps.BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(144, 144)),
      'assets/images/SETA.png',
    );
    setState(() {
      _customUserIcon = icon;
    });
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
      _currentPosition = _convertLatLng(widget.initialLocation);
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
            .map((lfLatLng) => _convertLatLng(lfLatLng))
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

  // Removida a lógica de finalização automática
  // (O usuário agora deverá clicar manualmente em "Parar viagem")

  Future<void> _updateUserLocation(Position position) async {
    final newPosition = gmaps.LatLng(position.latitude, position.longitude);
    double speedKmH = position.speed * 3.6;
    if (speedKmH.isNaN || speedKmH < 0) speedKmH = 0.0;
    double heading = position.heading;
    if (heading.isNaN || heading < 0) heading = _currentHeading;
    if (_mapController != null) {
      _currentZoom = await _mapController!.getZoomLevel();
    }
    setState(() {
      _currentSpeed = speedKmH;
      _currentHeading = heading;
      _currentPosition = newPosition;
      if (!_isTrackingPaused && _lastPosition != null) {
        final distanceInMeters = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          newPosition.latitude,
          newPosition.longitude,
        );
        _distanceTraveled += (distanceInMeters / 1000);
      }
      _userRoutePoints.add(newPosition);
      _updateUserPolyline();
      _lastPosition = newPosition;
    });
    final now = DateTime.now();
    // Executa a lógica de auto pausa/retomada somente se estiver em modo navegador
    if (_navigatorMode) {
      // Se o usuário estiver muito devagar, considera que ele parou
      if (speedKmH < widget.stopSpeedThreshold) {
        if (_stoppedTimestamp == null) {
          _stoppedTimestamp = now;
        }
        if (!_isTrackingPaused &&
            now.difference(_stoppedTimestamp!).inSeconds >=
                widget.autoPauseDelaySeconds) {
          setState(() {
            _isTrackingPaused = true;
          });
          _pauseInitiatedTimestamp = now;
          _pauseStartPosition = newPosition;
          await updateNavigatorModeAction(false);
          await updateTrackingModeAction(false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Container(
                height: 80, // altura desejada
                alignment: Alignment.center,
                child: const Text("Pausa automática ativada"),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        _stoppedTimestamp = null;
        if (_isTrackingPaused) {
          // Auto retomada: verifica se a distância movida é suficiente, sem exigir tempo de espera
          if (_pauseStartPosition != null) {
            double distance = Geolocator.distanceBetween(
              _pauseStartPosition!.latitude,
              _pauseStartPosition!.longitude,
              newPosition.latitude,
              newPosition.longitude,
            );
            if (distance >= widget.autoResumeMinDistance) {
              setState(() {
                _isTrackingPaused = false;
                _trackingMode = true;
              });
              _pauseInitiatedTimestamp = null;
              _pauseStartPosition = null;
              await updateNavigatorModeAction(_navigatorMode);
              await updateTrackingModeAction(_trackingMode);
              // Atualiza a câmera para a nova posição
              if (_mapController != null) {
                _mapController!.animateCamera(
                  gmaps.CameraUpdate.newCameraPosition(
                    gmaps.CameraPosition(
                      target: newPosition,
                      zoom: widget.initialZoom,
                      bearing: _currentHeading,
                      tilt: widget.mapTilt,
                    ),
                  ),
                );
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Container(
                    height: 80, // altura desejada
                    alignment: Alignment.center,
                    child: const Text("Tracking retomado automaticamente"),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        } else {
          // Se não estiver pausado e em movimento, atualiza a câmera automaticamente
          if (_mapController != null) {
            _mapController!.animateCamera(
              gmaps.CameraUpdate.newCameraPosition(
                gmaps.CameraPosition(
                  target: newPosition,
                  zoom: widget.initialZoom,
                  bearing: _currentHeading,
                  tilt: widget.mapTilt,
                ),
              ),
            );
          }
        }
      }
    } else {
      _stoppedTimestamp = null;
      _pauseInitiatedTimestamp = null;
      _pauseStartPosition = null;
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
        icon: _customUserIcon ??
            gmaps.BitmapDescriptor.defaultMarkerWithHue(
              gmaps.BitmapDescriptor.hueBlue,
            ),
      ),
    };
  }

  // Marcadores extras
  Set<gmaps.Marker> _buildMarkers() {
    if (!_showMarkers) return {};
    return widget.markerLocations.map((lfLatLng) {
      return gmaps.Marker(
        markerId: gmaps.MarkerId(lfLatLng.toString()),
        position: _convertLatLng(lfLatLng),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
          gmaps.BitmapDescriptor.hueRed,
        ),
      );
    }).toSet();
  }

  // Alterna entre modo navegador e tracking
  Future<void> _toggleNavigatorMode() async {
    setState(() {
      _navigatorMode = !_navigatorMode;
    });
    await updateNavigatorModeAction(_navigatorMode);
    await updateTrackingModeAction(_navigatorMode);
    if (_navigatorMode) {
      setState(() {
        _trackingMode = true;
        _isTrackingPaused = false;
        _distanceTraveled = 0.0;
        _lastPosition = _currentPosition;
        _elapsedSecondsNavigator = 0;
      });
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
      setState(() {
        _trackingMode = false;
        _isTrackingPaused = false;
      });
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

  // Função para pausar/continuar o tracking manualmente
  void _toggleTracking() async {
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
    if (_isTrackingPaused) {
      await updateNavigatorModeAction(false);
      await updateTrackingModeAction(false);
    } else {
      await updateNavigatorModeAction(_navigatorMode);
      await updateTrackingModeAction(_trackingMode);
    }
  }

  // Ao clicar em "Parar viagem", desativa todos os modos
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
      await updateTrackingModeAction(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mapa
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
            myLocationEnabled: true,
            compassEnabled: true,
            trafficEnabled: _showTraffic,
            zoomControlsEnabled: false,
            tiltGesturesEnabled: true,
          ),
          // Botão para recentrar o mapa
          Positioned(
            bottom: 230,
            left: 16,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  minimumSize: const Size(125, 56),
                ),
                onPressed: () {
                  _centerMapOnUserLocation();
                },
                icon: const Icon(
                  Icons.navigation,
                  color: Colors.white,
                ),
                label: const Text(
                  "Recentrar",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          // Exibição da velocidade
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
          // Exibição do zoom
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
          // Draggable Sheet
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.30,
            minChildSize: 0.12,
            maxChildSize: 0.30,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
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
                              _getInitialPosition();
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
                                            color: Colors.white, fontSize: 25),
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
                                            color: Colors.white, fontSize: 25),
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
                                            color: Colors.white, fontSize: 25),
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
                              const SizedBox(height: 25),
                            ],
                            // Se estiver pausado, mostra os botões "Continuar" e "Parar viagem"
                            _trackingMode
                                ? (!_isTrackingPaused
                                    ? ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                            horizontal: 60,
                                          ),
                                          minimumSize: const Size(300, 56),
                                        ),
                                        onPressed: () async {
                                          // Ao clicar "Pausar" manualmente
                                          setState(() {
                                            _isTrackingPaused = true;
                                          });
                                          await updateTrackingModeAction(false);
                                        },
                                        child: const Text(
                                          "Pausar",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 16,
                                                horizontal: 30,
                                              ),
                                              minimumSize: const Size(140, 56),
                                            ),
                                            onPressed: () async {
                                              setState(() {
                                                _isTrackingPaused = false;
                                                _trackingMode = true;
                                              });
                                              await updateTrackingModeAction(
                                                  true);
                                            },
                                            child: const Text(
                                              "Continuar",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16),
                                            ),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                                  fontSize: 16),
                                            ),
                                          ),
                                        ],
                                      ))
                                : const SizedBox(),
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
                      const SizedBox(height: 5),
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
