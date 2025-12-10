import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ==========================================
// 1. MODELOS DE DADOS
// ==========================================

class Produto {
  String id;
  String nome;
  double preco;
  int quantidade;
  String unidade; // Kg, Unidade, Maço
  String imagemUrl;
  bool ativo;
  String dataAdicao;

  Produto({
    required this.id,
    required this.nome,
    required this.preco,
    required this.quantidade,
    required this.unidade,
    required this.imagemUrl,
    this.ativo = true,
    required this.dataAdicao,
  });
}

class Venda {
  String id;
  String produtoNome;
  int quantidade;
  String data;
  String status; // Concluído, Pendente, Cancelado
  String metodoPagamento; // Pix, Dinheiro

  Venda({
    required this.id,
    required this.produtoNome,
    required this.quantidade,
    required this.data,
    required this.status,
    required this.metodoPagamento,
  });
}

// ==========================================
// 2. BACKEND SIMULADO (Service Controller)
// ==========================================

class HortAppService extends ChangeNotifier {
  static final HortAppService _instance = HortAppService._internal();
  factory HortAppService() => _instance;
  HortAppService._internal() {
    _carregarDadosIniciais();
  }

  List<Produto> produtos = [];
  List<Venda> vendas = [];

  void _carregarDadosIniciais() {
    // CAMINHOS DAS IMAGENS ATUALIZADOS PARA ASSETS LOCAIS
    produtos.add(Produto(
        id: '1',
        nome: 'Cenoura',
        preco: 10.00,
        quantidade: 20,
        unidade: 'Kg',
        ativo: true,
        dataAdicao: '08/02/2025',
        imagemUrl: 'assets/images/cenoura.jpg')); // Corrigido de 'mages' para 'images'
    produtos.add(Produto(
        id: '2',
        nome: 'Cebola',
        preco: 3.00,
        quantidade: 15,
        unidade: 'Kg',
        ativo: false,
        dataAdicao: '08/02/2025',
        imagemUrl: 'assets/images/cebola.jpg'));
    produtos.add(Produto(
        id: '3',
        nome: 'Maçãs',
        preco: 4.00,
        quantidade: 8,
        unidade: 'Kg',
        ativo: true,
        dataAdicao: '07/02/2025',
        imagemUrl: 'assets/images/maca.jpg'));
    produtos.add(Produto(
        id: '4',
        nome: 'Aipim',
        preco: 5.00,
        quantidade: 2,
        unidade: 'Kg',
        ativo: false,
        dataAdicao: '08/02/2025',
        imagemUrl: 'assets/images/aipim.jpg'));

    vendas.add(Venda(
        id: '101',
        produtoNome: 'Cenouras',
        quantidade: 10,
        data: '07/02/2025',
        status: 'Concluído',
        metodoPagamento: 'Pix'));
    vendas.add(Venda(
        id: '102',
        produtoNome: 'Cebolas',
        quantidade: 2,
        data: '07/02/2025',
        status: 'Concluído',
        metodoPagamento: 'Dinheiro'));
    vendas.add(Venda(
        id: '103',
        produtoNome: 'Maçãs',
        quantidade: 8,
        data: '07/02/2025',
        status: 'Cancelado',
        metodoPagamento: 'Não finalizado'));
  }

  void adicionarProduto(Produto p) {
    produtos.add(p);
    notifyListeners();
  }

  void atualizarProduto(String id, double novoPreco, int novaQuantidade) {
    final index = produtos.indexWhere((p) => p.id == id);
    if (index != -1) {
      produtos[index].preco = novoPreco;
      produtos[index].quantidade = novaQuantidade;
      notifyListeners();
    }
  }

  void alternarStatusProduto(String id) {
    var index = produtos.indexWhere((p) => p.id == id);
    if (index != -1) {
      produtos[index].ativo = !produtos[index].ativo;
      notifyListeners();
    }
  }
}

// ==========================================
// 3. TEMA E CORES DO APP
// ==========================================

const Color kPrimaryColor = Color(0xFF00A99D);
const Color kBackgroundColor = Color(0xFFF9F9F9);
const Color kTextPrimary = Color(0xFF333333);
const Color kDangerColor = Color(0xFFE53935);
const Color kSuccessColor = Color(0xFF43A047);
const Color kWarningColor = Colors.orange;

void main() {
  runApp(const HortApp());
}

class HortApp extends StatelessWidget {
  const HortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HortApp',
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
      home: const LoginScreen(),
    );
  }
}

// ==========================================
// 4. TELAS (FRONTEND)
// ==========================================

