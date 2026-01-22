import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ==========================================
// 1) TEMA E CORES
// ==========================================
const Color kPrimaryColor = Color(0xFF00A99D);
const Color kBackgroundColor = Color(0xFFF9F9F9);
const Color kTextPrimary = Color(0xFF333333);
const Color kDangerColor = Color(0xFFE53935);
const Color kSuccessColor = Color(0xFF43A047);
const Color kWarningColor = Colors.orange;

// Fotos de perfil (assets)
const List<String> kProfilePhotos = [
  'assets/images/logo.png',
  'assets/images/aipim.jpg',
  'assets/images/cebola.jpg',
  'assets/images/cenoura.jpg',
  'assets/images/maca.jpg',
];

// ==========================================
// 2) MODELOS
// ==========================================
class Produto {
  final String id;
  final String docPath; // caminho do doc (importante p/ consumer comprar)
  final String sellerUid; // dono do produto (vendedor)

  final String nome;
  final double preco;
  final int quantidade;
  final String unidade;
  final String imagemPath; // asset local
  final bool ativo;
  final String dataAdicao;

  final int vendasTotal;
  final int vendasMes;
  final int vendasSemana;

  Produto({
    required this.id,
    required this.docPath,
    required this.sellerUid,
    required this.nome,
    required this.preco,
    required this.quantidade,
    required this.unidade,
    required this.imagemPath,
    required this.ativo,
    required this.dataAdicao,
    required this.vendasTotal,
    required this.vendasMes,
    required this.vendasSemana,
  });

  static Produto fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc, {
        String? sellerUidOverride,
      }) {
    final d = doc.data() ?? {};

    // tenta usar field sellerUid; se faltar, infere do path: users/{uid}/produtos/{produtoId}
    String inferredSeller =
        sellerUidOverride ?? (d['sellerUid'] ?? '').toString();
    if (inferredSeller.isEmpty) {
      final seg = doc.reference.path.split('/');
      final idx = seg.indexOf('users');
      if (idx != -1 && idx + 1 < seg.length) inferredSeller = seg[idx + 1];
    }

    return Produto(
      id: doc.id,
      docPath: doc.reference.path,
      sellerUid: inferredSeller,
      nome: (d['nome'] ?? '').toString(),
      preco: (d['preco'] ?? 0).toDouble(),
      quantidade: (d['quantidade'] ?? 0).toInt(),
      unidade: (d['unidade'] ?? 'Kg').toString(),
      imagemPath: (d['imagemPath'] ?? 'assets/images/logo.png').toString(),
      ativo: (d['ativo'] ?? true) as bool,
      dataAdicao: (d['dataAdicao'] ?? '').toString(),
      vendasTotal: (d['vendasTotal'] ?? 0).toInt(),
      vendasMes: (d['vendasMes'] ?? 0).toInt(),
      vendasSemana: (d['vendasSemana'] ?? 0).toInt(),
    );
  }
}

class Venda {
  final String id;
  final String produtoId;
  final String produtoNome;
  final int quantidade;
  final String data;
  final String status;
  final String metodoPagamento;

  Venda({
    required this.id,
    required this.produtoId,
    required this.produtoNome,
    required this.quantidade,
    required this.data,
    required this.status,
    required this.metodoPagamento,
  });

  static Venda fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Venda(
      id: doc.id,
      produtoId: (d['produtoId'] ?? '').toString(),
      produtoNome: (d['produtoNome'] ?? '').toString(),
      quantidade: (d['quantidade'] ?? 0).toInt(),
      data: (d['data'] ?? '').toString(),
      status: (d['status'] ?? 'Concluído').toString(),
      metodoPagamento: (d['metodoPagamento'] ?? 'Pix').toString(),
    );
  }
}

class AppUserProfile {
  final String uid;
  final String nome;
  final String email;
  final String role; // vendedor | consumidor
  final String photoAsset;
  final bool notificacoesAtivas;

  AppUserProfile({
    required this.uid,
    required this.nome,
    required this.email,
    required this.role,
    required this.photoAsset,
    required this.notificacoesAtivas,
  });

  static AppUserProfile fromDoc(String uid, Map<String, dynamic> d) {
    return AppUserProfile(
      uid: uid,
      nome: (d['nome'] ?? 'Usuário').toString(),
      email: (d['email'] ?? '').toString(),
      role: (d['role'] ?? 'vendedor').toString(),
      photoAsset: (d['photoAsset'] ?? 'assets/images/logo.png').toString(),
      notificacoesAtivas: (d['notificacoesAtivas'] ?? true) as bool,
    );
  }
}

