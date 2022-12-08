import json
import os, os.path
import signal
import sqlite3 as sql
import sys
from distutils.command.build import build

import requests
from eth_defi.revert_reason import fetch_transaction_revert_reason
from flask import Flask, render_template, request, session
from flask_session import Session
from web3 import HTTPProvider, Web3

#Signal handler to delete the database file if it exists
def signal_handler(sig, frame):
    print("Cleaning up before exit")
    if os.path.exists("./data/database.db"):
        #This code uploads the file database.db located in the data folder to the IPFS network
        files = {
            'file':(open('./data/database.db', 'rb'))
        }
        #The IPFS authentication keys are removed
        response = requests.post('https://ipfs.infura.io:5001/api/v0/add', files=files, auth=('XXXXXXXXXXXXXXXX','XXXXXXXXXXXXXXXXXX'))

        #This code stores the hash of the previously stored database so it can be retrieved in the future
        temp = response.text
        templist = list(temp.split(","))
        ipfsHash = (list(templist[1].split('"'))[3])

        hashFile = open('./data/ipfsHash.dat', 'w')
        hashFile.write(ipfsHash)
        hashFile.close()
        os.remove("./data/database.db")

    sys.exit(0)

signal.signal(signal.SIGINT, signal_handler)
print("Signal interupt enabled")

#Save the path to the contracts json file
contractPath = './build/contracts/thesis.json'

#Save the contract's address from file
try:
    f = open('./data/address.dat', 'r')
    contractAddress = Web3.toChecksumAddress(f.read())
    f.close()
    print("The smart contract's address is:", contractAddress)
except:
    sys.exit("The smart contract has not been deployed.")

#Extract the contract's abi
contractFile = json.load(open(contractPath))
abi = contractFile['abi']

#Establish connection to the smart contract on the blockchain
try:
    f = open('./data/testnet.dat')
    testnet = f.read()
    f.close()
    w3 = Web3(HTTPProvider(testnet))
    w3.isConnected()
    print("Connection established")
except:
    sys.exit("Could not connect to the blockchain")

#Create the contract's instance
contract = w3.eth.contract(address = contractAddress, abi = abi)

#Read the private key of the signer
f = open('./data/key.dat', 'r')
key = f.read()
f.close()
signerAddress = w3.eth.account.privateKeyToAccount(key).address
    
app = Flask(__name__)
app.config["SESSION_TYPE"] = "filesystem"
app.secret_key = 'sdjninviusd2dnaasgsgsgasffssfssdbdnnv;onv'
Session(app)

@app.route('/')
def intro():
    session.clear()
    return render_template('index.html')

@app.route('/getAddress', methods=['GET', 'POST'])
def getAddress():

    #Get's the public MetaMask address of the user after their login.
    data=request.get_json()
    address = (data.split(":"))[1].replace('"','').replace('}','')
    
    session['loginAddress'] = address
    session.modified = True
    
    return ('', 204)

@app.route('/register')
def register():
    return render_template('register.html')

@app.route('/registerData', methods=['GET', 'POST'])
def registerData():

    msgFl = 0

    ram = request.args.get('RAM')
    cpu = request.args.get('CPU')
    cores = request.args.get('Cores')
    storage = request.args.get('Storage')
    mac = request.args.get('MAC')

    senderAddress = session.get("loginAddress")
    
    #Downloads the latest database file from the IPFS network and unpins it 
    params = {
        ('arg', open('./data/ipfsHash.dat', 'rb')),
    }
    #The IPFS authentication keys are removed
    response2 = requests.post('https://ipfs.infura.io:5001/api/v0/cat', params=params, auth=('XXXXXXXXXXXXXXXXXX','XXXXXXXXXXXXXXXXX'))
    with open('./data/database.db', 'wb') as f:
        f.write(response2.content)
    response3 = requests.post('https://ipfs.infura.io:5001/api/v0/pin/rm', params=params, auth=('XXXXXXXXXXXXXXXXX','XXXXXXXXXXXXXXXXX'))

    try:
        con = sql.connect("./data/database.db")
        cur = con.cursor()
        cur.execute("SELECT mac FROM devices WHERE mac=?", (mac,))
        result = cur.fetchone()
        if result:
            msg = "Device already registered"
            msgFl = 1
        else:
            #Inserts into the database the new device registry
            cur.execute("INSERT INTO devices (ram, cpu, cores, storage, mac, counter) VALUES (?,?,?,?,?,0)", (ram, cpu, cores, storage, mac))
            con.commit()
            #Gets the device ID from the database
            cur.execute("SELECT rowid FROM devices WHERE mac=?", (mac,))
            result= cur.fetchone()
            deviceId = result[0]

            #Issues a transaction that connects the newly registered device to the user's address
            buildTransaction = contract.functions.registerDevice(Web3.toChecksumAddress(senderAddress), deviceId).buildTransaction({
                'from':signerAddress,
                'nonce':w3.eth.getTransactionCount(signerAddress),
                'gas':3000000,
                'gasPrice':w3.eth.gas_price
            })
            signTransaction = w3.eth.account.signTransaction(buildTransaction, key)
            transactionHash = w3.eth.sendRawTransaction(signTransaction.rawTransaction)
            transactionReceipt = w3.eth.waitForTransactionReceipt(transactionHash, timeout = 300)

            if transactionReceipt["status"] :
                msg = "Registration completed successfully"
            else:
                reason = fetch_transaction_revert_reason(w3, transactionHash)
                msg = ("Transaction not completed. Reason:" + reason)
                msgFl = 1
        
    except:
        con.rollback()
        if msgFl == 0:
            msg = "Something went wrong, please try again"

    finally:
        con.close()
        
        if msg == "Device already registered":
            return render_template('register.html', msg = msg)

        #This code uploads the file database.db located in the data folder to the IPFS network
        files = {
            'file':(open('./data/database.db', 'rb'))
        }
        #The IPFS authentication keys are removed
        response = requests.post('https://ipfs.infura.io:5001/api/v0/add', files=files, auth=('XXXXXXXXXXXX','XXXXXXXXXXXX'))

        #This code stores the hash of the previously stored database so it can be retrieved in the future
        temp = response.text
        templist = list(temp.split(","))
        ipfsHash = (list(templist[1].split('"'))[3])

        hashFile = open('./data/ipfsHash.dat', 'w')
        hashFile.write(ipfsHash)
        hashFile.close()
        os.remove("./data/database.db")
        
        return render_template('result.html', msg = msg)


