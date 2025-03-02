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

import 'package:supabase_flutter/supabase_flutter.dart';
import '/flutter_flow/lat_lng.dart'; // Para o tipo LatLng do FlutterFlow
import 'index.dart'; // Imports other custom widgets

import 'index.dart'; // Imports other custom widgets
import '/flutter_flow/lat_lng.dart';
import '/custom_code/actions/update_navigator_mode_action.dart'; // Custom Action
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Classe para armazenar cada ponto da rota, incluindo velocidade em km/h
class _RoutePoint {
  final gmaps.LatLng position;
  final double speed; // km/h
  final DateTime timestamp;

  _RoutePoint(this.position, this.speed, this.timestamp);
}

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
    // Parâmetros de pausa/retomada:
    this.autoPauseDelaySeconds = 5,
    this.maxPauseDurationMinutes = 1, // (não usado aqui)
    this.autoResumeDelayMinutes = 1,
    this.autoResumeMinDistance = 5.0,
    this.stopSpeedThreshold = 1.0,
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

  final int autoPauseDelaySeconds;
  final int maxPauseDurationMinutes;
  final int autoResumeDelayMinutes;
  final double autoResumeMinDistance;
  final double stopSpeedThreshold;

  @override
  State<GoogleMapsLiveRoute> createState() => _GoogleMapsLiveRouteState();
}

