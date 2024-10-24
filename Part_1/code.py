from flask import Flask, jsonify
import boto3
from botocore.exceptions import NoCredentialsError, PartialCredentialsError, ClientError
from flask_talisman import Talisman

app = Flask(__name__)

s3 = boto3.client('s3')

#S3 bucket name
BUCKET_NAME = 'assignment132'

def list_s3_content(prefix=""):
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
        return jsonify(content[0]), content[1]  
    return jsonify(content)  

# Enforce HTTPS using Flask-Talisman
Talisman(app, content_security_policy=None)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, ssl_context=('cert.pem', 'key.pem'))
