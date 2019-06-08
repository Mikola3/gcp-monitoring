
#!/bin/bash
PASSWORD=$(openssl rand -hex 12)
CREDENTIALS=$(htpasswd -n -b admin $PASSWORD)
echo "$CREDENTIALS" > ./htpasswd