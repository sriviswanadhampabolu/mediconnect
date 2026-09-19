import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/api_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/neu_background.dart';
import '../core/widgets/server_config_dialog.dart';
import '../core/localization/app_localization.dart';
import '../providers/auth_provider.dart';

enum AuthStep {
  roleSelection,
  credentials,
  forgotPasswordEmail,
  forgotPasswordCode,
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AuthStep _currentStep = AuthStep.roleSelection;

  // Login Controllers
  final _loginIdentController = TextEditingController();
  final _loginPassController = TextEditingController();

  // Signup Controllers
  final _signupNameController = TextEditingController();
  final _signupContactController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPassController = TextEditingController();
  final _signupStoreNameController = TextEditingController();
  final _signupAddressController = TextEditingController();

  // Forgot Password Controllers
  final _forgotEmailController = TextEditingController();
  final _resetCodeController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _devPreviewCode;
  bool _isResetting = false;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginIdentController.dispose();
    _loginPassController.dispose();
    _signupNameController.dispose();
    _signupContactController.dispose();
    _signupEmailController.dispose();
    _signupPassController.dispose();
    _signupStoreNameController.dispose();
    _signupAddressController.dispose();
    _forgotEmailController.dispose();
    _resetCodeController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _handleLogin(AuthProvider auth) async {
    final ident = _loginIdentController.text.trim();
    final pass = _loginPassController.text.trim();
    if (ident.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email/phone and password.')),
      );
      return;
    }

