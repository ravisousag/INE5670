# INE5670 — Frontend (Flutter)

Aplicativo Flutter para gerenciar usuários e pareamento NFC com o backend Flask.

## Resumo
- Flutter app com páginas: `home`, `users`, `logs`.
- Implementa fluxo de pareamento token-based com polling via `user_nfc_modal`.

## Pré-requisitos
- Flutter SDK (recomenda-se a versão estável mais recente)
- Emulador Android/iOS ou dispositivo físico conectado

## Setup
No diretório `Front/` (ou onde estiver o código Flutter):

```bash
cd ~/Documentos/Projetos/Meus/INE5670/Front
flutter pub get
```

Se for executar no dispositivo físico, ajuste a URL base do backend (`ApiService.base`) para o IP da máquina onde o backend roda, por exemplo `http://192.168.1.229:5000`.

## Rodando o app

```bash
flutter run
```

ou para abrir no emulador:

```bash
flutter emulators
flutter emulators --launch <ID>
flutter run
```

## Principais pontos de integração
- O serviço HTTP está em `lib/api_service.dart` e `lib/services/nfc_service.dart`.
- Fluxo de pareamento:
  - `startPairing(cpf)` chama `POST /api/nfc/pair_start` e recebe `pair_token`;
  - `user_nfc_modal.dart` faz polling em `GET /api/nfc/pair_status/<pair_token>` até `vinculado=true`;
  - Arduino faz `POST /api/nfc/sync` para concluir o pareamento.

## Funcionalidades UI
- `users_page.dart` — criar/editar/remover usuários. Ao criar, é possível iniciar pareamento.
- `logs_page.dart` — exibe logs de acesso e ações (LINK/UNLINK/ACCESS_GRANTED/...)

## Testes e simulações
- Para testar sem Arduino, gere um `pair_token` pelo backend e depois simule o Arduino:

```bash
# gerar token (substitua CPF)
curl -X POST -H "Content-Type: application/json" \
  -d '{"cpf":"12345678900"}' \
  http://127.0.0.1:5000/api/nfc/pair_start

# depois simule sync com o UUID
curl -X POST -H "Content-Type: application/json" \
  -d '{"nfc_card_uuid":"9F48-4D3F-1BE7"}' \
  http://127.0.0.1:5000/api/nfc/sync
```

## Notas
- Se o app rodar em um dispositivo físico, `http://127.0.0.1:5000` não apontará para seu host — use o IP da máquina de desenvolvimento.
- A página `list_cards_page.dart` foi removida (não utilizada).

---
Arquivo gerado automaticamente. Peça para eu ajustar instruções específicas de ambiente ou adicionar passos de build/CI.
