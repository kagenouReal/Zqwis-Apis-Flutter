import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zqwis/back/api/dio_client.dart';
import 'package:zqwis/back/myfunc/user_model.dart';
import 'package:dio/dio.dart';
//===============
enum AuthStatus { unknown, authenticated, unauthenticated }
//===============
class AuthProvider extends ChangeNotifier {
AuthStatus _status = AuthStatus.unknown;
UserModel? _user;
String? _errorMessage;
bool _isLoading = false;
AuthStatus get status => _status;
UserModel? get user => _user;
String? get errorMessage => _errorMessage;
bool get isLoading => _isLoading;
bool get isAuthenticated => _status == AuthStatus.authenticated;
//===============
Future<void> checkSession() async {
_isLoading = true;
notifyListeners();
try {
final res = await DioClient.instance.getSession();
if (res.statusCode == 200 &&
res.data != null &&
res.data['user'] != null) {
await _fetchProfile();
} else {
_status = AuthStatus.unauthenticated;
}
} catch (e) {
_status = AuthStatus.unauthenticated;
} finally {
_isLoading = false;
notifyListeners();
}
}
//===============
Future<bool> login(String username, String password) async {
_isLoading = true;
_errorMessage = null;
notifyListeners();
try {
final res = await DioClient.instance.login(username, password);
final isOk = res.statusCode == 200 || res.statusCode == 302;
final hasError = res.data is Map && res.data['url']?.contains('error') == true;
if (isOk && !hasError) {
await _fetchProfile();
_isLoading = false;
notifyListeners();
return true;
} else if (res.statusCode == 401 || hasError) {
_errorMessage = 'Invalid Username Or Password.';
_status = AuthStatus.unauthenticated;
_isLoading = false;
notifyListeners();
return false;
} else {
_errorMessage = 'Login Failed. Please Try Again.';
_status = AuthStatus.unauthenticated;
_isLoading = false;
notifyListeners();
return false;
}
} catch (e) {
_errorMessage = 'Connection Error. Check Server.';
_status = AuthStatus.unauthenticated;
_isLoading = false;
notifyListeners();
return false;
}
}
//===============
Future<bool> register(String username, String password) async {
_isLoading = true;
_errorMessage = null;
notifyListeners();
try {
final res = await DioClient.instance.register(username, password);
if ((res.statusCode == 200 || res.statusCode == 201) && res.data['status'] == true) {
_isLoading = false;
notifyListeners();
return true;
} else {
String backendMsg = res.data['message']?.toString() ?? 'Registration Failed.';
if (res.statusCode == 403 || backendMsg.toLowerCase().contains('forbidden')) {
_errorMessage = 'Username Already Exists Or Restricted.';
} else {
_errorMessage = backendMsg.toUpperCase();
}
_isLoading = false;
notifyListeners();
return false;
}
} catch (e) {
if (e is DioException && e.response != null) {
final resData = e.response!.data;
String backendMsg = (resData is Map && resData['message'] != null)
? resData['message'].toString()
: 'REGISTRATION FAILED.';
if (e.response!.statusCode == 403 || backendMsg.toLowerCase().contains('forbidden')) {
_errorMessage = 'Username Already Exists Or Restricted.';
} else if (backendMsg.toLowerCase().contains('exists')) {
_errorMessage = 'Username Already Exists.';
} else {
_errorMessage = backendMsg.toUpperCase();
}
} else {
_errorMessage = 'Connection Error. Check Server.';
}
_isLoading = false;
notifyListeners();
return false;
}
}
//===============
Future<void> _fetchProfile() async {
try {
final profileRes = await DioClient.instance.getProfile();
if (profileRes.statusCode == 200) {
_user = UserModel.fromJson(profileRes.data);
_status = AuthStatus.authenticated;
final prefs = await SharedPreferences.getInstance();
await prefs.setString('cached_username', _user!.username);
await prefs.setString('cached_role', _user!.role);
await prefs.setString('cached_apikey', _user!.apikey);
} else {
_status = AuthStatus.unauthenticated;
}
} catch (e) {
_status = AuthStatus.unauthenticated;
}
}
//===============
Future<void> refreshProfile() async {
await _fetchProfile();
notifyListeners();
}
//===============
Future<void> logout() async {
try {
await DioClient.instance.logout();
await DioClient.instance.clearCookies();
final prefs = await SharedPreferences.getInstance();
await prefs.clear();
} catch (_) {}
_user = null;
_status = AuthStatus.unauthenticated;
notifyListeners();
}
}
