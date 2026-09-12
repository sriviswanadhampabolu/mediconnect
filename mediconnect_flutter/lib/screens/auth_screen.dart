import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
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
        _devPreviewCode = res['dev_code'];
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
      // Pre-fill login identifier and return to credentials step
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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildCurrentStepView(auth),
              ),
            ),
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
        // Brand Logo
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.local_hospital_rounded, color: AppTheme.primary, size: 40),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'MediConnect',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Hyperlocal Healthcare & Direct Chemist Network',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 24),

        // Step Guide Banner
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_outlined, size: 16, color: AppTheme.primary),
              SizedBox(width: 8),
              Text(
                'Step 1 of 2: Select Your Role to Continue',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ROLE CARD 1: Customer / Patient
        _buildRoleSelectionCard(
          title: 'Customer / Patient',
          badgeText: 'Patients & Families',
          description: 'Consult AI health agents, discover verified local chemists, order affordable generic medicines, and access 1-tap SOS emergency services.',
          icon: Icons.person_rounded,
          accentColor: AppTheme.primary,
          isSelected: isCustomer,
          features: const [
            'Instant multi-agent symptom triage & hospital booking',
            'Save 50–70% with verified generic medicine alternatives',
            'Live chat with local chemists & direct door delivery',
          ],
          onTap: () => auth.setSelectedRole('customer'),
        ),

        const SizedBox(height: 14),

        // ROLE CARD 2: Pharmacy Store Owner / Chemist
        _buildRoleSelectionCard(
          title: 'Pharmacy Owner / Chemist',
          badgeText: 'Licensed Chemists',
          description: 'Manage digital inventory stock, fulfill incoming patient prescription orders, chat directly with neighborhood customers, and monitor revenue.',
          icon: Icons.storefront_rounded,
          accentColor: AppTheme.secondary,
          isSelected: isOwner,
          features: const [
            'Digital medicine catalog & stock level adjustments',
            'Direct order processing with capped fair commissions',
            'Neighborhood patient chat & automated dispatch',
          ],
          onTap: () => auth.setSelectedRole('pharmacy_owner'),
        ),

        const SizedBox(height: 24),

        // CONTINUE BUTTON
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: isOwner ? AppTheme.secondary : AppTheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 2,
          ),
          onPressed: () {
            auth.clearError();
            setState(() {
              _currentStep = AuthStep.credentials;
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isOwner ? 'Continue as Pharmacy Owner' : 'Continue as Patient',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 1-CLICK DEMO SHORTCUTS
        _buildDemoQuickLogins(auth),
      ],
    );
  }

  Widget _buildRoleSelectionCard({
    required String title,
    required String badgeText,
    required String description,
    required IconData icon,
    required Color accentColor,
    required bool isSelected,
    required List<String> features,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : AppTheme.border,
            width: isSelected ? 2.2 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? accentColor.withOpacity(0.12) : Colors.black.withOpacity(0.02),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor : accentColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : accentColor,
                    size: 24,
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
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? accentColor : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
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
            const SizedBox(height: 10),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline, size: 14, color: accentColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          f,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
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
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back_rounded, size: 16, color: AppTheme.textSecondary),
                    SizedBox(width: 4),
                    Text('Change Role', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isOwner ? AppTheme.secondary.withOpacity(0.12) : AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isOwner ? AppTheme.secondary : AppTheme.primary, width: 1.2),
              ),
              child: Row(
                children: [
                  Icon(
                    isOwner ? Icons.storefront : Icons.person,
                    size: 14,
                    color: isOwner ? AppTheme.secondary : AppTheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isOwner ? 'Pharmacy Owner' : 'Patient',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isOwner ? AppTheme.secondary : AppTheme.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Header Title
        Text(
          isOwner ? 'Pharmacy Owner Sign In' : 'Patient Sign In',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isOwner
              ? 'Enter your pharmacy credentials to access your store dashboard.'
              : 'Enter your credentials to access your health profile and orders.',
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 18),

        // TAB BAR: Sign In vs Create Account
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: isOwner ? AppTheme.secondary : AppTheme.primaryDark,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'Sign In'),
              Tab(text: 'Create Account'),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // TAB BAR VIEWS
        SizedBox(
          height: isOwner ? 430 : 390,
          child: TabBarView(
            controller: _tabController,
            children: [
              // 1. SIGN IN FORM
              _buildLoginForm(auth),

              // 2. SIGN UP FORM
              _buildSignupForm(auth),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // QUICK DEMO TEST LOGINS
        _buildDemoQuickLogins(auth),
      ],
    );
  }

  Widget _buildLoginForm(AuthProvider auth) {
    final isOwner = auth.selectedRole == 'pharmacy_owner';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _loginIdentController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: isOwner ? 'Owner Email or Phone' : 'Email or Mobile Number',
            hintText: isOwner ? 'owner@sanjeevani.in' : 'rahul@health.in',
            prefixIcon: const Icon(Icons.account_circle_outlined, size: 20),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _loginPassController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Demo123!',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // FORGOT PASSWORD BUTTON
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.lock_reset, size: 16),
            label: const Text(
              'Forgot Password?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryDark,
              ),
            ),
            onPressed: () {
              // Pre-fill email if user entered it in identifier field
              final idText = _loginIdentController.text.trim();
              if (idText.contains('@')) {
                _forgotEmailController.text = idText;
              }
              auth.clearError();
              setState(() {
                _currentStep = AuthStep.forgotPasswordEmail;
              });
            },
          ),
        ),
        const SizedBox(height: 12),

        // SIGN IN ACTION BUTTON
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: isOwner ? AppTheme.secondary : AppTheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: auth.isLoading ? null : () => _handleLogin(auth),
          child: auth.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  isOwner ? 'Sign In as Pharmacy Owner' : 'Sign In as Patient',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                ),
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
          TextField(
            controller: _signupNameController,
            decoration: InputDecoration(
              labelText: isOwner ? 'Owner / Pharmacist Name' : 'Full Name',
              hintText: isOwner ? 'Ramesh Gupta' : 'John Doe',
              prefixIcon: const Icon(Icons.badge_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _signupContactController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: '+91 98101 23456',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _signupEmailController,
            decoration: InputDecoration(
              labelText: 'Email Address (Registered for verification)',
              hintText: isOwner ? 'owner@store.com' : 'patient@example.com',
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
            ),
          ),
          if (isOwner) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _signupStoreNameController,
              decoration: const InputDecoration(
                labelText: 'Pharmacy / Medical Store Name',
                hintText: 'e.g. LifeCare Local Chemist',
                prefixIcon: Icon(Icons.storefront_outlined, size: 20),
              ),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: _signupAddressController,
            decoration: InputDecoration(
              labelText: isOwner ? 'Shop Address / Market' : 'Delivery Address',
              hintText: 'Sector 15 Market, Gurgaon',
              prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _signupPassController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Create Password',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: isOwner ? AppTheme.secondary : AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: auth.isLoading ? null : () => _handleSignup(auth),
            child: auth.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    isOwner ? 'Register & Launch Store' : 'Create Patient Account',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STEP 3A: FORGOT PASSWORD - ENTER REGISTERED EMAIL
  // ===========================================================================
  Widget _buildForgotPasswordEmailStep(AuthProvider auth) {
    return Column(
      key: const ValueKey('ForgotPasswordEmailStep'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Back Button
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Back to Sign In'),
            onPressed: () {
              auth.clearError();
              setState(() => _currentStep = AuthStep.credentials);
            },
          ),
        ),
        const SizedBox(height: 8),

        // Lock Icon
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_reset_rounded, color: AppTheme.primary, size: 36),
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Reset Your Password',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter the registered email ID associated with your account. We will dispatch a 6-digit verification code to that email.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 24),

        // Email Field
        TextField(
          controller: _forgotEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Registered Email Address',
            hintText: 'e.g. rahul@health.in or owner@sanjeevani.in',
            prefixIcon: Icon(Icons.email_outlined, size: 20),
          ),
        ),
        const SizedBox(height: 20),

        // Submit Button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: AppTheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isResetting ? null : () => _handleSendResetCode(auth),
          child: _isResetting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text(
                  'Send Verification Code',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                ),
        ),
        const SizedBox(height: 16),

        // Registered accounts tip
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sample registered emails:\n• Patient: rahul@health.in\n• Pharmacy Owner: owner@sanjeevani.in',
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade900, height: 1.3),
                ),
              ),
            ],
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
        // Back Button
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Change Email'),
            onPressed: () {
              auth.clearError();
              setState(() => _currentStep = AuthStep.forgotPasswordEmail);
            },
          ),
        ),
        const SizedBox(height: 8),

        // Email Sent Icon
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_read_rounded, color: AppTheme.success, size: 36),
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Enter Verification Code',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
            children: [
              const TextSpan(text: 'A 6-digit code has been sent to:\n'),
              TextSpan(
                text: email,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // DEV DEMO PREVIEW CODE HELPER
        if (_devPreviewCode != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.vpn_key_rounded, size: 18, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Verification Code: $_devPreviewCode',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () {
                    _resetCodeController.text = _devPreviewCode!;
                  },
                  child: const Text('Auto-Fill', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),

        // 6-DIGIT CODE FIELD
        TextField(
          controller: _resetCodeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
          decoration: const InputDecoration(
            counterText: '',
            labelText: '6-Digit Verification Code',
            hintText: '123456',
            prefixIcon: Icon(Icons.security_rounded, size: 20),
          ),
        ),
        const SizedBox(height: 14),

        // NEW PASSWORD
        TextField(
          controller: _newPassController,
          obscureText: _obscureNewPassword,
          decoration: InputDecoration(
            labelText: 'New Password',
            hintText: 'Enter new secure password',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility, size: 20),
              onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // CONFIRM NEW PASSWORD
        TextField(
          controller: _confirmPassController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Confirm New Password',
            hintText: 'Re-enter new password',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, size: 20),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // RESET BUTTON
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: AppTheme.success,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isResetting ? null : () => _handleConfirmReset(auth),
          child: _isResetting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text(
                  'Verify Code & Reset Password',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                ),
        ),
        const SizedBox(height: 10),

        // RESEND CODE
        Center(
          child: TextButton.icon(
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Resend Verification Code', style: TextStyle(fontSize: 12)),
            onPressed: _isResetting ? null : () => _handleSendResetCode(auth),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 1-CLICK DEMO SHORTCUTS
  // ===========================================================================
  Widget _buildDemoQuickLogins(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on_rounded, color: AppTheme.secondary, size: 16),
              const SizedBox(width: 6),
              Text(
                'Instant 1-Click Evaluation Logins:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(color: AppTheme.primary.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.person, size: 14, color: AppTheme.primary),
                  label: const Text('Patient Demo', style: TextStyle(fontSize: 11)),
                  onPressed: auth.isLoading ? null : () => auth.demoCustomerLogin(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(color: AppTheme.secondary.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.storefront, size: 14, color: AppTheme.secondary),
                  label: const Text('Owner Demo', style: TextStyle(fontSize: 11)),
                  onPressed: auth.isLoading ? null : () => auth.demoOwnerLogin(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