// ==========================================
// 3) AUTH SERVICE
// ==========================================
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signUp({
    required String nome,
    required String email,
    required String senha,
    required String role, // vendedor | consumidor
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );
    final uid = cred.user!.uid;

    await _db.collection('users').doc(uid).set({
      'nome': nome.trim(),
      'email': email.trim(),
      'role': role,
      'photoAsset': 'assets/images/logo.png',
      'notificacoesAtivas': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> signIn({
    required String email,
    required String senha,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );
  }

  Future<void> signOut() async => _auth.signOut();
}

// ==========================================
// 4) FIRESTORE - POR VENDEDOR
// users/{uid}
// users/{uid}/produtos/{produtoId}
// users/{uid}/vendas/{vendaId}
// ==========================================
class HortFirestoreService {
  HortFirestoreService._();
  static final HortFirestoreService instance = HortFirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid {
    final u = AuthService.instance.currentUser;
    if (u == null) throw Exception('Usuário não autenticado.');
    return u.uid;
  }

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users').doc(_uid);

  CollectionReference<Map<String, dynamic>> get _produtosRef =>
      _userDoc.collection('produtos');

  CollectionReference<Map<String, dynamic>> get _vendasRef =>
      _userDoc.collection('vendas');

  // Perfil
  Stream<AppUserProfile> streamPerfil() {
    return _userDoc.snapshots().map((snap) {
      final data = snap.data() ?? {};
      return AppUserProfile.fromDoc(_uid, data);
    });
  }

  Future<AppUserProfile> getPerfilOnce() async {
    final snap = await _userDoc.get();
    final data = snap.data() ?? {};
    return AppUserProfile.fromDoc(_uid, data);
  }

  Future<void> atualizarPerfil({
    String? nome,
    String? photoAsset,
    bool? notificacoesAtivas,
  }) async {
    final data = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (nome != null) data['nome'] = nome.trim();
    if (photoAsset != null) data['photoAsset'] = photoAsset;
    if (notificacoesAtivas != null) {
      data['notificacoesAtivas'] = notificacoesAtivas;
    }
    await _userDoc.set(data, SetOptions(merge: true));
  }

  // Produtos (do vendedor logado)
  Stream<List<Produto>> streamProdutos() {
    return _produtosRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Produto.fromDoc(d)).toList());
  }

  Stream<List<Produto>> streamMaisVendidos({int limit = 5}) {
    return _produtosRef
        .orderBy('vendasMes', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Produto.fromDoc(d)).toList());
  }

  Future<void> adicionarProduto({
    required String nome,
    required double preco,
    required int quantidade,
    required String unidade,
    required String dataAdicao,
    required String imagemPath,
  }) async {
    await _produtosRef.add({
      'sellerUid': _uid,
      'nome': nome.trim(),
      'preco': preco,
      'quantidade': quantidade,
      'unidade': unidade,
      'imagemPath': imagemPath,
      'ativo': true,
      'dataAdicao': dataAdicao,
      'vendasTotal': 0,
      'vendasMes': 0,
      'vendasSemana': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> atualizarProduto({
    required String produtoId,
    double? novoPreco,
    int? novaQuantidade,
  }) async {
    final data = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (novoPreco != null) data['preco'] = novoPreco;
    if (novaQuantidade != null) data['quantidade'] = novaQuantidade;
    await _produtosRef.doc(produtoId).update(data);
  }

  Future<void> alternarStatusProduto(String produtoId, bool ativoAtual) async {
    await _produtosRef.doc(produtoId).update({
      'ativo': !ativoAtual,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> excluirProduto(String produtoId) async {
    await _produtosRef.doc(produtoId).delete();
  }

  // Vendas
  Stream<List<Venda>> streamVendasSemana() {
    final start = DateTime.now().subtract(const Duration(days: 7));
    return _vendasRef
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Venda.fromDoc(d)).toList());
  }

  Future<void> registrarVenda({
    required String produtoId,
    required int quantidadeVendida,
    required String metodoPagamento,
  }) async {
    if (quantidadeVendida <= 0) throw Exception('Quantidade inválida.');

    final produtoDocRef = _produtosRef.doc(produtoId);
    final vendaDocRef = _vendasRef.doc();

    await _db.runTransaction((tx) async {
      final produtoSnap = await tx.get(produtoDocRef);
      if (!produtoSnap.exists) throw Exception('Produto não encontrado.');

      final data = produtoSnap.data() as Map<String, dynamic>;
      final nome = (data['nome'] ?? '').toString();
      final qtdAtual = (data['quantidade'] ?? 0).toInt();
      final ativo = (data['ativo'] ?? true) as bool;

      final vendasTotalAtual = (data['vendasTotal'] ?? 0).toInt();
      final vendasMesAtual = (data['vendasMes'] ?? 0).toInt();
      final vendasSemanaAtual = (data['vendasSemana'] ?? 0).toInt();

      if (!ativo) throw Exception('Produto inativo. Ative para vender.');
      if (qtdAtual < quantidadeVendida) {
        throw Exception('Estoque insuficiente. Atual: $qtdAtual');
      }

      tx.update(produtoDocRef, {
        'quantidade': qtdAtual - quantidadeVendida,
        'vendasTotal': vendasTotalAtual + quantidadeVendida,
        'vendasMes': vendasMesAtual + quantidadeVendida,
        'vendasSemana': vendasSemanaAtual + quantidadeVendida,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.set(vendaDocRef, {
        'produtoId': produtoId,
        'produtoNome': nome,
        'quantidade': quantidadeVendida,
        'data': DateFormat('dd/MM/yyyy').format(DateTime.now()),
        'status': 'Concluído',
        'metodoPagamento': metodoPagamento,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}

// ==========================================
// 5) FIRESTORE - CONSUMIDOR (ver todos produtos)
// Usa collectionGroup('produtos')
// ==========================================
class ConsumerFirestoreService {
  ConsumerFirestoreService._();
  static final ConsumerFirestoreService instance = ConsumerFirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Produto>> streamProdutosAtivos() {
    return _db
        .collectionGroup('produtos')
        .where('ativo', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Produto.fromDoc(doc)).toList());
  }

  Stream<List<Produto>> streamMaisVendidosGlobal({int limit = 5}) {
    return _db
        .collectionGroup('produtos')
        .where('ativo', isEqualTo: true)
        .orderBy('vendasMes', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Produto.fromDoc(d)).toList());
  }
}

// ==========================================
// 5.1) COMPRAS - CONSUMIDOR (compra real)
// Atualiza estoque/vendas no produto do vendedor + cria registros
// ==========================================
class ConsumerPurchaseService {
  ConsumerPurchaseService._();
  static final ConsumerPurchaseService instance = ConsumerPurchaseService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> comprarProduto({
    required Produto produto,
    required int quantidade,
    required String metodoPagamento,
  }) async {
    final user = AuthService.instance.currentUser;
    if (user == null) throw Exception('Faça login para comprar.');
    if (quantidade <= 0) throw Exception('Quantidade inválida.');

    if (produto.sellerUid.isEmpty) {
      throw Exception('Produto sem vendedor (sellerUid vazio).');
    }

    final produtoRef = _db.doc(produto.docPath); // users/{sellerUid}/produtos/{id}
    final compraRef = _db.collection('compras').doc(); // global p/ histórico
    final vendaRef = _db
        .collection('users')
        .doc(produto.sellerUid)
        .collection('vendas')
        .doc(); // venda p/ vendedor

    await _db.runTransaction((tx) async {
      final snap = await tx.get(produtoRef);
      if (!snap.exists) throw Exception('Produto não encontrado.');

      final data = snap.data() as Map<String, dynamic>;
      final ativo = (data['ativo'] ?? true) as bool;
      final qtdAtual = (data['quantidade'] ?? 0).toInt();
      final nome = (data['nome'] ?? '').toString();

      final vendasTotalAtual = (data['vendasTotal'] ?? 0).toInt();
      final vendasMesAtual = (data['vendasMes'] ?? 0).toInt();
      final vendasSemanaAtual = (data['vendasSemana'] ?? 0).toInt();

      if (!ativo) throw Exception('Produto inativo.');
      if (qtdAtual < quantidade) {
        throw Exception('Estoque insuficiente. Atual: $qtdAtual');
      }

      // baixa estoque e soma vendas no produto do vendedor
      tx.update(produtoRef, {
        'quantidade': qtdAtual - quantidade,
        'vendasTotal': vendasTotalAtual + quantidade,
        'vendasMes': vendasMesAtual + quantidade,
        'vendasSemana': vendasSemanaAtual + quantidade,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // cria venda no vendedor
      tx.set(vendaRef, {
        'produtoId': produto.id,
        'produtoNome': nome,
        'quantidade': quantidade,
        'data': DateFormat('dd/MM/yyyy').format(DateTime.now()),
        'status': 'Concluído',
        'metodoPagamento': metodoPagamento,
        'createdAt': FieldValue.serverTimestamp(),
        'buyerUid': user.uid,
      });

      // cria compra global
      tx.set(compraRef, {
        'buyerUid': user.uid,
        'sellerUid': produto.sellerUid,
        'produtoId': produto.id,
        'produtoNome': nome,
        'quantidade': quantidade,
        'metodoPagamento': metodoPagamento,
        'status': 'Concluído',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}

// ==========================================
// 6) MAIN + APP GATE (direciona por role)
// ==========================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const HortApp());
}

class HortApp extends StatelessWidget {
  const HortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agroapp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: kBackgroundColor,
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor),
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: kBackgroundColor,
          elevation: 0,
          titleTextStyle: TextStyle(
              color: kTextPrimary, fontSize: 20, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: kTextPrimary),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: AuthService.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final user = snap.data;
          if (user == null) return const LoginScreen();

          // Se logou: checa role no Firestore
          return FutureBuilder<AppUserProfile>(
            future: HortFirestoreService.instance.getPerfilOnce(),
            builder: (context, profileSnap) {
              if (profileSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final p = profileSnap.data;
              final role = p?.role ?? 'vendedor';

              if (role == 'consumidor') {
                return const ConsumerMainContainer();
              }
              return const SellerMainContainer();
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// 7) LOGIN/CADASTRO com validação simples
// ==========================================
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
          return 'Email inválido.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Login não identificado.';
        case 'email-already-in-use':
          return 'Esse email já está cadastrado.';
        case 'weak-password':
          return 'Senha fraca. Use pelo menos 8 caracteres.';
        default:
          return 'Login não identificado.';
      }
    }
    return 'Login não identificado.';
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
        setState(() => _erro = 'Informe seu email e senha.');
        return;
      }
      if (!_isValidEmail(email)) {
        setState(() => _erro = 'Email inválido.');
        return;
      }
      if (senha.length < 8) {
        setState(() => _erro = 'Senha deve ter no mínimo 8 dígitos.');
        return;
      }

      if (_isCadastro) {
        if (_nomeCtrl.text.trim().isEmpty) {
          setState(() => _erro = 'Informe seu nome.');
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

  @override
  Widget build(BuildContext context) {
    final title = _isCadastro ? 'Criar conta' : 'Login';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 150,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.eco, size: 80, color: kPrimaryColor),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  if (_isCadastro) ...[
                    TextField(
                      controller: _nomeCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nome',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
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
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'vendedor', child: Text('Vendedor')),
                        DropdownMenuItem(
                            value: 'consumidor', child: Text('Consumidor')),
                      ],
                      onChanged: _loading
                          ? null
                          : (v) =>
                          setState(() => _roleCadastro = v ?? 'vendedor'),
                    ),
                    const SizedBox(height: 12),
                  ],

                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _senhaCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Senha (mín. 8)',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),

                  if (_erro != null) ...[
                    const SizedBox(height: 12),
                    Text(_erro!, style: const TextStyle(color: kDangerColor)),
                  ],

                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B0FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
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
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() => _isCadastro = !_isCadastro),
                    child: Text(_isCadastro
                        ? 'Já tenho conta → Entrar'
                        : 'Não tenho conta → Criar agora'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Nossos parceiros'),
                  const SizedBox(height: 8),
                  Image.asset(
                    'assets/images/ifs.png',
                    height: 70,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.school, color: Colors.grey),
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

// ==========================================
// 8) MAIN CONTAINER - VENDEDOR (4 abas)
// ==========================================
class SellerMainContainer extends StatefulWidget {
  const SellerMainContainer({super.key});

  @override
  State<SellerMainContainer> createState() => _SellerMainContainerState();
}

class _SellerMainContainerState extends State<SellerMainContainer> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    SellerHomeScreen(),
    SellerRegistrosScreen(),
    SellerProdutosScreen(),
    SharedPerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Registros'),
          NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined), label: 'Produtos'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

// ==========================================
// 9) MAIN CONTAINER - CONSUMIDOR (3 abas)
// ==========================================
class ConsumerMainContainer extends StatefulWidget {
  const ConsumerMainContainer({super.key});

  @override
  State<ConsumerMainContainer> createState() => _ConsumerMainContainerState();
}

class _ConsumerMainContainerState extends State<ConsumerMainContainer> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    ConsumerHomeScreen(),
    ConsumerMercadoScreen(),
    SharedPerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.storefront), label: 'Mercado'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

// ==========================================
// 10) HOME VENDEDOR: mais vendidos (do vendedor)
// ==========================================
class SellerHomeScreen extends StatelessWidget {
  const SellerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = HortFirestoreService.instance;

    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Image.asset(
            'assets/images/logo.png',
            height: 120,
            errorBuilder: (_, __, ___) =>
            const Icon(Icons.eco, color: kPrimaryColor),
          ),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Mais vendidos',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {},
              child: const Text('Atualizado (mês)',
                  style: TextStyle(color: Colors.grey)),
            ),
          ]),
          const SizedBox(height: 10),
          StreamBuilder<List<Produto>>(
            stream: service.streamMaisVendidos(limit: 5),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snap.data ?? [];
              if (items.isEmpty) {
                return const Text(
                  'Sem vendas ainda. Registre uma venda para aparecer aqui.',
                  style: TextStyle(color: Colors.grey),
                );
              }
              return Column(
                children: items.map((p) {
                  final subtitle =
                      '${p.vendasMes} vendas no mês • estoque ${p.quantidade}';
                  final stripColor = p.vendasMes >= 10
                      ? Colors.orange
                      : (p.vendasMes >= 3 ? Colors.yellow : Colors.green);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _bestSellerCard(p.nome, subtitle, stripColor),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 30),
          _didYouKnowCard(),
        ]),
      ),
    );
  }

  Widget _bestSellerCard(String title, String subtitle, Color stripColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)
        ],
      ),
      child: Row(children: [
        Container(
          width: 10,
          height: 80,
          decoration: BoxDecoration(
            color: stripColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              bottomLeft: Radius.circular(15),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(subtitle, style: const TextStyle(color: Colors.grey)),
          ]),
        ),
        IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert))
      ]),
    );
  }
}

