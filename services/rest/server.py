#!/usr/bin/env python
# encoding: utf-8
import json
import ssl
import json
import base64
import io
from flask import Flask, request, jsonify

credential_path = "/etc/credentials"

def main():
    app = Flask(__name__)

    def load_data():
        with open('./data.json', 'r') as f:
            return json.load(f)
    def load_image(name):
        with open('./assets/{0}'.format(name), 'rb') as f:
            out = io.BytesIO()
            base64.encode(f, out)
            return out.getvalue().decode('utf-8')


    @app.route('/', methods=['GET'])
    def query_records():
        data = load_data()
        for record in data['records']:
            record["image"] = load_image(record["image"])
        return jsonify(data)

    #setup SSL configuration
    context = ssl.SSLContext(ssl.PROTOCOL_TLS)
    context.load_verify_locations(cafile="{path}/clients.pem".format(path = credential_path),capath=None,cadata=None)
    context.load_cert_chain('{path}/server.cer'.format(path = credential_path), '{path}/server.key'.format(path = credential_path))

    ##require client certicates
    context.verify_mode = ssl.CERT_REQUIRED

    app.run(ssl_context=context,host="0.0.0.0",  port=8443, threaded=True)


if __name__ == "__main__":
    main()
