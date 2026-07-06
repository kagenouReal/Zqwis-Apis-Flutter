import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zqwis/main/helper/config.dart';

class DioClient {
  static DioClient? _instance;
  static DioClient get instance => _instance ??= DioClient._();
  late final Dio dio;
  late final PersistCookieJar _cookieJar;

  DioClient._() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        followRedirects: false,
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  String _generateLoginHash(int timestamp) {
    final bytes = utf8.encode('$timestamp${AppConfig.loginSecret}');
    return sha256.convert(bytes).toString();
  }

  Future<void> init() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    _cookieJar = PersistCookieJar(ignoreExpires: false, storage: FileStorage('${appDocDir.path}/.cookies/'));
    dio.interceptors.add(CookieManager(_cookieJar));
    dio.interceptors.add(_LogInterceptor());
  }

  CookieJar get cookieJar => _cookieJar;

  Future<Response> register(String username, String password) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return dio.post('/api/register', data: {'username': username, 'password': password}, options: Options(headers: {'x-zqwis-ts': ts.toString(), 'x-zqwis-auth': _generateLoginHash(ts)}));
  }

  Future<Response> login(String username, String password) async {
    final csrfRes = await dio.get('/api/auth/csrf');
    final csrfToken = csrfRes.data['csrfToken'] as String?;
    if (csrfToken == null) throw Exception('Failed to get CSRF token');
    final ts = DateTime.now().millisecondsSinceEpoch;
    return dio.post('/api/auth/callback/credentials', data: {'username': username, 'password': password, 'csrfToken': csrfToken, 'callbackUrl': '${AppConfig.baseUrl}/home', 'json': 'true'}, options: Options(contentType: Headers.formUrlEncodedContentType, followRedirects: false, validateStatus: (s) => s != null && s < 500, headers: {'x-zqwis-ts': ts.toString(), 'x-zqwis-auth': _generateLoginHash(ts)}));
  }

  Future<Response> getSession() => dio.get('/api/auth/session');
  Future<Response> logout() async {
    final csrfRes = await dio.get('/api/auth/csrf');
    final csrfToken = csrfRes.data['csrfToken'] as String?;
    return dio.post('/api/auth/signout', data: {'csrfToken': csrfToken, 'callbackUrl': '${AppConfig.baseUrl}/', 'json': 'true'}, options: Options(contentType: Headers.formUrlEncodedContentType));
  }

  Future<Response> getProfile() => dio.get('/api/profile');
  Future<Response> resetApikey() => dio.post('/api/profile/reset-apikey');
  Future<Response> changePassword(String newPassword) => dio.post('/api/profile/update/password', data: {'newPassword': newPassword});
  Future<Response> addIp(String ip) => dio.post('/api/profile/ip/add', data: {'ip': ip});
  Future<Response> deleteIp(String ip) => dio.post('/api/profile/ip/delete', data: {'ip': ip});

  Future<Response> getApiList() => dio.get('/api/v1/list');
  Future<Response> getStats() => dio.get('/api/owner/statsv1');
  
  Future<Response> listUsers() => dio.get('/api/admin/user/list');
  Future<Response> createUser(String username, String password, String role) => dio.post('/api/admin/user/create', data: {'username': username, 'password': password, 'role': role});
  Future<Response> deleteUser(String username) => dio.delete('/api/admin/user/delete', queryParameters: {'username': username});
  Future<Response> setLimit(String username, int amount) => dio.post('/api/admin/user/set-limit', data: {'username': username, 'amount': amount});
  Future<Response> setIpQuota(String username, int quota) => dio.post('/api/admin/user/set-ip-quota', data: {'username': username, 'quota': quota});
  
  Future<Response> getCoins() => dio.get('/api/coins/get');
  Future<Response> addCoins(String username, int amount, String reason) => dio.post('/api/admin/coins/add', data: {'username': username, 'amount': amount, 'reason': reason});
  Future<Response> adminSetCoins(String username, int amount, String action, String reason) => dio.post('/api/admin/coins/set', data: {'username': username, 'amount': amount, 'action': action, 'reason': reason});

  Future<Response> getBroadcast() => dio.get('/api/broadcast');
  Future<Response> getSystemInfo() => dio.get('/api/owner/manage/system-info');
  Future<Response> updateOwnerSetting(String key, dynamic value) => dio.post('/api/owner/manage/settings', data: {'key': key, 'value': value});
  Future<Response> backupDatabase() => dio.post('/api/owner/manage/db/backup');

  Future<Response> getWaStatus() => dio.get('/api/whatsapp/status');
  Future<Response> connectWa(String phoneNumber) => dio.post('/api/whatsapp/connect', data: {'phoneNumber': phoneNumber});
  Future<Response> disconnectWa(String phoneNumber) => dio.post('/api/whatsapp/disconnect', data: {'phoneNumber': phoneNumber});
  
  Future<Response> getMissionsList() => dio.get('/api/missions/list');
  Future<Response> claimMission(String missionId, String rewardType) {
    String path = '/api/missions/claim';
    if (missionId == 'daily_limit') path += '/daily-limit';
    else if (missionId == 'daily_login') path += '/daily-login';
    else if (missionId == 'daily_api_call_10') path += '/api-v1-10x';
    else if (missionId == 'weekly_login_7') path += '/weekly-login-7';
    else if (missionId == 'game_play_1') path += '/game-play-1';
    else if (missionId == 'game_win_3') path += '/game-win-3';
    else if (missionId == 'follow_github') path += '/follow-github';
    else if (missionId == 'follow_tiktok') path += '/follow-tiktok';
    else if (missionId == 'first_premium') path += '/first-premium';
    return dio.post(path, data: {'missionId': missionId});
  }

  Future<Response> buyPremium(String packageType) => dio.post('/api/shopping/buy/premium', data: {'packageId': packageType});
  Future<Response> buyLimit(String packageType) => dio.post('/api/shopping/buy/limit', data: {'packageId': packageType});
  Future<void> clearCookies() async => await _cookieJar.deleteAll();
}

class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('[DIO] ${options.method} ${options.path}');
    handler.next(options);
  }
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('[DIO ERROR] ${err.response?.statusCode} ${err.message}');
    handler.next(err);
  }
}
