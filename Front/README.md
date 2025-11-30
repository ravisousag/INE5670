# Front — Aplicação Flutter

Visão geral
----------
Este diretório contém a aplicação front-end desenvolvida com Flutter/Dart para o projeto INE5670. A interface comunica-se com o backend para coletar e exibir dados dos dispositivos e serviços do sistema móvel/embarcado.

Principais objetivos
- Aplicação multiplataforma (Android, iOS, Web, desktop).
- Interface para visualização, controle e configuração de dispositivos.
- Comunicação segura e configurável com o backend.

Pré-requisitos
--------------
- Flutter SDK (recomendado canal stable) — https://flutter.dev
- Dart (vem com o Flutter)
- Android SDK / Xcode (para builds mobile)
- Ferramentas de linha de comando: git
- (Opcional) Chrome para execução web local

Instalação (local)
------------------
1. Clone o repositório (se necessário):
   git clone https://github.com/ravisousag/INE5670.git
   cd INE5670/Front

2. Instale dependências:
   flutter pub get

3. Configure variáveis de ambiente do app (se aplicável):
   - Se o projeto usar pacotes como flutter_dotenv, crie um arquivo `.env` na raiz do Front com chaves como:
     BACKEND_BASE_URL=http://localhost:8000
     API_KEY=seu_token_aqui
   - Caso não utilize `.env`, verifique a constante de base URL em `lib/` e ajuste conforme necessário.

Execução (desenvolvimento)
--------------------------
- Emulador Android:
  flutter run -d emulator-5554
- iOS (macOS com Xcode):
  flutter run -d <device-id>
- Web (Chrome):
  flutter run -d chrome
- Desktop (se habilitado):
  flutter run -d windows|linux|macos

Builds para produção
--------------------
- Android (APK):
  flutter build apk --release
- Android (App Bundle):
  flutter build appbundle --release
- iOS:
  flutter build ios --release
- Web:
  flutter build web

Estrutura do diretório
----------------------
- android/, ios/, web/, macos/, windows/, linux/ — plataformas geradas pelo Flutter
- lib/ — código fonte Dart/Flutter
  - main.dart — ponto de entrada
  - (possíveis) pastas: app/, features/, core/, shared/
- pubspec.yaml — dependências e assets
- analysis_options.yaml — regras de lint/analysis

Arquitetura recomendada
----------------------
- Separar camadas: apresentação (widgets), estado (provider/bloc/riverpod), domínio (models), infra (serviços HTTP, repositórios).
- Exemplo de organização:
  lib/
    ├─ main.dart
    ├─ app/
    ├─ features/
    ├─ core/
    └─ shared/

Integração com o backend
------------------------
- Centralize a URL base do backend em uma única constante/arquivo de configuração.
- Exemplo (pseudo):
  const String BASE_URL = String.fromEnvironment('BACKEND_BASE_URL', defaultValue: 'http://localhost:8000');

- Exemplo de requisição com http:
  final response = await http.get(Uri.parse('$BASE_URL/api/resource'));

Tratamento de erros e timeouts
------------------------------
- Defina timeouts nas requisições (ex: timeout: Duration(seconds: 10)).
- Mostre mensagens de erro amigáveis ao usuário e logs detalhados em modo debug.

Testes
------
- Testes de unidade:
  flutter test
- Testes de widget:
  flutter test
- Recomendação: configurar CI para rodar testes em cada PR.

Linting e formatação
--------------------
- Rodar análise:
  dart analyze
- Formatar:
  flutter format .

CI sugerido (GitHub Actions)
----------------------------
- Workflow mínimo:
  - Checkout
  - Setup Flutter
  - flutter pub get
  - dart analyze
  - flutter test
  - (opcional) build

Segurança
--------
- Nunca comitar chaves ou tokens em texto plano.
- Use variáveis de ambiente/segredos de CI para chaves de produção.
- Habilite HTTPS no backend e valide certificados quando necessário.

Boas práticas de contribuição
-----------------------------
- Use branches por feature: feature/nome
- Faça commits pequenos e atômicos com mensagens claras.
- Abra Pull Requests com descrição das mudanças e screenshots se for UI.

Solução de problemas (comuns)
-----------------------------
- Erro “Missing SDK” — rode `flutter doctor` e instale dependências.
- Problemas com certificados HTTPS locais — use `flutter run --web-hostname=localhost` ou configure um certificado local confiável.
- Dependências quebradas — delete `.packages` e `pubspec.lock` e rode `flutter pub get`.

Contato
-------
Para dúvidas relacionadas ao front, abra uma issue ou contate o mantenedor do repositório.

Licença
-------
Ver arquivo LICENSE na raiz do repositório (se aplicável).