// --- Tela de Login ---
// --- Tela de Login Corrigida ---
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // 1. Adicionamos Center e SingleChildScrollView para permitir rolagem
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // LOGO DO APP
                  Image.asset(
                    'assets/images/logo.png',
                    height: 170,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.eco, size: 80, color: kPrimaryColor),
                  ),

                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Login',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
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
                      onPressed: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const MainContainer()));
                      },
                      child: const Text('ENTRAR',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                      onPressed: () {},
                      child: const Text('Esqueceu sua senha?')),

                  // 2. Trocamos o Spacer() por um SizedBox fixo,
                  // pois Spacer dá erro dentro de SingleChildScrollView
                  const SizedBox(height: 20),

                  const Text('Nossos parceiros'),
                  const SizedBox(height: 8),

                  // LOGO IFS + Texto
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/ifs.png',
                        height: 80,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.school, color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Ainda não é cadastrado? "),
                      TextButton(
                          onPressed: () {}, child: const Text("Cadastre-se")),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Container Principal ---
class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const RegistrosScreen(),
    const ProdutosScreen(),
    const PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
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

// --- Tela 1: Home ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', height: 120, errorBuilder: (_,__,___) => const Icon(Icons.eco, color: kPrimaryColor)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mais vendidos',
                    style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                TextButton(
                    onPressed: () {},
                    child: const Text('Ver todos',
                        style: TextStyle(color: Colors.grey))),
              ],
            ),
            const SizedBox(height: 10),
            _buildBestSellerCard(
                'Maçãs', '20 vendas no último mês', Colors.yellow[700]!),
            const SizedBox(height: 10),
            _buildBestSellerCard(
                'Cenouras', '15 vendas no último mês', Colors.orange[400]!),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Sabia que',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 8),
                        Text(
                          'A agricultura familiar é responsável por cerca de 70% dos alimentos que chegam à mesa dos brasileiros.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 80,
                    height: 80,
                    color: Colors.green[50],
                    child: const Icon(Icons.agriculture,
                        color: kPrimaryColor, size: 40),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBestSellerCard(String title, String subtitle, Color stripColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 80,
            decoration: BoxDecoration(
              color: stripColor,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                Text(subtitle, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert))
        ],
      ),
    );
  }
}

