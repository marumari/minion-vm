#!/usr/bin/env python

import os
import uuid

FILE = "apikey"

# Delete the old apikey, so we can reset the permissions
os.unlink(FILE)

# Generate API key
key = str(uuid.uuid4())

# Set the umask to 0, so we can write the file as 400
mode = 0o400
user_umask = os.umask(0)
try:
    # Delete the existing API key file
    with os.fdopen( os.open(FILE, os.O_WRONLY | os.O_CREAT, mode), 'w') as apikeyf:
        apikeyf.write(key)
finally:
    os.umask(user_umask)
