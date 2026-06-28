import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _nomeCtrl = TextEditingController();

  bool _isCadastro = false;
  bool _loading = false;
  String? _erro;

  String _roleCadastro = 'vendedor'; // vendedor | consumidor

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _nomeCtrl.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final e = email.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);
  }

  String _mapAuthError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'E-mail inválido.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'E-mail ou senha incorretos.';
        case 'email-already-in-use':
          return 'Esse e-mail já está cadastrado.';
        case 'weak-password':
          return 'Senha fraca. Use pelo menos 8 caracteres.';
        default:
          return 'Erro na autenticação. Tente novamente.';
      }
    }
    return 'Erro desconhecido.';
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      final email = _emailCtrl.text.trim();
      final senha = _senhaCtrl.text;

      if (email.isEmpty || senha.isEmpty) {
        setState(() => _erro = 'Informe o seu e-mail e senha.');
        return;
      }
      if (!_isValidEmail(email)) {
        setState(() => _erro = 'E-mail inválido.');
        return;
      }
      if (senha.length < 8) {
        setState(() => _erro = 'A senha deve ter no mínimo 8 caracteres.');
        return;
      }

      if (_isCadastro) {
        if (_nomeCtrl.text.trim().isEmpty) {
          setState(() => _erro = 'Informe o seu nome.');
          return;
        }
        await AuthService.instance.signUp(
          nome: _nomeCtrl.text,
          email: email,
          senha: senha,
          role: _roleCadastro,
        );
      } else {
        await AuthService.instance.signIn(
          email: email,
          senha: senha,
        );
      }
    } catch (e) {
      setState(() => _erro = _mapAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _mostrarDialogRecuperacaoSenha(BuildContext context) {
    final emailResetCtrl = TextEditingController(text: _emailCtrl.text);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recuperar Senha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Insira o seu e-mail abaixo para receber um link de redefinição de senha.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailResetCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final email = emailResetCtrl.text.trim();
              if (email.isEmpty || !_isValidEmail(email)) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor, insira um e-mail válido.'),
                    backgroundColor: kDangerColor,
                  ),
                );
                return;
              }
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('E-mail de redefinição enviado! Verifique a sua caixa de entrada.'),
                      backgroundColor: kSuccessColor,
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Erro: ${_mapAuthError(e)}'),
                      backgroundColor: kDangerColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Enviar Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isCadastro ? 'Criar conta' : 'Acesse a sua conta';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo do App
                  Image.asset(
                    'assets/images/logo.png',
                    height: 140,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.eco,
                      size: 80,
                      color: kPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Campos de Cadastro
                  if (_isCadastro) ...[
                    TextField(
                      controller: _nomeCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nome',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _roleCadastro,
                      decoration: InputDecoration(
                        labelText: 'Tipo de conta',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.group_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'vendedor',
                          child: Text('Produtor (Vendedor)'),
                        ),
                        DropdownMenuItem(
                          value: 'consumidor',
                          child: Text('Consumidor'),
                        ),
                      ],
                      onChanged: _loading
                          ? null
                          : (v) => setState(() => _roleCadastro = v ?? 'vendedor'),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Campo E-mail
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Campo Senha
                  TextField(
                    controller: _senhaCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Senha (mín. 8 caracteres)',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),

                  // Botão Esqueci a Senha
                  if (!_isCadastro)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading ? null : () => _mostrarDialogRecuperacaoSenha(context),
                        child: const Text(
                          'Esqueci a minha senha',
                          style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 12),

                  // Mensagem de Erro
                  if (_erro != null) ...[
                    Text(
                      _erro!,
                      style: const TextStyle(color: kDangerColor, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Botão Entrar/Cadastrar
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B0FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Text(
                        _isCadastro ? 'CADASTRAR' : 'ENTRAR',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Alternar entre Login e Cadastro
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() {
                      _isCadastro = !_isCadastro;
                      _erro = null;
                    }),
                    child: Text(
                      _isCadastro
                          ? 'Já tem uma conta? Entre aqui'
                          : 'Ainda não tem conta? Crie uma agora',
                      style: const TextStyle(color: kTextPrimary),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Seção do Patrocinador (IFS)
                  const Text(
                    'Apoio institucional',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Image.asset(
                    'assets/images/ifs.png',
                    height: 60,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.school,
                      color: Colors.grey,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}