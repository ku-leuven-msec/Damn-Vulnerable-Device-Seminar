#!/usr/bin/env python
# encoding: utf-8
import json
import ssl
from flask import Flask, request, jsonify

credential_path = "/etc/credentials"

app = Flask(__name__)

@app.route('/', methods=['GET'])
def query_records():
    name = request.args.get('name')
    print(name)
    with open('/tmp/data.txt', 'r') as f:
        data = f.read()
        records = json.loads(data)
        for record in records:
            if record['name'] == name:
                return jsonify(record)
        return jsonify({'error': 'data not found'})

@app.route('/', methods=['PUT'])
def create_record():
    record = json.loads(request.data)
    with open('/tmp/data.txt', 'r') as f:
        data = f.read()
    if not data:
        records = [record]
    else:
        records = json.loads(data)
        records.append(record)
    with open('/tmp/data.txt', 'w') as f:
        f.write(json.dumps(records, indent=2))
    return jsonify(record)

@app.route('/', methods=['POST'])
def update_record():
    record = json.loads(request.data)
    new_records = []
    with open('/tmp/data.txt', 'r') as f:
        data = f.read()
        records = json.loads(data)
    for r in records:
        if r['name'] == record['name']:
            r['email'] = record['email']
        new_records.append(r)
    with open('/tmp/data.txt', 'w') as f:
        f.write(json.dumps(new_records, indent=2))
    return jsonify(record)
    
@app.route('/', methods=['DELETE'])
def delete_record():
    record = json.loads(request.data)
    new_records = []
    with open('/tmp/data.txt', 'r') as f:
        data = f.read()
        records = json.loads(data)
        for r in records:
            if r['name'] == record['name']:
                continue
            new_records.append(r)
    with open('/tmp/data.txt', 'w') as f:
        f.write(json.dumps(new_records, indent=2))
    return jsonify(record)



#setup SSL configuration
context = ssl.SSLContext(ssl.PROTOCOL_TLS)
context.load_verify_locations(cafile="{path}/root.cer".format(path = credential_path),capath=None,cadata=None)
context.load_cert_chain('{path}/server.cer'.format(path = credential_path), '{path}/server.key'.format(path = credential_path))
app.run(ssl_context=context,host="0.0.0.0",  port=443, threaded=True)

#require client certicates
context.verify_mode = ssl.CERT_REQUIRED

app.run(ssl_context=context,host="0.0.0.0",  port=443)
