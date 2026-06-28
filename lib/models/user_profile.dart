class AppUserProfile {
  final String uid, nome, email, role, photoAsset;
  final bool notificacoesAtivas;

  AppUserProfile({
    required this.uid, required this.nome, required this.email,
    required this.role, required this.photoAsset, required this.notificacoesAtivas,
  });

  static AppUserProfile fromDoc(String uid, Map<String, dynamic> d) {
    return AppUserProfile(
      uid: uid, nome: (d['nome'] ?? 'Usuário').toString(), email: (d['email'] ?? '').toString(),
      role: (d['role'] ?? 'vendedor').toString(), photoAsset: (d['photoAsset'] ?? 'assets/images/logo.png').toString(),
      notificacoesAtivas: (d['notificacoesAtivas'] ?? true) as bool,
    );
  }
}