// --- Tela 2: Registros ---
// --- Tela 2: Registros ---
class RegistrosScreen extends StatelessWidget {
  const RegistrosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: HortAppService(),
      builder: (context, child) {
        final service = HortAppService();

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Histórico',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
              ...service.vendas.map((v) => _buildVendaCard(v)),
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
              ...service.produtos.map((p) => _buildEstoqueCard(p)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVendaCard(Venda venda) {
    Color statusColor =
    venda.status == 'Concluído' ? kSuccessColor : kDangerColor;
    IconData statusIcon = venda.status == 'Concluído'
        ? Icons.check_circle_outline
        : Icons.cancel_outlined;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey[200],
              child: const Icon(Icons.shopping_basket, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${venda.quantidade}x ${venda.produtoNome}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Feita em ${venda.data}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Icon(statusIcon, color: statusColor, size: 30),
                Text(
                  venda.metodoPagamento,
                  style: TextStyle(color: statusColor, fontSize: 10),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- WIDGET DO ESTOQUE (ATUALIZADO COM LÓGICA DE 3 ESTADOS) ---
  Widget _buildEstoqueCard(Produto produto) {
    // Definição das variáveis de status
    Color corStatus;
    IconData iconeStatus;
    String textoStatus;

    if (produto.quantidade == 0) {
      // Caso 0: Em Falta
      corStatus = kDangerColor;
      iconeStatus = Icons.cancel_outlined;
      textoStatus = 'Produto em falta';
    } else if (produto.quantidade <= 3) {
      // Caso <= 3: Pouco Estoque
      corStatus = kWarningColor;
      iconeStatus = Icons.access_time;
      textoStatus = 'Pouco estoque';
    } else {
      // Caso > 3: Bom Estoque
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
        child: Row(
          children: [
            Text(
              '${produto.quantidade}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produto.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Adicionado em ${produto.dataAdicao}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Icon(iconeStatus, color: corStatus),
                Text(
                  textoStatus,
                  style: TextStyle(color: corStatus, fontSize: 10),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// --- Tela 3: Gerenciar Produtos ---
class ProdutosScreen extends StatelessWidget {
  const ProdutosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: HortAppService(),
      builder: (context, child) {
        final service = HortAppService();
        final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

        return Scaffold(
          appBar: AppBar(
            title: const Text('Seus Produtos',
                style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.search))
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFF00B0FF),
            child: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AdicionarProdutoScreen()));
            },
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: service.produtos.length,
            itemBuilder: (context, index) {
              final prod = service.produtos[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Row(
                  children: [
                    // Imagem Local
                    ClipOval(
                      child: Image.asset(
                        prod.imagemUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            width: 60, height: 60, color: Colors.grey[300]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(prod.nome,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(width: 4),
                              Text(
                                  '${currency.format(prod.preco)} / ${prod.unidade}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Botão Editar - AGORA FUNCIONAL
                              GestureDetector(
                                onTap: () {
                                  _mostrarDialogoEdicao(context, prod, service);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                      color: kSuccessColor,
                                      borderRadius: BorderRadius.circular(20)),
                                  child: const Text('Editar',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Botão Ativo/Inativo
                              GestureDetector(
                                onTap: () =>
                                    service.alternarStatusProduto(prod.id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                      color: prod.ativo
                                          ? kSuccessColor
                                          : kDangerColor,
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Text(prod.ativo ? 'Ativo' : 'Inativo',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12)),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.grey)
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Lógica para abrir o Dialog de Edição
  void _mostrarDialogoEdicao(
      BuildContext context, Produto prod, HortAppService service) {
    final qtdCtrl = TextEditingController(text: prod.quantidade.toString());
    final precoCtrl = TextEditingController(text: prod.preco.toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
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
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Preço"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                service.atualizarProduto(
                  prod.id,
                  double.tryParse(precoCtrl.text) ?? prod.preco,
                  int.tryParse(qtdCtrl.text) ?? prod.quantidade,
                );
                Navigator.pop(ctx);
              },
              child: const Text("Salvar"),
            ),
          ],
        );
      },
    );
  }
}

// --- Tela Auxiliar: Adicionar Produto ---
class AdicionarProdutoScreen extends StatefulWidget {
  const AdicionarProdutoScreen({super.key});

  @override
  State<AdicionarProdutoScreen> createState() => _AdicionarProdutoScreenState();
}

class _AdicionarProdutoScreenState extends State<AdicionarProdutoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _qtdCtrl = TextEditingController();
  final _precoCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _tipoSelecionado;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Produto',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Área de Upload de Imagem (Simulado)
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueAccent),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_photo_alternate_outlined,
                        size: 40, color: Colors.blue),
                    Text("Adicionar Imagem (Padrão: Logo)",
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Campos
              _buildInput('Nome do Produto', _nomeCtrl),
              const SizedBox(height: 16),
              _buildInput('Quantidade', _qtdCtrl, isNumber: true),
              const SizedBox(height: 16),
              _buildInput('Preço (Kg)', _precoCtrl, isNumber: true),
              const SizedBox(height: 16),
              _buildInput('Descrição', _descCtrl),
              const SizedBox(height: 16),

              // Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text("Tipo do Produto",
                        style: TextStyle(color: Colors.grey)),
                    value: _tipoSelecionado,
                    items: ['Verdura', 'Legume', 'Fruta', 'Raiz']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                          value: value, child: Text(value));
                    }).toList(),
                    onChanged: (val) => setState(() => _tipoSelecionado = val),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Botão Continuar/Salvar
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
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Salvar no Service
                      // Usando 'logo.png' como padrão pois não temos seletor de arquivos real
                      HortAppService().adicionarProduto(Produto(
                        id: DateTime.now().toString(),
                        nome: _nomeCtrl.text,
                        preco: double.tryParse(_precoCtrl.text) ?? 0,
                        quantidade: int.tryParse(_qtdCtrl.text) ?? 0,
                        unidade: 'Kg',
                        ativo: true,
                        dataAdicao:
                        DateFormat('dd/MM/yyyy').format(DateTime.now()),
                        imagemUrl:
                        'assets/images/logo.png', // Imagem padrão para novos itens
                      ));
                      Navigator.pop(context); // Fecha a tela e volta pra lista
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Produto adicionado!")));
                    }
                  },
                  child: const Text('CONTINUAR',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller,
      {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blue),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: kPrimaryColor, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
    );
  }
}

// --- Tela 4: Perfil ---
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nome do usuario',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const Text('email_user@gmail.com',
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Editar Foto")));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(20)),
                          child: const Text('Editar Perfil',
                              style: TextStyle(fontSize: 12)),
                        ),
                      )
                    ],
                  )
                ],
              ),
              const SizedBox(height: 40),
              // Botões agora funcionais (Simulação)
              _buildProfileOption(context, Icons.person_outline, 'Conta',
                      () => _mostrarMsg(context, "Abrir detalhes da conta")),
              _buildDivider(),
              _buildProfileOption(context, Icons.notifications_none,
                  'Notificações', () => _mostrarMsg(context, "Sem notificações")),
              _buildDivider(),
              _buildProfileOption(context, Icons.people_outline,
                  'Gerenciar Dados', () => _mostrarMsg(context, "Gerenciamento de dados")),
              _buildDivider(),
              _buildProfileOption(context, Icons.settings_outlined,
                  'Configurações', () => _mostrarMsg(context, "Configurações gerais")),
              _buildDivider(),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()));
                },
                icon: const Icon(Icons.logout, color: Colors.black),
                label: const Text('Sair',
                    style: TextStyle(color: Colors.black, fontSize: 16)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarMsg(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildProfileOption(
      BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildDivider() => const Divider(height: 1, thickness: 1);
}