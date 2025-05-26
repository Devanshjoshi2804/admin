import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freight_flow_flutter/api/api_service.dart';

/// Provider for the existing API service
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
}); 