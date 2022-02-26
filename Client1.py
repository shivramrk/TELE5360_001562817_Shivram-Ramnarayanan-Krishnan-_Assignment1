import os
import sys
import pickle
from Crypto.PublicKey import RSA
from socket import *
from Crypto.Cipher import PKCS1_OAEP
from os import path
from Crypto.Hash import SHA256

if path.exists('pubpem.pem') and path.exists('privpem.pem'):
    print('Public key and Private key found in existence')
else:
    print('Public key and Private key not found in existence | New Keys Generating')
    privky = RSA.generate(1024)
    pubky = privky.publickey()

    privpem = privky.exportKey()
    pubpem = pubky.exportKey()
    print(privpem.decode())
    print(pubpem.decode())

with open('privpem.pem', 'wb') as private:
    private.write(privpem)
with open('pubpem.pem', 'wb') as public:
    public.write(pubpem)

with open('privpem.pem', 'rb') as private:
    privpem = private.read()
with open('pubpem.pem', 'rb') as public:
    pubpem = public.read()

privky = RSA.importKey(privpem)
pubky = RSA.importKey(pubpem)

client1 = socket(AF_INET, SOCK_STREAM)
client1.connect(('192.168.137.129', 49050))
e1 = 'Connected Successfully Established!'
client1.send(e1.encode())
servky = client1.recv(1024)

print('Server Key:', servky)

with open('servepem.pem', 'wb') as server:
    server.write(servky)

server_ky1 = RSA.importKey(servky)
client1.send(pubpem)

while True:
    print("Bob:")
    Dsend = sys.stdin.readline().strip()
    data1 = Dsend.encode()
    if Dsend == 'exit':
        Dsend = Dsend.encode()
        cipher = PKCS1_OAEP.new(server_ky1)
        dsend10 = cipher.encrypt(Dsend)
        dsend20 = pickle.dumps(Dsend)
        client1.send(Dsend)
        break

    bob1 = SHA256.new(data1)
    hexbob = bob1.hexdigest()
    hexboben = hexbob.encode()
    client1.send(hexboben)

    Dsend = Dsend.encode()
    cpr = PKCS1_OAEP.new(server_ky1)
    Dsend = cpr.encrypt(Dsend)
    Dsend = pickle.dumps(Dsend)
    client1.send(Dsend)

    hncd1 = client1.recv(1024)

    datrcv = client1.recv(1024)
    datrcv = pickle.loads(datrcv)
    cpr = PKCS1_OAEP.new(privky)
    datrcv = cpr.decrypt(datrcv)
    datrcv = datrcv.decode()
    data1 = datrcv.encode()

    z = SHA256.new(data1)
    hsh1d = z.hexdigest()
    hncd2 = hsh1d.encode()

    if hncd1 == hncd2:
        print("Signature Verification Valid")
    else:
        print("Signature verification invalid")
    print("Alice:", datrcv)
    if datrcv == 'exit':
        break

client1.close()

os.remove("servepem.pem")
