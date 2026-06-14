class UserModel {
  final String username;
  final String role;
  final String apikey;
  final dynamic limit;
  final List<String> whitelistIp;
  final bool isRoot;
  final String? password;
  final String? createdAt;
  final dynamic maxIpQuota;
  
  // New fields from updated backend
  final Map<String, dynamic>? premium;
  final Map<String, dynamic>? coins;
  final List<dynamic>? coinHistory;
  final Map<String, dynamic>? missions;
  final Map<String, dynamic>? activity;

  //===============
  const UserModel({
    required this.username,
    required this.role,
    required this.apikey,
    required this.limit,
    required this.whitelistIp,
    this.isRoot = false,
    this.password,
    this.createdAt,
    this.maxIpQuota,
    this.premium,
    this.coins,
    this.coinHistory,
    this.missions,
    this.activity,
  });

  //===============
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // If the json has a 'data' key, it might be the wrapped response
    final data = json.containsKey('data') && json['data'] is Map<String, dynamic> 
        ? json['data'] as Map<String, dynamic> 
        : json;

    return UserModel(
      username: data['username'] ?? '',
      role: data['role'] ?? 'user',
      apikey: data['apikey'] ?? '',
      limit: data['limit'],
      whitelistIp: List<String>.from(data['whitelistIp'] ?? []),
      isRoot: data['isRoot'] ?? false,
      password: data['password'],
      createdAt: data['createdAt'],
      maxIpQuota: data['maxIpQuota'],
      premium: data['premium'],
      coins: data['coins'],
      coinHistory: data['coinHistory'],
      missions: data['missions'],
      activity: data['activity'],
    );
  }

  //===============
  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin' || role == 'owner';
  String get limitDisplay => limit.toString();
  String get ipQuotaDisplay => (maxIpQuota ?? '0').toString();
  
  // Helper getters for new fields
  bool get isPremium => premium?['isPremium'] ?? false;
  String get premiumType => premium?['type'] ?? 'free';
  bool get isPermanentPremium => isPremium && premiumType == 'permanent';
  
  int get premiumDaysLeft {
    if (!isPremium || isPermanentPremium) return 0;
    return premium?['daysLeft'] ?? 0;
  }

  int get totalCoins => coins?['total'] ?? 0;
}
