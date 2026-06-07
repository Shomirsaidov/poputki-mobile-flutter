import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/app_theme.dart';

class PaymentWebviewScreen extends StatefulWidget {
  final String paymentUrl;
  const PaymentWebviewScreen({super.key, required this.paymentUrl});

  @override
  State<PaymentWebviewScreen> createState() => _PaymentWebviewScreenState();
}

class _PaymentWebviewScreenState extends State<PaymentWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            final url = request.url;
            if (url.contains('poputki.online/payment-result') ||
                url.contains('/payment-result')) {
              _handlePaymentReturn(url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _handlePaymentReturn(String url) {
    if (_finished) return;
    _finished = true;
    final uri = Uri.tryParse(url);
    final status = uri?.queryParameters['status'];
    final success = status == 'success' || status == 'paid' || status == null;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Оплата завершена. Проверьте статус в «Мои билеты».'
            : 'Оплата не завершена.'),
        backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.go('/');
  }

  Future<bool> _onBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onBack();
        if (shouldPop && mounted) context.pop();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          title: const Text('Оплата'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const LinearProgressIndicator(minHeight: 3),
          ],
        ),
      ),
    );
  }
}
