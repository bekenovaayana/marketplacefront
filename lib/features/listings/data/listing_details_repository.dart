import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/core/network/dio_client.dart';
import 'package:marketplace_frontend/features/listings/models/listing_detail.dart';

final listingDetailsRepositoryProvider = Provider<ListingDetailsRepository>((ref) {
  return ListingDetailsRepository(ref.watch(dioProvider));
});

class ListingDetailsRepository {
  ListingDetailsRepository(this._dio);

  final Dio _dio;

  Future<ListingDetail> getById(int id) async {
    final response = await _dio.get('/listings/$id');
    return ListingDetail.fromJson(response.data as Map<String, dynamic>);
  }
}
