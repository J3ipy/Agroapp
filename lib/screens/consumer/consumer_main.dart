import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'consumer_home.dart';
import 'consumer_mercado.dart';
import 'consumer_carrinho.dart';
import 'consumer_historico.dart'; // NOVO IMPORT
import '../../shared/perfil_screen.dart';
import '../../services/cart_provider.dart';
import '../../core/theme.dart';

class ConsumerMainContainer extends StatefulWidget {
  const ConsumerMainContainer({super.key});
  @override
  State<ConsumerMainContainer> createState() => _ConsumerMainContainerState();
}

class _ConsumerMainContainerState extends State<ConsumerMainContainer> {
  int _idx = 0;
  // ADICIONADO: ConsumerHistoricoScreen na lista de abas
  final _telas = const [ConsumerHomeScreen(), ConsumerMercadoScreen(), ConsumerHistoricoScreen(), SharedPerfilScreen()];

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
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConsumerCarrinhoScreen())),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.storefront), label: 'Mercado'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Pedidos'), // NOVA ABA
          NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}