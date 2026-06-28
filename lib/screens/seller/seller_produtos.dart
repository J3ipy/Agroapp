import 'package:flutter/material.dart';
import '../../services/hort_firestore.dart';
import '../../models/produto.dart';
import '../../shared/adicionar_produto_screen.dart';
import '../../core/theme.dart';

class SellerProdutosScreen extends StatelessWidget {
  const SellerProdutosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus Produtos', style: TextStyle(fontWeight: FontWeight.bold))),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00B0FF),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdicionarProdutoScreen())),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<Produto>>(
        stream: HortFirestoreService.instance.streamProdutos(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snap.hasData || snap.data!.isEmpty) return const Center(child: Text('Nenhum produto cadastrado.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snap.data!.length,
            itemBuilder: (_, i) {
              final prod = snap.data![i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    // LÓGICA DA IMAGEM ATUALIZADA AQUI:
                    child: prod.imagemPath.startsWith('http')
                        ? Image.network(prod.imagemPath, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.image, size: 50))
                        : Image.asset(prod.imagemPath, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.image, size: 50)),
                  ),
                  title: Text(prod.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('R\$ ${prod.preco} / ${prod.unidade}\nEstoque: ${prod.quantidade}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: kDangerColor),
                    onPressed: () async {
                      await HortFirestoreService.instance.excluirProduto(prod.id);
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produto apagado.')));
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}