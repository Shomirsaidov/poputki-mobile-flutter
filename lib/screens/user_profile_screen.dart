import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ApiClient _apiClient = ApiClient();
  Map<String, dynamic>? _user;
  List<dynamic> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiClient.get('/users/${widget.userId}/profile'),
        _apiClient.get('/users/${widget.userId}/reviews').catchError((e) {
          print('Error loading reviews: $e');
          return Response(requestOptions: RequestOptions(), data: [], statusCode: 200); // Fail-safe
        }),
      ]);

      setState(() {
        _user = results[0].data;
        _reviews = results[1].data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching profile data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при загрузке профиля')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  String _formatJoinedDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final formatter = DateFormat('MMMM yyyy', 'ru');
      return 'На сайте с ${formatter.format(date)}';
    } catch (e) {
      return '';
    }
  }

  String _formatReviewDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMMM yyyy', 'ru').format(date);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor)),
        ),
      );
    }

    if (_user == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text('Пользователь не найден'),
        ),
      );
    }

    final preferences = _user!['preferences'] as List<dynamic>? ?? [];
    final vehicle = _user!['vehicle'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _fetchProfileData,
        color: AppTheme.primaryColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Custom premium sliver header
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: AppTheme.primaryColor,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFBBF24), AppTheme.primaryColor],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _user!['name']?[0] ?? 'U',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Profile info content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  children: [
                    // Name & Sub-details
                    Text(
                      '${_user!['name'] ?? ''} ${_user!['surname'] ?? ''}'.trim(),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_user!['age'] != null) ...[
                          Text('${_user!['age']} лет', style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          const CircleAvatar(radius: 2, backgroundColor: Colors.grey),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _formatJoinedDate(_user!['created_at']),
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 3-Columns Stats Card
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10)],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn('РЕЙТИНГ', Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${_user!['rating'] ?? 5.0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                              const SizedBox(width: 2),
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                            ],
                          )),
                          _buildDivider(),
                          _buildStatColumn('ЗА РУЛЕМ', Text('${_user!['rides_as_driver'] ?? 0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900))),
                          _buildDivider(),
                          _buildStatColumn('ПАССАЖИРОМ', Text('${_user!['rides_as_passenger'] ?? 0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900))),
                        ],
                      ),
                    ),

                    // Preferences
                    if (preferences.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildSectionHeader('Предпочтения'),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Column(
                          children: preferences.map((pref) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF3B82F6),
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Color(0x663B82F6), blurRadius: 4)],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    pref.toString(),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          )).toList(),
                        ),
                      ),
                    ],

                    // Vehicle Details
                    if (vehicle != null) ...[
                      const SizedBox(height: 24),
                      _buildSectionHeader('Автомобиль'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.directions_car, color: Color(0xFFD97706), size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${vehicle['make'] ?? ''} ${vehicle['model'] ?? ''}'.trim(),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      vehicle['plate_number'] ?? '',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Reviews Header & List
                    const SizedBox(height: 24),
                    _buildSectionHeader('Отзывы (${_reviews.length})'),
                    const SizedBox(height: 12),
                    if (_reviews.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.shade100, style: BorderStyle.solid),
                        ),
                        child: const Column(
                          children: [
                            Text('💬', style: TextStyle(fontSize: 28)),
                            SizedBox(height: 8),
                            Text(
                              'Отзывов пока нет',
                              style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _reviews.length,
                        itemBuilder: (context, index) {
                          final review = _reviews[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: Colors.grey.shade100,
                                          child: Text(
                                            review['reviewer_name']?[0] ?? 'U',
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              review['reviewer_name'] ?? 'Попутчик',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                            ),
                                            Text(
                                              _formatReviewDate(review['created_at']),
                                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            '${review['rating']}',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                                          ),
                                          const SizedBox(width: 2),
                                          const Icon(Icons.star, size: 10, color: Color(0xFFD97706)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  review['comment'] ?? '',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, Widget val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        val,
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey.shade200,
    );
  }
}
