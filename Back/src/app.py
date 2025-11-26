from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
from models.user import db, User
from models.log import Log
from models.pairing import PairingSession
import os
import re

app = Flask(__name__)
CORS(app)  # Habilita CORS para todas as rotas

# Configuração do banco de dados
basedir = os.path.abspath(os.path.dirname(__file__))
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///' + os.path.join(basedir, 'database.sqlite')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# Inicializar banco de dados
db.init_app(app)

# Criar tabelas
with app.app_context():
    db.create_all()

def validate_cpf(cpf):
    """Valida formato do CPF (apenas números, 11 dígitos)"""
    # Remove caracteres não numéricos
    cpf = re.sub(r'[^0-9]', '', cpf)
    return len(cpf) == 11

def validate_email(email):
    """Valida formato do email"""
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None

@app.route('/')
def hello_world():
    return '<h1>API de Usuários - INE5670</h1>'

# Rota para criar usuário
@app.route('/api/users', methods=['POST'])
def create_user():
    try:
        data = request.get_json()
        
        # Validação de campos obrigatórios
        required_fields = ['name', 'cpf', 'email', 'phone']
        for field in required_fields:
            if not data or not data.get(field):
                return jsonify({'error': f'O campo {field} é obrigatório'}), 400
        
        # Validação de formato do CPF
        if not validate_cpf(data['cpf']):
            return jsonify({'error': 'CPF inválido. Deve conter 11 dígitos numéricos'}), 400
        
        # Validação de formato do email
        if not validate_email(data['email']):
            return jsonify({'error': 'Email inválido'}), 400
        
        # Limpar CPF (remover pontos e traços)
        cpf_clean = re.sub(r'[^0-9]', '', data['cpf'])
        
        # Verificar se CPF já existe
        if User.query.filter_by(cpf=cpf_clean).first():
            return jsonify({'error': 'CPF já cadastrado'}), 400
        
        # Verificar se email já existe
        if User.query.filter_by(email=data['email']).first():
            return jsonify({'error': 'Email já cadastrado'}), 400
        
        # Criar usuário com nfc_card_uuid = None (null)
        user = User(
            name=data['name'],
            cpf=cpf_clean,
            email=data['email'],
            phone=data['phone'],
            nfc_card_uuid=None
        )
        
        db.session.add(user)
        db.session.commit()
        
        return jsonify({
            'message': 'Usuário criado com sucesso',
            'user': user.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500
    
# Rota para Listar todos os usuários
@app.route('/api/users', methods=['GET'])
def list_users():
    try:
        users = User.query.all()
        return jsonify({
            'users': [user.to_dict() for user in users],
            'total': len(users)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Rota para editar usuário (por CPF)
@app.route('/api/users/cpf/<string:cpf>', methods=['PUT'])
def edit_user(cpf):
    try:
        # Limpar CPF (remover pontos e traços)
        cpf_clean = re.sub(r'[^0-9]', '', cpf)
        
        # Validar formato do CPF
        if not validate_cpf(cpf_clean):
            return jsonify({'error': 'CPF inválido. Deve conter 11 dígitos numéricos'}), 400
        
        # Buscar usuário por CPF
        user = User.query.filter_by(cpf=cpf_clean).first()
        if not user:
            return jsonify({'error': 'Usuário não encontrado'}), 404
        
        # Salvar CPF original para validações
        original_cpf = user.cpf
        original_email = user.email
        
        data = request.get_json()
        
        # Atualizar nome
        if 'name' in data:
            user.name = data['name']
        
        # Atualizar CPF
        if 'cpf' in data:
            if not validate_cpf(data['cpf']):
                return jsonify({'error': 'CPF inválido. Deve conter 11 dígitos numéricos'}), 400
            
            new_cpf_clean = re.sub(r'[^0-9]', '', data['cpf'])
            # Verificar se o novo CPF já existe (exceto para o próprio usuário)
            if new_cpf_clean != original_cpf:
                existing_user = User.query.filter_by(cpf=new_cpf_clean).first()
                if existing_user:
                    return jsonify({'error': 'CPF já cadastrado'}), 400
            user.cpf = new_cpf_clean
        
        # Atualizar email
        if 'email' in data:
            if not validate_email(data['email']):
                return jsonify({'error': 'Email inválido'}), 400
            
            # Verificar se o novo email já existe (exceto para o próprio usuário)
            if data['email'] != original_email:
                existing_user = User.query.filter_by(email=data['email']).first()
                if existing_user:
                    return jsonify({'error': 'Email já cadastrado'}), 400
            user.email = data['email']
        
        # Atualizar telefone
        if 'phone' in data:
            user.phone = data['phone']
        
        # Atualizar NFC UUID
        if 'nfc_card_uuid' in data:
            nfc_uuid = data['nfc_card_uuid']
            if nfc_uuid:
                existing_user = User.query.filter_by(nfc_card_uuid=nfc_uuid).first()
                if existing_user and existing_user.id != user.id:
                    return jsonify({'error': 'UUID do cartão NFC já cadastrado'}), 400
            user.nfc_card_uuid = nfc_uuid
        
        db.session.commit()
        
        return jsonify({
            'message': 'Usuário atualizado com sucesso',
            'user': user.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

# Rota para deletar usuário (por CPF)
@app.route('/api/users/cpf/<string:cpf>', methods=['DELETE'])
def delete_user(cpf):
    try:
        # Limpar CPF (remover pontos e traços)
        cpf_clean = re.sub(r'[^0-9]', '', cpf)
        
        # Validar formato do CPF
        if not validate_cpf(cpf_clean):
            return jsonify({'error': 'CPF inválido. Deve conter 11 dígitos numéricos'}), 400
        
        # Buscar usuário por CPF
        user = User.query.filter_by(cpf=cpf_clean).first()
        if not user:
            return jsonify({'error': 'Usuário não encontrado'}), 404
        
        db.session.delete(user)
        db.session.commit()
        
        return jsonify({
            'message': 'Usuário deletado com sucesso'
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


# Rota para ler usuário (por CPF)
@app.route('/api/users/cpf/<string:cpf>', methods=['GET'])
def get_user_by_cpf(cpf):
    try:
        # Limpar CPF (remover pontos e traços)
        cpf_clean = re.sub(r'[^0-9]', '', cpf)
        
        # Validar formato do CPF
        if not validate_cpf(cpf_clean):
            return jsonify({'error': 'CPF inválido. Deve conter 11 dígitos numéricos'}), 400
        
        # Buscar usuário por CPF
        user = User.query.filter_by(cpf=cpf_clean).first()
        if not user:
            return jsonify({'error': 'Usuário não encontrado'}), 404
        
        return jsonify({
            'user': user.to_dict()
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Rota para VINCULAR cartão NFC existente a um usuário (Flutter solicita)
@app.route('/api/nfc/link', methods=['PUT'])
def link_nfc_to_user():
    try:
        data = request.get_json()
        
        if not data or not data.get('nfc_card_uuid') or not data.get('cpf'):
            return jsonify({
                'error': 'nfc_card_uuid e cpf são obrigatórios'
            }), 400
        
        nfc_uuid = data['nfc_card_uuid']
        cpf_clean = re.sub(r'[^0-9]', '', data['cpf'])
        
        # Buscar usuário
        user = User.query.filter_by(cpf=cpf_clean).first()
        if not user:
            return jsonify({'error': 'Usuário não encontrado'}), 404
        
        # Verificar se usuário já tem cartão
        if user.nfc_card_uuid:
            return jsonify({
                'error': 'Usuário já possui um cartão NFC registrado',
                'nfc_card_uuid': user.nfc_card_uuid
            }), 409
        
        # Verificar se UUID já está registrado em outro usuário
        other_user = User.query.filter_by(nfc_card_uuid=nfc_uuid).first()
        if other_user:
            return jsonify({
                'error': 'UUID do cartão NFC já está registrado em outro usuário'
            }), 409
        
        # Vincular cartão ao usuário
        user.nfc_card_uuid = nfc_uuid
        db.session.commit()
        
        # Gravar log
        log = Log(
            user_id=user.id,
            nfc_uuid=nfc_uuid,
            user_exists=True,
            action='LINK'
        )
        db.session.add(log)
        db.session.commit()
        
        return jsonify({
            'message': 'Cartão NFC vinculado com sucesso',
            'user': user.to_dict(),
            'log_id': log.id
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


# Rota para VALIDAR cartão NFC 
@app.route('/api/nfc/validate/<string:nfc_uuid>', methods=['GET'])
def validate_nfc_card(nfc_uuid):

    try:
        user = User.query.filter_by(nfc_card_uuid=nfc_uuid).first()
        
        if user:
            # Cartão válido - gravar log de acesso
            log = Log(
                user_id=user.id,
                nfc_uuid=nfc_uuid,
                user_exists=True,
                action='ACCESS_GRANTED'
            )
            db.session.add(log)
            db.session.commit()
            
            return jsonify({
                'authorized': True,
                'message': f'Acesso permitido para {user.name}',
                'user': user.to_dict(),
                'log_id': log.id
            }), 200
        else:
            # Cartão inválido - gravar log de acesso negado
            log = Log(
                user_id=None,
                nfc_uuid=nfc_uuid,
                user_exists=False,
                action='ACCESS_DENIED'
            )
            db.session.add(log)
            db.session.commit()
            
            return jsonify({
                'authorized': False,
                'message': 'Cartão NFC não cadastrado',
                'log_id': log.id
            }), 404
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


# NOVO: Iniciar sessão de pareamento (gerar token)
@app.route('/api/nfc/pair_start', methods=['POST'])
def pair_start():
    """
    Cria um token de pareamento para um usuário.
    Body: { "cpf": "12345678900" }
    Retorna: { pair_token, expires_at }
    """
    try:
        data = request.get_json()
        if not data or not data.get('cpf'):
            return jsonify({'error': 'cpf é obrigatório'}), 400

        cpf_clean = re.sub(r'[^0-9]', '', data['cpf'])
        user = User.query.filter_by(cpf=cpf_clean).first()
        if not user:
            return jsonify({'error': 'Usuário não encontrado'}), 404

        # Se usuário já tem cartão vinculado, impedir pareamento
        if user.nfc_card_uuid:
            return jsonify({'error': 'Usuário já possui um cartão NFC vinculado'}), 409

        # Gerar token simples (hex groups)
        import secrets
        from datetime import datetime, timedelta
        token_raw = secrets.token_hex(8).upper()
        pair_token = f"{token_raw[0:4]}-{token_raw[4:8]}-{token_raw[8:12]}"

        expires_at = datetime.utcnow() + timedelta(seconds=60)

        session = PairingSession(
            pair_token=pair_token,
            user_id=user.id,
            expires_at=expires_at,
            vinculado=False
        )

        db.session.add(session)
        db.session.commit()

        return jsonify({
            'pair_token': session.pair_token,
            'expires_at': session.expires_at.isoformat(),
            'vinculado': session.vinculado,
            'user_id': session.user_id
        }), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


# NOVO: Endpoint que o Arduino chama quando lê um cartão para sincronizar (pareamento)
@app.route('/api/nfc/sync', methods=['POST'])
def nfc_sync():
    """
    Arduino envia: { "nfc_card_uuid": "..." }
    O backend procura por uma sessão de pareamento ativa (vinculado==False e não expirada)
    Se existir, vincula o usuário ao UUID e marca session.vinculado = True
    """
    try:
        data = request.get_json()
        if not data or not data.get('nfc_card_uuid'):
            return jsonify({'error': 'nfc_card_uuid é obrigatório'}), 400

        nfc_uuid = data['nfc_card_uuid']

        from datetime import datetime
        now = datetime.utcnow()

        # Procurar sessão ativa de pareamento (a mais recente)
        session = PairingSession.query.filter(
            PairingSession.vinculado == False,
            PairingSession.expires_at > now
        ).order_by(PairingSession.created_at.desc()).first()

        if not session:
            # Nenhuma sessão ativa esperando pareamento
            # Registrar log de tentativa não autorizada
            log = Log(user_id=None, nfc_uuid=nfc_uuid, user_exists=False, action='SYNC_NO_SESSION')
            db.session.add(log)
            db.session.commit()
            return jsonify({'linked': False, 'message': 'Nenhuma sessão de pareamento ativa'}), 404

        # Vincular UUID ao usuário
        user = User.query.get(session.user_id)
        if not user:
            return jsonify({'error': 'Usuário da sessão de pareamento não encontrado'}), 404

        # Evitar duplicidade
        existing = User.query.filter_by(nfc_card_uuid=nfc_uuid).first()
        if existing:
            return jsonify({'error': 'UUID já vinculado a outro usuário'}), 409

        user.nfc_card_uuid = nfc_uuid
        session.vinculado = True

        # Gravar log de LINK por pareamento
        log = Log(user_id=user.id, nfc_uuid=nfc_uuid, user_exists=True, action='LINK')

        db.session.add(log)
        db.session.commit()

        return jsonify({'linked': True, 'user': user.to_dict(), 'pair_token': session.pair_token}), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


# NOVO: Status do pareamento (consumido pelo app via polling)
@app.route('/api/nfc/pair_status/<string:pair_token>', methods=['GET'])
def pair_status(pair_token):
    try:
        session = PairingSession.query.filter_by(pair_token=pair_token).first()
        if not session:
            return jsonify({'error': 'Token de pareamento não encontrado'}), 404

        from datetime import datetime
        now = datetime.utcnow()
        expired = session.expires_at <= now

        user = User.query.get(session.user_id)

        return jsonify({
            'pair_token': session.pair_token,
            'vinculado': bool(session.vinculado),
            'expired': expired,
            'user': user.to_dict() if user else None,
            'expires_at': session.expires_at.isoformat() if session.expires_at else None
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


# NOVO: Desassociar cartão NFC de um usuário
@app.route('/api/nfc/unlink', methods=['PUT'])
def unlink_nfc_from_user():
    """
    Remove a associação de um cartão NFC de um usuário
    Body: { "cpf": "12345678900" }
    """
    try:
        data = request.get_json()
        if not data or not data.get('cpf'):
            return jsonify({'error': 'cpf é obrigatório'}), 400

        cpf_clean = re.sub(r'[^0-9]', '', data['cpf'])
        user = User.query.filter_by(cpf=cpf_clean).first()
        if not user:
            return jsonify({'error': 'Usuário não encontrado'}), 404

        if not user.nfc_card_uuid:
            return jsonify({'error': 'Usuário não possui cartão NFC vinculado'}), 400

        nfc_uuid = user.nfc_card_uuid
        user.nfc_card_uuid = None
        db.session.commit()

        # Gravar log de UNLINK
        log = Log(user_id=user.id, nfc_uuid=nfc_uuid, user_exists=True, action='UNLINK')
        db.session.add(log)
        db.session.commit()

        return jsonify({
            'message': 'Cartão NFC desvinculado com sucesso',
            'user': user.to_dict(),
            'log_id': log.id
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


# @app.route('/api/nfc/all', methods=['GET'])
# def list_all_nfc_cards():
#     """
#     Lista todos os cartões NFC registrados (associados a usuários)
#     e sessões de pareamento (opcionais)
#     """
#     try:
#         users = User.query.filter(User.nfc_card_uuid != None).all()
#         sessions = PairingSession.query.order_by(PairingSession.created_at.desc()).all()

#         cards = []
#         for u in users:
#             cards.append({
#                 'nfc_card_uuid': u.nfc_card_uuid,
#                 'user': u.to_dict()
#             })

#         sessions_list = [s.to_dict() for s in sessions]

#         return jsonify({
#             'cards': cards,
#             'pairing_sessions': sessions_list
#         }), 200

#     except Exception as e:
#         return jsonify({'error': str(e)}), 500

# Rota para listar todos os logs
@app.route('/api/logs', methods=['GET'])
def list_logs():
    try:
        logs = Log.query.order_by(Log.timestamp.desc()).all()
        return jsonify({
            'logs': [log.to_dict() for log in logs],
            'total': len(logs)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000, debug=True)