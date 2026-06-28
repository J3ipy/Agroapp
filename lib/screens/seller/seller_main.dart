import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Imports das suas outras telas
import 'seller_registros.dart';
import 'seller_produtos.dart';
import '../../shared/perfil_screen.dart';
import '../../core/theme.dart';

// ============================================================================
// 1. O CONTAINER (Controla as Abas de Navegação Inferior do Produtor)
// ============================================================================
class SellerMainContainer extends StatefulWidget {
  const SellerMainContainer({super.key});

  @override
  State<SellerMainContainer> createState() => _SellerMainContainerState();
}

class _SellerMainContainerState extends State<SellerMainContainer> {
  int _idx = 0;

  final _telas = const [
    SellerHomeScreen(),
    SellerRegistrosScreen(),
    SellerProdutosScreen(),
    SharedPerfilScreen()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _telas[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Registros'),
          NavigationDestination(icon: Icon(Icons.inventory_2), label: 'Produtos'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

// ============================================================================
// 2. A TELA HOME (Dashboard com Dicas e Resumo Real de Vendas)
// ============================================================================
class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({super.key});

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {
  late String _mensagemDoDia;
  final _uid = FirebaseAuth.instance.currentUser?.uid;

  final List<String> _dicasProdutor = [
    "Sabia que fotos nítidas com boa iluminação aumentam suas vendas no app em até 40%?",
    "Mantenha seu estoque sempre updated para garantir a confiança dos seus clientes!",
    "Produtos da categoria 'Raízes' e 'Verduras' têm maior saída nas primeiras horas da manhã.",
    "Lembre-se de higienizar bem os produtos antes de realizar as entregas de pedidos fechados!"
  ];

  @override
  void initState() {
    super.initState();
    _mensagemDoDia = _dicasProdutor[Random().nextInt(_dicasProdutor.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel do Produtor', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CORREÇÃO: Saudação dinâmica buscando o primeiro nome do Produtor no Firestore
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(_uid).snapshots(),
              builder: (context, snapshot) {
                String nomeExibicao = "Carregando...";
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final nomeCompleto = data['nome'] ?? 'Produtor';
                  nomeExibicao = nomeCompleto.split(' ').first;
                } else if (snapshot.hasError) {
                  nomeExibicao = "Produtor";
                }
                return Text(
                    'Olá, $nomeExibicao!',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                );
              },
            ),
            const SizedBox(height: 4),
            Text('Acompanhe os resultados da sua colheita hoje', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 20),

            // CARD INFORMATIVO DINÂMICO (Dica de Vendas)
            Card(
              color: kPrimaryColor.withOpacity(0.1),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb, color: kPrimaryColor, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Dica de Vendas', style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(_mensagemDoDia, style: const TextStyle(color: Colors.black87, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text('📊 Resumo de Vendas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // CORREÇÃO: Puxa o histórico real de subcoleção "vendas" do vendedor ativo e monta os indicadores
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(_uid).collection('vendas').snapshots(),
              builder: (context, snapshot) {
                int totalPedidos = 0;
                int totalItensVendidos = 0;

                if (snapshot.hasData) {
                  final docs = snapshot.data!.docs;
                  totalPedidos = docs.length;
                  for (var doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    totalItensVendidos += (data['quantidade'] ?? 0) as int;
                  }
                }

                return Row(
                  children: [
                    // Card 1: Quantidade de Pedidos
                    Expanded(
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.local_shipping, color: kPrimaryColor, size: 28),
                              const SizedBox(height: 12),
                              Text('$totalPedidos', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text('Pedidos Realizados', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Card 2: Itens despachados
                    Expanded(
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.assignment_turned_in, color: Colors.green, size: 28),
                              const SizedBox(height: 12),
                              Text('$totalItensVendidos', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text('Produtos Escoados', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}