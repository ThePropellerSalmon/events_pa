import 'package:events_pa/events_map_page.dart';
import 'package:events_pa/main.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:intl/intl.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _isLoading = false;
  bool _isSignedIn = false;

  // Static fields
  static const String emailLbl = "Email: ";
  static const String firstNameLbl = "First name: ";
  static const String lastNameLbl = "Last name: ";
  static const String enterNewPasswordLbl = "Enter your new password: ";
  static const String confirmNewPasswordLbl = "Confirm your new password: ";
  static const String accountCreationDateLbl = "Active since: ";

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _enterNewPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  // Fetched fields
  String _email = '';
  String _accountCreationDate = '';

  // Error messages
  String? _firstNameError;
  String? _lastNameError;
  String? _enterNewPasswordError;
  String? _confirmNewPasswordError;

  @override
  void initState() {
    super.initState(); // Always call this first
    _loadUserData(); // Custom method to fetch Supabase data
  }

  Future<void> _loadUserData() async {
    final authUser = Supabase.instance.client.auth.currentUser;
    var currentUser;

    if (authUser == null) return;

    final response =
        await Supabase.instance.client
            .from('users')
            .select()
            .eq('userId', authUser.id)
            .single();

    setState(() {
      currentUser = response;

      _email = authUser.email ?? 'N/A';
      _firstNameController.text = currentUser['firstName'] ?? '';
      _lastNameController.text = currentUser['lastName'] ?? '';

      var rawCreationDate = currentUser['accountCreationDate'];
      _accountCreationDate = formatDateToISO8601(rawCreationDate);
    });
  }

  // Function to check if the password is strong
  bool _isStrongPassword(String password) {
    final strongPasswordRegex = RegExp(
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
    );
    return strongPasswordRegex.hasMatch(password);
  }

  bool _validateFields() {
    setState(() {
      _firstNameError =
          _firstNameController.text.isEmpty ? "First Name is required" : null;
      _lastNameError =
          _lastNameController.text.isEmpty ? "Last Name is required" : null;

      if (_enterNewPasswordController.text.isEmpty &&
          _confirmNewPasswordController.text.isEmpty) {
        _enterNewPasswordError = null;
        _confirmNewPasswordError = null;
      } else {
        _enterNewPasswordError =
            !_isStrongPassword(_enterNewPasswordController.text)
                ? "Password must be at least 8 characters, contain an uppercase letter, a lowercase letter, a number, and a special character."
                : null;
        _confirmNewPasswordError =
            _confirmNewPasswordController.text !=
                    _enterNewPasswordController.text
                ? "Passwords do not match"
                : null;
      }
    });

    return _firstNameError == null &&
        _lastNameError == null &&
        _enterNewPasswordError == null &&
        _confirmNewPasswordError == null;
  }

  Future _updateUserInfo() async {
    if (!_validateFields()) return;

    final authUser = Supabase.instance.client.auth.currentUser;

    if (authUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_enterNewPasswordController.text != "" &&
          _confirmNewPasswordController.text != "") {
        final passwordUpdated = await _updatePassword(
          _enterNewPasswordController.text,
        );

        if (!passwordUpdated) {
          return;
        }
      }

      final response =
          await Supabase.instance.client
              .from('users')
              .update({
                'firstName': _firstNameController.text.trim(),
                'lastName': _lastNameController.text.trim(),
              })
              .eq('userId', authUser.id)
              .select();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('User updated successfully!')));
    } catch (error) {
      context.showSnackBar('Error updating the user: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _updatePassword(String newPassword) async {
    try {
      final response = await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user != null) {
        return true;
      } else {
        return false;
      }
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unexpected error: $error')));
    }
    return false;
  }

  // Custom functions

  // Date format such as "1st of January 2025"
  String formatDateToISO8601(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '';

    try {
      final parsedDate = DateTime.parse(rawDate);

      // Get the day with suffix
      final day = parsedDate.day;
      final suffix = getDaySuffix(day);

      // Format as "1st of January 2025"
      final formatted =
          '$day$suffix of ${DateFormat('MMMM y').format(parsedDate)}';
      return formatted;
    } catch (e) {
      return '';
    }
  }

  String getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //title: const Text('Account Page'),
        flexibleSpace: SafeArea(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text('Go to Map'),
                onPressed: () {
                  context.push('/events_map');
                },
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome to your account!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              // Email
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        emailLbl,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        _email,
                        style: const TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // FirstName
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        firstNameLbl,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _firstNameController,
                        decoration: InputDecoration(errorText: _firstNameError),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // LastName
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        lastNameLbl,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _lastNameController,
                        decoration: InputDecoration(errorText: _lastNameError),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // EnterNewPassword
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        enterNewPasswordLbl,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _enterNewPasswordController,
                        decoration: InputDecoration(
                          errorText: _enterNewPasswordError,
                        ),
                        style: const TextStyle(fontSize: 16),
                        obscureText: true,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ConfirmNewPassword
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        confirmNewPasswordLbl,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _confirmNewPasswordController,
                        decoration: InputDecoration(
                          errorText: _confirmNewPasswordError,
                        ),
                        style: const TextStyle(fontSize: 16),
                        obscureText: true,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Divider(
                thickness: 1,
                color: Colors.black, // You can change color
              ),

              const SizedBox(height: 10),

              // Creation date
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        accountCreationDateLbl,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        _accountCreationDate,
                        style: const TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _isLoading ? null : _updateUserInfo,
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Update'),
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: () => Supabase.instance.client.auth.signOut(),
                child: const Text('Log Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
