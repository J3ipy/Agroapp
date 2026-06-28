import 'package:cloud_firestore/cloud_firestore.dart';

class Venda {
  final String id, produtoId, produtoNome, data, status, metodoPagamento;
  final int quantidade;

  Venda({
    required this.id, required this.produtoId, required this.produtoNome,
    required this.quantidade, required this.data, required this.status, required this.metodoPagamento,
  });

  static Venda fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Venda(
      id: doc.id, produtoId: (d['produtoId'] ?? '').toString(), produtoNome: (d['produtoNome'] ?? '').toString(),
      quantidade: (d['quantidade'] ?? 0).toInt(), data: (d['data'] ?? '').toString(),
      status: (d['status'] ?? 'Concluído').toString(), metodoPagamento: (d['metodoPagamento'] ?? 'Pix').toString(),
    );
  }
}