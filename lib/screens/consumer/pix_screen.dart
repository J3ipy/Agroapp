import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme.dart';

class PixScreen extends StatelessWidget {
  final String pedidoId;
  final double valorTotal;

  const PixScreen({super.key, required this.pedidoId, required this.valorTotal});

  @override
  Widget build(BuildContext context) {
    // Simulando um código PIX Copia e Cola
    final String pixCopiaECola = "00020126400014br.gov.bcb.pix0111032804075400203Pix52040000530398654041.005802BR5925JOAO_PEDRO_SANTANA_SILVA_6008ESTANCIA62290525AKVELvabD4dmkFf72nH8KbJxp630484E4";

    return Scaffold(
      appBar: AppBar(title: const Text('Pagamento via PIX')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Escaneie o QR Code abaixo no app do seu banco:', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            const SizedBox(height: 24),

            // Gerador de QR Code
            Center(
              child: QrImageView(
                data: pixCopiaECola,
                version: QrVersions.auto,
                size: 250.0,
                backgroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 24),
            Text('Valor: R\$ ${valorTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kPrimaryColor)),
            const SizedBox(height: 30),

            const Text('Ou utilize o Pix Copia e Cola:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
              child: Text(pixCopiaECola, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'monospace', color: Colors.black54)),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, foregroundColor: Colors.white),
                icon: const Icon(Icons.copy),
                label: const Text('Copiar Código PIX'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: pixCopiaECola));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código copiado para a área de transferência!'), backgroundColor: kSuccessColor));
                },
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('Já paguei / Voltar ao Início'),
            )
          ],
        ),
      ),
    );
  }
}