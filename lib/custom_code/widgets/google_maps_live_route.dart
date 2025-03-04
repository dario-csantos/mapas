// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/backend/sqlite/sqlite_manager.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom widgets

// Outras importações necessárias
import 'package:supabase_flutter/supabase_flutter.dart';
import '/flutter_flow/lat_lng.dart'; // Para o tipo LatLng do FlutterFlow
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:wakelock_plus/wakelock_plus.dart';

// Se quiser usar image_picker
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Classe para armazenar cada ponto da rota com velocidade e timestamp
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
    this.maxPauseDurationMinutes = 1,
    this.autoResumeDelayMinutes = 1,
    this.autoResumeMinDistance = 5.0,
    this.stopSpeedThreshold = 1.0,
    this.socioId = 234234,
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
  final int socioId;

  @override
  State<GoogleMapsLiveRoute> createState() => _GoogleMapsLiveRouteState();
}

class _GoogleMapsLiveRouteState extends State<GoogleMapsLiveRoute> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  gmaps.GoogleMapController? _mapController;
  Set<gmaps.Polyline> _polylines = {};
  List<gmaps.LatLng> _userRoutePoints = [];
  List<_RoutePoint> _localRouteData = [];
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
  bool _navigatorMode = false;
  bool _trackingMode = false;
  bool _isTrackingPaused = false;
  double _distanceTraveled = 0.0;
  gmaps.LatLng? _lastPosition;
  DateTime? _stoppedTimestamp;
  DateTime? _pauseInitiatedTimestamp;
  gmaps.LatLng? _pauseStartPosition;
  bool _popupOpen = false;
  gmaps.BitmapDescriptor? _customUserIcon;
  List<gmaps.Marker> _fetchedMarkers = [];
  DateTime? _startTime;
  Duration _accumulatedPause = Duration.zero;
  DateTime? _pauseStartTime;

  // Controllers para os campos de texto
  late TextEditingController _nameController;
  late TextEditingController _regionController;
  late TextEditingController _descriptionController;

  // Guarda o ID da rota criada no SQLite
  int? _currentRouteId;

  // Filtro Rota
  int? _selectedRouteId = 48;

  // NOVO: lista de imagens selecionadas para enviar
  List<XFile> _pickedImages = [];

  void updateShowSavedRoute(int? selectedRouteId) {
    if (selectedRouteId != null) {
      setState(() {
        _selectedRouteId = selectedRouteId;
        _showSavedRoute = true;
      });
      _loadPolylineSavedRoute();
    } else {
      setState(() {
        _showSavedRoute = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _regionController = TextEditingController();
    _descriptionController = TextEditingController();
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
    _nameController.dispose();
    _regionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  gmaps.LatLng _convertLatLng(LatLng lfLatLng) {
    return gmaps.LatLng(lfLatLng.latitude, lfLatLng.longitude);
  }

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
    _mapController?.animateCamera(
      gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(target: latLng, zoom: 16.99),
      ),
    );
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

  // ───────────────────────────────────────────────
  // FUNÇÕES PARA ROTAS E MARKERS DO SUPABASE
  Future<List<gmaps.LatLng>> _fetchSavedRoute(int routeId) async {
    try {
      final response = await Supabase.instance.client
          .from('route_points')
          .select('latitude, longitude')
          .eq('route_id', routeId)
          .order('timestamp', ascending: false);
      print("Dados recebidos para routeId $routeId: $response");
      final data = response as List<dynamic>;
      List<gmaps.LatLng> routePoints = [];
      for (var row in data) {
        final lat = row['latitude'];
        final lng = row['longitude'];
        if (lat != null && lng != null) {
          routePoints.add(gmaps.LatLng(lat, lng));
        }
      }
      return routePoints;
    } catch (e) {
      print('Erro ao buscar rota salva: $e');
      return [];
    }
  }

  Future<void> _loadPolylineSavedRoute() async {
    if (_selectedRouteId == null) return;
    final savedPoints = await _fetchSavedRoute(_selectedRouteId!);
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
    if (_showSavedRoute && savedPoints.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _zoomToFitRoute(savedPoints);
      });
    }
  }

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

  Future<void> _loadMarkersFromSupabase() async {
    final markers = await _fetchMarkersFromSupabase();
    setState(() {
      _fetchedMarkers = markers;
    });
  }

  Future<List<gmaps.Marker>> _fetchMarkersFromSupabase() async {
    try {
      final response = await Supabase.instance.client
          .from('route_points')
          .select('latitude, longitude')
          .order('timestamp', ascending: true);
      final data = response as List<dynamic>;
      List<gmaps.Marker> markersList = [];
      for (var row in data) {
        final lat = row['latitude'];
        final lng = row['longitude'];
        if (lat != null && lng != null) {
          markersList.add(
            gmaps.Marker(
              markerId: gmaps.MarkerId("$lat,$lng"),
              position: gmaps.LatLng(lat, lng),
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

  // ───────────────────────────────────────────────
  // TRACKING
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

    // Lógica de auto pausa/retomada (simplificada aqui)
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
          if (_pauseStartTime == null) {
            _pauseStartTime = now;
          }
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
            _pauseInitiatedTimestamp = null;
            _pauseStartPosition = null;
            await updateNavigatorModeAction(_navigatorMode);
            await updateTrackingModeAction(_trackingMode);
            if (_pauseStartTime != null) {
              final pausedDuration =
                  DateTime.now().difference(_pauseStartTime!);
              _accumulatedPause += pausedDuration;
              _pauseStartTime = null;
            }
            _mapController?.animateCamera(
              gmaps.CameraUpdate.newCameraPosition(
                gmaps.CameraPosition(
                  target: newPosition,
                  zoom: widget.initialZoom,
                  bearing: _currentHeading,
                  tilt: widget.mapTilt,
                ),
              ),
            );
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
          _mapController?.animateCamera(
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
    } else {
      _stoppedTimestamp = null;
      _pauseInitiatedTimestamp = null;
      _pauseStartPosition = null;
    }

    // Se tracking ativo e não pausado, registra o ponto e salva no SQLite
    if (_trackingMode && !_isTrackingPaused) {
      if (_startTime == null) {
        _startTime = now;
        final db = SQLiteManager.instance.database;
        _currentRouteId = await db.insert('routes', {
          'socio_id': widget.socioId,
          'name': _nameController.text,
          'region': _regionController.text,
          'description': _descriptionController.text,
          'created_at': now.toIso8601String(),
          'avg_speed': 0.0,
          'total_duration': 0,
          'total_distance': 0.0,
        });
      }
      _localRouteData.add(_RoutePoint(newPosition, speedKmH, now));
      if (_currentRouteId != null) {
        final db = SQLiteManager.instance.database;
        await db.insert('route_points', {
          'route_id': _currentRouteId,
          'latitude': newPosition.latitude,
          'longitude': newPosition.longitude,
          'speed': speedKmH,
          'timestamp': now.toIso8601String(),
        });
      }
    }
  }

  // ───────────────────────────────────────────────
  // EXIBIÇÃO EM TEMPO REAL DO TEMPO
  Duration _getLiveElapsedTime() {
    if (_startTime == null) return Duration.zero;
    final now = DateTime.now();
    final baseDuration = now.difference(_startTime!);
    return baseDuration - _accumulatedPause;
  }

  String _formatLiveElapsedTime() {
    final duration = _getLiveElapsedTime();
    final hours = duration.inHours;
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return hours > 0 ? "$hours:$minutes:$seconds" : "$minutes:$seconds";
  }

  // ───────────────────────────────────────────────
  // SINCRONIZAÇÃO COM O SUPABASE
  Future<void> _saveAllLocalDataToSupabase() async {
    try {
      final db = SQLiteManager.instance.database;
      final localPoints = await db.query('route_points',
          where: 'route_id = ?', whereArgs: [_currentRouteId]);
      final localRouteList = await db
          .query('routes', where: 'route_id = ?', whereArgs: [_currentRouteId]);
      if (localRouteList.isEmpty) {
        print('Nenhuma rota encontrada.');
        return;
      }
      final localRoute = localRouteList.first;
      final routeData = {
        'socio_id': localRoute['socio_id'],
        'name': localRoute['name'],
        'region': localRoute['region'], // Adicione a região aqui
        'description': localRoute['description'],
        'created_at': localRoute['created_at'],
        'avg_speed': localRoute['avg_speed'],
        'total_duration': localRoute['total_duration'],
        'total_distance': localRoute['total_distance'],
      };
      // Insere a rota no Supabase
      final routeResponse = await Supabase.instance.client
          .from('routes')
          .insert(routeData)
          .select()
          .single();
      final supabaseRouteId = routeResponse['route_id'];

      // Insere os pontos
      final rowsToInsert = localPoints.map((row) {
        return {
          'route_id': supabaseRouteId,
          'latitude': row['latitude'],
          'longitude': row['longitude'],
          'speed': row['speed'],
          'timestamp': row['timestamp'],
        };
      }).toList();
      if (rowsToInsert.isNotEmpty) {
        await Supabase.instance.client
            .from('route_points')
            .insert(rowsToInsert)
            .select();
        print('Rota e ${rowsToInsert.length} pontos salvos no Supabase.');
      } else {
        print('Nenhum ponto para salvar.');
      }

      // NOVO: Upload das imagens e salvar no route_imagens
      if (_pickedImages.isNotEmpty) {
        await _uploadRouteImages(supabaseRouteId);
      }

      // Limpeza local, se quiser
      // await db.delete('route_points', where: 'route_id = ?', whereArgs: [_currentRouteId]);
      // await db.delete('routes', where: 'route_id = ?', whereArgs: [_currentRouteId]);

      _localRouteData.clear();
      _currentRouteId = null;
    } catch (e) {
      print('Erro ao salvar dados locais no Supabase: $e');
    }
  }

  // ───────────────────────────────────────────────
  // CÁLCULOS DE ESTATÍSTICAS FINAIS
  double _calculateAverageSpeed() {
    if (_localRouteData.isEmpty) return 0.0;
    double totalSpeed = 0.0;
    for (var point in _localRouteData) {
      totalSpeed += point.speed;
    }
    return totalSpeed / _localRouteData.length;
  }

  Duration _calculateTotalDuration() {
    if (_localRouteData.length < 2) return Duration.zero;
    _localRouteData.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final start = _localRouteData.first.timestamp;
    final end = _localRouteData.last.timestamp;
    return end.difference(start);
  }

  // ───────────────────────────────────────────────
  // ATUALIZAÇÃO DE POLYLINE E MARKERS
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

  Set<gmaps.Marker> _buildMarkers() {
    if (!_showMarkers) return {};
    return _fetchedMarkers.toSet();
  }

  // ───────────────────────────────────────────────
  // MODO NAVEGADOR E CONTROLE
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
        _currentRouteId = null;
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
        _trackingMode = true;
        _isTrackingPaused = false;
        _startTime = null;
        _accumulatedPause = Duration.zero;
        _pauseStartTime = null;
        _localRouteData.clear();
        _userRoutePoints.clear();
        _currentRouteId = null;
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

  void _stopTrackingPopup() async {
    setState(() {
      _popupOpen = true;
    });
    _showRoutePreviewPopup();
  }

  void _showRoutePreviewPopup() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          alignment: Alignment.topCenter,
          insetPadding: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height,
            color: Colors.black87,
            child: Column(
              children: [
                // Topo com título e botão "SALVE"
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Verifique e salve a rota",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await _saveRoute();
                        },
                        child: const Text(
                          "SALVE",
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Preview do mapa
                SizedBox(
                  height: 180,
                  child: _buildPreviewMap(_userRoutePoints),
                ),
                // Linha de métricas
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMetricItem(
                          "${_distanceTraveled.toStringAsFixed(1)} km",
                          Icons.route_outlined),
                      _buildMetricItem(_formatLiveElapsedTime(), Icons.timer),
                      _buildMetricItem(
                          "${_calculateAverageSpeed().toStringAsFixed(1)} km/h",
                          Icons.speed),
                      _buildMetricItem("0 m", Icons.terrain),
                    ],
                  ),
                ),
                // Campos de texto (Nome, Região, Descrição)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildTextField("Nome da rota", _nameController),
                        const SizedBox(height: 8),
                        _buildTextField("Região", _regionController),
                        const SizedBox(height: 8),
                        _buildTextField("Descrição", _descriptionController),

                        // Exemplo de botão para escolher imagens
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          onPressed: () async {
                            await _pickImages();
                          },
                          child: const Text(
                            "Adicionar fotos",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),

                        // Exibir as imagens selecionadas (miniaturas)
                        if (_pickedImages.isNotEmpty)
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _pickedImages.length,
                              itemBuilder: (context, index) {
                                final img = _pickedImages[index];
                                return Container(
                                  margin: const EdgeInsets.all(5),
                                  child: Image.file(File(img.path),
                                      width: 80, height: 80, fit: BoxFit.cover),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Linha de botões: Salvar rota e Não Salvar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          onPressed: () async {
                            await _saveRoute();
                          },
                          child: const Text("Salvar rota",
                              style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          onPressed: () {
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
                              _currentRouteId = null;
                              _pickedImages.clear();
                            });
                            updateNavigatorModeAction(false);
                            updateTrackingModeAction(false);
                            Navigator.pop(ctx);
                          },
                          child: const Text("Não Salvar",
                              style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricItem(String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.black54,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

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

  void _zoomPreviewMap(
      gmaps.GoogleMapController controller, List<gmaps.LatLng> points) {
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

  // ───────────────────────────────────────────────
  // FUNÇÃO UNIFICADA DE SALVAMENTO DA ROTA
  Future<void> _saveRoute() async {
    final totalDuration = _calculateTotalDuration();
    final avgSpeed = _calculateAverageSpeed();
    final distance = _distanceTraveled;
    if (_currentRouteId != null) {
      final db = SQLiteManager.instance.database;
      await db.update(
        'routes',
        {
          'name': _nameController.text,
          'region': _regionController.text,
          'description': _descriptionController.text,
          'avg_speed': avgSpeed,
          'total_duration': totalDuration.inSeconds,
          'total_distance': distance,
        },
        where: 'route_id = ?',
        whereArgs: [_currentRouteId],
      );
    }
    await _saveAllLocalDataToSupabase();
    _nameController.clear();
    _regionController.clear();
    _descriptionController.clear();
    _pickedImages.clear(); // limpa as imagens
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
      _currentRouteId = null;
    });
    await updateNavigatorModeAction(false);
    await updateTrackingModeAction(false);
    Navigator.pop(context);
  }

  // ───────────────────────────────────────────────
  // FUNÇÕES PARA FOTOS

  /// Exemplo simples usando image_picker para selecionar várias imagens
  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? selectedFiles = await picker.pickMultiImage();
    if (selectedFiles != null) {
      setState(() {
        _pickedImages.addAll(selectedFiles);
      });
    }
  }

  /// Função para fazer upload de cada imagem e salvar em `route_imagens`
  Future<void> _uploadRouteImages(int supabaseRouteId) async {
    final bucketName = 'imagens';
    final subfolder = 'img_routes';

    for (final file in _pickedImages) {
      try {
        final fileBytes = await File(file.path).readAsBytes();
        final fileName =
            "route_${supabaseRouteId}_${DateTime.now().millisecondsSinceEpoch}.jpg";

        // Cria um arquivo temporário
        final tempDir = await getTemporaryDirectory();
        final tempFilePath = '${tempDir.path}/$fileName';
        final tempFile = File(tempFilePath);
        await tempFile.writeAsBytes(fileBytes);

        // Faz upload usando o arquivo temporário
        final uploadResponse = await Supabase.instance.client.storage
            .from(bucketName)
            .upload('$subfolder/$fileName', tempFile);

        // uploadResponse é uma String, verifique se não é vazia (sucesso)
        if (uploadResponse == null || uploadResponse.isEmpty) {
          print("Erro ao fazer upload: resposta vazia");
          continue;
        }

        // Construa a URL pública manualmente
        final publicUrl =
            "https://cneovsksqcyedzzzrodf.supabase.co/storage/v1/object/public/$bucketName/$subfolder/$fileName";

        // Insira na tabela route_imagens
        await Supabase.instance.client.from('route_imagens').insert({
          'route_id': supabaseRouteId,
          'route_imagem_url': publicUrl,
        });
        print("Foto salva em route_imagens: $publicUrl");
      } catch (e) {
        print("Erro no upload: $e");
      }
    }
  }

  // ───────────────────────────────────────────────
  // EXIBIÇÃO
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
                child: Text("${_currentSpeed.toStringAsFixed(1)} km/h",
                    style: const TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text("Zoom: ${_currentZoom.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
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
                        offset: const Offset(0, -4)),
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
                                          if (_pauseStartTime == null) {
                                            _pauseStartTime = DateTime.now();
                                          }
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
