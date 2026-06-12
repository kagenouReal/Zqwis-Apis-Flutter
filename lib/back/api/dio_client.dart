import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
//===============
class DioClient {
static DioClient? _instance;
static DioClient get instance => _instance ??= DioClient._();
late final Dio dio;
late final PersistCookieJar _cookieJar;
static const String baseUrl = 'zqwis-backend.up.railway.app';
//===============
DioClient._() {
dio = Dio(
BaseOptions(
baseUrl: baseUrl,
connectTimeout: const Duration(seconds: 15),
receiveTimeout: const Duration(seconds: 15),
headers: {
'Content-Type': 'application/json',
'Accept': 'application/json',
},
followRedirects: false,
validateStatus: (status) => status != null && status < 500,
),
);
}
//===============
Future<void> init() async {
final appDocDir = await getApplicationDocumentsDirectory();
_cookieJar = PersistCookieJar(
ignoreExpires: false,
storage: FileStorage('${appDocDir.path}/.cookies/'),
);
dio.interceptors.add(CookieManager(_cookieJar));
dio.interceptors.add(_LogInterceptor());
}
//===============
CookieJar get cookieJar => _cookieJar;
//===============
Future<Response> register(String username, String password) async {
return dio.post(
'/api/register', 
data: {
'username': username,
'password': password,
},
);
}
//===============
Future<Response> login(String username, String password) async {
final csrfRes = await dio.get('/api/auth/csrf');
final csrfToken = csrfRes.data['csrfToken'] as String?;
if (csrfToken == null) throw Exception('Failed to get CSRF token');
return dio.post(
'/api/auth/callback/credentials',
data: {
'username': username,
'password': password,
'csrfToken': csrfToken,
'callbackUrl': '$baseUrl/home',
'json': 'true',
},
options: Options(
contentType: Headers.formUrlEncodedContentType,
followRedirects: false,
validateStatus: (s) => s != null && s < 500, 
),
);
}
//===============
Future<Response> getSession() async {
return dio.get('/api/auth/session');
}
//===============
Future<Response> logout() async {
final csrfRes = await dio.get('/api/auth/csrf');
final csrfToken = csrfRes.data['csrfToken'] as String?;
return dio.post(
'/api/auth/signout',
data: {'csrfToken': csrfToken, 'callbackUrl': '$baseUrl/', 'json': 'true'},
options: Options(contentType: Headers.formUrlEncodedContentType),
);
}
//===============
Future<Response> getProfile() => dio.get('/api/profile');
//===============
Future<Response> updateProfile(Map<String, dynamic> body) =>
dio.put('/api/profile', data: body);
//===============
Future<Response> getApiList() => dio.get('/api/v1/list');
//===============
Future<Response> getStats() => dio.get('/api/stats');
//===============
Future<Response> listUsers() => dio.get('/api/admin/listuser');
//===============
Future<Response> createUser(String username, String password, String role) =>
dio.post('/api/admin/cuser',
data: {'username': username, 'password': password, 'role': role});
//===============
Future<Response> deleteUser(String username) =>
dio.delete('/api/admin/duser', queryParameters: {'username': username});
//===============
Future<Response> setLimit(String username, int amount) =>
dio.post('/api/admin/setlimit',
data: {'username': username, 'amount': amount});
//===============
Future<Response> setIpQuota(String username, int quota) =>
    dio.post('/api/admin/setipquota',
        data: {'username': username, 'quota': quota});
//===============
Future<Response> getOwnerManageData({String? type}) =>
    dio.get('/api/owner/manage', queryParameters: type != null ? {'type': type} : null);
//===============
Future<Response> updateOwnerSetting(String key, dynamic value) =>
    dio.post('/api/owner/manage', data: {
      'action': 'update_setting',
      'key': key,
      'value': value,
    });
//===============
Future<Response> backupDatabase() =>
    dio.post('/api/owner/manage', data: {'action': 'db_backup'});
//===============
Future<Response> getWaStatus() => dio.get('/api/whatsapp/status');
//===============
Future<Response> connectWa(String phoneNumber) =>
    dio.post('/api/whatsapp/connect', data: {'phoneNumber': phoneNumber});
//===============
Future<Response> disconnectWa(String phoneNumber) =>
    dio.post('/api/whatsapp/disconnect', data: {'phoneNumber': phoneNumber});
//===============
Future<Response> getCoins() => dio.get('/api/coins');
//===============
Future<Response> addCoins(String username, int amount, String reason) =>
    dio.post('/api/admin/coins', data: {'username': username, 'amount': amount, 'reason': reason, 'action': 'add'});

Future<Response> adminSetCoins(String username, int amount, String action, String reason) =>
    dio.post('/api/admin/setcoin', data: {'username': username, 'amount': amount, 'action': action, 'reason': reason});

Future<Response> getMissions({String action = ''}) =>
    dio.get('/api/missions', queryParameters: action.isNotEmpty ? {'action': action} : null);
//===============
Future<Response> claimMission(String missionId) =>
    dio.post('/api/missions', data: {'missionId': missionId});
//===============
Future<Response> buyPremium(String packageType) =>
    dio.post('/api/shopping/buyprem', data: {'packageId': packageType});
//===============
Future<Response> buyLimit(String packageType) =>
    dio.post('/api/shopping/buylimit', data: {'packageId': packageType});
//===============
Future<void> clearCookies() async {
await _cookieJar.deleteAll();
}
}
//===============
class _LogInterceptor extends Interceptor {
@override
void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
print('[DIO] ${options.method} ${options.path}');
handler.next(options);
}
//===============
@override
void onError(DioException err, ErrorInterceptorHandler handler) {
print('[DIO ERROR] ${err.response?.statusCode} ${err.message}');
handler.next(err);
}
}
