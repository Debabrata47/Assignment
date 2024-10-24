#!/bin/bash

sudo -i
cd /home/ubuntu/
mkdir flask-app
cd flask-app

# Update and install required packages
sudo apt update
sudo apt install -y python3 python3-pip python3-venv git curl unzip

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install




# Create a directory for the application and set up a virtual environment
python3 -m venv venv
source venv/bin/activate

# Install Flask, Boto3, and Flask-Talisman inside the virtual environment
pip install flask boto3 flask-talisman

# Create the Flask app file
cat << 'EOF' > /home/ubuntu/flask-app/app.py
from flask import Flask, jsonify
import boto3
from botocore.exceptions import NoCredentialsError, PartialCredentialsError, ClientError
from flask_talisman import Talisman

app = Flask(__name__)
s3 = boto3.client('s3')
BUCKET_NAME = 'assignment135'

def list_s3_content(prefix=""):
    """Helper function to list directories and files in an S3 bucket or path."""
    try:
        if prefix:
            prefix = prefix.rstrip('/') + '/'  # Ensure the prefix ends with a '/'
            
            # Check if the path exists (only when prefix is not empty)
            try:
                s3.head_object(Bucket=BUCKET_NAME, Key=prefix)
            except ClientError as e:
                if e.response['Error']['Code'] == '404':
                    return {"error": "Path does not exist"}, 404

        # List objects in the bucket with the given prefix
        response = s3.list_objects_v2(Bucket=BUCKET_NAME, Prefix=prefix, Delimiter='/')

        directories = []
        files = []

        # Collect directories (common prefixes)
        if 'CommonPrefixes' in response:
            directories = [prefix['Prefix'].rstrip('/').split('/')[-1] for prefix in response['CommonPrefixes']]

        # Collect files
        if 'Contents' in response:
            # Exclude the directory itself (if it's included as a key in the response)
            files = [content['Key'].split('/')[-1] for content in response['Contents'] if content['Key'] != prefix]

        # Combine directories and files
        content = directories + files

        # If no directories or files are found, return empty content
        if not content:
            return {"content": []}

        return {"content": content}
    except (NoCredentialsError, PartialCredentialsError):
        return {"error": "AWS credentials not found"}, 500
    except Exception as e:
        return {"error": str(e)}, 500

@app.route('/list-bucket-content', defaults={'path': ''}, methods=['GET'])
@app.route('/list-bucket-content/<path:path>', methods=['GET'])
def list_bucket_content(path):
    """Endpoint to list directories (folders) in the S3 bucket."""
    content = list_s3_content(path)
    if isinstance(content, tuple):
        return jsonify(content[0]), content[1]  # Return error if any
    return jsonify({"content": content})

# Enforce HTTPS using Flask-Talisman
Talisman(app, content_security_policy=None)

if __name__ == '__main__':
    context = ('/home/ubuntu/flask-app/cert.pem', '/home/ubuntu/flask-app/key.pem')
    app.run(host='0.0.0.0', port=5000, ssl_context=context)
EOF

# Generate self-signed SSL certificate
openssl req -x509 -newkey rsa:4096 -keyout /home/ubuntu/flask-app/key.pem -out /home/ubuntu/flask-app/cert.pem -days 365 -nodes -subj "/CN=localhost"

# Run the Flask app in the background
nohup python3 /home/ubuntu/flask-app/app.py &
