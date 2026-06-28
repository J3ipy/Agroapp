import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/hort_firestore.dart';
import '../../services/cloudinary_service.dart';
import '../../models/user_profile.dart';

class SharedPerfilScreen extends StatefulWidget {
  const SharedPerfilScreen({super.key});

  @override
  State<SharedPerfilScreen> createState() => _SharedPerfilScreenState();
}

class _SharedPerfilScreenState extends State<SharedPerfilScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _uploading = false;

  void _mostrarLGPD(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Política de Privacidade (LGPD)'),
        content: const SingleChildScrollView(
          child: Text('De acordo com a Lei Geral de Proteção de Dados (Lei nº 13.709/2018):\n\n1. Os seus dados são utilizados estritamente para a operação da plataforma.\n2. Nenhuma informação financeira sensível é armazenada diretamente nos nossos servidores.\n3. Você tem o direito de solicitar a alteração ou exclusão total dos seus dados a qualquer momento.'),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendi'))],
      ),
    );
  }

  void _editarNome(BuildContext context, String nomeAtual) {
    final ctrl = TextEditingController(text: nomeAtual);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Nome'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Novo Nome')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, foregroundColor: Colors.white),
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                await HortFirestoreService.instance.atualizarPerfil(nome: ctrl.text.trim());
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _trocarFoto() async {
    final XFile? imagem = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (imagem != null) {
      setState(() => _uploading = true);
      String? url = await CloudinaryService.uploadImage(File(imagem.path));
      if (url != null) {
        await HortFirestoreService.instance.atualizarPerfil(photoAsset: url);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto atualizada!')));
      }
      setState(() => _uploading = false);
    }
  }

  // NOVO: Função para excluir conta (Direito ao Esquecimento - LGPD)
  void _excluirContaLGPD(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Conta Permanentemente', style: TextStyle(color: kDangerColor)),
        content: const Text('Atenção: Esta ação é irreversível. Todos os seus dados pessoais, perfil e histórico serão apagados dos nossos servidores de acordo com a LGPD. Deseja continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kDangerColor, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                final user = AuthService.instance.currentUser;
                if (user != null) {
                  // Apaga o documento do Firestore
                  await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
                  // Apaga o utilizador da autenticação
                  await user.delete();
                  await AuthService.instance.signOut();
                }
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Erro. É necessário um login recente para excluir a conta. Saia e entre novamente.'), backgroundColor: kDangerColor));
              }
            },
            child: const Text('Sim, Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meu Perfil', style: TextStyle(fontWeight: FontWeight.bold))),
      body: StreamBuilder<AppUserProfile>(
        stream: HortFirestoreService.instance.streamPerfil(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final p = snap.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: p.photoAsset.startsWith('http') ? NetworkImage(p.photoAsset) : AssetImage(p.photoAsset) as ImageProvider,
                    ),
                    if (_uploading) const CircularProgressIndicator(),
                    if (!_uploading)
                      CircleAvatar(
                        backgroundColor: kPrimaryColor,
                        radius: 18,
                        child: IconButton(icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white), onPressed: _trocarFoto),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(child: Text(p.nome, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
              Center(child: Text(p.email, style: const TextStyle(color: Colors.grey))),
              const SizedBox(height: 30),

              Card(
                child: Column(
                  children: [
                    ListTile(leading: const Icon(Icons.edit), title: const Text('Editar Nome'), trailing: const Icon(Icons.arrow_forward_ios, size: 16), onTap: () => _editarNome(context, p.nome)),
                    const Divider(height: 1),
                    ListTile(leading: const Icon(Icons.privacy_tip), title: const Text('Política de Privacidade (LGPD)'), trailing: const Icon(Icons.arrow_forward_ios, size: 16), onTap: () => _mostrarLGPD(context)),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications),
                      title: const Text('Notificações'),
                      value: p.notificacoesAtivas,
                      activeColor: kPrimaryColor,
                      onChanged: (v) => HortFirestoreService.instance.atualizarPerfil(notificacoesAtivas: v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade300, foregroundColor: Colors.black87, padding: const EdgeInsets.all(12)),
                onPressed: () => AuthService.instance.signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('SAIR DA CONTA', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              // NOVO: Botão Vermelho de Exclusão (LGPD)
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: kDangerColor),
                onPressed: () => _excluirContaLGPD(context),
                icon: const Icon(Icons.delete_forever),
                label: const Text('Excluir Minha Conta (LGPD)'),
              ),
            ],
          );
        },
      ),
    );
  }
}