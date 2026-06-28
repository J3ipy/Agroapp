import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // IMPORT ADICIONADO
import '../../services/auth_service.dart'; // IMPORT ADICIONADO
import '../../services/hort_firestore.dart';
import '../../services/cloudinary_service.dart';
import '../../core/theme.dart';

class AdicionarProdutoScreen extends StatefulWidget {
  const AdicionarProdutoScreen({super.key});

  @override
  State<AdicionarProdutoScreen> createState() => _AdicionarProdutoScreenState();
}

class _AdicionarProdutoScreenState extends State<AdicionarProdutoScreen> {
  final _nomeCtrl = TextEditingController();
  final _precoCtrl = TextEditingController();
  final _qtdCtrl = TextEditingController();

  String _unidade = 'Kg';
  String _categoria = 'Frutas';
  File? _imagemSelecionada;
  bool _loading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _precoCtrl.dispose();
    _qtdCtrl.dispose();
    super.dispose();
  }

  Future<void> _escolherImagem() async {
    final XFile? imagem = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Reduz o tamanho para o upload ser mais rápido
    );

    if (imagem != null) {
      setState(() {
        _imagemSelecionada = File(imagem.path);
      });
    }
  }

  Future<void> _salvar() async {
    setState(() => _loading = true);
    try {
      final nome = _nomeCtrl.text.trim();
      final precoTxt = _precoCtrl.text.trim().replaceAll(',', '.');
      final qtdTxt = _qtdCtrl.text.trim();

      if (nome.isEmpty) throw Exception('Informe o nome do produto.');
      if (_imagemSelecionada == null) throw Exception('Por favor, selecione uma imagem.');

      final preco = double.tryParse(precoTxt);
      if (preco == null || preco <= 0) throw Exception('Preço inválido.');
      final qtd = int.tryParse(qtdTxt);
      if (qtd == null || qtd < 0) throw Exception('Quantidade inválida.');

      String? imageUrl = await CloudinaryService.uploadImage(_imagemSelecionada!);
      if (imageUrl == null) throw Exception('Falha ao enviar a imagem. Tente novamente.');

      final dataAdicao = DateTime.now().toString().split(' ')[0];

      // Atualiza o serviço para aceitar a categoria
      await FirebaseFirestore.instance.collection('users').doc(AuthService.instance.currentUser!.uid).collection('produtos').add({
        'sellerUid': AuthService.instance.currentUser!.uid,
        'nome': nome,
        'preco': preco,
        'quantidade': qtd,
        'unidade': _unidade,
        'categoria': _categoria, // NOVO CAMPO
        'imagemPath': imageUrl,
        'ativo': true,
        'dataAdicao': dataAdicao,
        'vendasTotal': 0,
        'vendasMes': 0,
        'vendasSemana': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produto adicionado!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Produto', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Correção da Imagem
          GestureDetector(
            onTap: _loading ? null : _escolherImagem,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: _imagemSelecionada != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_imagemSelecionada!, fit: BoxFit.cover, width: double.infinity, height: 200), // BoxFit.cover corrige a distorção
              )
                  : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 50, color: Colors.grey), SizedBox(height: 8), Text('Toque para escolher uma foto', style: TextStyle(color: Colors.grey))]),
            ),
          ),
          const SizedBox(height: 24),

          TextField(controller: _nomeCtrl, decoration: const InputDecoration(labelText: 'Nome do Produto', border: OutlineInputBorder())),
          const SizedBox(height: 16),

          // Dropdown de Categoria
          DropdownButtonFormField<String>(
            value: _categoria,
            decoration: const InputDecoration(labelText: 'Tipo de Produto', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'Frutas', child: Text('Frutas')),
              DropdownMenuItem(value: 'Verduras', child: Text('Verduras')),
              DropdownMenuItem(value: 'Legumes', child: Text('Legumes')),
              DropdownMenuItem(value: 'Raízes', child: Text('Raízes (Tubérculos)')),
              DropdownMenuItem(value: 'Grãos', child: Text('Grãos / Cereais')),
              DropdownMenuItem(value: 'Outros', child: Text('Outros')),
            ],
            onChanged: (v) => setState(() => _categoria = v!),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: TextField(controller: _precoCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Preço (R\$)', border: OutlineInputBorder()))),
              const SizedBox(width: 16),
              Expanded(child: TextField(controller: _qtdCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantidade', border: OutlineInputBorder()))),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _unidade,
            decoration: const InputDecoration(labelText: 'Unidade de Medida', border: OutlineInputBorder()),
            items: const [DropdownMenuItem(value: 'Kg', child: Text('Kilogramas (Kg)')), DropdownMenuItem(value: 'Un', child: Text('Unidade (Un)'))],
            onChanged: (v) => setState(() => _unidade = v!),
          ),
          const SizedBox(height: 32),

          SizedBox(height: 52, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, foregroundColor: Colors.white), onPressed: _loading ? null : _salvar, child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('SALVAR PRODUTO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }
}