Widget _didYouKnowCard() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    ),
    child: Row(children: [
      const Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Sabia que',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 8),
          Text(
            'A agricultura familiar é responsável por cerca de 70% dos alimentos que chegam à mesa dos brasileiros.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ]),
      ),
      const SizedBox(width: 10),
      Container(
        width: 80,
        height: 80,
        color: Colors.greenAccent.withOpacity(0.15),
        child: const Icon(Icons.agriculture, color: kPrimaryColor, size: 40),
      )
    ]),
  );
}

// ==========================================
// 11) REGISTROS VENDEDOR: vendas semana + estoque
// ==========================================
class SellerRegistrosScreen extends StatelessWidget {
  const SellerRegistrosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = HortFirestoreService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Vendas da Semana',
            style: TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<Venda>>(
            stream: service.streamVendasSemana(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final vendas = snap.data ?? [];
              if (vendas.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('Nenhuma venda nos últimos 7 dias.',
                      style: TextStyle(color: Colors.grey)),
                );
              }
              return Column(children: vendas.map(_vendaCard).toList());
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Estoque',
            style: TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<Produto>>(
            stream: service.streamProdutos(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final produtos = snap.data ?? [];
              if (produtos.isEmpty) {
                return const Text('Nenhum produto cadastrado.',
                    style: TextStyle(color: Colors.grey));
              }
              return Column(children: produtos.map(_estoqueCard).toList());
            },
          ),
        ],
      ),
    );
  }

  Widget _vendaCard(Venda venda) {
    final statusColor =
    venda.status == 'Concluído' ? kSuccessColor : kDangerColor;
    final statusIcon = venda.status == 'Concluído'
        ? Icons.check_circle_outline
        : Icons.cancel_outlined;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey[200],
            child: const Icon(Icons.shopping_basket, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${venda.quantidade}x ${venda.produtoNome}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Feita em ${venda.data}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ),
          Column(children: [
            Icon(statusIcon, color: statusColor, size: 30),
            Text(venda.metodoPagamento,
                style: TextStyle(color: statusColor, fontSize: 10)),
          ])
        ]),
      ),
    );
  }

  Widget _estoqueCard(Produto produto) {
    Color corStatus;
    IconData iconeStatus;
    String textoStatus;

    if (produto.quantidade == 0) {
      corStatus = kDangerColor;
      iconeStatus = Icons.cancel_outlined;
      textoStatus = 'Produto em falta';
    } else if (produto.quantidade <= 3) {
      corStatus = kWarningColor;
      iconeStatus = Icons.access_time;
      textoStatus = 'Pouco estoque';
    } else {
      corStatus = kSuccessColor;
      iconeStatus = Icons.check_circle_outline;
      textoStatus = 'Bom estoque';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(children: [
          Text('${produto.quantidade}',
              style:
              const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          Expanded(
            child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(produto.nome,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Adicionado em ${produto.dataAdicao}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ),
          Column(children: [
            Icon(iconeStatus, color: corStatus),
            Text(textoStatus, style: TextStyle(color: corStatus, fontSize: 10)),
          ])
        ]),
      ),
    );
  }
}

