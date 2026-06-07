import 'package:flutter/material.dart';
import '../models/ride.dart';
import '../models/bus_ticket.dart';
import 'api_client.dart';

class SearchProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  List<Ride> _rides = [];
  List<BusTicket> _busTickets = [];
  List<String> _cities = [];
  bool _isLoading = false;
  String _activeTab = 'buses'; // 'rides' | 'buses'

  List<Ride> get rides => _rides;
  List<BusTicket> get busTickets => _busTickets;
  List<String> get cities => _cities;
  bool get isLoading => _isLoading;
  String get activeTab => _activeTab;

  void setActiveTab(String tab) {
    _activeTab = tab;
    fetchCities();
    search();
    notifyListeners();
  }

  Future<void> fetchCities() async {
    try {
      final type = _activeTab == 'buses' ? 'bus' : 'ride';
      final response = await _apiClient.get('/general/cities', queryParameters: {'type': type});
      if (response.statusCode == 200) {
        _cities = List<String>.from(response.data);
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching cities: $e');
    }
  }

  Future<void> search({String? from, String? to, String? date}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final params = <String, dynamic>{};
      if (from != null && from.isNotEmpty) params['from'] = from;
      if (to != null && to.isNotEmpty) params['to'] = to;
      if (date != null && date.isNotEmpty) params['date'] = date;

      if (_activeTab == 'rides') {
        final response = await _apiClient.get('/rides', queryParameters: params);
        if (response.statusCode == 200) {
          _rides = (response.data as List).map((json) => Ride.fromJson(json)).toList();
        }
      } else {
        final response = await _apiClient.get('/bus-tickets', queryParameters: params);
        if (response.statusCode == 200) {
          _busTickets = (response.data as List).map((json) => BusTicket.fromJson(json)).toList();
        }
      }
    } catch (e) {
      print('Search error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
