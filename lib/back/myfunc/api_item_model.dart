class ApiItemModel {
final String name;
final String category;
final String method;
final String path;
final String desc;
final List<String> query;
final List<String> body;
final String example;
final String curl;
//===============
const ApiItemModel({
required this.name,
required this.category,
required this.method,
required this.path,
required this.desc,
this.query = const [],
this.body = const [],
required this.example,
required this.curl,
});
//===============
factory ApiItemModel.fromJson(Map<String, dynamic> json) {
return ApiItemModel(
name: json['name'] ?? '',
category: json['category'] ?? '',
method: json['method'] ?? 'GET',
path: json['path'] ?? '',
desc: json['desc'] ?? '',
query: List<String>.from(json['query'] ?? []),
body: List<String>.from(json['body'] ?? []),
example: json['example'] ?? '',
curl: json['curl'] ?? '',
);
}
}
