import 'package:cloud_firestore/cloud_firestore.dart';

class Produto {
  final String id, docPath, sellerUid, nome, unidade, imagemPath, dataAdicao, categoria;
  final double preco;
  final int quantidade, vendasTotal, vendasMes, vendasSemana;
  final bool ativo;

  Produto({
    required this.id, required this.docPath, required this.sellerUid,
    required this.nome, required this.preco, required this.quantidade,
    required this.unidade, required this.imagemPath, required this.ativo,
    required this.dataAdicao, required this.vendasTotal, required this.categoria,
    required this.vendasMes, required this.vendasSemana,
  });

  static Produto fromDoc(DocumentSnapshot<Map<String, dynamic>> doc, {String? sellerUidOverride}) {
    final d = doc.data() ?? {};
    String inferredSeller = sellerUidOverride ?? (d['sellerUid'] ?? '').toString();
    if (inferredSeller.isEmpty) {
      final seg = doc.reference.path.split('/');
      final idx = seg.indexOf('users');
      if (idx != -1 && idx + 1 < seg.length) inferredSeller = seg[idx + 1];
    }
    return Produto(
      id: doc.id, docPath: doc.reference.path, sellerUid: inferredSeller,
      nome: (d['nome'] ?? '').toString(), preco: (d['preco'] ?? 0).toDouble(),
      quantidade: (d['quantidade'] ?? 0).toInt(), unidade: (d['unidade'] ?? 'Kg').toString(),
      categoria: (d['categoria'] ?? 'Outros').toString(),
      imagemPath: (d['imagemPath'] ?? 'assets/images/logo.png').toString(),
      ativo: (d['ativo'] ?? true) as bool, dataAdicao: (d['dataAdicao'] ?? '').toString(),
      vendasTotal: (d['vendasTotal'] ?? 0).toInt(), vendasMes: (d['vendasMes'] ?? 0).toInt(),
      vendasSemana: (d['vendasSemana'] ?? 0).toInt(),
    );
  }
}