    final success = await auth.login(ident, pass, enforceRole: true);
    if (!success && mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppTheme.emergency,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleGoogleLogin(AuthProvider auth) async {
    final defaultEmail = auth.selectedRole == 'pharmacy_owner'
        ? 'owner.chemist@gmail.com'
        : 'patient.cyberhub@gmail.com';
    final name = auth.selectedRole == 'pharmacy_owner' ? 'CyberMed Chemist' : 'Rahul Sharma (Google)';

    final success = await auth.directEmailLogin(
      email: defaultEmail,
      name: name,
      role: auth.selectedRole,
    );
    if (!success && mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!), backgroundColor: AppTheme.emergency),
      );
    }
  }

  void _handleDirectEmailLoginPrompt(AuthProvider auth) {
    final textInField = _loginIdentController.text.trim();
    final defaultEmail = textInField.contains('@')
        ? textInField
        : (auth.selectedRole == 'pharmacy_owner' ? 'chemist.cybercity@gmail.com' : 'rahul.patient@gmail.com');
    final emailController = TextEditingController(text: defaultEmail);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('✉️', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('Direct Email Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sign in directly with your email without typing a password. Your session will be instantly connected.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Your Email Address',
                hintText: 'e.g. rahul@gmail.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty || !email.contains('@')) return;
              Navigator.of(ctx).pop();
              final success = await auth.directEmailLogin(
                email: email,
                name: email.split('@').first,
                role: auth.selectedRole,
              );
              if (!success && mounted && auth.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(auth.errorMessage!), backgroundColor: AppTheme.emergency),
                );
              }
            },
            child: const Text('Sign In Directly'),
          ),
        ],
      ),
    );
  }

  void _handleSignup(AuthProvider auth) async {
    final name = _signupNameController.text.trim();
    final contact = _signupContactController.text.trim();
    final email = _signupEmailController.text.trim();
    final pass = _signupPassController.text.trim();
    final storeName = _signupStoreNameController.text.trim();
    final address = _signupAddressController.text.trim();

    if (name.isEmpty || contact.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in Name, Phone, and Password.')),
      );
      return;
    }

    final success = await auth.signup(
      name: name,
      contact: contact,
      email: email.isNotEmpty ? email : null,
      password: pass,
      role: auth.selectedRole,
      storeName: storeName.isNotEmpty ? storeName : null,
      address: address.isNotEmpty ? address : 'Sector 15, Gurgaon',
    );

    if (!success && mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!), backgroundColor: AppTheme.emergency),
      );
    }
  }

  void _handleSendResetCode(AuthProvider auth) async {
    final email = _forgotEmailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid registered email address.')),
      );
      return;
    }

    setState(() => _isResetting = true);
    try {
      final res = await auth.requestPasswordReset(email);
      setState(() {
        _isResetting = false;
        _devPreviewCode = res['dev_code'] ?? '123456';
        _currentStep = AuthStep.forgotPasswordCode;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification code sent to $email! Please check your inbox.'),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() => _isResetting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.emergency,
          ),
        );
      }
    }
  }

  void _handleConfirmReset(AuthProvider auth) async {
    final email = _forgotEmailController.text.trim();
    final code = _resetCodeController.text.trim();
    final newPass = _newPassController.text.trim();
    final confirmPass = _confirmPassController.text.trim();

    if (code.isEmpty || code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the valid 6-digit verification code.')),
      );
      return;
    }

    if (newPass.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 4 characters.')),
      );
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match. Please re-enter.')),
      );
      return;
    }

    setState(() => _isResetting = true);
    final success = await auth.confirmPasswordReset(
      email: email,
      code: code,
      newPassword: newPass,
    );
    setState(() => _isResetting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully! Please sign in with your new credentials.'),
          backgroundColor: AppTheme.success,
          duration: Duration(seconds: 4),
        ),
      );
      _loginIdentController.text = email;
      _loginPassController.clear();
      _resetCodeController.clear();
      _newPassController.clear();
      _confirmPassController.clear();
      _devPreviewCode = null;
      setState(() {
        _currentStep = AuthStep.credentials;
      });
    } else if (mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!), backgroundColor: AppTheme.emergency),
      );
    }
  }

  void _showLanguagePickerSheet() {
    final languages = [
      {'code': 'en', 'name': 'English', 'native': 'English'},
      {'code': 'hi', 'name': 'Hindi', 'native': 'हिन्दी'},
      {'code': 'te', 'name': 'Telugu', 'native': 'తెలుగు'},
      {'code': 'ta', 'name': 'Tamil', 'native': 'தமிழ்'},
      {'code': 'bn', 'name': 'Bengali', 'native': 'বাংলা'},
      {'code': 'mr', 'name': 'Marathi', 'native': 'मराठी'},
      {'code': 'gu', 'name': 'Gujarati', 'native': 'ગુજરાતી'},
      {'code': 'kn', 'name': 'Kannada', 'native': 'ಕನ್ನಡ'},
      {'code': 'ml', 'name': 'Malayalam', 'native': 'മലയാളം'},
      {'code': 'pa', 'name': 'Punjabi', 'native': 'ਪੰਜਾਬੀ'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.neuDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Select Language / भाषा चुनें',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: languages.length,
                    itemBuilder: (ctx, i) {
                      final l = languages[i];
                      final isSelected = _selectedLanguage == l['name'];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.translate, size: 20, color: AppTheme.primary),
                        title: Text(l['native']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(l['name']!, style: const TextStyle(fontSize: 12)),
                        trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primary) : null,
                        onTap: () {
                          final code = l['code'] ?? 'en';
                          AppLocalization().setLanguage(code);
                          setState(() {
                            _selectedLanguage = l['name']!;
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Language set to ${l['native']} (${l['name']})')),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NeuBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top System App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Server Config Pill Button
                    InkWell(
                      onTap: () => ServerConfigDialog.show(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: AppTheme.neuPill(
                          active: ApiConstants.isSimulatorMode,
                          activeColor: AppTheme.warning,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              ApiConstants.isSimulatorMode ? Icons.bolt : Icons.wifi,
                              size: 14,
                              color: ApiConstants.isSimulatorMode ? AppTheme.warning : AppTheme.success,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              ApiConstants.isSimulatorMode ? 'Simulator' : 'Online',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: ApiConstants.isSimulatorMode ? AppTheme.warning : AppTheme.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Language Picker Pill Button
                    InkWell(
                      onTap: _showLanguagePickerSheet,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: AppTheme.neuPill(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🌐', style: TextStyle(fontSize: 13)),
                            const SizedBox(width: 6),
                            Text(
                              _selectedLanguage,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.textMuted),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Auth Card
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.neuRaised(radius: 28),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: _buildCurrentStepView(auth),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepView(AuthProvider auth) {
    switch (_currentStep) {
      case AuthStep.roleSelection:
        return _buildRoleSelectionStep(auth);
      case AuthStep.credentials:
        return _buildCredentialsStep(auth);
      case AuthStep.forgotPasswordEmail:
        return _buildForgotPasswordEmailStep(auth);
      case AuthStep.forgotPasswordCode:
        return _buildForgotPasswordCodeStep(auth);
    }
  }

  // ===========================================================================
  // STEP 1: CHOOSE ROLE FIRST
  // ===========================================================================
  Widget _buildRoleSelectionStep(AuthProvider auth) {
    final isCustomer = auth.selectedRole == 'customer';
    final isOwner = auth.selectedRole == 'pharmacy_owner';

    return Column(
      key: const ValueKey('RoleSelectionStep'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Brand Header (Matching docs/index.html login-brand-badge)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: AppTheme.neuSquircle(radius: 16),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/app_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text('🩺', style: TextStyle(fontSize: 28)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MediConnect',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'AI Hyperlocal Health Assistant & Chemist',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Step Guide Banner
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('👉', style: TextStyle(fontSize: 14)),
              SizedBox(width: 6),
              Text(
                'Step 1 of 2: Select Your Role to Continue',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E40AF),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ROLE CARD 1: Customer / Patient
        _buildRoleSelectionCard(
          title: 'Customer / Patient',
          badgeText: 'Patients & Families',
          description: 'Consult 12 AI safety agents, discover nearest verified chemists, order 50–70% cheaper generic medicines, and 1-tap emergency SOS.',
          iconText: '👤',
          accentColor: AppTheme.primary,
          isSelected: isCustomer,
          features: const [
            '12-Agent clinical triage & generic price comparison',
            'Save 50–70% with verified chemical equivalents',
            'Direct chat with neighborhood chemists & fast delivery',
          ],
          onTap: () => auth.setSelectedRole('customer'),
        ),

        const SizedBox(height: 12),

        // ROLE CARD 2: Pharmacy Store Owner / Chemist
        _buildRoleSelectionCard(
          title: 'Pharmacy Owner / Chemist',
          badgeText: 'Licensed Chemists',
          description: 'Manage digital store inventory, fulfill patient prescription orders with fair commissions, and chat live with customers.',
          iconText: '🏪',
          accentColor: AppTheme.success,
          isSelected: isOwner,
          features: const [
            'Live stock counts with quick +/- adjustments',
            'Incoming orders feed with capped 6.5% commission',
            'Direct 2-way patient chat & local SOS node',
          ],
          onTap: () => auth.setSelectedRole('pharmacy_owner'),
        ),

        const SizedBox(height: 20),

        // CONTINUE BUTTON (Royal Blue Gradient with Glow)
        Container(
          decoration: BoxDecoration(
            gradient: isOwner ? AppTheme.successGradient : AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (isOwner ? AppTheme.success : AppTheme.primary).withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {
              auth.clearError();
              setState(() => _currentStep = AuthStep.credentials);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isOwner ? 'Continue as Pharmacy Owner' : 'Continue as Patient',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        // 1-CLICK DEMO SHORTCUTS
        _buildDemoQuickLogins(auth),
      ],
    );
  }

  Widget _buildRoleSelectionCard({
    required String title,
    required String badgeText,
    required String description,
    required String iconText,
    required Color accentColor,
    required bool isSelected,
    required List<String> features,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: isSelected
            ? AppTheme.neuRaised(
                radius: 20,
                color: AppTheme.surface,
                border: Border.all(color: accentColor, width: 2.0),
              )
            : AppTheme.neuRaised(
                radius: 20,
                color: AppTheme.surface,
                border: Border.all(color: Colors.white.withOpacity(0.85), width: 1.2),
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: AppTheme.neuSquircle(radius: 12),
                  child: Center(
                    child: Text(iconText, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? accentColor : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? accentColor : Colors.grey.shade400,
                      width: 2,
                    ),
                    color: isSelected ? accentColor : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
            ),
            const SizedBox(height: 8),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check, size: 14, color: accentColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          f,
                          style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // STEP 2: ENTER LOGIN CREDENTIALS
  // ===========================================================================
  Widget _buildCredentialsStep(AuthProvider auth) {
    final isOwner = auth.selectedRole == 'pharmacy_owner';

    return Column(
      key: const ValueKey('CredentialsStep'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Role Bar & Switch Role Button
        Row(
          children: [
            InkWell(
              onTap: () {
                auth.clearError();
                setState(() => _currentStep = AuthStep.roleSelection);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: AppTheme.neuPill(),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back_rounded, size: 14, color: AppTheme.textSecondary),
                    SizedBox(width: 4),
                    Text('← Change Role', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isOwner ? const Color(0xFFD1FAE5) : const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isOwner ? AppTheme.success : AppTheme.primary,
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Text(isOwner ? '🏪' : '👤', style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    isOwner ? 'Pharmacy Owner' : 'Patient',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isOwner ? const Color(0xFF065F46) : const Color(0xFF1E40AF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Segmented Switcher: Log In vs Sign Up
        Container(
          padding: const EdgeInsets.all(4),
          decoration: AppTheme.neuSunken(radius: 16),
          child: TabBar(
            controller: _tabController,
            labelColor: isOwner ? AppTheme.success : AppTheme.primary,
            unselectedLabelColor: AppTheme.textMuted,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: AppTheme.neuRaised(radius: 12),
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            tabs: const [
              Tab(text: 'Log In'),
              Tab(text: 'Sign Up'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tab Views
        SizedBox(
          height: isOwner ? 410 : 380,
          child: TabBarView(
            controller: _tabController,
            children: [
              // 1. Log In Form
              _buildLoginForm(auth),

              // 2. Sign Up Form
              _buildSignupForm(auth),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Quick Demo Test Logins
        _buildDemoQuickLogins(auth),
      ],
    );
  }

  Widget _buildLoginForm(AuthProvider auth) {
    final isOwner = auth.selectedRole == 'pharmacy_owner';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Mobile Number or Email',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: AppTheme.neuSunken(radius: 16),
          child: TextField(
            controller: _loginIdentController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: isOwner ? 'owner@sanjeevani.in or +91 98101 23456' : 'rahul@health.in or +91 98765 43210',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixIcon: const Icon(Icons.phone_android, size: 18, color: AppTheme.primary),
            ),
          ),
        ),
        const SizedBox(height: 14),

        const Text(
          'Password',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: AppTheme.neuSunken(radius: 16),
          child: TextField(
            controller: _loginPassController,
            obscureText: _obscurePassword,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Demo123!',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixIcon: const Icon(Icons.lock_outline, size: 18, color: AppTheme.primary),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
        ),

        // Forgot Password
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            onPressed: () {
              final idText = _loginIdentController.text.trim();
              if (idText.contains('@')) {
                _forgotEmailController.text = idText;
              }
              auth.clearError();
              setState(() => _currentStep = AuthStep.forgotPasswordEmail);
            },
            child: const Text(
              'Forgot Password?',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Submit Button
        Container(
          decoration: BoxDecoration(
            gradient: isOwner ? AppTheme.successGradient : AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: (isOwner ? AppTheme.success : AppTheme.primary).withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            onPressed: auth.isLoading ? null : () => _handleLogin(auth),
            child: auth.isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    isOwner ? 'Log In as Pharmacy Owner ➔' : 'Log In as Patient ➔',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  ),
          ),
        ),
        const SizedBox(height: 14),

        // Divider
        Row(
          children: [
            Expanded(child: Divider(color: AppTheme.border.withOpacity(0.7))),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('OR DIRECT ACCESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
            ),
            Expanded(child: Divider(color: AppTheme.border.withOpacity(0.7))),
          ],
        ),
        const SizedBox(height: 10),

        // Continue with Google Button
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            side: BorderSide(color: AppTheme.border.withOpacity(0.8)),
          ),
          icon: const Text('🇬', style: TextStyle(fontSize: 16)),
          label: const Text(
            'Continue with Google',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          onPressed: auth.isLoading ? null : () => _handleGoogleLogin(auth),
        ),
        const SizedBox(height: 8),

        // Login with Email Directly (Passwordless)
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.surfaceVariant,
            foregroundColor: AppTheme.textPrimary,
            padding: const EdgeInsets.symmetric(vertical: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          icon: const Icon(Icons.mark_email_read_outlined, size: 16, color: AppTheme.primary),
          label: const Text(
            'Login with Email Directly (Passwordless)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          onPressed: auth.isLoading ? null : () => _handleDirectEmailLoginPrompt(auth),
        ),
      ],
    );
  }

  Widget _buildSignupForm(AuthProvider auth) {
    final isOwner = auth.selectedRole == 'pharmacy_owner';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: AppTheme.neuSunken(radius: 14),
            child: TextField(
              controller: _signupNameController,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: isOwner ? 'Pharmacist Full Name *' : 'Patient Full Name *',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                prefixIcon: const Icon(Icons.person_outline, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 8),

          Container(
            decoration: AppTheme.neuSunken(radius: 14),
            child: TextField(
              controller: _signupContactController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Mobile Number * (e.g. +91 98101 23456)',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                prefixIcon: Icon(Icons.phone_outlined, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 8),

          Container(
            decoration: AppTheme.neuSunken(radius: 14),
            child: TextField(
              controller: _signupEmailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Registered Email Address',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                prefixIcon: Icon(Icons.email_outlined, size: 18),
              ),
            ),
          ),
          if (isOwner) ...[
            const SizedBox(height: 8),
            Container(
              decoration: AppTheme.neuSunken(radius: 14),
              child: TextField(
                controller: _signupStoreNameController,
                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Pharmacy Name * (e.g. Sanjeevani Local Chemist)',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  prefixIcon: Icon(Icons.storefront_outlined, size: 18),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),

          Container(
            decoration: AppTheme.neuSunken(radius: 14),
            child: TextField(
              controller: _signupPassController,
              obscureText: _obscurePassword,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Password (Min 4 chars) *',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                prefixIcon: const Icon(Icons.lock_outline, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              gradient: isOwner ? AppTheme.successGradient : AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: auth.isLoading ? null : () => _handleSignup(auth),
              child: auth.isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      isOwner ? 'Register & Launch Store ➔' : 'Register & Launch ➔',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STEP 3A: FORGOT PASSWORD - ENTER EMAIL
  // ===========================================================================
  Widget _buildForgotPasswordEmailStep(AuthProvider auth) {
    return Column(
      key: const ValueKey('ForgotPasswordEmailStep'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            onTap: () {
              auth.clearError();
              setState(() => _currentStep = AuthStep.credentials);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: AppTheme.neuPill(),
              child: const Text('← Back to Sign In', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        Center(
          child: Container(
            width: 54,
            height: 54,
            decoration: AppTheme.neuSquircle(radius: 16),
            child: const Center(
              child: Text('🔐', style: TextStyle(fontSize: 26)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        const Text(
          'Reset Your Password',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 4),
        const Text(
          'Enter your registered email ID. A 6-digit verification code will be dispatched directly to that Gmail inbox.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.3),
        ),
        const SizedBox(height: 16),

        Container(
          decoration: AppTheme.neuSunken(radius: 16),
          child: TextField(
            controller: _forgotEmailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: 'e.g. yourname@gmail.com or rahul@health.in',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixIcon: Icon(Icons.email_outlined, size: 18),
            ),
          ),
        ),
        const SizedBox(height: 16),

        Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(18),
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            onPressed: _isResetting ? null : () => _handleSendResetCode(auth),
            child: _isResetting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Send Verification Code to Gmail ➔', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: const Text(
            'Sample registered emails for testing:\n• Patient: rahul@health.in\n• Pharmacy Owner: owner@sanjeevani.in',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF1E40AF), height: 1.4),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP 3B: FORGOT PASSWORD - ENTER CODE & NEW PASSWORD
  // ===========================================================================
  Widget _buildForgotPasswordCodeStep(AuthProvider auth) {
    final email = _forgotEmailController.text.trim();

    return Column(
      key: const ValueKey('ForgotPasswordCodeStep'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            onTap: () {
              auth.clearError();
              setState(() => _currentStep = AuthStep.forgotPasswordEmail);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: AppTheme.neuPill(),
              child: const Text('← Change Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        Center(
          child: Container(
            width: 54,
            height: 54,
            decoration: AppTheme.neuSquircle(radius: 16),
            child: const Center(
              child: Text('📨', style: TextStyle(fontSize: 26)),
            ),
          ),
        ),
        const SizedBox(height: 10),

        const Text(
          'Enter Verification Code',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          'Code dispatched to $email',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),

        // Dev Auto-fill Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFCD34D)),
          ),
          child: Row(
            children: [
              const Text('🔑 Code: ', style: TextStyle(fontSize: 12, color: Color(0xFF92400E))),
              Text(
                _devPreviewCode ?? '123456',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  _resetCodeController.text = _devPreviewCode ?? '123456';
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Auto-Fill',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Container(
          decoration: AppTheme.neuSunken(radius: 16),
          child: TextField(
            controller: _resetCodeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 6),
            decoration: const InputDecoration(
              counterText: '',
              hintText: '123456',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),
        const SizedBox(height: 10),

        Container(
          decoration: AppTheme.neuSunken(radius: 14),
          child: TextField(
            controller: _newPassController,
            obscureText: _obscureNewPassword,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'New Password (min 4 chars)',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              prefixIcon: const Icon(Icons.lock_outline, size: 18),
              suffixIcon: IconButton(
                icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility, size: 18),
                onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        Container(
          decoration: AppTheme.neuSunken(radius: 14),
          child: TextField(
            controller: _confirmPassController,
            obscureText: _obscureConfirmPassword,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Confirm New Password',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              prefixIcon: const Icon(Icons.lock_outline, size: 18),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, size: 18),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        Container(
          decoration: BoxDecoration(
            gradient: AppTheme.successGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _isResetting ? null : () => _handleConfirmReset(auth),
            child: _isResetting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Verify Code & Reset Password ➔', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 1-CLICK FAST EVALUATION DEMO LOGINS (Matching docs/index.html)
  // ===========================================================================
  Widget _buildDemoQuickLogins(AuthProvider auth) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Container(height: 1, color: AppTheme.border)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'OR 1-CLICK FAST EVALUATION LOGINS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Expanded(child: Container(height: 1, color: AppTheme.border)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: auth.isLoading ? null : () => auth.demoCustomerLogin(),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: AppTheme.neuPill(),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('👤', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 6),
                      Text(
                        'Patient Demo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: auth.isLoading ? null : () => auth.demoOwnerLogin(),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: AppTheme.neuPill(
                    borderColor: AppTheme.success.withOpacity(0.5),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🏪', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 6),
                      Text(
                        'Owner Demo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
