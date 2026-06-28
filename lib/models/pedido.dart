import 'package:cloud_firestore/cloud_firestore.dart';
import 'produto.dart';

class CartItem {
  final Produto produto;
  int quantidade;
  CartItem({required this.produto, this.quantidade = 1});
  double get subtotal => produto.preco * quantidade;
}

class Pedido {
  final String id, consumidorUid, consumidorNome, metodoPagamento, status, enderecoEntrega;
  final List<Map<String, dynamic>> itens;
  final double valorTotal;
  final Timestamp dataPedido;

  Pedido({
    required this.id, required this.consumidorUid, required this.consumidorNome,
    required this.itens, required this.valorTotal, required this.metodoPagamento,
    required this.status, required this.dataPedido, required this.enderecoEntrega,
  });

  static Pedido fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Pedido(
      id: doc.id, consumidorUid: (d['consumidorUid'] ?? '').toString(),
      consumidorNome: (d['consumidorNome'] ?? '').toString(),
      itens: List<Map<String, dynamic>>.from(d['itens'] ?? []),
      valorTotal: (d['valorTotal'] ?? 0).toDouble(), metodoPagamento: (d['metodoPagamento'] ?? '').toString(),
      status: (d['status'] ?? 'aguardando_pagamento').toString(),
      dataPedido: d['dataPedido'] as Timestamp? ?? Timestamp.now(), enderecoEntrega: (d['enderecoEntrega'] ?? '').toString(),
    );
  }
}