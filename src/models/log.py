from models.user import db
from datetime import datetime

class Log(db.Model):
    __tablename__ = 'logs'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)
    nfc_uuid = db.Column(db.String(36), nullable=False)
    user_exists = db.Column(db.Boolean, default=True, nullable=False)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    
    # Relacionamento com User
    user = db.relationship('User', backref='logs')
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'nfc_uuid': self.nfc_uuid,
            'user_exists': self.user_exists,
            'timestamp': self.timestamp.isoformat() if self.timestamp else None
        }

