import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/worker_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../widgets/job_detail_screen.dart';
import 'package:kaamwala/views/widgets/custom_loading_indicator.dart';
import '../../models/job_model.dart';

class FindJobsScreen extends ConsumerStatefulWidget {
  const FindJobsScreen({super.key});

  @override
  ConsumerState<FindJobsScreen> createState() => _FindJobsScreenState();
}

class _FindJobsScreenState extends ConsumerState<FindJobsScreen> with TickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();
  final ScrollController _scrollController = ScrollController();

  Position? _currentPosition;
  double _selectedRadius = 10.0;
  JobModel? _selectedJob;

  static const ll.LatLng _defaultCenter = ll.LatLng(31.5204, 74.3587); // Lahore Center

  @override
  void initState() {
    super.initState();
    _fetchWorkerLocation();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchWorkerLocation() async {
    if (!mounted) return;

    try {
      final pos = await _locationService.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = pos;
        });
        _animatedMove(ll.LatLng(pos.latitude, pos.longitude), 13.5);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentPosition = Position(
            latitude: _defaultCenter.latitude,
            longitude: _defaultCenter.longitude,
            timestamp: DateTime.now(),
            accuracy: 100,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        });
      }
    }
  }

  void _animatedMove(ll.LatLng destLocation, double destZoom) {
    try {
      _mapController.move(destLocation, destZoom);
    } catch (_) {}
  }

  List<JobModel> _filterJobs(List<JobModel> rawJobs) {
    final workerLat = _currentPosition?.latitude ?? _defaultCenter.latitude;
    final workerLng = _currentPosition?.longitude ?? _defaultCenter.longitude;

    final List<JobModel> filtered = [];

    for (final job in rawJobs) {
      if (job.latitude == 0.0 && job.longitude == 0.0) {
        continue;
      }

      final distanceKm = _locationService.calculateDistance(
        workerLat,
        workerLng,
        job.latitude,
        job.longitude,
      );

      if (distanceKm <= _selectedRadius) {
        filtered.add(job);
      }
    }

    filtered.sort((a, b) {
      final distA = _locationService.calculateDistance(workerLat, workerLng, a.latitude, a.longitude);
      final distB = _locationService.calculateDistance(workerLat, workerLng, b.latitude, b.longitude);
      return distA.compareTo(distB);
    });

    return filtered;
  }

  List<Marker> _buildMapMarkers(List<JobModel> jobs, bool isDark) {
    final List<Marker> markers = [];
    final workerLat = _currentPosition?.latitude ?? _defaultCenter.latitude;
    final workerLng = _currentPosition?.longitude ?? _defaultCenter.longitude;

    // 1. Worker Location Pin (Green Beacon)
    markers.add(
      Marker(
        point: ll.LatLng(workerLat, workerLng),
        width: 80,
        height: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                '📍 YOU',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green, width: 4),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // 2. Job Markers
    for (final job in jobs) {
      final isSelected = _selectedJob?.jobId == job.jobId;

      markers.add(
        Marker(
          point: ll.LatLng(job.latitude, job.longitude),
          width: 130,
          height: 72,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedJob = job;
              });
              _animatedMove(ll.LatLng(job.latitude, job.longitude), 14.5);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF009688)
                          : (isDark ? Colors.white24 : Colors.black12),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.work, size: 11, color: Color(0xFF009688)),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          job.serviceType,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            color: isSelected
                                ? const Color(0xFF009688)
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: isSelected ? 36 : 30,
                  height: isSelected ? 36 : 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF009688),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF009688).withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.work,
                    color: Colors.white,
                    size: isSelected ? 18 : 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final openJobsAsync = ref.watch(openJobsStreamProvider);
    final workerAsync = ref.watch(workerProfileStreamProvider);
    final currentWorker = workerAsync.valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nearby Job Marketplace',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _fetchWorkerLocation();
              ref.invalidate(openJobsStreamProvider);
            },
          ),
        ],
      ),
      body: openJobsAsync.when(
        data: (allJobs) {
          final nearbyJobs = _filterJobs(allJobs);
          final markers = _buildMapMarkers(nearbyJobs, isDark);
          final workerLat = _currentPosition?.latitude ?? _defaultCenter.latitude;
          final workerLng = _currentPosition?.longitude ?? _defaultCenter.longitude;

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  flex: 5,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFF009688).withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: ll.LatLng(workerLat, workerLng),
                              initialZoom: 13.5,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.all,
                              ),
                              onTap: (_, _) => setState(() => _selectedJob = null),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.kaamwala.app',
                                maxZoom: 19,
                              ),
                              CircleLayer(
                                circles: [
                                  CircleMarker(
                                    point: ll.LatLng(workerLat, workerLng),
                                    radius: _selectedRadius * 1000,
                                    useRadiusInMeter: true,
                                    color: const Color(0xFF009688).withValues(alpha: 0.08),
                                    borderColor: const Color(0xFF009688).withValues(alpha: 0.45),
                                    borderStrokeWidth: 1.5,
                                  ),
                                ],
                              ),
                              MarkerLayer(markers: markers),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                )
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.my_location, color: Color(0xFF009688)),
                              onPressed: () {
                                _animatedMove(ll.LatLng(workerLat, workerLng), 14.5);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${nearbyJobs.length} Jobs within ${_selectedRadius.toInt()}km',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<double>(
                            value: _selectedRadius,
                            items: [5.0, 10.0, 25.0, 50.0]
                                .map((r) => DropdownMenuItem(value: r, child: Text('${r.toInt()} km')))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedRadius = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: nearbyJobs.isEmpty
                      ? Center(child: Text('No open jobs nearby in your category.', style: TextStyle(color: Colors.grey)))
                      : ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: nearbyJobs.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final job = nearbyJobs[index];
                            final isSelected = _selectedJob?.jobId == job.jobId;

                            if (currentWorker != null && !job.viewedByWorkerIds.contains(currentWorker.workerId)) {
                              FirestoreService().recordJobView(job.jobId, currentWorker.workerId);
                            }
                            final hasApplied = currentWorker != null && job.applicants.contains(currentWorker.workerId);

                            return GestureDetector(
                              onTap: () {
                                setState(() => _selectedJob = job);
                                _animatedMove(ll.LatLng(job.latitude, job.longitude), 14.5);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF009688) : (isDark ? Colors.white10 : Colors.black12),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    if (isSelected)
                                      BoxShadow(
                                        color: const Color(0xFF009688).withValues(alpha: 0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          job.serviceType.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF009688),
                                          ),
                                        ),
                                        Text(
                                          DateFormat('MMM dd').format(job.scheduledDate),
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      job.userName.isNotEmpty ? job.userName : 'Customer',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    if (job.budgetRange.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text('Budget: ${job.budgetRange}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                    ],
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => JobDetailScreen(job: job, isAdmin: false),
                                                ),
                                              );
                                            },
                                            child: const Text('View Details'),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: hasApplied ? null : () async {
                                              if (currentWorker != null) {
                                                // apply logic instead of accept
                                                await FirestoreService().updateJob(job.jobId, {
                                                  'applicants': FieldValue.arrayUnion([currentWorker.workerId])
                                                });
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Applied successfully!')),
                                                  );
                                                }
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF009688),
                                              foregroundColor: Colors.white,
                                            ),
                                            child: Text(hasApplied ? 'Applied' : 'Apply for Job'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CustomLoadingIndicator()),
        error: (err, _) => Center(child: SelectableText('Error: $err')),
      ),
    );
  }
}
