import 'package:flutter/material.dart';
import '../../services/hort_firestore.dart';
import '../../models/produto.dart';
import '../../core/theme.dart';

class SellerHomeScreen extends StatelessWidget {
  const SellerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/logo.png', height: 40, errorBuilder: (_,__,___) => const Text('AgroApp')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Seus produtos mais vendidos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          StreamBuilder<List<Produto>>(
            stream: HortFirestoreService.instance.streamMaisVendidos(limit: 5),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final items = snap.data ?? [];
              if (items.isEmpty) return const Text('Nenhuma venda registrada ainda.', style: TextStyle(color: Colors.grey));

              return Column(
                children: items.map((p) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.trending_up, color: Colors.green),
                    title: Text(p.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${p.vendasMes} vendas no mês • Estoque: ${p.quantidade}'),
                  ),
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 30),
          _didYouKnowCard(),
        ]),
      ),
    );
  }

  Widget _didYouKnowCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Row(children: [
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Sabia que...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 8),
          Text('A agricultura familiar é responsável por cerca de 70% dos alimentos que chegam à mesa dos brasileiros.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ])),
        const SizedBox(width: 10),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.agriculture, color: kPrimaryColor, size: 30))
      ]),
    );
  }
}