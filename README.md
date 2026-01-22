# 🥬 HortApp — Agricultura Familiar Conectada

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)

![Status](https://img.shields.io/badge/Status-Em_Desenvolvimento-yellow)

O **HortApp** é um aplicativo mobile criado para **aproximar produtores da agricultura familiar** e **consumidores**, facilitando a comercialização direta de produtos **sem intermediários**.  
O app permite que pequenos produtores gerenciem **catálogo, estoque, status do produto e vendas**, enquanto consumidores podem visualizar produtos ativos e realizar compras dentro do aplicativo.

---

## ✨ Funcionalidades Implementadas (Atualizado)

### 🔐 Autenticação e Perfis
- Login e cadastro com validação simples.
- Criação de perfil no Firestore (`users/{uid}`) com **role**:
  - `vendedor`
  - `consumidor`

### 👨‍🌾 Vendedor
- **📊 Home (Dashboard):**
  - Lista de **“Mais vendidos”** (por vendedor).
  - Card informativo (“Sabia que...”).
- **📦 Produtos:**
  - Listagem com foto (assets), preço, unidade e estoque.
  - **Adicionar produto** com seleção de imagem via assets.
  - **Editar produto** (preço e quantidade).
  - **Ativar/Inativar** produto.
  - **Excluir produto** com confirmação.
- **📝 Histórico (Registros):**
  - Vendas dos últimos 7 dias.
  - Visão inteligente do estoque:
    - 🟢 Bom estoque: > 3
    - 🟠 Pouco estoque: ≤ 3
    - 🔴 Produto em falta: 0

### 🧑‍💻 Consumidor
- **🛒 Mercado:**
  - Lista de **produtos ativos** (via `collectionGroup('produtos')`).
  - Botão **Comprar** com fluxo de confirmação:
    - quantidade
    - método de pagamento (Pix/Cartão/Dinheiro)
- **⭐ Destaques:**
  - “Mais vendidos (global)” com base em `vendasMes`.

### 👤 Perfil (Compartilhado)
- Visualização de dados do usuário (nome, email, role).
- **Trocar foto de perfil** (seleção entre imagens do app via assets).
- Ativar/desativar notificações (campo no Firestore).
- Logout.

---

## 🧠 Estrutura do Firestore (Atual)

```text
users/{uid}
users/{uid}/produtos/{produtoId}
users/{uid}/vendas/{vendaId}
compras/{compraId}               # histórico global do consumidor (opcional, mas recomendado)
````

### Campos principais no produto

* `nome`, `preco`, `quantidade`, `unidade`, `imagemPath`, `ativo`
* `vendasTotal`, `vendasMes`, `vendasSemana`
* `createdAt`, `updatedAt`
* `sellerUid`

---

## ⚠️ Importante: Índices do Firestore (Collection Group)

Para o consumidor listar produtos com filtros/ordenação, o Firestore pode exigir **índices compostos**.

Se aparecer:

> `The query requires an index`

Crie índices para `collectionGroup: produtos` com:

* `ativo == true` + `orderBy updatedAt desc`
* `ativo == true` + `orderBy vendasMes desc`

> Dica: o próprio erro do console normalmente já traz o link direto para criar o índice.

---

## 🖼️ Imagens sem Firebase Storage (Assets)

O projeto utiliza imagens locais em `assets/images/`, evitando custos com Firebase Storage.

Exemplos:

* `assets/images/aipim.jpg`
* `assets/images/cebola.jpg`
* `assets/images/cenoura.jpg`
* `assets/images/maca.jpg`

---

## 🛠 Tecnologias Utilizadas

* **Linguagem:** [Dart](https://dart.dev/)
* **Framework:** [Flutter](https://flutter.dev/) (3.x)
* **Backend:** Firebase

  * `firebase_auth`: autenticação
  * `cloud_firestore`: banco de dados
* **Pacotes:**

  * `intl`: formatação de moeda e datas

---

## 🚀 Como Rodar o Projeto

### Pré-requisitos

* Flutter SDK instalado
* Android Studio ou VS Code configurado
* Emulador Android ou dispositivo físico

### Passo a Passo

1. **Clone o repositório**

```bash
git clone https://github.com/SEU-USUARIO/HortApp.git
cd HortApp
```

2. **Instale as dependências**

```bash
flutter pub get
```

3. **Configure os Assets**
   Garanta que `pubspec.yaml` contém:

```yaml
flutter:
  assets:
    - assets/images/
```

E que a pasta `assets/images` possui:

* `logo.png`
* `ifs.png`
* `aipim.jpg`
* `cebola.jpg`
* `cenoura.jpg`
* `maca.jpg`

4. **Configure o Firebase**

* Crie um projeto no Firebase Console
* Adicione o app Android com o `applicationId` do seu projeto
* Baixe `google-services.json` e coloque em:

  * `android/app/google-services.json`

5. **Execute**

```bash
flutter run
```

---

## 📂 Estrutura de Pastas (Sugestão)

```text
lib/
├── main.dart           # ponto de entrada e app completo (atual)
├── models/             # (refatoração futura) Produto, Venda, AppUserProfile
├── services/           # (refatoração futura) Firestore/Auth/Purchase services
└── screens/            # (refatoração futura) telas separadas
assets/
└── images/
```



## 🗺️ Roadmap

* [x] Conectar com banco real (Firebase Auth + Firestore)
* [x] Fluxo de compra do Consumidor
* [x] Troca de foto de perfil via assets
* [x] Excluir produto
* [ ] Regras do Firestore mais restritas e seguras para compra
* [ ] Aba “Minhas compras” (histórico do consumidor)
* [ ] Filtros e pesquisa no Mercado
* [ ] Upload real de imagens (opcional) — câmera/galeria (Storage/alternativas)

---

## 👥 Autores

* **João Pedro Santana Silva Santos**
* **Luiz Eduardo Andrade de Oliveira**


