# 🥬 HortApp - Agricultura Familiar Conectada

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)

![Status](https://img.shields.io/badge/Status-Em_Desenvolvimento-yellow)

O **HortApp** é um aplicativo móvel desenvolvido para facilitar a comercialização direta de produtos da agricultura familiar. O objetivo é eliminar intermediários, permitindo que pequenos produtores gerenciem seus produtos, estoques e vendas, conectando-se diretamente aos consumidores finais.

Este repositório contém o **Front-end** e uma simulação de **Back-end (Mock Service)** desenvolvidos em Flutter.

## ✨ Funcionalidades Implementadas

* **🔐 Autenticação:** Tela de Login com interface amigável e integração visual com parceiros (IFS).
* **📊 Dashboard (Home):**
    * Visualização dos produtos "Mais Vendidos".
    * Cards informativos sobre a agricultura familiar.
* **📦 Gerenciamento de Produtos:**
    * Listagem de produtos com foto, preço e unidade (Kg/Unidade).
    * **Adicionar Produto:** Formulário para inclusão de novos itens no catálogo.
    * **Editar Produto:** Alteração rápida de preço e quantidade.
    * **Status:** Alternar produto entre "Ativo" e "Inativo".
* **📉 Controle de Estoque Inteligente:**
    * Feedback visual automático baseado na quantidade:
        * 🟢 **Bom estoque:** > 3 unidades.
        * 🟠 **Pouco estoque:** ≤ 3 unidades.
        * 🔴 **Produto em falta:** 0 unidades.
* **📝 Histórico de Vendas:** Registro visual das vendas realizadas (Concluídas/Canceladas) e métodos de pagamento.

## 🛠 Tecnologias Utilizadas

* **Linguagem:** [Dart](https://dart.dev/)
* **Framework:** [Flutter](https://flutter.dev/) (Versão 3.x)
* **Pacotes:**
    * `intl`: Para formatação de moeda (R$) e datas.
    * `flutter_lints`: Para boas práticas de código.
* **Arquitetura:** MVC Simplificado (Service Controller para gerenciamento de estado local).

## 🚀 Como Rodar o Projeto

### Pré-requisitos

* [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado.
* Android Studio ou VS Code configurado.
* Dispositivo Android (Físico ou Emulador).

### Passo a Passo

1.  **Clone o repositório:**
    ```bash
    git clone [https://github.com/SEU-USUARIO/HortApp.git](https://github.com/SEU-USUARIO/HortApp.git)
    cd HortApp
    ```

2.  **Instale as dependências:**
    ```bash
    flutter pub get
    ```

3.  **Configure os Assets:**
    Certifique-se de que a pasta `assets/images` contém as imagens necessárias (`logo.png`, `cenoura.jpg`, `cebola.jpg`, `maca.jpg`, `aipim.jpg`, `ifs.png`).

4.  **Execute o aplicativo:**
    ```bash
    flutter run
    ```

## 📂 Estrutura de Pastas

```text
lib/
├── main.dart           # Ponto de entrada e estrutura principal
├── models/             # (Sugestão futura) Classes Produto e Venda
├── services/           # Lógica de dados (HortAppService)
└── screens/            # Telas (Login, Home, Registros, Produtos)
assets/
└── images/             # Imagens estáticas (Logos, Produtos)

````

## 🚧 Próximos Passos (Roadmap)

- [ ] Conectar com Banco de Dados Real (Firebase/Supabase).
- [ ] Implementar upload real de imagens (Câmera/Galeria).
- [ ] Criar fluxo de compra para o perfil "Consumidor".
- [ ] Filtros avançados de pesquisa.

## 👥 Autores

* **João Pedro Santana Silva Santos**
* **Luiz Eduardo Andrade de Oliveira**
