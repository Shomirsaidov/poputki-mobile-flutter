import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String _appVersion = '1.0.0';
  static const String _developerName = 'Abubakr Shomirsaidov';
  static const String _supportEmail = 'poputkionline@gmail.com';
  static const String _telegramBot = 'https://t.me/poputkionline_bot';
  static const String _websiteUrl = 'https://poputki.online';

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось открыть $url')),
      );
    }
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Скопировано в буфер обмена')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'О приложении',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFBBF24), AppTheme.primaryColor],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 48),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Poputki.online',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Center(
              child: Text(
                'Версия $_appVersion',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 32),
            _sectionTitle('О ПРИЛОЖЕНИИ'),
            _infoCard(
              child: const Text(
                'Poputki.online — платформа для поиска попутчиков и покупки автобусных билетов в Таджикистане. '
                'Создавайте поездки, бронируйте места и путешествуйте удобно.',
                style: TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle('РАЗРАБОТКА'),
            _infoTile(
              icon: Icons.code_rounded,
              iconColor: const Color(0xFF8B5CF6),
              iconBg: const Color(0xFFEDE9FE),
              title: 'Разработчик',
              subtitle: _developerName,
            ),
            const SizedBox(height: 24),
            _sectionTitle('КОНТАКТЫ'),
            _infoTile(
              icon: Icons.email_outlined,
              iconColor: const Color(0xFF2563EB),
              iconBg: const Color(0xFFDBEAFE),
              title: 'Поддержка',
              subtitle: _supportEmail,
              onTap: () => _openUrl(context, 'mailto:$_supportEmail'),
              onLongPress: () => _copyToClipboard(context, _supportEmail),
              trailing: Icons.chevron_right,
            ),
            const SizedBox(height: 12),
            _infoTile(
              icon: Icons.telegram,
              iconColor: const Color(0xFF0EA5E9),
              iconBg: const Color(0xFFE0F2FE),
              title: 'Telegram-бот',
              subtitle: '@poputkionline_bot',
              onTap: () => _openUrl(context, _telegramBot),
              trailing: Icons.open_in_new_rounded,
            ),
            const SizedBox(height: 12),
            _infoTile(
              icon: Icons.public_rounded,
              iconColor: const Color(0xFF10B981),
              iconBg: const Color(0xFFD1FAE5),
              title: 'Сайт',
              subtitle: 'poputki.online',
              onTap: () => _openUrl(context, _websiteUrl),
              trailing: Icons.open_in_new_rounded,
            ),
            const SizedBox(height: 32),
            const Center(
              child: Text(
                '© 2026 Poputki.online\nВсе права защищены',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Colors.grey,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _infoCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: child,
    );
  }

  Widget _infoTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    IconData? trailing,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                Icon(trailing, size: 18, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
