part of '../../pages/login_page.dart';

class _PhoneStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController phoneCtrl;
  final bool loading;

  const _PhoneStep({
    required this.formKey,
    required this.phoneCtrl,
    required this.loading,
  });
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.paddingXL),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.cardGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Welcome to\n${AppConstants.appName}',
              style: AppTextStyles.headlineLarge.copyWith(height: 1.2),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in with your phone number to access\nyour healthcare benefits.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 40),
            Text('Phone Number', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              autofocus: true,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ],
              decoration: InputDecoration(
                prefixIcon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🇬🇭', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 6),
                      Text(
                        '+233',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(width: 1, height: 20, color: AppColors.border),
                    ],
                  ),
                ),
                hintText: 'XX XXX XXXX',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Phone number is required';
                if (v.length < 9) return 'Enter a valid 9-digit number';
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(
              "We'll send a verification code to this number",
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: loading
                    ? null
                    : () {
                        if (!formKey.currentState!.validate()) return;
                        context.read<AuthBloc>().add(
                          AuthSendOtpRequested('+233${phoneCtrl.text.trim()}'),
                        );
                      },
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Send OTP', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'By continuing, you agree to our Terms of Service\nand Privacy Policy.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Step 2: OTP
// ─────────────────────────────────────────────
