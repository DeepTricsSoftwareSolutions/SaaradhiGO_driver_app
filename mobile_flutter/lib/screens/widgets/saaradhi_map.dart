
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme.dart';

// ... (existing code omitted for brevity in thought, but I will providing full replacement chunk)

/// Real Telangana map using OpenStreetMap tiles (no API key needed).
/// Shows Hyderabad, Warangal, Karimnagar, Nizamabad, etc.
/// Animated driver vehicles (bikes, autos, cars) move around the map.
class SaaradhiMap extends StatefulWidget {
  final bool isOnline;
  final LatLng? driverLocation;
  final List<LatLng>? currentRoute;
  
  const SaaradhiMap({
    super.key, 
    required this.isOnline,
    this.driverLocation,
    this.currentRoute,
  });

  @override
  State<SaaradhiMap> createState() => _SaaradhiMapState();
}

class _SaaradhiMapState extends State<SaaradhiMap>
    with TickerProviderStateMixin {
  // Center on Telangana (Hyderabad) fallback
  static const LatLng _hyderabad = LatLng(17.3850, 78.4867);
  final MapController _mapController = MapController();

  late AnimationController _vehicleAnimCtrl;

  // Simulated vehicle fleet across Telangana
  final List<_VehicleData> _vehicles = [
    // Hyderabad cluster
    _VehicleData(const LatLng(17.3850, 78.4867), const LatLng(17.3920, 78.4930), 'car'),
    _VehicleData(const LatLng(17.4448, 78.3789), const LatLng(17.4400, 78.3720), 'bike'),
    _VehicleData(const LatLng(17.4501, 78.3800), const LatLng(17.4550, 78.3860), 'auto'),
    _VehicleData(const LatLng(17.3616, 78.4747), const LatLng(17.3580, 78.4810), 'bike'),
    _VehicleData(const LatLng(17.4239, 78.4738), const LatLng(17.4300, 78.4800), 'car'),
    _VehicleData(const LatLng(17.3950, 78.5100), const LatLng(17.3880, 78.5050), 'auto'),
    // Warangal
    _VehicleData(const LatLng(17.9784, 79.5941), const LatLng(17.9830, 79.5990), 'bike'),
    _VehicleData(const LatLng(17.9710, 79.5800), const LatLng(17.9760, 79.5860), 'auto'),
    // Karimnagar
    _VehicleData(const LatLng(18.4386, 79.1288), const LatLng(18.4440, 79.1340), 'car'),
    _VehicleData(const LatLng(18.4300, 79.1200), const LatLng(18.4360, 79.1260), 'bike'),
    // Nizamabad
    _VehicleData(const LatLng(18.6725, 78.0941), const LatLng(18.6780, 78.1000), 'car'),
    // Khammam
    _VehicleData(const LatLng(17.2473, 80.1514), const LatLng(17.2530, 80.1570), 'auto'),
  ];

  @override
  void initState() {
    super.initState();
    _vehicleAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant SaaradhiMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.driverLocation != null && oldWidget.driverLocation != widget.driverLocation) {
        _mapController.move(widget.driverLocation!, 15.0);
    }
  }

  @override
  void dispose() {
    _vehicleAnimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── 3D Subtle Tilt ──
        Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0008)
            ..rotateX(0.12),
          alignment: FractionalOffset.center,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.driverLocation ?? _hyderabad,
              initialZoom: widget.driverLocation != null ? 15.0 : 7.5,
              minZoom: 5,
              maxZoom: 18,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.saaradhigo.driver',
                tileBuilder: _darkTileBuilder,
              ),

              if (widget.currentRoute != null && widget.currentRoute!.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: widget.currentRoute!,
                      color: AppTheme.primaryGold,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              
              if (widget.isOnline)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.driverLocation ?? _hyderabad,
                      width: 120,
                      height: 120,
                      child: _PulsingMarker(),
                    ),
                  ],
                ),

              AnimatedBuilder(
                animation: _vehicleAnimCtrl,
                builder: (context, _) {
                  return MarkerLayer(
                    markers: _vehicles.map((v) {
                      final t = _vehicleAnimCtrl.value;
                      final lat = v.from.latitude + (v.to.latitude - v.from.latitude) * t;
                      final lng = v.from.longitude + (v.to.longitude - v.from.longitude) * t;
                      return Marker(
                        point: LatLng(lat, lng),
                        width: 40,
                        height: 40,
                        child: _VehicleMarker(type: v.type),
                      );
                    }).toList(),
                  );
                },
              ),

              MarkerLayer(
                markers: _buildCityLabels(),
              ),
            ],
          ),
        ),

        // ── Static Overlays (Compass, etc.) ──
        Positioned(
          right: 16,
          top: 100,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: const Icon(Icons.explore, color: AppTheme.primaryGold, size: 20),
          ),
        ),
      ],
    );
  }

  /// Applies a dark matrix filter to the map tiles
  Widget _darkTileBuilder(
      BuildContext context, Widget tileWidget, TileImage tile) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        0.35, 0, 0, 0, 0,
        0, 0.38, 0, 0, 0,
        0, 0, 0.32, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: tileWidget,
    );
  }

  List<Marker> _buildCityLabels() {
    const cities = [
      ('Hyderabad', 17.3850, 78.4867),
      ('Warangal', 17.9784, 79.5941),
      ('Karimnagar', 18.4386, 79.1288),
      ('Nizamabad', 18.6725, 78.0941),
      ('Khammam', 17.2473, 80.1514),
      ('Nalgonda', 17.0520, 79.2671),
      ('Mahbubnagar', 16.7488, 77.9869),
      ('Adilabad', 19.6640, 78.5320),
    ];

    return cities.map((city) {
      return Marker(
        point: LatLng(city.$2, city.$3),
        width: 100,
        height: 26,
        alignment: Alignment.topCenter,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFFC9A227).withValues(alpha: 0.2),
              width: 0.8,
            ),
          ),
          child: Text(
            city.$1,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFC9A227),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _VehicleData {
  final LatLng from;
  final LatLng to;
  final String type; // 'car', 'bike', 'auto'
  _VehicleData(this.from, this.to, this.type);
}

class _VehicleMarker extends StatelessWidget {
  final String type;
  const _VehicleMarker({required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (type) {
      case 'bike':
        icon = Icons.electric_moped;
        color = const Color(0xFF4FC3F7); // Light blue for bikes
        break;
      case 'auto':
        icon = Icons.electric_rickshaw;
        color = const Color(0xFFFFB300); // Amber for autos
        break;
      default:
        icon = Icons.directions_car;
        color = const Color(0xFFC9A227); // Gold for cars
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(color: color, width: 1.5),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _PulsingMarker extends StatefulWidget {
  @override
  State<_PulsingMarker> createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<_PulsingMarker> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
    _scale = Tween<double>(begin: 0.1, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = Tween<double>(begin: 0.6, end: 0.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: _opacity.value,
              child: Transform.scale(
                scale: _scale.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(color: AppTheme.primaryGold, shape: BoxShape.circle),
                ),
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppTheme.primaryGold,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(color: AppTheme.primaryGold.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
