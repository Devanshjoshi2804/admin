import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RealTimeTrackingService extends ChangeNotifier {
  static final RealTimeTrackingService _instance = RealTimeTrackingService._internal();
  factory RealTimeTrackingService() => _instance;
  RealTimeTrackingService._internal();

  io.Socket? _socket;
  StreamSubscription<Position>? _positionStream;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Tracking state
  bool _isTracking = false;
  Position? _currentPosition;
  List<Position> _trackingHistory = [];
  String? _currentTripId;
  Map<String, dynamic> _tripData = {};
  
  // Geofencing
  final List<GeofenceZone> _geofences = [];
  final Set<String> _triggeredGeofences = {};
  
  // Performance metrics
  double _totalDistance = 0.0;
  DateTime? _trackingStartTime;
  Duration _totalTrackingTime = Duration.zero;
  double _averageSpeed = 0.0;
  
  // Getters
  bool get isTracking => _isTracking;
  Position? get currentPosition => _currentPosition;
  List<Position> get trackingHistory => List.unmodifiable(_trackingHistory);
  String? get currentTripId => _currentTripId;
  Map<String, dynamic> get tripData => Map.unmodifiable(_tripData);
  double get totalDistance => _totalDistance;
  Duration get totalTrackingTime => _totalTrackingTime;
  double get averageSpeed => _averageSpeed;
  List<GeofenceZone> get geofences => List.unmodifiable(_geofences);

  // Initialize the service
  Future<void> initialize() async {
    await _initializeNotifications();
    await _connectToSocket();
    await _loadTrackingState();
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(initSettings);
  }

  Future<void> _connectToSocket() async {
    _socket = io.io('ws://localhost:8080', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket?.on('connect', (_) {
      print('Connected to tracking server');
      if (_currentTripId != null) {
        _socket?.emit('join_trip', {'tripId': _currentTripId});
      }
    });

    _socket?.on('trip_update', (data) {
      _handleTripUpdate(data);
    });

    _socket?.on('geofence_alert', (data) {
      _handleGeofenceAlert(data);
    });

    _socket?.connect();
  }

  // Start tracking for a trip
  Future<bool> startTracking(String tripId, {Map<String, dynamic>? tripData}) async {
    if (_isTracking) {
      await stopTracking();
    }

    // Check permissions
    bool hasPermission = await _checkLocationPermissions();
    if (!hasPermission) {
      return false;
    }

    _currentTripId = tripId;
    _tripData = tripData ?? {};
    _isTracking = true;
    _trackingStartTime = DateTime.now();
    _totalDistance = 0.0;
    _trackingHistory.clear();
    _triggeredGeofences.clear();

    // Start position stream
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      _onPositionUpdate,
      onError: (error) {
        print('Location error: $error');
        _showNotification('Location Error', 'Failed to get location updates');
      },
    );

    // Join trip room on socket
    _socket?.emit('start_tracking', {
      'tripId': tripId,
      'driverId': 'current_driver_id', // Get from auth
      'timestamp': DateTime.now().toIso8601String(),
    });

    await _saveTrackingState();
    notifyListeners();

    _showNotification(
      'Tracking Started',
      'GPS tracking is now active for trip #$tripId',
    );

    return true;
  }

  // Stop tracking
  Future<void> stopTracking() async {
    if (!_isTracking) return;

    _isTracking = false;
    await _positionStream?.cancel();
    _positionStream = null;

    if (_trackingStartTime != null) {
      _totalTrackingTime = DateTime.now().difference(_trackingStartTime!);
      _averageSpeed = _totalDistance / _totalTrackingTime.inHours;
    }

    // Send final update
    _socket?.emit('stop_tracking', {
      'tripId': _currentTripId,
      'totalDistance': _totalDistance,
      'totalTime': _totalTrackingTime.inMinutes,
      'averageSpeed': _averageSpeed,
      'trackingHistory': _trackingHistory.map((p) => {
        'latitude': p.latitude,
        'longitude': p.longitude,
        'timestamp': p.timestamp?.toIso8601String(),
        'speed': p.speed,
        'accuracy': p.accuracy,
      }).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    });

    await _clearTrackingState();
    notifyListeners();

    _showNotification(
      'Tracking Completed',
      'Trip tracking has been stopped. Total distance: ${_totalDistance.toStringAsFixed(2)} km',
    );
  }

  void _onPositionUpdate(Position position) {
    if (!_isTracking) return;

    Position? previousPosition = _currentPosition;
    _currentPosition = position;
    _trackingHistory.add(position);

    // Calculate distance
    if (previousPosition != null) {
      double distance = Geolocator.distanceBetween(
        previousPosition.latitude,
        previousPosition.longitude,
        position.latitude,
        position.longitude,
      ) / 1000; // Convert to kilometers

      _totalDistance += distance;
    }

    // Check geofences
    _checkGeofences(position);

    // Send real-time update
    _socket?.emit('location_update', {
      'tripId': _currentTripId,
      'position': {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'speed': position.speed,
        'heading': position.heading,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'timestamp': position.timestamp?.toIso8601String(),
      },
      'totalDistance': _totalDistance,
      'timestamp': DateTime.now().toIso8601String(),
    });

    notifyListeners();
  }

  // Geofencing functionality
  void addGeofence(GeofenceZone zone) {
    _geofences.add(zone);
    notifyListeners();
  }

  void removeGeofence(String zoneId) {
    _geofences.removeWhere((zone) => zone.id == zoneId);
    notifyListeners();
  }

  void _checkGeofences(Position position) {
    for (GeofenceZone zone in _geofences) {
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        zone.latitude,
        zone.longitude,
      );

      bool isInside = distance <= zone.radius;
      bool wasTriggered = _triggeredGeofences.contains(zone.id);

      if (zone.triggerOnEntry && isInside && !wasTriggered) {
        _triggerGeofence(zone, 'ENTER', position);
      } else if (zone.triggerOnExit && !isInside && wasTriggered) {
        _triggerGeofence(zone, 'EXIT', position);
      }
    }
  }

  void _triggerGeofence(GeofenceZone zone, String action, Position position) {
    if (action == 'ENTER') {
      _triggeredGeofences.add(zone.id);
    } else {
      _triggeredGeofences.remove(zone.id);
    }

    // Send geofence event
    _socket?.emit('geofence_event', {
      'tripId': _currentTripId,
      'zoneId': zone.id,
      'zoneName': zone.name,
      'action': action,
      'position': {
        'latitude': position.latitude,
        'longitude': position.longitude,
      },
      'timestamp': DateTime.now().toIso8601String(),
    });

    _showNotification(
      'Geofence Alert',
      '$action ${zone.name}',
    );
  }

  // Handle socket events
  void _handleTripUpdate(dynamic data) {
    // Update trip data from server
    if (data['tripId'] == _currentTripId) {
      _tripData.addAll(Map<String, dynamic>.from(data));
      notifyListeners();
    }
  }

  void _handleGeofenceAlert(dynamic data) {
    _showNotification(
      'Geofence Alert',
      data['message'] ?? 'Geofence event occurred',
    );
  }

  // Utility methods
  Future<bool> _checkLocationPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<void> _showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'tracking_channel',
      'Location Tracking',
      channelDescription: 'Notifications for GPS tracking updates',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(0, title, body, details);
  }

  // Persistence
  Future<void> _saveTrackingState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_tracking', _isTracking);
    await prefs.setString('current_trip_id', _currentTripId ?? '');
    await prefs.setString('trip_data', jsonEncode(_tripData));
  }

  Future<void> _loadTrackingState() async {
    final prefs = await SharedPreferences.getInstance();
    _isTracking = prefs.getBool('is_tracking') ?? false;
    _currentTripId = prefs.getString('current_trip_id');
    
    String? tripDataString = prefs.getString('trip_data');
    if (tripDataString != null) {
      _tripData = Map<String, dynamic>.from(jsonDecode(tripDataString));
    }

    if (_isTracking && _currentTripId != null) {
      // Resume tracking
      await startTracking(_currentTripId!, tripData: _tripData);
    }
  }

  Future<void> _clearTrackingState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_tracking');
    await prefs.remove('current_trip_id');
    await prefs.remove('trip_data');
  }

  // Cleanup
  @override
  void dispose() {
    stopTracking();
    _socket?.disconnect();
    super.dispose();
  }
}

class GeofenceZone {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius;
  final bool triggerOnEntry;
  final bool triggerOnExit;
  final String? description;

  GeofenceZone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.triggerOnEntry = true,
    this.triggerOnExit = true,
    this.description,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'radius': radius,
    'triggerOnEntry': triggerOnEntry,
    'triggerOnExit': triggerOnExit,
    'description': description,
  };

  factory GeofenceZone.fromJson(Map<String, dynamic> json) => GeofenceZone(
    id: json['id'],
    name: json['name'],
    latitude: json['latitude'],
    longitude: json['longitude'],
    radius: json['radius'],
    triggerOnEntry: json['triggerOnEntry'] ?? true,
    triggerOnExit: json['triggerOnExit'] ?? true,
    description: json['description'],
  );
} 