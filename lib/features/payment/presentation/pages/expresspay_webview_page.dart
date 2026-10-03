import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../domain/entities/payment_callback.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/payment_bloc.dart';
import '../../domain/entities/payment_entities.dart';

class ExpressPayWebViewPage extends StatefulWidget {
  final String url;
  final String reference;
  final SubscriptionPlan plan;

  const ExpressPayWebViewPage({
    super.key,
    required this.url,
    required this.reference,
    required this.plan,
  });

  @override
  State<ExpressPayWebViewPage> createState() => _ExpressPayWebViewPageState();
}

class _ExpressPayWebViewPageState extends State<ExpressPayWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _handledCallback = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (!mounted) return;
            setState(() => _isLoading = true);
            _checkForCallback(url);
          },
          onPageFinished: (url) {
            if (!mounted) return;
            setState(() => _isLoading = false);
            _checkForCallback(url);
          },
          onNavigationRequest: (request) {
            if (_isCallbackUrl(request.url)) {
              _checkForCallback(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  bool _isCallbackUrl(String url) {
    return isExpressPayCallback(url, Firebase.app().options.projectId);
  }

  void _checkForCallback(String url) {
    if (!mounted || _handledCallback) return;
    if (!_isCallbackUrl(url)) return;

    _handledCallback = true;
    _handleCallback(url);
  }

  void _handleCallback(String url) {
    context.read<PaymentBloc>().add(PaymentVerifyRequested(widget.reference));

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && !_handledCallback) {
          _handledCallback = true;
          context.read<PaymentBloc>().add(PaymentCancelled());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Secure Payment'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _handledCallback = true;
              context.read<PaymentBloc>().add(PaymentCancelled());
              Navigator.pop(context);
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                children: [
                  const Icon(Icons.lock, size: 14, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    'Secure',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
          ],
        ),
      ),
    );
  }
}
