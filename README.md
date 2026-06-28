# 🥬 AgroApp — Agricultura Familiar Conectada

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Status](https://img.shields.io/badge/Status-MVP_Concluído-success)

O **AgroApp** (anteriormente HortApp) é um aplicativo mobile criado para **aproximar produtores da agricultura familiar** e **consumidores**, facilitando a comercialização direta de produtos **sem intermediários**.  
O app permite que pequenos produtores gerenciem seu catálogo, estoque e vendas, enquanto os consumidores podem explorar, filtrar, adicionar itens ao carrinho e realizar compras com geolocalização e geração de PIX. O projeto conta também com um **ERP de Backoffice** integrado para gestão administrativa.

---

## ✨ Funcionalidades Implementadas

### 🔐 Autenticação e Perfis
* **Login e Cadastro:** Validação segura de credenciais.
* **Separação de Papéis (Roles):** Perfis distintos e rotas específicas para `vendedor` e `consumidor`.

### 👨‍🌾 Para o Produtor (Vendedor)
* **Dashboard de Vendas:** Visão geral de "Mais vendidos" e cards educativos.
* **Gestão de Catálogo (CRUD):** Adição, edição, ativação/inativação e exclusão de produtos.
* **Upload em Nuvem:** Envio de fotos reais dos produtos através da API do Cloudinary.
* **Controle de Estoque:** Dedução automática pós-compra e alertas visuais (Verde, Laranja e Vermelho para produtos esgotados).
* **Exportação de Relatórios:** Geração de relatórios de vendas em CSV/Excel compartilháveis via WhatsApp ou e-mail.

### 🧑‍💻 Para o Consumidor
* **Mercado Inteligente:** Listagem global de produtos ativos com barra de pesquisa.
* **Filtros Avançados:** Filtragem por categorias (Frutas, Verduras, etc.) e faixa de preço.
* **Carrinho de Compras:** Adição de itens e cálculo automático de subtotal.
* **Checkout com Geolocalização:** Integração com Google Maps para marcação exata do local de entrega.
* **Pagamentos:** Geração dinâmica de QR Code PIX (Copia e Cola) e simulação de Cartão/Dinheiro.
* **Histórico e Avaliações:** Aba "Minhas Compras" com opção de classificar os produtos (1 a 5 estrelas).

### 👤 Perfil e Segurança (Compartilhado)
* **Gestão de Perfil:** Visualização de dados e troca de foto de avatar.
* **Notificações Push:** Alertas locais integrados via `flutter_local_notifications`.
* **Adequação à LGPD:** Termos de privacidade e botão para **Exclusão Definitiva de Conta** e apagamento de dados do banco.

---

## 🖥️ ERP / Painel Administrativo (Backoffice)
O AgroApp é suportado por um painel web construído em **Appsmith** (Low-Code), conectado diretamente ao Firebase.
* **Gestão de Usuários:** Tabela com todos os produtores e consumidores cadastrados.
* **Gestão de Pedidos:** Acompanhamento global das transações.
* **Catálogo Global:** Leitura de produtos através de *Collection Group Queries*.
* **Histórico Financeiro:** Visualização do histórico de vendas de forma unificada.

---

## 🧠 Estrutura do Banco de Dados (Firestore)

A arquitetura foi desenhada com subcoleções para garantir segurança e isolamento de dados por usuário:

```text
users/{uid}                              # Dados do perfil do usuário
users/{uid}/produtos/{produtoId}         # Catálogo isolado do vendedor
users/{uid}/vendas/{vendaId}             # Histórico de vendas do vendedor
pedidos/{pedidoId}                       # Histórico global de compras (Consumidores)

```

**Segurança:** Regras rigorosas (`rules_version = '2'`) aplicadas no Firestore impedem que consumidores acessem dados financeiros dos vendedores, permitindo apenas a leitura dos produtos ativos e gravação no momento do checkout.

---

## 🛠 Tecnologias Utilizadas

* **Framework Mobile:** [Flutter](https://flutter.dev/) (Dart)
* **BaaS (Backend as a Service):** Firebase (Auth e Firestore)
* **Armazenamento de Imagens:** Cloudinary API
* **Geolocalização:** Google Maps SDK (`Maps_flutter`) e `geolocator`
* **ERP Web:** Appsmith
* **Outros Pacotes Relevantes:**
* `share_plus` (Exportação CSV)
* `provider` (Gerenciamento de estado do Carrinho)
* `qr_flutter` (Geração de QR Code PIX)



---

## 🚀 Como Rodar o Projeto

### Pré-requisitos

* Flutter SDK (3.x) instalado.
* Chave de API do Google Maps (Necessária no `AndroidManifest.xml`).
* Conta no Cloudinary e Firebase.

### Passo a Passo

1. **Clone o repositório**
```bash
git clone [https://github.com/SEU-USUARIO/AgroApp.git](https://github.com/SEU-USUARIO/AgroApp.git)
cd AgroApp

```


2. **Instale as dependências**
```bash
flutter pub get

```


3. **Configure as Chaves e Serviços**
* Adicione o seu ficheiro `google-services.json` em `android/app/`.
* Insira a sua API Key do Google Maps na tag `<meta-data>` dentro de `android/app/src/main/AndroidManifest.xml`.
* Configure as suas credenciais do Cloudinary no serviço de imagens.


4. **Execute em modo Debug**
```bash
flutter run

```


5. **Gere o APK para Produção**
```bash
flutter build apk --release

```



---

## 🗺️ Roadmap (Concluído ✅)

* [x] Conectar com banco real (Firebase Auth + Firestore)
* [x] Fluxo completo de compra do Consumidor (Carrinho e Checkout)
* [x] Upload real de imagens integrando Cloudinary
* [x] Filtros e pesquisa avançada no Mercado
* [x] Integração com Google Maps para georreferenciação
* [x] Exportação de relatórios (CSV) e LGPD
* [x] Regras de Segurança do Firestore aplicadas
* [x] Desenvolver um ERP para gerenciar usuários e produtos (Appsmith)

---

## 👥 Autores

* **João Pedro Santana Silva Santos**
* **Luiz Eduardo Andrade de Oliveira**

> Projeto Integrador II