// ==========================================
// 12) PRODUTOS VENDEDOR: listar/editar/ativar/vender/excluir
// ==========================================
class SellerProdutosScreen extends StatelessWidget {
  const SellerProdutosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = HortFirestoreService.instance;
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seus Produtos',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00B0FF),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdicionarProdutoScreen()),
        ),
      ),
      body: StreamBuilder<List<Produto>>(
        stream: service.streamProdutos(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final produtos = snap.data ?? [];
          if (produtos.isEmpty) {
            return const Center(child: Text('Nenhum produto cadastrado.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: produtos.length,
            itemBuilder: (_, index) {
              final prod = produtos[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.10),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Row(children: [
                  ClipOval(
                    child: Image.asset(
                      prod.imagemPath,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Text(
                                prod.nome,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                            ),
                            Text(
                              '${currency.format(prod.preco)} / ${prod.unidade}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _pill(
                                label: 'Editar',
                                color: kSuccessColor,
                                onTap: () => _dialogEdicao(context, prod),
                              ),
                              _pill(
                                label: prod.ativo ? 'Ativo' : 'Inativo',
                                color:
                                prod.ativo ? kSuccessColor : kDangerColor,
                                onTap: () => service.alternarStatusProduto(
                                  prod.id,
                                  prod.ativo,
                                ),
                              ),
                              _pill(
                                label: 'Vender',
                                color: const Color(0xFF00B0FF),
                                onTap: () => _dialogVenda(context, prod),
                              ),
                              _pill(
                                label: 'Excluir',
                                color: kDangerColor,
                                onTap: () => _dialogExcluirProduto(context, prod),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Vendas (mês): ${prod.vendasMes} • Estoque: ${prod.quantidade}',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ]),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
                ]),
              );
            },
          );
        },
      ),
    );
  }

  Widget _pill({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 12)),
      ),
    );
  }

  void _dialogEdicao(BuildContext context, Produto prod) {
    final service = HortFirestoreService.instance;
    final qtdCtrl = TextEditingController(text: prod.quantidade.toString());
    final precoCtrl = TextEditingController(text: prod.preco.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Editar ${prod.nome}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtdCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Quantidade"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: precoCtrl,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: "Preço"),
            ),
            const SizedBox(height: 10),
            const Text(
              'Dica: deixe vazio algum campo se não quiser alterar.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                final qtdTxt = qtdCtrl.text.trim();
                final precoTxt = precoCtrl.text.trim().replaceAll(',', '.');

                int? novaQtd;
                double? novoPreco;

                if (qtdTxt.isNotEmpty) {
                  final parsed = int.tryParse(qtdTxt);
                  if (parsed == null || parsed < 0) {
                    throw Exception('Quantidade inválida.');
                  }
                  novaQtd = parsed;
                }

                if (precoTxt.isNotEmpty) {
                  final parsed = double.tryParse(precoTxt);
                  if (parsed == null || parsed < 0) {
                    throw Exception('Preço inválido.');
                  }
                  novoPreco = parsed;
                }

                if (novaQtd == null && novoPreco == null) {
                  Navigator.pop(ctx);
                  return;
                }

                await service.atualizarProduto(
                  produtoId: prod.id,
                  novaQuantidade: novaQtd,
                  novoPreco: novoPreco,
                );

                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Produto atualizado!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceAll('Exception: ', ''),
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  void _dialogVenda(BuildContext context, Produto prod) {
    final service = HortFirestoreService.instance;
    final qtdCtrl = TextEditingController(text: '1');
    String metodo = 'Pix';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text("Registrar venda • ${prod.nome}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Estoque atual: ${prod.quantidade}',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 10),
              TextField(
                controller: qtdCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Quantidade vendida",
                  hintText: "Ex: 1",
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: metodo,
                decoration: const InputDecoration(
                  labelText: 'Método de pagamento',
                ),
                items: const [
                  DropdownMenuItem(value: 'Pix', child: Text('Pix')),
                  DropdownMenuItem(value: 'Cartão', child: Text('Cartão')),
                  DropdownMenuItem(value: 'Dinheiro', child: Text('Dinheiro')),
                ],
                onChanged: (v) => setStateDialog(() => metodo = v ?? 'Pix'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B0FF),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                try {
                  final qtd = int.tryParse(qtdCtrl.text.trim()) ?? 0;
                  await service.registrarVenda(
                    produtoId: prod.id,
                    quantidadeVendida: qtd,
                    metodoPagamento: metodo,
                  );

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Venda registrada!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString().replaceAll('Exception: ', '')),
                      ),
                    );
                  }
                }
              },
              child: const Text("Confirmar"),
            ),
          ],
        ),
      ),
    );
  }

  void _dialogExcluirProduto(BuildContext context, Produto prod) {
    final service = HortFirestoreService.instance;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir produto'),
        content: Text('Tem certeza que deseja excluir "${prod.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kDangerColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await service.excluirProduto(prod.id);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Produto excluído!')),
                );
              }
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 13) ADICIONAR PRODUTO (assets como imagens)
// ==========================================
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
  String _imagemPath = 'assets/images/aipim.jpg';
  bool _loading = false;

  final _assetsSugestoes = const [
    'assets/images/aipim.jpg',
    'assets/images/cebola.jpg',
    'assets/images/cenoura.jpg',
    'assets/images/maca.jpg',
  ];

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _precoCtrl.dispose();
    _qtdCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() => _loading = true);
    try {
      final nome = _nomeCtrl.text.trim();
      final precoTxt = _precoCtrl.text.trim().replaceAll(',', '.');
      final qtdTxt = _qtdCtrl.text.trim();

      if (nome.isEmpty) throw Exception('Informe o nome do produto.');
      final preco = double.tryParse(precoTxt);
      if (preco == null || preco <= 0) throw Exception('Preço inválido.');
      final qtd = int.tryParse(qtdTxt);
      if (qtd == null || qtd < 0) throw Exception('Quantidade inválida.');

      final dataAdicao = DateFormat('dd/MM/yyyy').format(DateTime.now());

      await HortFirestoreService.instance.adicionarProduto(
        nome: nome,
        preco: preco,
        quantidade: qtd,
        unidade: _unidade,
        dataAdicao: dataAdicao,
        imagemPath: _imagemPath,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto adicionado!')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Produto',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Informações do produto',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _nomeCtrl,
            decoration: const InputDecoration(
              labelText: 'Nome',
              prefixIcon: Icon(Icons.inventory_2_outlined),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _precoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Preço',
              prefixIcon: Icon(Icons.attach_money),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qtdCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade',
                    prefixIcon: Icon(Icons.numbers),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _unidade,
                  decoration: const InputDecoration(
                    labelText: 'Unidade',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Kg', child: Text('Kg')),
                    DropdownMenuItem(value: 'Un', child: Text('Un')),
                    DropdownMenuItem(value: 'L', child: Text('L')),
                    DropdownMenuItem(value: 'Cx', child: Text('Cx')),
                  ],
                  onChanged: _loading
                      ? null
                      : (v) => setState(() => _unidade = v ?? 'Kg'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Imagem do produto',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _assetsSugestoes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final path = _assetsSugestoes[i];
                final selected = path == _imagemPath;
                return GestureDetector(
                  onTap: _loading ? null : () => setState(() => _imagemPath = path),
                  child: Container(
                    width: 88,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? kPrimaryColor : Colors.grey.shade300,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        path,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported,
                              color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B0FF),
                foregroundColor: Colors.white,
              ),
              onPressed: _loading ? null : _salvar,
              child: _loading
                  ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text(
                'SALVAR',
                style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 14) HOME CONSUMIDOR: mais vendidos global
// ==========================================
class ConsumerHomeScreen extends StatelessWidget {
  const ConsumerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ConsumerFirestoreService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Destaques',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Mais vendidos (global)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          StreamBuilder<List<Produto>>(
            stream: service.streamMaisVendidosGlobal(limit: 5),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Text(
                  'Erro ao carregar: ${snap.error}',
                  style: const TextStyle(color: kDangerColor),
                );
              }
              final items = snap.data ?? [];
              if (items.isEmpty) {
                return const Text('Sem produtos em destaque no momento.',
                    style: TextStyle(color: Colors.grey));
              }

              return Column(
                children: items.map((p) {
                  final subtitle =
                      'Vendas no mês: ${p.vendasMes} • Estoque: ${p.quantidade}';
                  final stripColor = p.vendasMes >= 10
                      ? Colors.orange
                      : (p.vendasMes >= 3 ? Colors.yellow : Colors.green);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _consumerBestSellerCard(p, subtitle, stripColor),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 26),
          _didYouKnowCard(),
        ]),
      ),
    );
  }

  Widget _consumerBestSellerCard(Produto p, String subtitle, Color stripColor) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)
        ],
      ),
      child: Row(children: [
        Container(
          width: 10,
          height: 86,
          decoration: BoxDecoration(
            color: stripColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              bottomLeft: Radius.circular(15),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ClipOval(
          child: Image.asset(
            p.imagemPath,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 56,
              height: 56,
              color: Colors.grey[300],
              child: const Icon(Icons.image, color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.nome,
                style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 6),
            Text('${currency.format(p.preco)} / ${p.unidade}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(width: 10),
      ]),
    );
  }
}

// ==========================================
// 15) MERCADO CONSUMIDOR: lista de produtos ativos + comprar
// ==========================================
class ConsumerMercadoScreen extends StatelessWidget {
  const ConsumerMercadoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ConsumerFirestoreService.instance;
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mercado',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<Produto>>(
        stream: service.streamProdutosAtivos(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Erro ao carregar produtos: ${snap.error}',
                style: const TextStyle(color: kDangerColor),
              ),
            );
          }
          final produtos = snap.data ?? [];
          if (produtos.isEmpty) {
            return const Center(
              child: Text('Nenhum produto disponível agora.',
                  style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: produtos.length,
            itemBuilder: (_, i) {
              final p = produtos[i];
              final estoqueOk = p.quantidade > 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        p.imagemPath,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 64,
                          height: 64,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.nome,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('${currency.format(p.preco)} / ${p.unidade}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              estoqueOk
                                  ? 'Estoque: ${p.quantidade}'
                                  : 'Indisponível',
                              style: TextStyle(
                                color:
                                estoqueOk ? kSuccessColor : kDangerColor,
                                fontSize: 12,
                              ),
                            ),
                          ]),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        estoqueOk ? const Color(0xFF00B0FF) : Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: estoqueOk ? () => _dialogComprar(context, p) : null,
                      child: const Text('Comprar'),
                    ),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _dialogComprar(BuildContext context, Produto p) {
    final qtdCtrl = TextEditingController(text: '1');
    String metodo = 'Pix';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text('Comprar • ${p.nome}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Estoque atual: ${p.quantidade}',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 10),
              TextField(
                controller: qtdCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantidade',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: metodo,
                decoration: const InputDecoration(
                  labelText: 'Pagamento',
                ),
                items: const [
                  DropdownMenuItem(value: 'Pix', child: Text('Pix')),
                  DropdownMenuItem(value: 'Cartão', child: Text('Cartão')),
                  DropdownMenuItem(value: 'Dinheiro', child: Text('Dinheiro')),
                ],
                onChanged: (v) => setStateDialog(() => metodo = v ?? 'Pix'),
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
                backgroundColor: const Color(0xFF00B0FF),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                try {
                  final qtd = int.tryParse(qtdCtrl.text.trim()) ?? 0;

                  await ConsumerPurchaseService.instance.comprarProduto(
                    produto: p,
                    quantidade: qtd,
                    metodoPagamento: metodo,
                  );

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Compra realizada!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString().replaceAll('Exception: ', '')),
                      ),
                    );
                  }
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 16) PERFIL COMPARTILHADO (vendedor e consumidor) + trocar foto
// ==========================================
class SharedPerfilScreen extends StatelessWidget {
  const SharedPerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = HortFirestoreService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<AppUserProfile>(
        stream: service.streamPerfil(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final p = snap.data;
          if (p == null) {
            return const Center(child: Text('Perfil não encontrado.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.grey[200],
                      child: ClipOval(
                        child: Image.asset(
                          p.photoAsset,
                          width: 68,
                          height: 68,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person,
                              size: 40, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.nome,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                            const SizedBox(height: 2),
                            Text(p.email,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: p.role == 'consumidor'
                                    ? Colors.blue.withOpacity(0.12)
                                    : Colors.green.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                p.role == 'consumidor'
                                    ? 'Consumidor'
                                    : 'Vendedor',
                                style: TextStyle(
                                  color: p.role == 'consumidor'
                                      ? Colors.blue
                                      : kPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              _perfilTile(
                context: context,
                icon: Icons.edit,
                title: 'Editar nome',
                subtitle: 'Atualize como você aparece no app',
                onTap: () => _dialogEditarNome(context, p.nome),
              ),

              _perfilTile(
                context: context,
                icon: Icons.photo_camera,
                title: 'Trocar foto de perfil',
                subtitle: 'Escolha uma imagem do app',
                onTap: () => _dialogTrocarFoto(context, p.photoAsset),
              ),

              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: SwitchListTile(
                  title: const Text('Notificações',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Ativar/desativar alertas',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  value: p.notificacoesAtivas,
                  activeColor: kPrimaryColor,
                  onChanged: (v) async {
                    await service.atualizarPerfil(notificacoesAtivas: v);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(v
                              ? 'Notificações ativadas.'
                              : 'Notificações desativadas.'),
                        ),
                      );
                    }
                  },
                ),
              ),

              const SizedBox(height: 14),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDangerColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    await AuthService.instance.signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('SAIR',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _perfilTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: kPrimaryColor.withOpacity(0.12),
          child: Icon(icon, color: kPrimaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing:
        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }

  void _dialogEditarNome(BuildContext context, String nomeAtual) {
    final ctrl = TextEditingController(text: nomeAtual);
    final service = HortFirestoreService.instance;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar nome'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Nome',
          ),
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
              try {
                final novo = ctrl.text.trim();
                if (novo.isEmpty) throw Exception('Nome inválido.');
                await service.atualizarPerfil(nome: novo);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _dialogTrocarFoto(BuildContext context, String fotoAtual) {
    final service = HortFirestoreService.instance;
    String selected = fotoAtual.isNotEmpty ? fotoAtual : kProfilePhotos.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Trocar foto de perfil'),
          content: SizedBox(
            width: double.maxFinite,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: kProfilePhotos.map((path) {
                final isSel = path == selected;
                return GestureDetector(
                  onTap: () => setStateDialog(() => selected = path),
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSel ? kPrimaryColor : Colors.grey.shade300,
                        width: isSel ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        path,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
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
                await service.atualizarPerfil(photoAsset: selected);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Foto atualizada!')),
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
