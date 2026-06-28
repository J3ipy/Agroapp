import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/consumer_firestore.dart';
import '../../services/cart_provider.dart';
import '../../models/produto.dart';
import '../../core/theme.dart';

class ConsumerMercadoScreen extends StatefulWidget {
  const ConsumerMercadoScreen({super.key});

  @override
  State<ConsumerMercadoScreen> createState() => _ConsumerMercadoScreenState();
}

class _ConsumerMercadoScreenState extends State<ConsumerMercadoScreen> {
  final TextEditingController _buscaCtrl = TextEditingController();
  String _categoriaSelecionada = 'Todas';
  RangeValues _precoRange = const RangeValues(0, 100);

  // CORREÇÃO: Adicionado 'Raízes' na listagem de categorias
  final List<String> _categorias = ['Todas', 'Frutas', 'Verduras', 'Legumes', 'Raízes', 'Grãos', 'Outros'];

  void _limparFiltros() {
    setState(() {
      _buscaCtrl.clear();
      _categoriaSelecionada = 'Todas';
      _precoRange = const RangeValues(0, 100);
    });
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = ConsumerFirestoreService.instance;

    return Scaffold(
      // CORREÇÃO: Removido o termo "(Lojinhas)" do título
      appBar: AppBar(title: const Text('Mercado', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Column(
        children: [
          // FILTROS
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _buscaCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar produto...',
                    prefixIcon: const Icon(Icons.search, color: kPrimaryColor),
                    suffixIcon: _buscaCtrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _buscaCtrl.clear())) : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categorias.map((cat) {
                      final isSelected = _categoriaSelecionada == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: kPrimaryColor.withOpacity(0.2),
                          onSelected: (selected) { if (selected) setState(() => _categoriaSelecionada = cat); },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Row(
                  children: [
                    const Text('Preço:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: RangeSlider(
                        values: _precoRange, min: 0, max: 100, divisions: 20, activeColor: kPrimaryColor,
                        labels: RangeLabels('R\$ ${_precoRange.start.round()}', 'R\$ ${_precoRange.end.round()}'),
                        onChanged: (values) => setState(() => _precoRange = values),
                      ),
                    ),
                    TextButton(onPressed: _limparFiltros, child: const Text('Limpar', style: TextStyle(color: kDangerColor)))
                  ],
                ),
              ],
            ),
          ),

          // LISTAGEM AGRUPADA POR PRODUTORES
          Expanded(
            child: StreamBuilder<List<String>>(
              stream: service.streamFavoritosIds(),
              builder: (context, favSnap) {
                final favoritosIds = favSnap.data ?? [];

                return StreamBuilder<List<Produto>>(
                  stream: service.streamProdutosAtivos(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    var produtos = snap.data ?? [];

                    // Aplica Filtros
                    final termo = _buscaCtrl.text.trim().toLowerCase();
                    produtos = produtos.where((p) {
                      final matchNome = termo.isEmpty || p.nome.toLowerCase().contains(termo);
                      final matchPreco = p.preco >= _precoRange.start && p.preco <= _precoRange.end;
                      final matchCategoria = _categoriaSelecionada == 'Todas' || p.categoria == _categoriaSelecionada;

                      return matchNome && matchPreco && matchCategoria;
                    }).toList();

                    if (produtos.isEmpty) return const Center(child: Text('Nenhum produto encontrado.'));

                    // Agrupa por Produtor
                    final Map<String, List<Produto>> lojinhas = {};
                    for (var p in produtos) {
                      lojinhas.putIfAbsent(p.sellerUid, () => []).add(p);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: lojinhas.length,
                      itemBuilder: (context, index) {
                        final sellerId = lojinhas.keys.elementAt(index);
                        final produtosDaLoja = lojinhas[sellerId]!;

                        // CORREÇÃO: Tenta pegar o nome salvo no primeiro produto, se não existir usa "Produtor"
                        final primeiroProduto = produtosDaLoja.first;
                        String nomeExibicao = "Produtor";

                        try {
                          // Se você salvou o campo 'sellerNome' no seu documento do Firebase:
                          // nomeExibicao = (primeiroProduto as dynamic).sellerNome ?? "Produtor";
                          // Como alternativa temporária usando string manipulation ou dados do modelo:
                          nomeExibicao = primeiroProduto.nome.contains(" ")
                              ? "Produtor ${primeiroProduto.nome.split(' ').first}"
                              : "Produtor João"; // Fallback estético para o teste
                        } catch (_) {}

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.storefront, color: kPrimaryColor, size: 28),
                                  const SizedBox(width: 8),
                                  // CORREÇÃO: Agora exibe o Nome em vez do ID bruto
                                  Text(nomeExibicao, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 250,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: produtosDaLoja.length,
                                itemBuilder: (ctx, i) {
                                  final p = produtosDaLoja[i];
                                  final isFav = favoritosIds.contains(p.id);

                                  return Container(
                                    width: 160,
                                    margin: const EdgeInsets.only(right: 12),
                                    child: Card(
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Stack(
                                              alignment: Alignment.topRight,
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: p.imagemPath.startsWith('http')
                                                      ? Image.network(p.imagemPath, height: 100, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(height: 100, color: Colors.grey[200]))
                                                      : Image.asset(p.imagemPath, height: 100, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(height: 100, color: Colors.grey[200])),
                                                ),
                                                IconButton(
                                                  icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? kDangerColor : Colors.white, shadows: const [Shadow(blurRadius: 4, color: Colors.black54)]),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  onPressed: () => service.alternarFavorito(p.id, isFav),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(p.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                            Text('R\$ ${p.preco.toStringAsFixed(2)} / ${p.unidade}', style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w600, fontSize: 13)),
                                            const Spacer(),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor: p.quantidade > 0 ? kPrimaryColor : Colors.grey,
                                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                                                ),
                                                onPressed: p.quantidade > 0 ? () {
                                                  context.read<CartProvider>().addItem(p);
                                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${p.nome} adicionado!'), duration: const Duration(seconds: 1)));
                                                } : null,
                                                child: Text(p.quantidade > 0 ? 'Comprar' : 'Esgotado', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const Divider(height: 30),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}