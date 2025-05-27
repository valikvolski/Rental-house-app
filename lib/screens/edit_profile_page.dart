import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/user_service.dart';
import '../services/storage_service.dart';

class EditProfilePage extends StatefulWidget {
  final AuthService authService;
  final String? initialName;
  final String? initialEmail;
  final String? initialPhone;
  final String? initialRole;
  final String? initialPhotoUrl;

  const EditProfilePage({
    super.key,
    required this.authService,
    this.initialName,
    this.initialEmail,
    this.initialPhone,
    this.initialRole,
    this.initialPhotoUrl,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _emailController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController;
  String _role = 'user';
  File? _pickedImage;
  String? _photoUrl;
  bool _isLoading = false;
  bool _isUserDataLoading = true;
  bool _canEditAge = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _ageController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = widget.authService.currentUser;
    if (user == null) return;
    final userService = UserService();
    final firestoreUser = await userService.getUserInfo(user.uid);
    // Проверка Google-аккаунта
    bool isGoogle = user.providerData.any((p) => p.providerId == 'google.com');
    String ageStr = (firestoreUser?['age'] ?? '').toString();
    bool ageEmpty = ageStr.isEmpty || ageStr == '0';
    setState(() {
      _nameController.text = firestoreUser?['displayName'] ?? user.displayName ?? '';
      _phoneController.text = (firestoreUser?['phoneNumber'] ?? '').replaceAll('+375', '');
      _emailController.text = firestoreUser?['email'] ?? user.email ?? '';
      _role = firestoreUser?['role'] ?? 'user';
      _photoUrl = firestoreUser?['photoUrl'] ?? user.photoURL;
      _ageController.text = ageStr;
      _canEditAge = isGoogle && ageEmpty;
      _isUserDataLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Имя не может быть пустым')),
      );
      return;
    }
    if (_phoneController.text.isEmpty || _phoneController.text.length != 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректный номер телефона')),);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = widget.authService.currentUser;
      String? photoUrl = _photoUrl;
      if (user != null && _pickedImage != null) {
        // Загружаем фото профиля в Storage
        final storageService = StorageService();
        photoUrl = await storageService.uploadImage(_pickedImage!, user.uid);
      }
      if (user != null) {
        await user.updateDisplayName(_nameController.text);
        // await user.updatePhotoURL(photoUrl); // если нужно обновить в Firebase Auth
        final emailToSave = _emailController.text.isNotEmpty ? _emailController.text : user.email;
        await widget.authService.updateUserData(user.uid, {
          'displayName': _nameController.text,
          'phoneNumber': '+375${_phoneController.text}',
          'role': _role,
          'photoUrl': photoUrl,
          'email': emailToSave,
          'age': _ageController.text,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Профиль успешно обновлен')),
          );
          setState(() {
            _canEditAge = false;
          });
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при обновлении профиля: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _changePassword() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final user = FirebaseAuth.instance.currentUser;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сменить пароль'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Старый пароль'),
                validator: (v) => v == null || v.isEmpty ? 'Введите старый пароль' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Новый пароль'),
                validator: (v) => v == null || v.length < 6 ? 'Минимум 6 символов' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final cred = EmailAuthProvider.credential(
                  email: user!.email!,
                  password: oldPasswordController.text,
                );
                await user.reauthenticateWithCredential(cred);
                await user.updatePassword(newPasswordController.text);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Пароль успешно изменён')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка: $e')),
                );
              }
            },
            child: const Text('Сменить'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestLandlord() async {
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _ageController.text.isEmpty ||
        (_photoUrl == null || _photoUrl!.isEmpty) && _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все поля и добавьте фото!')),
      );
      return;
    }
    if (int.tryParse(_ageController.text) == null || int.parse(_ageController.text) < 21) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Стать арендодателем можно только с 21 года!')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = widget.authService.currentUser;
      if (user != null) {
        String? photoUrl = _photoUrl;
        if (_pickedImage != null) {
          final storageService = StorageService();
          photoUrl = await storageService.uploadImage(_pickedImage!, user.uid);
        }
        await widget.authService.updateUserData(user.uid, {
          'role': 'landlord',
          'displayName': _nameController.text,
          'phoneNumber': '+375${_phoneController.text}',
          'photoUrl': photoUrl,
          'age': _ageController.text,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Теперь вы арендодатель!')),
          );
          setState(() {
            _role = 'landlord';
          });
          Navigator.pop(context, {'role': 'landlord'});
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Личные данные',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: _isLoading || _isUserDataLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundImage: _pickedImage != null
                                  ? FileImage(_pickedImage!)
                                  : (_photoUrl != null && _photoUrl!.isNotEmpty)
                                      ? NetworkImage(_photoUrl!) as ImageProvider
                                      : const AssetImage('assets/default_avatar.png'),
                              child: (_photoUrl == null || _photoUrl!.isEmpty) && _pickedImage == null
                                  ? const Icon(Icons.person, size: 48)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Material(
                                color: colors.primary,
                                shape: const CircleBorder(),
                                child: IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.white),
                                  onPressed: _pickImage,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Имя',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _emailController,
                          enabled: false,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.number,
                          maxLength: 9,
                          decoration: InputDecoration(
                            labelText: 'Телефон',
                            prefixText: '+375 ',
                            hintText: '29*******',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _ageController,
                          enabled: _canEditAge == true,
                          decoration: InputDecoration(
                            labelText: 'Возраст',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          enabled: false,
                          controller: TextEditingController(text: _role == 'user' ? 'Арендатор' : 'Арендодатель'),
                          decoration: InputDecoration(
                            labelText: 'Ваша роль',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                            child: Text(
                              'Сохранить',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _changePassword,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Сменить пароль'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_role == 'user')
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _requestLandlord,
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Запросить разрешение на сдачу в аренду'),
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