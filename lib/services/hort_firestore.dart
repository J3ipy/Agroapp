import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/produto.dart';
import '../models/venda.dart';
import '../models/user_profile.dart';
import 'auth_service.dart';

class HortFirestoreService {
  HortFirestoreService._();
  static final HortFirestoreService instance = HortFirestoreService._();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid => AuthService.instance.currentUser!.uid;
  DocumentReference<Map<String, dynamic>> get _userDoc => _db.collection('users').doc(_uid);
  CollectionReference<Map<String, dynamic>> get _produtosRef => _userDoc.collection('produtos');
  CollectionReference<Map<String, dynamic>> get _vendasRef => _userDoc.collection('vendas');

  Stream<AppUserProfile> streamPerfil() => _userDoc.snapshots().map((s) => AppUserProfile.fromDoc(_uid, s.data() ?? {}));
  Future<AppUserProfile> getPerfilOnce() async => AppUserProfile.fromDoc(_uid, (await _userDoc.get()).data() ?? {});

  Future<void> atualizarPerfil({String? nome, String? photoAsset, bool? notificacoesAtivas}) async {
    final data = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    if (nome != null) data['nome'] = nome.trim();
    if (photoAsset != null) data['photoAsset'] = photoAsset;
    if (notificacoesAtivas != null) data['notificacoesAtivas'] = notificacoesAtivas;
    await _userDoc.set(data, SetOptions(merge: true));
  }

  Stream<List<Produto>> streamProdutos() => _produtosRef.orderBy('createdAt', descending: true).snapshots().map((s) => s.docs.map((d) => Produto.fromDoc(d)).toList());
  Stream<List<Produto>> streamMaisVendidos({int limit = 5}) => _produtosRef.orderBy('vendasMes', descending: true).limit(limit).snapshots().map((s) => s.docs.map((d) => Produto.fromDoc(d)).toList());

  Future<void> adicionarProduto({required String nome, required double preco, required int quantidade, required String unidade, required String dataAdicao, required String imagemPath}) async {
    await _produtosRef.add({
      'sellerUid': _uid, 'nome': nome.trim(), 'preco': preco, 'quantidade': quantidade, 'unidade': unidade,
      'imagemPath': imagemPath, 'ativo': true, 'dataAdicao': dataAdicao, 'vendasTotal': 0, 'vendasMes': 0, 'vendasSemana': 0,
      'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> atualizarProduto({required String produtoId, double? novoPreco, int? novaQuantidade}) async {
    final data = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    if (novoPreco != null) data['preco'] = novoPreco;
    if (novaQuantidade != null) data['quantidade'] = novaQuantidade;
    await _produtosRef.doc(produtoId).update(data);
  }

  Future<void> alternarStatusProduto(String produtoId, bool ativoAtual) async => await _produtosRef.doc(produtoId).update({'ativo': !ativoAtual, 'updatedAt': FieldValue.serverTimestamp()});
  Future<void> excluirProduto(String produtoId) async => await _produtosRef.doc(produtoId).delete();

  Stream<List<Venda>> streamVendasSemana() {
    // Simplificado para evitar a exigência de índice composto no Firebase
    return _vendasRef
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Venda.fromDoc(d)).toList());
  }

  Future<void> registrarVenda({required String produtoId, required int quantidadeVendida, required String metodoPagamento}) async {
    await _db.runTransaction((tx) async {
      final snap = await tx.get(_produtosRef.doc(produtoId));
      if (!snap.exists) throw Exception('Produto não encontrado.');
      final data = snap.data()!;
      if (!(data['ativo'] ?? true)) throw Exception('Produto inativo.');
      if ((data['quantidade'] ?? 0) < quantidadeVendida) throw Exception('Estoque insuficiente.');

      tx.update(_produtosRef.doc(produtoId), {
        'quantidade': (data['quantidade'] ?? 0) - quantidadeVendida,
        'vendasTotal': (data['vendasTotal'] ?? 0) + quantidadeVendida,
        'vendasMes': (data['vendasMes'] ?? 0) + quantidadeVendida,
        'vendasSemana': (data['vendasSemana'] ?? 0) + quantidadeVendida,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.set(_vendasRef.doc(), {
        'produtoId': produtoId, 'produtoNome': data['nome'], 'quantidade': quantidadeVendida,
        'data': DateFormat('dd/MM/yyyy').format(DateTime.now()), 'status': 'Concluído',
        'metodoPagamento': metodoPagamento, 'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}