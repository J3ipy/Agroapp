import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/cart_provider.dart';
import '../../services/auth_service.dart';
import '../../services/hort_firestore.dart';
import '../../services/notification_service.dart';
import 'mapa_endereco_screen.dart'; // IMPORT ADICIONADO
import 'pix_screen.dart'; // IMPORT ADICIONADO

class ConsumerCarrinhoScreen extends StatelessWidget {
  const ConsumerCarrinhoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Scaffold(
      appBar: AppBar(title: const Text('Meu Carrinho', style: TextStyle(fontWeight: FontWeight.bold))),
      body: cart.items.isEmpty
          ? const Center(child: Text('O seu carrinho está vazio.', style: TextStyle(color: Colors.grey)))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final item = cart.items.values.toList()[index];
                final prodId = cart.items.keys.toList()[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: item.produto.imagemPath.startsWith('http')
                              ? Image.network(item.produto.imagemPath, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(width: 60, height: 60, color: Colors.grey[300]))
                              : Image.asset(item.produto.imagemPath, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(width: 60, height: 60, color: Colors.grey[300])),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.produto.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('${currency.format(item.produto.preco)} un.', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text('Subtotal: ${currency.format(item.subtotal)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(icon: const Icon(Icons.remove_circle_outline), color: Colors.red, onPressed: () => cart.updateQuantity(prodId, item.quantidade - 1)),
                            Text('${item.quantidade}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            IconButton(icon: const Icon(Icons.add_circle_outline), color: const Color(0xFF00A99D), onPressed: () => cart.updateQuantity(prodId, item.quantidade + 1)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(currency.format(cart.total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF00A99D))),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B0FF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () => _mostrarOpcoesPagamento(context, cart),
                    child: const Text('FINALIZAR PEDIDO', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _mostrarOpcoesPagamento(BuildContext context, CartProvider cart) async {
    // 1. ANTES DE PAGAR, PEDE A LOCALIZAÇÃO
    final localizacao = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapaEnderecoScreen()),
    );

    // Se o usuário cancelou o mapa, aborta o checkout
    if (localizacao == null) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('É necessário confirmar o local de entrega.')));
      return;
    }

    String enderecoFormatado = "Lat: ${localizacao.latitude}, Lng: ${localizacao.longitude}";

    if (!context.mounted) return;

    // 2. MOSTRA OPÇÕES DE PAGAMENTO
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Método de Pagamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(leading: const Icon(Icons.pix, color: const Color(0xFF32BCAD)), title: const Text('Pix'), onTap: () => _processarPedido(context, ctx, cart, 'Pix', enderecoFormatado)),
              ListTile(leading: const Icon(Icons.credit_card, color: Colors.blue), title: const Text('Cartão de Crédito/Débito na Entrega'), onTap: () => _processarPedido(context, ctx, cart, 'Cartão', enderecoFormatado)),
              ListTile(leading: const Icon(Icons.request_page, color: Colors.black54), title: const Text('Dinheiro na Entrega'), onTap: () => _processarPedido(context, ctx, cart, 'Dinheiro', enderecoFormatado)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processarPedido(BuildContext mainContext, BuildContext bottomSheetContext, CartProvider cart, String metodoPagamento, String endereco) async {
    Navigator.pop(bottomSheetContext);
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) throw Exception("Utilizador não autenticado");

      final perfil = await HortFirestoreService.instance.getPerfilOnce();
      final db = FirebaseFirestore.instance;

      // Usamos um WriteBatch para garantir que TUDO acontece ao mesmo tempo (Atomicidade)
      final batch = db.batch();

      List<Map<String, dynamic>> itensDb = [];
      final pedidoRef = db.collection('pedidos').doc();

      for (var item in cart.items.values) {
        // 1. Prepara dados do pedido
        itensDb.add({
          "produtoId": item.produto.id,
          "produtoNome": item.produto.nome,
          "sellerUid": item.produto.sellerUid,
          "quantidade": item.quantidade,
          "precoUnitario": item.produto.preco,
          "subtotal": item.subtotal,
        });

        // 2. DEDUZ ESTOQUE EM TEMPO REAL
        final produtoRef = db.collection('users').doc(item.produto.sellerUid).collection('produtos').doc(item.produto.id);
        batch.update(produtoRef, {
          'quantidade': FieldValue.increment(-item.quantidade),
          'vendasTotal': FieldValue.increment(item.quantidade),
          'vendasMes': FieldValue.increment(item.quantidade),
          'vendasSemana': FieldValue.increment(item.quantidade),
        });

        // 3. REGISTA A VENDA NO HISTÓRICO DO VENDEDOR
        final vendaRef = db.collection('users').doc(item.produto.sellerUid).collection('vendas').doc();
        batch.set(vendaRef, {
          'produtoId': item.produto.id,
          'produtoNome': item.produto.nome,
          'quantidade': item.quantidade,
          'data': DateFormat('dd/MM/yyyy').format(DateTime.now()),
          'status': 'Concluído',
          'metodoPagamento': metodoPagamento,
          'createdAt': FieldValue.serverTimestamp(),
          'buyerUid': user.uid,
        });
      }

      // 4. Salva o Pedido Global
      batch.set(pedidoRef, {
        "consumidorUid": user.uid,
        "consumidorNome": perfil.nome,
        "itens": itensDb,
        "valorTotal": cart.total,
        "metodoPagamento": metodoPagamento,
        "status": "aguardando_pagamento",
        "dataPedido": FieldValue.serverTimestamp(),
        "enderecoEntrega": endereco,
      });

      // 5. Executa tudo no Firebase de uma vez!
      await batch.commit();

      // Envia notificação
      await NotificationService.instance.sendOrderConfirmationLocal(pedidoRef.id);

      final valorFinal = cart.total; // Guarda o valor antes de limpar
      cart.clear();

      if (mainContext.mounted) {
        if (metodoPagamento == 'Pix') {
          // NAVEGA PARA A TELA DO QR CODE DO PIX
          Navigator.push(mainContext, MaterialPageRoute(builder: (_) => PixScreen(pedidoId: pedidoRef.id, total: valorFinal)));
        } else {
          ScaffoldMessenger.of(mainContext).showSnackBar(const SnackBar(content: Text('Pedido realizado com sucesso!'), backgroundColor: Colors.green));
        }
      }
    } catch (e) {
      if (mainContext.mounted) ScaffoldMessenger.of(mainContext).showSnackBar(SnackBar(content: Text('Erro ao processar pedido: $e'), backgroundColor: Colors.red));
    }
  }
}