class VaultItem {
  final String id;
  final String serviceName;
  final String? username;
  final String profileId;
  final int length;
  final Map<String, bool> options;

  VaultItem({
    required this.id,
    required this.serviceName,
    this.username,
    required this.profileId,
    required this.length,
    required this.options,
  });
}
