import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT White Cane',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF2D336B)),
      ),
      home: const MyHomePage(title: 'IoT White Cane'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final MapController _mapController = MapController();
  double latitude = 0.0;
  double longitude = 0.0;
  List<Marker> _markers = [];
  double _currentZoom = 18.0;

  @override
  void initState() {
    super.initState();

    // ดึงข้อมูลจาก Firebase Realtime Database
    DatabaseReference locationRef = FirebaseDatabase.instance.ref("location");

    // ใช้ onValue เพื่อดึงข้อมูล
    locationRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        setState(() {
          latitude = data['latitude'] ?? 0.0;
          longitude = data['longitude'] ?? 0.0;
        });

        // เพิ่ม Marker
        _updateMarker(latitude, longitude);
      }
    });
  }

  // ฟังก์ชันเพิ่ม Marker
  void _updateMarker(double latitude, double longitude) {
    setState(() {
      _markers = [
        Marker(
          point: LatLng(latitude, longitude),
          builder: (ctx) => const Icon(Icons.location_on, color: Color(0XFFB4232E), size: 40),
        ),
      ];
    });
  }

  void _onMapZoomChanged() {
    double maxZoom = 18.0;
    double minZoom = 0.0;

    double zoom = 15.0;

    if (zoom > maxZoom) {
      _mapController.move(_mapController.center, maxZoom);
      _currentZoom = maxZoom;
    } else if (zoom < minZoom) {
      _mapController.move(_mapController.center, minZoom);
      _currentZoom = minZoom;
    } else {
      _currentZoom = zoom;
    }
  }

  void _goToMarker() {
    if (latitude != 0.0 && longitude != 0.0) {
      _mapController.move(LatLng(latitude, longitude), 18.0); // ซูมไปที่ตำแหน่ง
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF263666),
        title: Text(widget.title),
        centerTitle: true,
        titleTextStyle: TextStyle(color: Color(0xFFECF4FC), fontSize: 20),
      ),
      body: Stack(
        children:[
          (latitude != 0.0 && longitude != 0.0)
          ? FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: LatLng(latitude, longitude),
                zoom: _currentZoom,
                maxZoom: 18.0,
                onPositionChanged: (position, hasGesture) {
                    if (hasGesture) {
                      _onMapZoomChanged();
                    }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: _markers,
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()), 

        Positioned(
            bottom: 30,
            right: 30,
            child: FloatingActionButton(
              onPressed: _goToMarker,
              child: Icon(Icons.my_location, color: Color(0xFFECF4FC),),
              tooltip: "ไปยังตำแหน่ง Marker",
              backgroundColor: Color(0xFF263666),
            ),
          ),
        ],
      ),
    );
  }
}
