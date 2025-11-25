# INE5670 — Backend (Flask)

API backend para gerenciamento de usuários e fluxo de pareamento NFC.

## Resumo
- Framework: Flask
- Banco: SQLite (arquivo `database.sqlite` em `Back/src/`)
- Principais responsabilidades: CRUD de usuários, pareamento NFC (token + polling), endpoints para Arduino

## Pré-requisitos
- Python 3.8+ (recomenda-se 3.10/3.11)
- `python3-venv` (para criar um ambiente virtual)

## Setup (recomendado)
No diretório `Back/`:

```bash
cd ~/Documentos/Projetos/Meus/INE5670/Back
# criar venv local
python3 -m venv .venv
source .venv/bin/activate

# atualizar pip e instalar dependências
pip install --upgrade pip
pip install -r requirements.txt
```

Observação: se ao executar `pip install` aparecer o erro sobre "externally-managed-environment" (PEP 668), crie e use um virtualenv como mostrado acima.

## Rodando em desenvolvimento

```bash
source .venv/bin/activate
python3 src/app.py
```

Por padrão a API roda em `http://127.0.0.1:5000`.

## Principais endpoints

- `POST /api/users` — criar usuário
- `GET /api/users` — listar usuários
- `PUT /api/users/cpf/<cpf>` — editar usuário
- `DELETE /api/users/cpf/<cpf>` — remover usuário
- `GET /api/users/cpf/<cpf>` — obter usuário por CPF

- NFC / Pareamento
  - `POST /api/nfc/pair_start` — inicia sessão de pareamento (Body: `{ "cpf": "..." }`) — retorna `pair_token`
  - `GET /api/nfc/pair_status/<pair_token>` — consulta status do pareamento (polling do app)
  - `POST /api/nfc/sync` — Arduino envia `{ "nfc_card_uuid": "..." }` para sincronizar com sessão ativa
  - `PUT /api/nfc/link` — vincular cartão manualmente (Body: `{ "nfc_card_uuid": "...", "cpf": "..." }`)
  - `PUT /api/nfc/unlink` — desassociar cartão do usuário (Body: `{ "cpf": "..." }`)
  - `GET /api/nfc/validate/<nfc_uuid>` — valida cartão (usado pelo Arduino no acesso)

- `GET /api/logs` — listar logs de acesso/ações

## Fluxo de pareamento (resumo)
1. App (Flutter) chama `POST /api/nfc/pair_start` com o `cpf` do usuário. Recebe `pair_token` e `expires_at`.
2. App faz polling em `GET /api/nfc/pair_status/<pair_token>` a cada ~2s mostrando instruções.
3. Arduino detecta cartão e faz `POST /api/nfc/sync` com `{ "nfc_card_uuid": "..." }`.
4. Backend encontra sessão ativa, vincula UUID ao usuário e marca sessão como `vinculado`.
5. App, no próximo poll, vê `vinculado: true` e atualiza a UI.

## Testes rápidos (curl)

Gerar token de pareamento (substitua CPF):
```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"cpf":"12345678900"}' \
  http://127.0.0.1:5000/api/nfc/pair_start
```

Simular Arduino enviando UUID (substitua UUID real):
```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"nfc_card_uuid":"9F48-4D3F-1BE7"}' \
  http://127.0.0.1:5000/api/nfc/sync
```

Consultar status do pareamento (substitua token retornado):
```bash
curl http://127.0.0.1:5000/api/nfc/pair_status/<PAIR_TOKEN>
```

## Observações e troubleshooting
- O banco `database.sqlite` é criado automaticamente na primeira execução.
- Se o app Flutter for executado em um dispositivo físico, ajuste a `base` URL nas services para apontar ao IP da máquina que roda o backend (por exemplo `http://192.168.1.229:5000`).
- Para produção, considere usar `gunicorn` (incluso em `requirements.txt`).

## Estrutura de arquivos relevante
- `src/app.py` — aplicação Flask
- `src/models/` — modelos `User`, `Log`, `PairingSession`

---
Arquivo gerado automaticamente. Para dúvidas, abra uma issue local ou me peça ajuda.
