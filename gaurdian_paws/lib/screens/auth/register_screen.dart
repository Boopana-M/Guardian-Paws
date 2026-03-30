import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:provider/provider.dart';

import '../../providers/session_provider.dart';
import '../girl/simple_girl_home_screen.dart';
import '../guardian/guardian_home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isGirl = true;
  String? _imei;
  String? _deviceModel;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    final plugin = DeviceInfoPlugin();
    try {
      String model;
      String imeiFallback;
      if (Theme.of(context).platform == TargetPlatform.android) {
        final info = await plugin.androidInfo;
        model = info.model ?? 'Android Device';
        imeiFallback = info.id ?? 'unknown-imei';
      } else {
        final info = await plugin.iosInfo;
        model = info.utsname.machine ?? 'iOS Device';
        imeiFallback = info.identifierForVendor ?? 'unknown-imei';
      }
      setState(() {
        _deviceModel = model;
        _imei = imeiFallback;
      });
    } catch (_) {}
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
    });
    final user = ParseUser(
      _emailController.text.trim(),
      _passwordController.text,
      _emailController.text.trim(),
    )
      ..set<String>('name', _nameController.text.trim())
      ..set<String>('phone', _phoneController.text.trim())
      ..set<String>('role', _isGirl ? 'girl' : 'guardian')
      ..set<String?>('imei', _imei)
      ..set<String?>('deviceModel', _deviceModel)
      ..set<bool>('protectionModeActive', false)
      ..set<int>('checkInterval', 15)
      ..set<String>('status', 'SAFE')
      ..set<bool>('deviceOnline', true);

    final response = await user.signUp();
    setState(() {
      _loading = false;
    });
    if (response.success && mounted) {
      final session = Provider.of<SessionProvider>(context, listen: false);
      await session.setUser(user);

      final linkFunc = ParseCloudFunction('linkGuardianOnSignup');
      await linkFunc.execute();

      if (_isGirl) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const SimpleGirlHomeScreen(),
          ),
        );
      } else {
        Navigator.of(context)
            .pushReplacementNamed(GuardianHomeScreen.routeName);
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.error?.message ?? 'Sign up failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffef4ea),
      appBar: AppBar(
        backgroundColor: const Color(0xfffef4ea),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xfff39c6b)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 16,
                  color: Colors.black12,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Guardian-Paws account',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xfff39c6b),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ToggleButtons(
                    isSelected: [_isGirl, !_isGirl],
                    onPressed: (index) {
                      setState(() {
                        _isGirl = index == 0;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    selectedColor: Colors.white,
                    fillColor: const Color(0xfff39c6b),
                    children: const [
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('I am the Girl'),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('I am a Guardian'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v != null && v.isNotEmpty ? null : 'Required',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v != null && v.contains('@') ? null : 'Invalid email',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        v != null && v.length >= 6 ? null : 'Invalid phone',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (v) =>
                        v != null && v.length >= 6 ? null : 'Too short',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Device model: ${_deviceModel ?? 'Detecting...'}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'IMEI / Device ID: ${_imei ?? 'Detecting...'}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xfff39c6b),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : const Text('Create my cozy profile'),
                    ),
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

