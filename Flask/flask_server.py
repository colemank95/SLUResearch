import os
from flask import Flask, request, redirect, url_for, flash, send_from_directory
from werkzeug.utils import secure_filename
import requests
import queue


UPLOAD_FOLDER = '/Users/kylecoleman/GitHubProjects/VCC-KDN-EdgeComputing-Project/Docker/FlaskServer/Uploads'
# UPLOAD_FOLDER = '/home/kyle/VCC-KDN-EdgeComputing-Project/Docker/FlaskServer/Uploads'
ALLOWED_EXTENSIONS = set(['txt', 'pdf', 'png', 'jpg', 'jpeg', 'gif'])

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

queueDict = {}


def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


@app.route('/', methods=['GET', 'POST'])
def upload_file():
    if request.method == 'POST':
        # check if the post request has the file part
        if 'file' not in request.files:
            flash('No file part')
            return redirect(request.url)
        file = request.files['file']
        # if user does not select file, browser also
        # submit a empty part without filename
        if file.filename == '':
            flash('No selected file')
            return redirect(request.url)
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            file.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))
            uploader = request.environ['REMOTE_ADDR']
            print('Uploader: ' + uploader)
            # Place image in proper queue. Create queue if there is no existing queue for that IP Adress
            if uploader in queueDict:
                queueDict[uploader].put(file)
                print('Added file to existing IP address queue: ' + uploader)
                print('Number of images in queue ' + uploader +
                      ': ' + str(queueDict[uploader].qsize()))
            else:
                queueDict[str(uploader)] = queue.Queue()
                print('Created a new queue for the IP address: ' + uploader)
                queueDict[str(uploader)].put(file)
                print('Added file to new IP address queue: ' + uploader)

            # return redirect(url_for('uploaded_file',
                # filename=filename))
    return '''
    <!doctype html>
    <title>Upload new File</title>
    <h1>Upload new File</h1>
    <form method=post enctype=multipart/form-data>
      <p><input type=file name=file>
         <input type=submit value=Upload>
    </form>
    '''


@app.route('/uploads/<filename>')
def uploaded_file(filename):

    with open(UPLOAD_FOLDER + '/' + filename, 'rb') as f:
        # send_file = f.read()
        # print(type(f))
        r = requests.post("http://192.168.244.137:5000", files={'file': f})
        print(r.status_code, r.reason)
    # f.close()
    return send_from_directory(app.config['UPLOAD_FOLDER'],
                               filename)
