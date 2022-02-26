import sys
import pickle
import os
from os import path
from Crypto.Cipher import PKCS1_OAEP
from socket import *
from Crypto.Hash import SHA256
from Crypto.PublicKey import RSA

if path.exists('pubpem.pem') and path.exists('privpem.pem'):
    print('Public key and Private key found in existence')
else:
    print('Public key and Private key not found in existence | New Keys Generating')
    privky = RSA.generate(1024)
    pubky = privky.publickey()
    privpem = privky.exportKey()
    pubpem = pubky.exportKey()
    with open('privpem.pem', "wb") as priv:
        priv.write(privpem)
    with open('pubpem.pem', "wb") as pub:
        pub.write(pubpem)

with open('privpem.pem', 'rb') as priv:
    privpem = priv.read()
with open('pubpem.pem', 'rb') as pub:
    pubpem = pub.read()

privky = RSA.importKey(privpem)
pubky = RSA.importKey(pubpem)

serv = socket(AF_INET, SOCK_STREAM)
serv.setsockopt(SOL_SOCKET, SO_REUSEADDR, 1)
serv.bind(('', 49050))
serv.listen(5)
print("Socket Listening")
while True:
    (Port_Number, IP_adr) = serv.accept()
    x = Port_Number.recv(1024).decode()
    print(x)
    print('Connected with:', x)
    Port_Number.send(pubpem)
    print(pubpem.decode())
    clkey = Port_Number.recv(1024)
    with open('clienpem.pem', 'wb') as client:
        client.write(clkey)
    cl_key1 = RSA.importKey(clkey)
    while True:

        alice1 = Port_Number.recv(1024)
        datrcv = Port_Number.recv(1024)
        datrcv = pickle.loads(datrcv)
        cpr = PKCS1_OAEP.new(privky)
        datrcv2 = cpr.decrypt(datrcv)
        datrcv = datrcv2.decode()

        d2 = datrcv.encode()
        h1bob = SHA256.new(d2)
        hexbob = h1bob.hexdigest()
        hexenbob = hexbob.encode()

        if alice1 == hexenbob:
            print("Signature Verification Valid")
        else:
            print("Signature Invalid")

        print('Bob:', datrcv)
        if datrcv == 'exit':
            break
        print('Alice:')

        datsend = sys.stdin.readline().strip()
        data1 = datsend.encode()
        if datsend == 'exit':
            datsend = datsend.encode()
            cpr = PKCS1_OAEP.new(cl_key1)
            datsend = cpr.encrypt(datsend)
            datsend = pickle.dumps(datsend)
            Port_Number.send(datsend)
            break

        t = SHA256.new(data1)
        hexalice = t.hexdigest()
        hexenalice = hexalice.encode()
        Port_Number.send(hexenalice)

        datsend = datsend.encode()
        cpr = PKCS1_OAEP.new(cl_key1)
        datsend = cpr.encrypt(datsend)
        datsend = pickle.dumps(datsend)
        Port_Number.send(datsend)

    break

Port_Number.close()
os.remove("clienpem.pem")
