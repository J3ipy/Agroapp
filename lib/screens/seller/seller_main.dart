import 'package:flutter/material.dart';
import 'seller_home.dart';
import 'seller_registros.dart';
import 'seller_produtos.dart';
import '../../shared/perfil_screen.dart';

class SellerMainContainer extends StatefulWidget {
  const SellerMainContainer({super.key});
  @override
  State<SellerMainContainer> createState() => _SellerMainContainerState();
}

class _SellerMainContainerState extends State<SellerMainContainer> {
  int _idx = 0;
  final _telas = const [SellerHomeScreen(), SellerRegistrosScreen(), SellerProdutosScreen(), SharedPerfilScreen()];
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