import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/produto.dart';
import 'auth_service.dart';

class ConsumerFirestoreService {
  ConsumerFirestoreService._();
  static final ConsumerFirestoreService instance = ConsumerFirestoreService._();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid => AuthService.instance.currentUser!.uid;

  // Produtos
  Stream<List<Produto>> streamProdutosAtivos() => _db.collectionGroup('produtos').where('ativo', isEqualTo: true).orderBy('updatedAt', descending: true).snapshots().map((s) => s.docs.map((d) => Produto.fromDoc(d)).toList());

  Stream<List<Produto>> streamMaisVendidosGlobal({int limit = 5}) => _db.collectionGroup('produtos').where('ativo', isEqualTo: true).orderBy('vendasMes', descending: true).limit(limit).snapshots().map((s) => s.docs.map((d) => Produto.fromDoc(d)).toList());

  // ================= FAVORITOS =================
  Stream<List<String>> streamFavoritosIds() {
    return _db.collection('users').doc(_uid).collection('favoritos')
        .snapshots().map((snap) => snap.docs.map((d) => d.id).toList());
  }

  Future<void> alternarFavorito(String produtoId, bool isFavorito) async {
    final ref = _db.collection('users').doc(_uid).collection('favoritos').doc(produtoId);
    if (isFavorito) {
      await ref.delete();
    } else {
      await ref.set({'produtoId': produtoId, 'dataSalvo': FieldValue.serverTimestamp()});
    }
  }

  // ================= AVALIAÇÕES =================
  Stream<double> streamMediaAvaliacoes(String sellerUid, String produtoId) {
    return _db.collection('users').doc(sellerUid).collection('produtos').doc(produtoId).collection('avaliacoes')
        .snapshots().map((snap) {
      if (snap.docs.isEmpty) return 0.0;
      double total = 0;
      for (var doc in snap.docs) {
        total += (doc.data()['nota'] ?? 0).toDouble();
      }
      return total / snap.docs.length;
    });
  }

  Future<void> salvarAvaliacao(String sellerUid, String produtoId, double nota, String comentario) async {
    await _db.collection('users').doc(sellerUid).collection('produtos').doc(produtoId).collection('avaliacoes').add({
      'consumidorUid': _uid,
      'nota': nota,
      'comentario': comentario,
      'data': FieldValue.serverTimestamp(),
    });
  }

  // ================= HISTÓRICO DE COMPRAS =================
  Stream<QuerySnapshot<Map<String, dynamic>>> streamMeusPedidos() {
    return _db.collection('pedidos')
        .where('consumidorUid', isEqualTo: _uid)
        .orderBy('dataPedido', descending: true)
        .snapshots();
  }
}