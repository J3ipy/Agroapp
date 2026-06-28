import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Imports das suas outras telas e serviços
import 'consumer_mercado.dart';
import 'consumer_carrinho.dart';
import 'consumer_historico.dart';
import '../../shared/perfil_screen.dart';
import '../../services/cart_provider.dart';
import '../../models/produto.dart';
import '../../core/theme.dart';

// ============================================================================
// 1. O CONTAINER (Controla as Abas de Navegação Inferior)
// ============================================================================
class ConsumerMainContainer extends StatefulWidget {
  const ConsumerMainContainer({super.key});

  @override
  State<ConsumerMainContainer> createState() => _ConsumerMainContainerState();
}

class _ConsumerMainContainerState extends State<ConsumerMainContainer> {
  int _idx = 0;

  final _telas = const [
    ConsumerHomeScreen(),
    ConsumerMercadoScreen(),
    ConsumerHistoricoScreen(),
    SharedPerfilScreen()
  ];

  @override
  Widget build(BuildContext context) {
    final cartItemCount = context.watch<CartProvider>().itemCount;

    return Scaffold(
      body: _telas[_idx],
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimaryColor,
        child: Badge(
          isLabelVisible: cartItemCount > 0,
          label: Text('$cartItemCount'),
          child: const Icon(Icons.shopping_cart, color: Colors.white),
        ),
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ConsumerCarrinhoScreen())
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.storefront), label: 'Mercado'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Pedidos'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

// ============================================================================
// 2. A TELA HOME (Dashboard de Boas-vindas com Produtos Mais Vendidos)
// ============================================================================
class ConsumerHomeScreen extends StatefulWidget {
  const ConsumerHomeScreen({super.key});

  @override
  State<ConsumerHomeScreen> createState() => _ConsumerHomeScreenState();
}

class _ConsumerHomeScreenState extends State<ConsumerHomeScreen> {
  late String _mensagemConsumidor;
  final _uid = FirebaseAuth.instance.currentUser?.uid;

  final List<String> _frasesConsumidor = [
    "Comprando aqui, você apoia diretamente o trabalhador rural e fortalece a economia local!",
    "Alimentos colhidos frescos direto da horta para a mesa da sua família. Aproveite!",
    "Sabia que consumir produtos da época é mais saudável e ajuda a economizar nas compras?",
    "Fique de olho no estoque! Nossos produtores parceiros trazem novidades todas as semanas."
  ];

  @override
  void initState() {
    super.initState();
    _mensagemConsumidor = _frasesConsumidor[Random().nextInt(_frasesConsumidor.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AgroApp', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CORREÇÃO: Saudação dinâmica buscando o primeiro nome do Cliente logado
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(_uid).snapshots(),
              builder: (context, snapshot) {
                String nomeExibicao = "Carregando...";
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final nomeCompleto = data['nome'] ?? 'Cliente';
                  nomeExibicao = nomeCompleto.split(' ').first; // Pega só o primeiro nome
                } else if (snapshot.hasError) {
                  nomeExibicao = "Cliente";
                }

                return Text(
                    'Bem-vindo de volta, $nomeExibicao!',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                );
              },
            ),
            const SizedBox(height: 4),
            Text('O que deseja colocar na mesa hoje?', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),

            // CARD DE MENSAGENS (Consumo Consciente)
            Card(
              color: Colors.green[50],
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.eco, color: Colors.green, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Consumo Consciente', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(_mensagemConsumidor, style: const TextStyle(color: Colors.black87, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text('🔥 Produtos Mais Vendidos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // CORREÇÃO: Listagem real dos produtos mais vendidos globalmente via Collection Group
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collectionGroup('produtos')
                  .orderBy('vendasTotal', descending: true)
                  .limit(3)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('Nenhum registro de vendas no momento.', style: TextStyle(color: Colors.grey));
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final nome = data['nome'] ?? 'Produto';
                    final preco = (data['preco'] ?? 0.0).toDouble();
                    final unidade = data['unidade'] ?? 'Un';
                    final vendasTotal = data['vendasTotal'] ?? 0;
                    final imagemPath = data['imagemPath'] ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imagemPath.startsWith('http')
                              ? Image.network(imagemPath, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(width: 50, height: 50, color: Colors.grey[200]))
                              : Image.asset(imagemPath, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(width: 50, height: 50, color: Colors.grey[200])),
                        ),
                        title: Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('R\$ ${preco.toStringAsFixed(2)} / $unidade'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$vendasTotal vendidos',
                            style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}