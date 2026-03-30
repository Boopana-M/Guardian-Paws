import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class GuardianManagementScreen extends StatefulWidget {
  const GuardianManagementScreen({super.key});

  @override
  State<GuardianManagementScreen> createState() =>
      _GuardianManagementScreenState();
}

class _GuardianManagementScreenState
    extends State<GuardianManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _sending = false;
  List<ParseObject> _guardians = [];

  @override
  void initState() {
    super.initState();
    _loadGuardians();
  }

  Future<void> _loadGuardians() async {
    final user = await ParseUser.currentUser() as ParseUser?;
    if (user == null) return;
    final relationQuery =
        QueryBuilder<ParseObject>(ParseObject('Guardian'))
          ..whereEqualTo('linkedUsers', user.objectId);
    final res = await relationQuery.query();
    if (res.success && res.results != null) {
      setState(() {
        _guardians = res.results!.cast<ParseObject>();
      });
    }
  }

  Future<void> _inviteGuardian() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _sending = true;
    });
    final func = ParseCloudFunction('inviteGuardian');
    final res = await func.execute(parameters: {
      'guardianName': _nameController.text.trim(),
      'guardianPhone': _phoneController.text.trim(),
      'guardianEmail': _emailController.text.trim(),
    });
    setState(() {
      _sending = false;
    });
    if (res.success) {
      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
      await _loadGuardians();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardian invited')),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error?.message ?? 'Failed to invite')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trusted guardians',
          style: TextStyle(color: Color(0xfff39c6b)),
        ),
        iconTheme: const IconThemeData(color: Color(0xfff39c6b)),
        backgroundColor: const Color(0xfffef4ea),
        elevation: 0,
      ),
      backgroundColor: const Color(0xfffef4ea),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Guardian name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v != null && v.isNotEmpty ? null : 'Required',
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Guardian phone',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        v != null && v.length >= 6 ? null : 'Invalid',
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Guardian email (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _sending ? null : _inviteGuardian,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xfff39c6b),
                        foregroundColor: Colors.white,
                      ),
                      child: _sending
                          ? const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : const Text('Add guardian'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _guardians.length,
              itemBuilder: (context, index) {
                final g = _guardians[index];
                final accepted = g.get<bool>('acceptedInvite') ?? false;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.shield_moon),
                    title: Text(g.get<String>('name') ?? 'Guardian'),
                    subtitle: Text(
                      '${g.get<String>('phone') ?? ''}\n'
                      '${accepted ? 'Linked in app' : 'SMS invited'}',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

