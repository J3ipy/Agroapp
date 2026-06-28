import 'package:flutter/material.dart';
import '../../services/consumer_firestore.dart';
import '../../models/produto.dart';
import '../../core/theme.dart';

class ConsumerHomeScreen extends StatelessWidget {
  const ConsumerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Destaques da Região', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Mais vendidos (Global)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          StreamBuilder<List<Produto>>(
            stream: ConsumerFirestoreService.instance.streamMaisVendidosGlobal(limit: 5),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final items = snap.data ?? [];
              if (items.isEmpty) return const Text('Sem destaques no momento.', style: TextStyle(color: Colors.grey));

              return Column(
                children: items.map((p) => Card(
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: p.imagemPath.startsWith('http') ? Image.network(p.imagemPath, width: 50, height: 50, fit: BoxFit.cover) : Image.asset(p.imagemPath, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.image)),
                    ),
                    title: Text(p.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('R\$ ${p.preco} / ${p.unidade}'),
                    trailing: const Icon(Icons.star, color: Colors.amber),
                  ),
                )).toList(),
              );
            },
          ),
        ]),
      ),
    );
  }
}