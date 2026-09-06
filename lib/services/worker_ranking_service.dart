import 'dart:math';
import '../models/user_model.dart';
import 'location_service.dart';

class RankedWorker {
  final WorkerModel worker;
  final double matchScore; // 0 to 100
  final double? distanceInKm;
  final String recommendationReasonEn;
  final String recommendationReasonUrdu;
  final String recommendationReasonRoman;

  RankedWorker({
    required this.worker,
    required this.matchScore,
    this.distanceInKm,
    required this.recommendationReasonEn,
    required this.recommendationReasonUrdu,
    required this.recommendationReasonRoman,
  });
}

class WorkerRankingService {
  final LocationService _locationService = LocationService();

  /// Extract numeric years of experience from string like "5 Years", "3+", "10 yrs"
  double _parseExperienceYears(String experience) {
    if (experience.trim().isEmpty) return 1.0;
    final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(experience);
    if (match != null) {
      return double.tryParse(match.group(1)!) ?? 1.0;
    }
    return 1.0;
  }

  /// Rank available workers based on distance, rating, experience, and service match
  Future<List<RankedWorker>> rankWorkers({
    required List<WorkerModel> workers,
    required String targetService,
    double? userLat,
    double? userLng,
    String? userLocationAddress,
  }) async {
    // 1. Resolve user coordinates if not directly provided
    double? finalUserLat = userLat;
    double? finalUserLng = userLng;

    if ((finalUserLat == null || finalUserLng == null) &&
        userLocationAddress != null &&
        userLocationAddress.trim().isNotEmpty) {
      final coords = await _locationService.geocodeAddress(userLocationAddress);
      if (coords != null) {
        finalUserLat = coords['latitude'];
        finalUserLng = coords['longitude'];
      }
    }

    final List<RankedWorker> rankedList = [];

    for (final worker in workers) {
      // Must be approved and match service type
      if (worker.approvalStatus != 'approved') continue;
      
      final isServiceMatch = targetService.isEmpty ||
          worker.serviceType.toLowerCase().contains(targetService.toLowerCase()) ||
          targetService.toLowerCase().contains(worker.serviceType.toLowerCase());

      if (!isServiceMatch) continue;

      // 2. Calculate Distance
      double? distanceKm;
      double workerLat = worker.latitude;
      double workerLng = worker.longitude;

      if ((workerLat == 0.0 || workerLng == 0.0) && worker.location.isNotEmpty) {
        final workerCoords = await _locationService.geocodeAddress(worker.location);
        if (workerCoords != null) {
          workerLat = workerCoords['latitude'] ?? 0.0;
          workerLng = workerCoords['longitude'] ?? 0.0;
        }
      }

      if (finalUserLat != null && finalUserLng != null && workerLat != 0.0 && workerLng != 0.0) {
        distanceKm = _locationService.calculateDistance(
          finalUserLat,
          finalUserLng,
          workerLat,
          workerLng,
        );
      }

      // 3. Multi-Factor AI Score (0 - 100)
      // Rating: 0 - 35 pts
      final ratingScore = (worker.rating.clamp(0.0, 5.0) / 5.0) * 35.0;

      // Experience: 0 - 25 pts
      final expYears = _parseExperienceYears(worker.experience);
      final expScore = min(expYears * 3.5, 25.0);

      // Distance: 0 - 25 pts (closer is higher score)
      double distScore = 15.0; // neutral default if distance unknown
      if (distanceKm != null) {
        distScore = max(0.0, 25.0 - (distanceKm * 1.2));
      }

      // Availability: 0 - 15 pts
      final availScore = worker.availability ? 15.0 : 0.0;

      final totalScore = ratingScore + expScore + distScore + availScore;

      // 4. Generate Natural Factual Explanations
      final reasonEn = _buildReasonEn(worker, distanceKm, expYears);
      final reasonUrdu = _buildReasonUrdu(worker, distanceKm, expYears);
      final reasonRoman = _buildReasonRoman(worker, distanceKm, expYears);

      rankedList.add(
        RankedWorker(
          worker: worker,
          matchScore: double.parse(totalScore.toStringAsFixed(1)),
          distanceInKm: distanceKm != null ? double.parse(distanceKm.toStringAsFixed(1)) : null,
          recommendationReasonEn: reasonEn,
          recommendationReasonUrdu: reasonUrdu,
          recommendationReasonRoman: reasonRoman,
        ),
      );
    }

    // Sort by match score descending (highest score first)
    rankedList.sort((a, b) => b.matchScore.compareTo(a.matchScore));

    return rankedList;
  }

  String _buildReasonEn(WorkerModel worker, double? distanceKm, double expYears) {
    final parts = <String>[];
    if (worker.rating > 0) {
      parts.add('⭐ ${worker.rating.toStringAsFixed(1)} rating');
    }
    if (worker.experience.isNotEmpty) {
      parts.add('${worker.experience} exp');
    }
    if (distanceKm != null) {
      parts.add('📍 ${distanceKm.toStringAsFixed(1)} km away');
    }
    if (worker.availability) {
      parts.add('🟢 Online now');
    }
    return parts.isNotEmpty ? parts.join(' • ') : 'Verified Kaamwala Expert';
  }

  String _buildReasonUrdu(WorkerModel worker, double? distanceKm, double expYears) {
    final parts = <String>[];
    if (worker.rating > 0) {
      parts.add('⭐ ${worker.rating.toStringAsFixed(1)} ریٹنگ');
    }
    if (worker.experience.isNotEmpty) {
      parts.add('${worker.experience} تجربہ');
    }
    if (distanceKm != null) {
      parts.add('📍 ${distanceKm.toStringAsFixed(1)} کلومیٹر دور');
    }
    if (worker.availability) {
      parts.add('🟢 ابھی آن لائن');
    }
    return parts.isNotEmpty ? parts.join(' • ') : 'تصدیق شدہ ماہر';
  }

  String _buildReasonRoman(WorkerModel worker, double? distanceKm, double expYears) {
    final parts = <String>[];
    if (worker.rating > 0) {
      parts.add('⭐ ${worker.rating.toStringAsFixed(1)} rating');
    }
    if (worker.experience.isNotEmpty) {
      parts.add('${worker.experience} tajurba');
    }
    if (distanceKm != null) {
      parts.add('📍 ${distanceKm.toStringAsFixed(1)} km door');
    }
    if (worker.availability) {
      parts.add('🟢 Abhi Online');
    }
    return parts.isNotEmpty ? parts.join(' • ') : 'Verified Expert';
  }
}
