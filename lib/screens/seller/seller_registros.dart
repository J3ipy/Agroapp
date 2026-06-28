import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/hort_firestore.dart';
import '../../models/venda.dart';
import '../../core/theme.dart';

class SellerRegistrosScreen extends StatelessWidget {
  const SellerRegistrosScreen({super.key});

  Future<void> _exportarRelatorioCSV(BuildContext context, List<Venda> vendas) async {
    try {
      // 1. Criar o cabeçalho e as linhas do CSV
      String csvData = "ID da Venda;Produto;Quantidade;Data;Metodo de Pagamento;Status\n";
      for (var v in vendas) {
        csvData += "${v.id};${v.produtoNome};${v.quantidade};${v.data};${v.metodoPagamento};${v.status}\n";
      }

      // 2. Obter o diretório temporário do telemóvel
      final directory = await getTemporaryDirectory();
      final String filePath = '${directory.path}/relatorio_vendas_agroapp.csv';

      // 3. Guardar o ficheiro
      final File file = File(filePath);
      await file.writeAsString(csvData);

      // 4. Partilhar o ficheiro gerado
      await Share.shareXFiles([XFile(filePath)], text: 'Aqui está o relatório de vendas do AgroApp!');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao exportar: $e'), backgroundColor: kDangerColor));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Vendas', style: TextStyle(fontWeight: FontWeight.bold))),
      body: StreamBuilder<List<Venda>>(
        stream: HortFirestoreService.instance.streamVendasSemana(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final vendas = snap.data ?? [];

          if (vendas.isEmpty) return const Center(child: Text('Nenhuma venda registada.', style: TextStyle(color: Colors.grey)));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: kSuccessColor, foregroundColor: Colors.white),
                    icon: const Icon(Icons.download),
                    label: const Text('Exportar Relatório (CSV)', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _exportarRelatorioCSV(context, vendas),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: vendas.length,
                  itemBuilder: (_, i) {
                    final v = vendas[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: kPrimaryColor.withOpacity(0.2), child: const Icon(Icons.receipt, color: kPrimaryColor)),
                        title: Text(v.produtoNome, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${v.quantidade} un. via ${v.metodoPagamento}\nData: ${v.data}'),
                        trailing: const Icon(Icons.check_circle, color: kSuccessColor),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}