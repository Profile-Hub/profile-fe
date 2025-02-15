import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/admin_services.dart';
import '../models/adminmodel.dart';
import '../services/getAlluser_services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../routes.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final AdminService _adminService = AdminService();
  List<VerificationRequest> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _users = await _adminService.requestVerification();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching users: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            GoRouter.of(context).go(Routes.home);
          },
        ),
        title: Text('User Request'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index].user;
                if (user.country.isEmpty || user.email.isEmpty) {
                  return SizedBox.shrink();
                }
                return Card(
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    title: Text('Name: ${user.firstName} ${user.lastName}'),
                    subtitle: Text('Country: ${user.country} | Phone Number: ${user.phoneNumber}'),
                    trailing: user.isVerifiedDocument
                        ? SizedBox.shrink()
                        : Text(
                            'Not Verified',
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                    onTap: () {
                      GoRouter.of(context).go('${Routes.documentverify}/${user.id}');
                    },
                  ),
                );
              },
            ),
    );
  }
}
