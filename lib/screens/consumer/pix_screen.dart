import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme.dart';

class PixScreen extends StatefulWidget {
  final String pedidoId;
  final double total;

  const PixScreen({
    super.key,
    required this.pedidoId,
    required this.total,
  });

  @override
  State<PixScreen> createState() => _PixScreenState();
}

class _PixScreenState extends State<PixScreen> {
  // Variável que controla se o botão de finalizar está bloqueado ou não
  bool _pagamentoConfirmado = false;

  // SUBSTITUA O TEXTO ABAIXO PELO SEU PIX COPIA E COLA REAL (Gerado no app do seu banco)
  final String _pixCopiaECola = "00020126400014br.gov.bcb.pix0111032804075400203Pix52040000530398654041.005802BR5925JOAO_PEDRO_SANTANA_SILVA_6008ESTANCIA62290525AKVELvabD4dmkFf72nH8KbJxp630484E4";
  void _simularPagamento() {
    // Mostra um aviso na tela
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Aguardando confirmação do banco...'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );

    // Espera 2 segundos para simular a comunicação com o banco central
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _pagamentoConfirmado = true; // Libera o botão verde!
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pagamento recebido com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _finalizarPedido() {
    // AQUI VOCÊ COLOCA A SUA FUNÇÃO DE SALVAR O PEDIDO NO FIREBASE E LIMPAR O CARRINHO
    // Exemplo:
    // context.read<CartProvider>().clearCart();

    showDialog(
      context: context,
      barrierDismissible: false, // Impede de fechar clicando fora
      builder: (ctx) => AlertDialog(
        title: const Text('Compra Finalizada!'),
        content: const Text('O seu pedido foi recebido pelo produtor e logo será preparado.'),
        actions: [
          TextButton(
            onPressed: () {
              // Fecha o pop-up e volta para a tela principal (Home)
              Navigator.of(ctx).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Voltar para o Início', style: TextStyle(color: kPrimaryColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagamento via PIX', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Escaneie o QR Code abaixo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Abra o app do seu banco e escolha a opção pagar via QR Code.',
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // GERADOR DE QR CODE
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              // O pacote qr_flutter versão 4.x usa QrImageView
              child: QrImageView(
                data: _pixCopiaECola,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Valor Total: R\$ ${widget.total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryColor),
            ),
            const SizedBox(height: 24),

            // CAMPO COPIA E COLA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _pixCopiaECola,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[800]),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: kPrimaryColor),
                    onPressed: () {
                      // Função de copiar para área de transferência viria aqui
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Código copiado!')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // BOTÃO DE SIMULAR PAGAMENTO (SÓ APARECE SE NÃO TIVER PAGO)
            if (!_pagamentoConfirmado)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.account_balance, color: Colors.white),
                  label: const Text("Simular Pagamento no Banco", style: TextStyle(color: Colors.white, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _simularPagamento,
                ),
              ),

            if (!_pagamentoConfirmado) const SizedBox(height: 16),

            // BOTÃO DE FINALIZAR PEDIDO (BLOQUEADO ATÉ PAGAR)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  // Fica cinza se não pagou, fica verde se pagou
                  backgroundColor: _pagamentoConfirmado ? Colors.green : Colors.grey[400],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                // O botão fica inativo (null) enquanto o pagamento não for confirmado
                onPressed: _pagamentoConfirmado ? _finalizarPedido : null,
                child: Text(
                  _pagamentoConfirmado ? "Finalizar e Confirmar Pedido" : "Aguardando Pagamento...",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}