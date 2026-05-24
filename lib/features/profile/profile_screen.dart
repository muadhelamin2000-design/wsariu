import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'models/user_model.dart';
import 'services/user_service.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/modern_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<UserModel> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    setState(() {
      _users = UserService.getUsers();
    });
  }

  void _addNewUser() async {
    final name = await ModernDialog.showInput(
      context: context,
      title: 'إضافة مستخدم جديد',
      hint: 'اسم المستخدم',
    );
    
    if (name != null && name.isNotEmpty) {
      final newUser = UserModel(
        id: const Uuid().v4(),
        name: name,
        createdAt: DateTime.now(),
      );
      await UserService.saveUser(newUser);
      _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5EF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'نِعْمَ الْعَبْدُ',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0F3D2E)),
            ),
            const SizedBox(height: 8),
            const Text('من المستخدم اليوم؟', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            SizedBox(
              height: 200,
              child: _users.isEmpty
                  ? const Text('لا يوجد مستخدمين بعد')
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return GestureDetector(
                          onTap: () {
                            UserService.currentUser = user;
                            context.go('/dashboard');
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: const Color(0xFF0F3D2E),
                                  child: Text(user.avatar, style: const TextStyle(fontSize: 30)),
                                ),
                                const SizedBox(height: 12),
                                Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                  onPressed: () async {
                                    await UserService.deleteUser(user.id);
                                    _loadUsers();
                                  },
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 40),
            TextButton.icon(
              icon: const Icon(Icons.edit_note),
              label: const Text('إضافة فرد جديد للأسرة'),
              onPressed: _addNewUser,
            ),
          ],
        ),
      ),
    );
  }
}
