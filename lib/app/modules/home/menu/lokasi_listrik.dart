import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:customer_bengkelly/app/componen/color.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/data_endpoint/lokasilistrik.dart';
import '../../../data/endpoint.dart';

class LokasiListrik1 extends StatefulWidget {
  const LokasiListrik1({super.key});

  @override
  State<LokasiListrik1> createState() => _LokasiListrik1State();
}

class _LokasiListrik1State extends State<LokasiListrik1> {
  late GoogleMapController _controller;
  Position? _currentPosition;
  List<Marker> _markers = [];
  List<DatachargingStation> _locationData = [];
  List<DatachargingStation> _filteredLocationData = [];
  DatachargingStation? _nearestLocation;
  final PanelController _panelController = PanelController();
  String _currentAddress = 'Mengambil lokasi...';
  BitmapDescriptor? _customIcon;
  TextEditingController _searchController = TextEditingController();
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadCustomIcon();
    _searchController.addListener(_filterLocations);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterLocations);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomIcon() async {
    _customIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(48, 48)),
      'assets/icons/dropcar2.png',
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      print('Current position: $_currentPosition');
      _getAddressFromLatLng();
      setState(() {});
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  Future<void> _getAddressFromLatLng() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentPosition!.latitude, _currentPosition!.longitude);

      Placemark place = placemarks[0];

      setState(() {
        _currentAddress = "${place.locality}, ${place.subAdministrativeArea}";
      });
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  Future<void> _checkPermissions() async {
    var status = await Permission.location.status;
    print('Permission status: $status');
    if (status.isGranted) {
      print('Permission already granted');
      await _getCurrentLocation();
      await _fetchLocations();
    } else {
      var requestedStatus = await Permission.location.request();
      print('Requested permission status: $requestedStatus');
      if (requestedStatus.isGranted) {
        print('Permission granted');
        await _getCurrentLocation();
        await _fetchLocations();
      } else {
        print('Permission denied');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Permission denied'),
        ));
      }
    }
  }

  Future<void> _fetchLocations() async {
    try {
      final lokasi = await API.LokasiListrikID();
      if (lokasi.datachargingStation != null && _currentPosition != null) {
        _locationData = lokasi.datachargingStation!;
        _filteredLocationData = List.from(_locationData);
        for (var data in lokasi.datachargingStation!) {
          final location = data.geometry?.location;
          if (location != null && location.lat != null && location.lng != null) {
            final lat = double.tryParse(location.lat!);
            final lng = double.tryParse(location.lng!);
            if (lat != null && lng != null) {
              _addMarker(lat, lng, data);
            } else {
              print('Invalid lat/lng values: lat=${location.lat}, lng=${location.lng}');
              _addFallbackMarker(data);
            }
          } else {
            print('Null lat/lng: lat=${location?.lat}, lng=${location?.lng}');
            _addFallbackMarker(data);
          }
        }
        _findNearestLocation();
        setState(() {});
      } else {
        print('Failed to fetch locations or current position is null');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to fetch locations or current position is null'),
        ));
      }
    } catch (e) {
      print('Error fetching locations: $e');
    }
  }

  void _addMarker(double lat, double lng, DatachargingStation data) {
    final latLng = LatLng(lat, lng);
    final distance = _calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      latLng.latitude,
      latLng.longitude,
    );
    final travelTime = _calculateTravelTime(distance); // Calculate travel time
    print('Adding marker at: $latLng');
    _markers.add(
      Marker(
        markerId: MarkerId('${data.name}'),
        position: latLng,
        icon: _customIcon ?? BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(
          title: data.name,
          snippet: 'Jarak: ${distance.toStringAsFixed(2)} km\nWaktu tempuh: ${travelTime.toStringAsFixed(0)} min',
        ),
      ),
    );
  }

  void _addFallbackMarker(DatachargingStation data) {
    final latLng = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    print('Adding fallback marker at: $latLng');
    _markers.add(
      Marker(
        markerId: MarkerId('${data.name}'),
        position: latLng,
        icon: _customIcon ?? BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(
          title: data.name,
          snippet: 'Invalid coordinates provided',
        ),
      ),
    );
  }

  double _calculateDistance(double startLatitude, double startLongitude, double endLatitude, double endLongitude) {
    return Geolocator.distanceBetween(startLatitude, startLongitude, endLatitude, endLongitude) / 1000;
  }

  double _calculateTravelTime(double distance) {
    const averageSpeed = 50.0; // Average speed in km/h
    return (distance / averageSpeed) * 60; // Convert hours to minutes
  }

  void _moveCamera(double lat, double lng) {
    _controller.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(lat, lng),
      ),
    );
  }

  void _filterLocations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLocationData = _locationData.where((location) {
        return location.name?.toLowerCase().contains(query) ?? false;
      }).toList();
    });
  }

  void _findNearestLocation() {
    double minDistance = double.infinity;
    DatachargingStation? nearestLocation;

    for (var location in _locationData) {
      final lat = double.tryParse(location.geometry?.location?.lat ?? '');
      final lng = double.tryParse(location.geometry?.location?.lng ?? '');
      if (lat != null && lng != null) {
        final distance = _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          lat,
          lng,
        );
        if (distance < minDistance) {
          minDistance = distance;
          nearestLocation = location;
        }
      }
    }

    setState(() {
      _nearestLocation = nearestLocation;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cities = _locationData.map((e) => e.name?.split(' ')[0] ?? '').toSet().toList();
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
        ),
        title: Row(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lokasi Saat ini', style: GoogleFonts.nunito(fontSize: 12)),
                Text(_currentAddress, style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
      body: _currentPosition == null
          ? Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: MyColors.appPrimaryColor,
            ),
            SizedBox(height: 10),
            Text('Sedang memuat lokasi...'),
          ],
        ),
      )
          : Stack(
        children: [
          GoogleMap(
            mapType: MapType.terrain,
            zoomGesturesEnabled: true,
            mapToolbarEnabled: true,
            compassEnabled: true,
            zoomControlsEnabled: true,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (controller) {
              _controller = controller;
              setState(() {
                _markers.forEach((marker) {
                  print('Marker added to map: ${marker.markerId}');
                });
              });
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              zoom: 14,
            ),
            markers: Set<Marker>.of(_markers),
            padding: EdgeInsets.only(bottom: 240), // Tambahkan padding di sini
          ),
          Positioned(
            top: 10.0,
            left: 15.0,
            right: 15.0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.0),
              margin: EdgeInsets.only(right: 40),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 5,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Pencarian...',
                      border: InputBorder.none,
                      icon: Icon(Icons.search),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    child:
                  DropdownButton<String>(
                    isExpanded: true,
                    hint: Text('Pilih berdasarkan Kota', style: GoogleFonts.nunito(),),
                    value: _selectedCity,
                    items: cities.map((city) {
                      return DropdownMenuItem<String>(
                        value: city,
                        child: Text(city),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCity = value;
                        _filteredLocationData = _locationData.where((location) {
                          return location.name?.startsWith(value ?? '') ?? false;
                        }).toList();
                      });
                    },
                  ),
                  ),
                ],
              ),
            ),
          ),
          SlidingUpPanel(
            controller: _panelController,
            panel: _buildSlidingPanel(),
            minHeight: 230,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            parallaxEnabled: true,
            parallaxOffset: 0.5,
          ),
          if (_nearestLocation != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(10),
                color: Colors.white,
                child: Text(
                  'Terdekat: ${_nearestLocation!.name} (${_calculateDistance(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                    double.parse(_nearestLocation!.geometry!.location!.lat!),
                    double.parse(_nearestLocation!.geometry!.location!.lng!),
                  ).toStringAsFixed(2)} km)',
                  style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSlidingPanel() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 10),
          height: 5,
          width: 40,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: _filteredLocationData.map((data) {
                final location = data.geometry?.location;
                final lat = location?.lat != null ? double.tryParse(location!.lat!) : null;
                final lng = location?.lng != null ? double.tryParse(location!.lng!) : null;
                if (lat != null && lng != null) {
                  final distance = _calculateDistance(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                    lat,
                    lng,
                  );
                  final travelTime = _calculateTravelTime(distance);

                  return InkWell(
                    onTap: () {
                      _moveCamera(lat, lng);
                      _panelController.close();
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: MyColors.bgform,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data.name ?? 'Unknown', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                                SizedBox(height: 5),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: MyColors.bgform,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Tegangan Recharge Stasiun ', style: GoogleFonts.nunito(fontWeight: FontWeight.normal)),
                                      SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Icon(Icons.ev_station_rounded, color: Colors.green,),
                                          SizedBox(width: 5,),
                                          Expanded(
                                            child: Text(
                                              data.power ?? 'Unknown',
                                              style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                                              softWrap: true,
                                              maxLines: 2, // Set to your desired max lines
                                              overflow: TextOverflow.ellipsis, // Handles overflow
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/icons/dropcar2.png',
                                    width: 30,
                                    height: 30,
                                  ),
                                  Column(
                                    children: [
                                      Text('${distance.toStringAsFixed(2)} km'),
                                      Text('${travelTime.toStringAsFixed(0)} min'),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              InkWell(
                                onTap: () async {
                                  final String googleMapsUrl = "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving";
                                  if (await canLaunch(googleMapsUrl)) {
                                    await launch(googleMapsUrl);
                                  } else {
                                    throw 'Could not launch $googleMapsUrl';
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        spreadRadius: 5,
                                        blurRadius: 10,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Text(' Directions', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                                      IconButton(
                                        icon: Icon(Icons.directions),
                                        onPressed: () async {
                                          final String googleMapsUrl = "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving";
                                          if (await canLaunch(googleMapsUrl)) {
                                            await launch(googleMapsUrl);
                                          } else {
                                            throw 'Could not launch $googleMapsUrl';
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  print('Invalid lat/lng values in ListView: lat=${location?.lat}, lng=${location?.lng}');
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: MyColors.bgform,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data.name ?? 'Unknown', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                        Text('Invalid coordinates'),
                      ],
                    ),
                  );
                }
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
