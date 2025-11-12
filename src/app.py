from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from models.user import db, User
from models.log import Log
import os
import re

app = Flask(__name__)

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

# 1. Rota para criar usuário
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
        
        # Verificar se NFC UUID já existe (se fornecido)
        nfc_uuid = data.get('nfc_card_uuid')
        if nfc_uuid and User.query.filter_by(nfc_card_uuid=nfc_uuid).first():
            return jsonify({'error': 'UUID do cartão NFC já cadastrado'}), 400
        
        # Criar usuário
        user = User(
            name=data['name'],
            cpf=cpf_clean,
            email=data['email'],
            phone=data['phone'],
            nfc_card_uuid=nfc_uuid
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

# 2. Rota para editar usuário (por CPF)
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

# 3. Rota para deletar usuário (por CPF)
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

# 4. Rota para ler usuário (por ID)
@app.route('/api/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    try:
        user = User.query.get_or_404(user_id)
        return jsonify({
            'user': user.to_dict()
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# 4.1. Rota para ler usuário (por CPF)
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

# 5. Rota para associar/atualizar UUID de cartão NFC
@app.route('/api/users/nfc', methods=['POST'])
def associate_nfc_card():
    try:
        data = request.get_json()
        
        # Validação de campos obrigatórios
        if not data:
            return jsonify({'error': 'Dados JSON são obrigatórios'}), 400
        
        if not data.get('cpf'):
            return jsonify({'error': 'CPF é obrigatório'}), 400
        
        if not data.get('nfc_card_uuid'):
            return jsonify({'error': 'nfc_card_uuid é obrigatório'}), 400
        
        # Limpar e validar CPF
        cpf_clean = re.sub(r'[^0-9]', '', data['cpf'])
        if not validate_cpf(cpf_clean):
            return jsonify({'error': 'CPF inválido. Deve conter 11 dígitos numéricos'}), 400
        
        # Buscar usuário por CPF
        user = User.query.filter_by(cpf=cpf_clean).first()
        if not user:
            return jsonify({'error': 'Usuário não encontrado'}), 404
        
        # Verificar se o UUID já está sendo usado por outro usuário
        nfc_uuid = data['nfc_card_uuid']
        existing_user = User.query.filter_by(nfc_card_uuid=nfc_uuid).first()
        if existing_user and existing_user.id != user.id:
            return jsonify({'error': 'UUID do cartão NFC já está associado a outro usuário'}), 400
        
        # Atualizar o nfc_card_uuid do usuário
        user.nfc_card_uuid = nfc_uuid
        db.session.commit()
        
        return jsonify({
            'message': 'Cartão NFC associado com sucesso',
            'user': user.to_dict(),
            'nfc_card_uuid': user.nfc_card_uuid
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

# 5.1. Rota para buscar usuário por UUID de cartão NFC (consulta)
@app.route('/api/users/nfc/<string:nfc_uuid>', methods=['GET'])
def get_user_by_nfc(nfc_uuid):
    try:
        user = User.query.filter_by(nfc_card_uuid=nfc_uuid).first()
        
        # Gravar log de acesso (sempre, mesmo se usuário não for encontrado)
        if user:
            # Usuário encontrado
            log = Log(
                user_id=user.id,
                nfc_uuid=nfc_uuid,
                user_exists=True
            )
            db.session.add(log)
            db.session.commit()
            
            return jsonify({
                'user': user.to_dict(),
                'nfc_card_uuid': user.nfc_card_uuid
            }), 200
        else:
            # Usuário não encontrado - gravar log indicando usuário inexistente
            log = Log(
                user_id=None,
                nfc_uuid=nfc_uuid,
                user_exists=False
            )
            db.session.add(log)
            db.session.commit()
            
            return jsonify({'error': 'Usuário não encontrado para este UUID de cartão NFC'}), 404
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

# Rota adicional: Listar todos os usuários
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

if __name__ == '__main__':
    app.run(debug=True)