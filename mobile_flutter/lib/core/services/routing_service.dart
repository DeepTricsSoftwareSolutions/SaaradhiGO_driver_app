import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';

class RoutingService {
  final Dio _dio = Dio();
  
  // Public OSRM routing server
  static const String _osrmBaseUrl = 'http://router.project-osrm.org/route/v1/driving/';

  /// Fetches the route polyline between two coordinates, along with ETA and Distance
  Future<Map<String, dynamic>?> getRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    try {
      final s = '${start.longitude},${start.latitude}';
      final e = '${end.longitude},${end.latitude}';
      final url = '$_osrmBaseUrl$s;$e?overview=full&geometries=geojson';
      
      final response = await _dio.get(url);
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry']['coordinates'] as List;
          
          List<LatLng> polyline = geometry.map((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();

          return {
            'polyline': polyline,
            'distanceMeters': route['distance'],
            'durationSeconds': route['duration'],
          };
        }
      }
    } catch (e) {
      debugPrint('[RoutingService] Error fetching route: \$e');
    }
    return null;
  }
}
