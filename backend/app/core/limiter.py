from slowapi import Limiter
from slowapi.util import get_remote_address

# Identifie les utilisateurs par leur IP
limiter = Limiter(key_func=get_remote_address)