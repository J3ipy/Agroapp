import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/consumer_firestore.dart';
import '../../core/theme.dart';

class ConsumerHistoricoScreen extends StatelessWidget {
  const ConsumerHistoricoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ConsumerFirestoreService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Meus Pedidos')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.streamMeusPedidos(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final pedidos = snap.data!.docs;
          if (pedidos.isEmpty) return const Center(child: Text('Você ainda não fez compras.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pedidos.length,
            itemBuilder: (_, i) {
              final p = pedidos[i].data();
              final itens = List<Map<String, dynamic>>.from(p['itens'] ?? []);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pedido: ${pedidos[i].id}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const Divider(),
                      ...itens.map((item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${item['quantidade']}x ${item['produtoNome']}'),
                        trailing: OutlinedButton(
                          onPressed: () => _mostrarAvaliacaoDialog(context, item['sellerUid'], item['produtoId'], item['produtoNome']),
                          child: const Text('Avaliar'),
                        ),
                      )),
                      const Divider(),
                      Text('Total: R\$ ${p['valorTotal']} (${p['metodoPagamento']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _mostrarAvaliacaoDialog(BuildContext context, String sellerUid, String produtoId, String produtoNome) {
    int nota = 5;
    final obsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text('Avaliar $produtoNome'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(index < nota ? Icons.star : Icons.star_border, color: Colors.amber, size: 32),
                  onPressed: () => setStateDialog(() => nota = index + 1),
                )),
              ),
              TextField(
                controller: obsCtrl,
                decoration: const InputDecoration(labelText: 'Comentário (opcional)', border: OutlineInputBorder()),
                maxLines: 2,
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, foregroundColor: Colors.white),
              onPressed: () async {
                await ConsumerFirestoreService.instance.salvarAvaliacao(sellerUid, produtoId, nota.toDouble(), obsCtrl.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avaliação enviada!')));
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}