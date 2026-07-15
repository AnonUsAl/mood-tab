import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class PrivacyLockPage extends StatefulWidget {
  const PrivacyLockPage({
    super.key,
    required this.expectedPin,
    required this.onUnlocked,
  });

  final String expectedPin;
  final VoidCallback onUnlocked;

  @override
  State<PrivacyLockPage> createState() => _PrivacyLockPageState();
}

class _PrivacyLockPageState extends State<PrivacyLockPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _verifyPin(String value) {
    if (value.length != 4) return;
    if (value == widget.expectedPin) {
      widget.onUnlocked();
      return;
    }

    setState(() {
      _errorText = 'PIN 码错误，请重试';
      _controller.clear();
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 34,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '隐私锁',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '请输入 4 位 PIN 码查看情绪记录',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryOf(context),
                        ),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    key: const ValueKey('privacy-pin-field'),
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 4,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: InputDecoration(
                      hintText: '••••',
                      counterText: '',
                      errorText: _errorText,
                    ),
                    onChanged: (value) {
                      if (_errorText != null) {
                        setState(() => _errorText = null);
                      }
                      _verifyPin(value);
                    },
                    onSubmitted: _verifyPin,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
