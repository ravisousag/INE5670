from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from .user import db


class PairingSession(db.Model):
    __tablename__ = 'pairing_sessions'

    id = Column(Integer, primary_key=True)
    pair_token = Column(String(64), unique=True, nullable=False)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime, nullable=False)
    vinculado = Column(Boolean, default=False)

    user = relationship('User')

    def to_dict(self):
        return {
            'id': self.id,
            'pair_token': self.pair_token,
            'user_id': self.user_id,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'expires_at': self.expires_at.isoformat() if self.expires_at else None,
            'vinculado': bool(self.vinculado),
        }
