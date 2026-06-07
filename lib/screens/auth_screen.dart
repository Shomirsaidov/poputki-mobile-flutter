import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../theme/app_theme.dart';

enum AuthStep {
  phone,
  password,
  register,
  setPassword,
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthStep _currentStep = AuthStep.phone;

  // Controllers
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  // Registration and Setup states
  String _selectedGender = 'male'; // 'male' or 'female'
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Пол',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGender = 'male';
                  });
                },
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _selectedGender == 'male'
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                    border: Border.all(
                      color: _selectedGender == 'male'
                          ? AppTheme.primaryColor
                          : Colors.grey.shade300,
                      width: _selectedGender == 'male' ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.male_rounded,
                        color: _selectedGender == 'male'
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Мужской',
                        style: TextStyle(
                          color: _selectedGender == 'male'
                              ? AppTheme.primaryColor
                              : AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGender = 'female';
                  });
                },
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _selectedGender == 'female'
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                    border: Border.all(
                      color: _selectedGender == 'female'
                          ? AppTheme.primaryColor
                          : Colors.grey.shade300,
                      width: _selectedGender == 'female' ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.female_rounded,
                        color: _selectedGender == 'female'
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Женский',
                        style: TextStyle(
                          color: _selectedGender == 'female'
                              ? AppTheme.primaryColor
                              : AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
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

  Widget _buildStepContent() {
    switch (_currentStep) {
      case AuthStep.phone:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          key: const ValueKey('phone_step'),
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  size: 60,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Добро пожаловать!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Введите номер телефона, чтобы продолжить пользоваться Poputki.online',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            CustomTextField(
              label: 'Номер телефона',
              hint: '+992 000 00 00 00',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Введите номер';
                if (val.length < 9) return 'Некорректный номер';
                return null;
              },
            ),
            const SizedBox(height: 32),
            Consumer<AuthProvider>(
              builder: (context, auth, child) {
                return CustomButton(
                  text: 'Продолжить',
                  isLoading: auth.isLoading,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final result = await auth.checkPhoneOrLogin(_phoneController.text);
                      if (result != null && mounted) {
                        final status = result['status'];
                        if (status == 'success') {
                          // Handled automatically by provider
                        } else if (status == 'password_required') {
                          setState(() {
                            _currentStep = AuthStep.password;
                          });
                        } else if (status == 'needs_password_setup') {
                          setState(() {
                            _currentStep = AuthStep.setPassword;
                            final existingUser = result['user'];
                            if (existingUser != null && existingUser['name'] != null) {
                              _nameController.text = existingUser['name'];
                            }
                          });
                        } else if (status == 'needs_registration') {
                          setState(() {
                            _currentStep = AuthStep.register;
                          });
                        }
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(auth.errorMessage ?? 'Ошибка подключения. Попробуйте снова.'),
                            backgroundColor: Colors.red.shade800,
                          ),
                        );
                      }
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  'Нужна помощь?',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );

      case AuthStep.password:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          key: const ValueKey('password_step'),
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentStep = AuthStep.phone;
                  _passwordController.clear();
                });
              },
              child: const Row(
                children: [
                  Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'Назад',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Вход по паролю',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Введите пароль для номера ${_phoneController.text}',
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            CustomTextField(
              label: 'Пароль',
              hint: '••••••••',
              controller: _passwordController,
              isPassword: true,
              prefixIcon: Icons.lock_outline_rounded,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Введите пароль';
                return null;
              },
            ),
            const SizedBox(height: 32),
            Consumer<AuthProvider>(
              builder: (context, auth, child) {
                return CustomButton(
                  text: 'Войти',
                  isLoading: auth.isLoading,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final result = await auth.checkPhoneOrLogin(
                        _phoneController.text,
                        password: _passwordController.text,
                      );
                      if (result != null && result['status'] == 'success' && mounted) {
                        // Success
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(auth.errorMessage ?? 'Неверный пароль. Попробуйте еще раз.'),
                            backgroundColor: Colors.red.shade800,
                          ),
                        );
                      }
                    }
                  },
                );
              },
            ),
          ],
        );

      case AuthStep.setPassword:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          key: const ValueKey('set_password_step'),
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentStep = AuthStep.phone;
                  _passwordController.clear();
                  _nameController.clear();
                });
              },
              child: const Row(
                children: [
                  Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'Назад',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Защита аккаунта',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Пожалуйста, создайте пароль и подтвердите ваше имя, чтобы входить в приложение с мобильного устройства.',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),
            CustomTextField(
              label: 'Имя',
              hint: 'Иван Иванов',
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              prefixIcon: Icons.person_outline_rounded,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Введите имя';
                return null;
              },
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: 'Создайте пароль',
              hint: '••••••••',
              controller: _passwordController,
              isPassword: true,
              prefixIcon: Icons.lock_outline_rounded,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Введите пароль';
                if (val.length < 6) return 'Пароль должен быть не менее 6 символов';
                return null;
              },
            ),
            const SizedBox(height: 32),
            Consumer<AuthProvider>(
              builder: (context, auth, child) {
                return CustomButton(
                  text: 'Сохранить и войти',
                  isLoading: auth.isLoading,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final success = await auth.registerMobile(
                        phone: _phoneController.text,
                        password: _passwordController.text,
                        name: _nameController.text,
                        age: 0,
                        sex: 'male',
                      );
                      if (success && mounted) {
                        // Success
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(auth.errorMessage ?? 'Ошибка при установке пароля.'),
                            backgroundColor: Colors.red.shade800,
                          ),
                        );
                      }
                    }
                  },
                );
              },
            ),
          ],
        );

      case AuthStep.register:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          key: const ValueKey('register_step'),
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentStep = AuthStep.phone;
                  _passwordController.clear();
                  _nameController.clear();
                  _ageController.clear();
                });
              },
              child: const Row(
                children: [
                  Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'Назад',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Регистрация',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Заполните форму ниже, чтобы создать аккаунт в Poputki.online',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),
            CustomTextField(
              label: 'ФИО (Имя и Фамилия)',
              hint: 'Иван Иванов',
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              prefixIcon: Icons.person_outline_rounded,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Введите имя';
                if (!val.trim().contains(' ')) return 'Введите имя и фамилию через пробел';
                return null;
              },
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: 'Возраст',
              hint: '25',
              controller: _ageController,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.calendar_today_outlined,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Введите возраст';
                final parsed = int.tryParse(val);
                if (parsed == null || parsed <= 0 || parsed > 120) return 'Некорректный возраст';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildGenderSelector(),
            const SizedBox(height: 20),
            CustomTextField(
              label: 'Придумайте пароль',
              hint: '••••••••',
              controller: _passwordController,
              isPassword: true,
              prefixIcon: Icons.lock_outline_rounded,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Введите пароль';
                if (val.length < 6) return 'Пароль должен быть не менее 6 символов';
                return null;
              },
            ),
            const SizedBox(height: 32),
            Consumer<AuthProvider>(
              builder: (context, auth, child) {
                return CustomButton(
                  text: 'Зарегистрироваться',
                  isLoading: auth.isLoading,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final success = await auth.registerMobile(
                        phone: _phoneController.text,
                        password: _passwordController.text,
                        name: _nameController.text,
                        age: int.parse(_ageController.text),
                        sex: _selectedGender,
                      );
                      if (success && mounted) {
                        // Success
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(auth.errorMessage ?? 'Ошибка регистрации. Попробуйте еще раз.'),
                            backgroundColor: Colors.red.shade800,
                          ),
                        );
                      }
                    }
                  },
                );
              },
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: Form(
            key: _formKey,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: _buildStepContent(),
            ),
          ),
        ),
      ),
    );
  }
}
