from flask import Flask, render_template, request, redirect, url_for
from datetime import datetime

app = Flask(__name__)

chores = []

@app.route('/')
def index():
    return render_template('index.html', chores=chores, enumerate=enumerate)

@app.route('/add', methods=['POST'])
def add_chore():
    chore = request.form.get('chore')
    if chore:
        chores.append({'task': chore, 'completed': False, 'date_added': datetime.now()})
    return redirect(url_for('index'))

@app.route('/complete/<int:chore_id>')
def complete_chore(chore_id):
    if 0 <= chore_id < len(chores):
        chores[chore_id]['completed'] = True
    return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8081)