@app.route('/execute')
def execute():
    return render_template('execute.html')

@app.route('/executeData', methods=['GET', 'POST'])
def executeData():
    msgFl = 0
    try:     
        ram = int(request.form['RAM'])
        cpu = int(request.form['CPU'])
        cores = int(request.form['Cores'])
        storage = int(request.form['Storage'])
        
        senderAddress = session.get("loginAddress")

        tempamount = (ram * 0.001 + cpu * 0.001 + cores + storage * 0.001) 
        amount = int(tempamount * 1000000000000000000)

        #This code downloads the latest database file from the IPFS network and unpins it 
        params = {
            ('arg', open('./data/ipfsHash.dat', 'rb')),
        }
        #The IPFS authentication keys are removed
        response2 = requests.post('https://ipfs.infura.io:5001/api/v0/cat', params=params, auth=('XXXXXXXXXXXX','XXXXXXXXXXXX'))
        with open('./data/database.db', 'wb') as f:
            f.write(response2.content)
        response3 = requests.post('https://ipfs.infura.io:5001/api/v0/pin/rm', params=params, auth=('XXXXXXXXXXXX','XXXXXXXXXXXX'))

        #Connects to the locally stored database and searches for entries that match the user requirements
        con = sql.connect("./data/database.db")
        cur = con.cursor()
        cur.execute("SELECT rowid FROM (SELECT counter, rowid FROM devices WHERE ram>=? AND cpu>=? AND cores>=? AND storage>=?) WHERE counter = (SELECT MIN(counter) FROM (SELECT * FROM devices WHERE ram>=? AND cpu>=? AND cores>=? AND storage>=?))", (ram, cpu, cores, storage, ram, cpu, cores, storage))
        result = cur.fetchone()
        deviceId = result[0]

        cur.execute("SELECT MAX(counter) FROM devices")
        tempCounter = cur.fetchone()
        counter = tempCounter[0]

        #If any registered device matches the requirements a transaction is issued
        if result:
            buildTransaction = contract.functions.transferFromDeviceID(deviceId, Web3.toChecksumAddress(senderAddress), amount).buildTransaction({
                'from':signerAddress,
                'nonce':w3.eth.getTransactionCount(signerAddress),
                'gas':3000000,
                'gasPrice':w3.eth.gas_price
            })
            signTransaction = w3.eth.account.signTransaction(buildTransaction, key)
            transactionHash = w3.eth.sendRawTransaction(signTransaction.rawTransaction)
            transactionReceipt = w3.eth.waitForTransactionReceipt(transactionHash, timeout = 300)

            if transactionReceipt["status"] :
                event = contract.events.Transfer().processReceipt(transactionReceipt)
                msg = "Transaction completed. Transaction is on block:", event[0]['blockNumber']
                cur.execute("UPDATE devices SET counter = ? WHERE rowid = ?", (counter+1, deviceId))
                con.commit()
            else:
                reason = fetch_transaction_revert_reason(w3, transactionHash)
                msg = ("Transaction not completed. Reason:" + reason)
                msgFl = 1
                
        else:
            msg = "Unfortunately no registered device meet the requirements."
            msgFl = 1

    except:
        con.rollback()
        if msgFl == 0:
            msg = "Something went wrong, please try again"

    finally:
        con.close()
        
        #This code uploads the file database.db located in the data folder to the IPFS network
        files = {
            'file':(open('./data/database.db', 'rb'))
        }
        #The IPFS authentication keys are removed
        response = requests.post('https://ipfs.infura.io:5001/api/v0/add', files=files, auth=('XXXXXXXXXXXXXXXX','XXXXXXXXXXXXXXXX'))

        #This code stores the hash of the previously stored database so it can be retrieved in the future
        temp = response.text
        templist = list(temp.split(","))
        ipfsHash = (list(templist[1].split('"'))[3])

        hashFile = open('./data/ipfsHash.dat', 'w')
        hashFile.write(ipfsHash)
        hashFile.close()
        os.remove("./data/database.db")
        
        return render_template('result.html', msg = msg)
        


if __name__ == '__main__':
    app.run(debug = False)