class _GoogleMapsLiveRouteState extends State<GoogleMapsLiveRoute> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  gmaps.GoogleMapController? _mapController;
  Timer? _updateTimer;
  Timer? _timerNavigatorMode;
  StreamSubscription<Position>? _positionStream;

  // Polylines e Markers
  Set<gmaps.Polyline> _polylines = {};
  List<gmaps.Marker> _fetchedMarkers = []; // Marcadores (castomer=true)
  List<gmaps.LatLng> _userRoutePoints = []; // Exibição da rota em tempo real

  // Dados temporários da rota
  List<_RoutePoint> _localRouteData = [];

  // Estado do mapa e tracking
  gmaps.LatLng? _currentPosition;
  gmaps.LatLng? _lastPosition;
  double _currentSpeed = 0.0;
  double _currentHeading = 0.0;
  double _currentZoom = 16.0;
  double _distanceTraveled = 0.0;

  bool _showTraffic = false;
  bool _showSavedRoute = false;
  bool _showMarkers = false;
  bool _showUserRoute = false;

  bool _navigatorMode = false;
  bool _trackingMode = false;
  bool _isTrackingPaused = false;

  // Lógica de pausa
  DateTime? _stoppedTimestamp;
  DateTime? _pauseInitiatedTimestamp;
  gmaps.LatLng? _pauseStartPosition;

  // Para cálculo de duração (subtraindo pausas)
  DateTime? _startTime;
  Duration _accumulatedPause = Duration.zero;
  DateTime? _pauseStartTime;

  // Bloqueia auto-resume quando popup estiver aberto
  bool _popupOpen = false;

  gmaps.BitmapDescriptor? _customUserIcon;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _currentPosition = _convertLatLng(widget.initialLocation);
    _getInitialPosition();
    _startTracking();
    _loadPolylineSavedRoute();
    _loadCustomUserIcon();
    _currentPosition = _convertLatLng(widget.initialLocation);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _updateTimer?.cancel();
    _timerNavigatorMode?.cancel();
    super.dispose();
  }

  // Converte FlutterFlow LatLng para gmaps.LatLng
  gmaps.LatLng _convertLatLng(LatLng lfLatLng) {
    return gmaps.LatLng(lfLatLng.latitude, lfLatLng.longitude);
  }

  // ─────────────────────────────────────────
  // CENTRALIZAR NO USUÁRIO
  // ─────────────────────────────────────────

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
          gmaps.CameraPosition(target: latLng, zoom: 16.99),
        ),
      );
    }
  }

  // ─────────────────────────────────────────
  // ÍCONE DO USUÁRIO
  // ─────────────────────────────────────────

  Future<void> _loadCustomUserIcon() async {
    final icon = await gmaps.BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(144, 144)),
      'assets/images/SETA.png',
    );
    setState(() {
      _customUserIcon = icon;
    });
  }

  // ─────────────────────────────────────────
  // POSIÇÃO INICIAL
  // ─────────────────────────────────────────

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

  // ─────────────────────────────────────────
  // FUNÇÕES PARA ROTA SALVA (driver=true)
  // ─────────────────────────────────────────

  Future<List<gmaps.LatLng>> _fetchSavedRoute() async {
    try {
      final response = await Supabase.instance.client
          .from('trakingDriver')
          .select('location')
          .eq('driver', true)
          .order('created_at', ascending: true);
      final data = response as List<dynamic>;
      List<gmaps.LatLng> routePoints = [];
      for (var row in data) {
        final locationStr = row['location'] as String;
        final latLng = _parseLocationString(locationStr);
        if (latLng != null) {
          routePoints.add(latLng);
        }
      }
      return routePoints;
    } catch (e) {
      print('Erro ao buscar rota salva: $e');
      return [];
    }
  }

  // Carrega e exibe a rota salva (polylines) e dá zoom
  Future<void> _loadPolylineSavedRoute() async {
    final savedPoints = await _fetchSavedRoute();
    setState(() {
      _polylines.removeWhere((poly) => poly.polylineId.value == "saved_route");
      if (_showSavedRoute && savedPoints.isNotEmpty) {
        _polylines.add(
          gmaps.Polyline(
            polylineId: const gmaps.PolylineId("saved_route"),
            points: savedPoints,
            color: widget.routeColor,
            width: 5,
          ),
        );
      }
    });
    // Zoom automático para enquadrar a rota salva
    if (_showSavedRoute && savedPoints.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _zoomToFitRoute(savedPoints);
      });
    }
  }

  // Dá zoom automático para enquadrar os pontos
  Future<void> _zoomToFitRoute(List<gmaps.LatLng> points) async {
    if (points.isEmpty || _mapController == null) return;
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = gmaps.LatLngBounds(
      southwest: gmaps.LatLng(minLat, minLng),
      northeast: gmaps.LatLng(maxLat, maxLng),
    );
    try {
      final cameraUpdate = gmaps.CameraUpdate.newLatLngBounds(bounds, 60);
      await _mapController!.animateCamera(cameraUpdate);
    } catch (e) {
      print("Erro ao dar zoom na rota: $e");
    }
  }

  // ─────────────────────────────────────────
  // FUNÇÕES PARA MARKERS (castomer=true)
  // ─────────────────────────────────────────

  Future<List<gmaps.Marker>> _fetchMarkersFromSupabase() async {
    try {
      final response = await Supabase.instance.client
          .from('trakingDriver')
          .select('location')
          .eq('castomer', true)
          .order('created_at', ascending: true);
      final data = response as List<dynamic>;
      List<gmaps.Marker> markersList = [];
      for (var row in data) {
        final locationStr = row['location'] as String;
        final latLng = _parseLocationString(locationStr);
        if (latLng != null) {
          markersList.add(
            gmaps.Marker(
              markerId: gmaps.MarkerId(latLng.toString()),
              position: latLng,
              icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                  gmaps.BitmapDescriptor.hueRed),
            ),
          );
        }
      }
      return markersList;
    } catch (e) {
      print('Erro ao buscar markers: $e');
      return [];
    }
  }

  Future<void> _loadMarkersFromSupabase() async {
    final markers = await _fetchMarkersFromSupabase();
    setState(() {
      _fetchedMarkers = markers;
    });
  }

  // Converte string "LatLng(lat: X, lng: Y)" em gmaps.LatLng
  gmaps.LatLng? _parseLocationString(String location) {
    final regex = RegExp(r"LatLng\(lat:\s*([-\d\.]+),\s*lng:\s*([-\d\.]+)\)");
    final match = regex.firstMatch(location);
    if (match != null) {
      final lat = double.tryParse(match.group(1)!);
      final lng = double.tryParse(match.group(2)!);
      if (lat != null && lng != null) {
        return gmaps.LatLng(lat, lng);
      }
    }
    return null;
  }

  // ─────────────────────────────────────────
  // TRACKING DA POSIÇÃO
  // ─────────────────────────────────────────

  Future<void> _startTracking() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print("❌ Permissão negada.");
      return;
    }
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best, distanceFilter: 1),
    ).listen((Position newPosition) {
      _updateUserLocation(newPosition);
    });
    _updateTimer = Timer.periodic(
      Duration(seconds: widget.updateIntervalSeconds),
      (timer) async {
        final newPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best);
        _updateUserLocation(newPosition);
      },
    );
  }

  // Atualiza posição, calcula distância e armazena localmente (com speed km/h)
  Future<void> _updateUserLocation(Position position) async {
    final newPosition = gmaps.LatLng(position.latitude, position.longitude);

    // Converte para km/h
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

      // Exibição em tempo real
      _userRoutePoints.add(newPosition);
      _updateUserPolyline();
      _lastPosition = newPosition;
    });

    final now = DateTime.now();

    // Lógica de auto-pausa/retomada se no modo navegador e popup não estiver aberto
    if (!_popupOpen && _navigatorMode) {
      if (speedKmH < widget.stopSpeedThreshold) {
        if (_stoppedTimestamp == null) {
          _stoppedTimestamp = now;
        }
        if (!_isTrackingPaused &&
            now.difference(_stoppedTimestamp!).inSeconds >=
                widget.autoPauseDelaySeconds) {
          setState(() {
            _isTrackingPaused = true;
            _pauseStartPosition = newPosition;
            _pauseInitiatedTimestamp = now;
          });
          await updateNavigatorModeAction(false);
          await updateTrackingModeAction(false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Container(
                height: 80,
                alignment: Alignment.center,
                child: const Text("Pausa automática ativada"),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
          _pauseStartTime ??= now;
        }
      } else {
        _stoppedTimestamp = null;
        if (_isTrackingPaused && _pauseStartPosition != null) {
          final distance = Geolocator.distanceBetween(
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
            if (_pauseStartTime != null) {
              final pausedDuration =
                  DateTime.now().difference(_pauseStartTime!);
              _accumulatedPause += pausedDuration;
              _pauseStartTime = null;
            }
            _pauseInitiatedTimestamp = null;
            _pauseStartPosition = null;
            await updateNavigatorModeAction(_navigatorMode);
            await updateTrackingModeAction(_trackingMode);
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
                  height: 80,
                  alignment: Alignment.center,
                  child: const Text("Tracking retomado automaticamente"),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          // Se não pausado, atualiza câmera
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

    // Armazena localmente se tracking ativo e não pausado
    if (_trackingMode && !_isTrackingPaused) {
      _startTime ??= now;
      _localRouteData.add(_RoutePoint(newPosition, speedKmH, now));
    }
  }

  // ─────────────────────────────────────────
  // ATUALIZA POLYLINE DO USUÁRIO
  // ─────────────────────────────────────────

  void _updateUserPolyline() {
    setState(() {
      _polylines.removeWhere((poly) => poly.polylineId.value == "user_route");
      if (widget.showUserRoute) {
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

  // ─────────────────────────────────────────
  // MARKERS
  // ─────────────────────────────────────────

  Set<gmaps.Marker> _buildMarkers() {
    if (!_showMarkers) return {};
    return _fetchedMarkers.toSet();
  }

  // ─────────────────────────────────────────
  // MARKER DO USUÁRIO
  // ─────────────────────────────────────────

  Set<gmaps.Marker> _buildMarkerUser() {
    return {
      gmaps.Marker(
        markerId: const gmaps.MarkerId("user_position"),
        position: _currentPosition ??
            gmaps.LatLng(widget.initialLocation.latitude,
                widget.initialLocation.longitude),
        icon: _customUserIcon ??
            gmaps.BitmapDescriptor.defaultMarkerWithHue(
                gmaps.BitmapDescriptor.hueBlue),
      ),
    };
  }

  // ─────────────────────────────────────────
  // FUNÇÕES DE CONTROLE MODO NAVEGADOR E TRACKING
  // ─────────────────────────────────────────

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
        _startTime = null;
        _accumulatedPause = Duration.zero;
        _pauseStartTime = null;
        _localRouteData.clear();
        _userRoutePoints.clear();
      });
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

  void _toggleTracking() async {
    setState(() {
      if (_trackingMode && !_isTrackingPaused) {
        _isTrackingPaused = true;
        _pauseStartTime = DateTime.now();
      } else if (_trackingMode && _isTrackingPaused) {
        _isTrackingPaused = false;
        if (_pauseStartTime != null) {
          final pausedDuration = DateTime.now().difference(_pauseStartTime!);
          _accumulatedPause += pausedDuration;
          _pauseStartTime = null;
        }
      } else {
        // Iniciar tracking
        _trackingMode = true;
        _isTrackingPaused = false;
        _startTime = null;
        _accumulatedPause = Duration.zero;
        _pauseStartTime = null;
        _localRouteData.clear();
        _userRoutePoints.clear();
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

  // Timer do modo navegação (caso queira exibir tempo decorrido por segundo)
  void _startTimerNavigatorMode() {
    _timerNavigatorMode?.cancel();
    _timerNavigatorMode = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_trackingMode && !_isTrackingPaused) {
        setState(() {
          // Se quiser atualizar algo a cada segundo...
        });
      }
    });
  }

  // ─────────────────────────────────────────
  // PARAR VIAGEM + POPUP DE PRÉ-VISUALIZAÇÃO
  // ─────────────────────────────────────────

  void _stopTrackingPopup() {
    setState(() {
      _popupOpen = true;
    });
    _showRoutePreviewPopup();
  }

  // Salva todos os pontos no Supabase (com kmh)
  Future<void> _saveAllLocalDataToSupabase() async {
    try {
      final driverValue = true;
      final costumerValue = false;
      final statusValue = true;
      final userRefValue = '10000000-0000-0000-0000-000000000000';
      final socioIdValue = 1234;

      final rowsToInsert = _localRouteData.map((point) {
        final lat = point.position.latitude;
        final lng = point.position.longitude;
        final locationString = "LatLng(lat: $lat, lng: $lng)";
        return {
          'location': locationString,
          'driver': driverValue,
          'castomer': costumerValue,
          'status': statusValue,
          'userRef': userRefValue,
          'socio_id': socioIdValue,
          'kmh': point.speed, // Armazena a velocidade em km/h
        };
      }).toList();

      if (rowsToInsert.isNotEmpty) {
        await Supabase.instance.client
            .from('trakingDriver')
            .insert(rowsToInsert)
            .select();
        print('Rota salva com ${rowsToInsert.length} pontos.');
      } else {
        print('Nenhum ponto para salvar.');
      }
      _localRouteData.clear();
    } catch (e) {
      print('Erro ao salvar dados locais no Supabase: $e');
    }
  }

  // Calcula a velocidade média a partir dos pontos (somente speeds)
  double _calculateAverageSpeed() {
    if (_localRouteData.isEmpty) return 0.0;
    double totalSpeed = 0.0;
    for (var p in _localRouteData) {
      totalSpeed += p.speed;
    }
    return totalSpeed / _localRouteData.length;
  }

  // Duração total do primeiro ao último ponto (subtraindo pausas)
  Duration _calculateTotalDuration() {
    if (_localRouteData.isEmpty) return Duration.zero;
    // Ordena para pegar o timestamp inicial e final
    _localRouteData.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final start = _localRouteData.first.timestamp;
    final end = _localRouteData.last.timestamp;
    final total = end.difference(start);
    return total - _accumulatedPause;
  }

  // Formata a duração
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    if (hours > 0) {
      return "$hours:$minutes:$seconds";
    } else {
      return "$minutes:$seconds";
    }
  }

  // Retorna a duração total formatada
  String _formatLiveElapsedTime() {
    final duration = _calculateTotalDuration();
    return _formatDuration(duration);
  }

  // Exibe popup de pré-visualização com estatísticas e mapa
  void _showRoutePreviewPopup() {
    final totalDuration = _calculateTotalDuration();
    final avgSpeed = _calculateAverageSpeed();

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.all(8.0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: double.infinity,
            height: 420,
            child: Column(
              children: [
                Expanded(child: _buildPreviewMap(_userRoutePoints)),
                Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            "${_distanceTraveled.toStringAsFixed(1)} km",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 20),
                          ),
                          const Text("Distância",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            "${avgSpeed.toStringAsFixed(1)} km/h",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 20),
                          ),
                          const Text("Velocidade média",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            _formatDuration(totalDuration),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 20),
                          ),
                          const Text("Duração",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        // SALVAR DEFINITIVAMENTE
                        await _saveAllLocalDataToSupabase();
                        setState(() {
                          _navigatorMode = false;
                          _trackingMode = false;
                          _isTrackingPaused = false;
                          _distanceTraveled = 0.0;
                          _userRoutePoints.clear();
                          _localRouteData.clear();
                          _popupOpen = false;
                          _startTime = null;
                          _accumulatedPause = Duration.zero;
                          _pauseStartTime = null;
                        });
                        updateNavigatorModeAction(false);
                        updateTrackingModeAction(false);
                        Navigator.pop(ctx);
                      },
                      child: const Text("Salvar definitivamente"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // NÃO SALVAR => limpa tudo e sai
                        setState(() {
                          _navigatorMode = false;
                          _trackingMode = false;
                          _isTrackingPaused = false;
                          _distanceTraveled = 0.0;
                          _userRoutePoints.clear();
                          _localRouteData.clear();
                          _popupOpen = false;
                          _startTime = null;
                          _accumulatedPause = Duration.zero;
                          _pauseStartTime = null;
                        });
                        updateNavigatorModeAction(false);
                        updateTrackingModeAction(false);
                        Navigator.pop(ctx);
                      },
                      child: const Text("Não Salvar"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // Constrói o mapa de pré-visualização e enquadra a rota
  Widget _buildPreviewMap(List<gmaps.LatLng> routePoints) {
    final previewPolylines = <gmaps.Polyline>{
      gmaps.Polyline(
        polylineId: const gmaps.PolylineId("preview_route"),
        points: routePoints,
        color: Colors.red,
        width: 5,
      ),
    };
    final initialPosition =
        routePoints.isNotEmpty ? routePoints.first : const gmaps.LatLng(0, 0);

    return gmaps.GoogleMap(
      initialCameraPosition:
          gmaps.CameraPosition(target: initialPosition, zoom: 14),
      polylines: previewPolylines,
      onMapCreated: (controller) async {
        if (routePoints.isNotEmpty) {
          await Future.delayed(const Duration(milliseconds: 200));
          _zoomPreviewMap(controller, routePoints);
        }
      },
    );
  }

  // Dá zoom automático no popup para mostrar todos os pontos
  void _zoomPreviewMap(
    gmaps.GoogleMapController controller,
    List<gmaps.LatLng> points,
  ) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = gmaps.LatLngBounds(
      southwest: gmaps.LatLng(minLat, minLng),
      northeast: gmaps.LatLng(maxLat, maxLng),
    );

    final cameraUpdate = gmaps.CameraUpdate.newLatLngBounds(bounds, 50);
    controller.animateCamera(cameraUpdate);
  }

  // ─────────────────────────────────────────
  // BUILD PRINCIPAL
  // ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mapa principal
          gmaps.GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              _loadPolylineSavedRoute();
            },
            initialCameraPosition: gmaps.CameraPosition(
              target: _currentPosition ??
                  gmaps.LatLng(widget.initialLocation.latitude,
                      widget.initialLocation.longitude),
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

          // Botão Recentrar
          Positioned(
            bottom: 230,
            left: 16,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.7),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  minimumSize: const Size(125, 56),
                ),
                onPressed: _centerMapOnUserLocation,
                icon: const Icon(Icons.navigation, color: Colors.white),
                label: const Text("Recentrar",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
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
                    borderRadius: BorderRadius.circular(10)),
                child: Text("${_currentSpeed.toStringAsFixed(1)} km/h",
                    style: const TextStyle(color: Colors.white, fontSize: 18)),
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
                  borderRadius: BorderRadius.circular(8)),
              child: Text("Zoom: ${_currentZoom.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),

          // Draggable Sheet com controles
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
                        offset: const Offset(0, -4))
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
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      const SizedBox(height: 8),
                      if (!_navigatorMode)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              minimumSize: const Size(300, 56),
                            ),
                            onPressed: () {
                              _toggleNavigatorMode();
                              _getInitialPosition();
                            },
                            icon: const Icon(Icons.navigation,
                                color: Colors.white),
                            label: const Text("Navegar",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16)),
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
                                              color: Colors.white,
                                              fontSize: 25)),
                                      const Text("km",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14)),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                          "${_currentSpeed.toStringAsFixed(1)} km/h",
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 25)),
                                      const Text("km/h",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14)),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(_formatLiveElapsedTime(),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 25)),
                                      const Text("tempo",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 25),
                            ],
                            if (_trackingMode)
                              !_isTrackingPaused
                                  ? ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16, horizontal: 60),
                                        minimumSize: const Size(300, 56),
                                      ),
                                      onPressed: () async {
                                        setState(() {
                                          _isTrackingPaused = true;
                                          _pauseStartPosition =
                                              _currentPosition;
                                          _pauseInitiatedTimestamp =
                                              DateTime.now();
                                          _pauseStartTime ??= DateTime.now();
                                        });
                                        await updateTrackingModeAction(false);
                                      },
                                      child: const Text("Pausar",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16)),
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
                                                    BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 16, horizontal: 30),
                                            minimumSize: const Size(140, 56),
                                          ),
                                          onPressed: () async {
                                            setState(() {
                                              _isTrackingPaused = false;
                                              _trackingMode = true;
                                              if (_pauseStartTime != null) {
                                                final pausedDuration =
                                                    DateTime.now().difference(
                                                        _pauseStartTime!);
                                                _accumulatedPause +=
                                                    pausedDuration;
                                                _pauseStartTime = null;
                                              }
                                            });
                                            await updateTrackingModeAction(
                                                true);
                                          },
                                          child: const Text("Continuar",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16)),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 16, horizontal: 30),
                                            minimumSize: const Size(140, 56),
                                          ),
                                          onPressed: () {
                                            _stopTrackingPopup();
                                          },
                                          child: const Text("Parar viagem",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16)),
                                        ),
                                      ],
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
                              if (_showMarkers) {
                                _loadMarkersFromSupabase();
                              }
                            },
                            child: Icon(_showMarkers
                                ? Icons.location_on
                                : Icons.location_off),
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
                            child: Icon(_showUserRoute
                                ? Icons.timeline
                                : Icons.timeline_outlined),
                            backgroundColor: Colors.blue,
                            tooltip: "Mostrar/Ocultar Minha Rota",
                          ),
                          FloatingActionButton(
                            onPressed: () {
                              setState(() {
                                _showTraffic = !_showTraffic;
                              });
                            },
                            child: Icon(_showTraffic
                                ? Icons.traffic
                                : Icons.traffic_outlined),
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
