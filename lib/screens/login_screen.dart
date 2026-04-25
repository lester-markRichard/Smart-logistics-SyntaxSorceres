import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/language_provider.dart';
import '../models/logistics_models.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  UserRole _selectedRole = UserRole.admin;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _truckNumberController = TextEditingController();

  void _handleLogin() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name.')),
      );
      return;
    }

    if (_selectedRole == UserRole.driver) {
      final truckNum = _truckNumberController.text.trim();
      if (truckNum.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your truck number.')),
        );
        return;
      }
      Provider.of<AppStateProvider>(context, listen: false)
          .login(name, _selectedRole, truckNumber: truckNum);
      Navigator.pushReplacementNamed(context, '/driver_dashboard');
    } else if (_selectedRole == UserRole.admin) {
      final provider = Provider.of<AppStateProvider>(context, listen: false);
      provider.login(name, _selectedRole);
      
      if (provider.vehicles.isEmpty) {
        Navigator.pushReplacementNamed(context, '/add_vehicle');
      } else {
        Navigator.pushReplacementNamed(context, '/admin_dashboard');
      }
    } else if (_selectedRole == UserRole.warehouse) {
      final provider = Provider.of<AppStateProvider>(context, listen: false);
      provider.login(name, _selectedRole);
      
      if (provider.totalWarehouseSlots == 0) {
        Navigator.pushReplacementNamed(context, '/warehouse_setup');
      } else {
        Navigator.pushReplacementNamed(context, '/warehouse_dashboard');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _truckNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      body: Row(
        children: [
          // Left side: Graphic/Branding (visible on wider screens)
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                  ],
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.hub_outlined, size: 80, color: Colors.white),
                      SizedBox(height: 24),
                      Text(
                        'Smart Logistics Platform',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Predictive routing, real-time tracking, and warehouse optimization.',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Right side: Login Form
          Expanded(
            flex: 1,
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(48.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: TextButton.icon(
                            onPressed: () => langProvider.toggleLanguage(),
                            icon: const Icon(Icons.language, color: Colors.white),
                            label: Text(
                              langProvider.isHindi ? 'English' : 'हिंदी',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          langProvider.translate('welcome_back'),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to your dashboard',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Role Selection
                        Text(
                          'SELECT ROLE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildRoleCard(UserRole.admin, Icons.admin_panel_settings, 'Admin'),
                            const SizedBox(width: 12),
                            _buildRoleCard(UserRole.driver, Icons.local_shipping, 'Driver'),
                            const SizedBox(width: 12),
                            _buildRoleCard(UserRole.warehouse, Icons.warehouse, 'Warehouse'),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Form Fields
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            labelStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        
                        if (_selectedRole == UserRole.driver) ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _truckNumberController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Truck Number (e.g. TRK-9001)',
                              labelStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Theme.of(context).cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 48),

                        // Login Button
                        ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            langProvider.translate('sign_in'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(UserRole role, IconData icon, String label) {
    final isSelected = _selectedRole == role;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedRole = role),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withOpacity(0.1) : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? primaryColor : Colors.white54,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? primaryColor : Colors.white54,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
