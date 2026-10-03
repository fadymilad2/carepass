part of '../../pages/login_page.dart';

class _OtpStep extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const _OtpStep({required this.phoneNumber, required this.verificationId});

  @override
  State<_OtpStep> createState() => _OtpStepState();
}

class _OtpStepState extends State<_OtpStep> {
  String _otp = '';
  bool _canResend = false;
  int _seconds = 60;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        if (_seconds > 0) {
          _seconds--;
          _startCountdown();
        } else {
          _canResend = true;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthBloc>().state is AuthLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.paddingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            padding: EdgeInsets.zero,
            onPressed: () => context.read<AuthBloc>().add(AuthCheckRequested()),
          ),
          const SizedBox(height: 24),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.message_outlined,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 24),
          Text('Enter OTP', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              children: [
                const TextSpan(text: 'We sent a 6-digit code to '),
                TextSpan(
                  text: widget.phoneNumber,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          TextFormField(
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: (val) {
              setState(() => _otp = val);
              if (val.length == 6 && !loading) _verify(context);
            },
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'Enter 6-digit code',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: loading || _otp.length < 6
                  ? null
                  : () => _verify(context),
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text('Verify', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: _canResend
                ? TextButton(
                    onPressed: () {
                      setState(() {
                        _canResend = false;
                        _seconds = 60;
                        _otp = '';
                      });
                      _startCountdown();
                      context.read<AuthBloc>().add(
                        AuthSendOtpRequested(widget.phoneNumber),
                      );
                    },
                    child: Text(
                      'Resend OTP',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : Text(
                    'Resend OTP in $_seconds seconds',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _verify(BuildContext context) {
    context.read<AuthBloc>().add(
      AuthVerifyOtpRequested(verificationId: widget.verificationId, otp: _otp),
    );
  }
}

// ─────────────────────────────────────────────
//  Step 3: Profile + T&C
// ─────────────────────────────────────────────
