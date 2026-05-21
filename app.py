import os
from flask import Flask, render_template, request, redirect, url_for, jsonify
from flask_mysqldb import MySQL

app = Flask(__name__)

# Configure MySQL from environment variables
app.config['MYSQL_HOST'] = os.environ.get('MYSQL_HOST', 'localhost')
app.config['MYSQL_USER'] = os.environ.get('MYSQL_USER', 'default_user')
app.config['MYSQL_PASSWORD'] = os.environ.get('MYSQL_PASSWORD', 'default_password')
app.config['MYSQL_DB'] = os.environ.get('MYSQL_DB', 'default_db')

# Initialize MySQL
mysql = MySQL(app)

def init_db():
    with app.app_context():
        cur = mysql.connection.cursor()
        cur.execute('''
        CREATE TABLE IF NOT EXISTS messages (
            id INT AUTO_INCREMENT PRIMARY KEY,
            message TEXT
        );
        ''')
        mysql.connection.commit()  
        cur.close()

@app.route('/')
def hello():
    cur = mysql.connection.cursor()
    cur.execute('SELECT id, message FROM messages')
    messages = cur.fetchall()
    cur.close()
    return render_template('index.html', messages=messages)

@app.route('/submit', methods=['POST'])
def submit():
    new_message = request.form.get('new_message')
    cur = mysql.connection.cursor()
    cur.execute('INSERT INTO messages (message) VALUES (%s)', [new_message])
    mysql.connection.commit()
    message_id = cur.lastrowid
    cur.close()
    return jsonify({'id': message_id, 'message': new_message})

@app.route('/update/<int:message_id>', methods=['PUT'])
def update(message_id):
    updated_message = request.json.get('message')
    cur = mysql.connection.cursor()
    cur.execute('UPDATE messages SET message = %s WHERE id = %s', [updated_message, message_id])
    mysql.connection.commit()
    cur.close()
    return jsonify({'id': message_id, 'message': updated_message})

@app.route('/delete/<int:message_id>', methods=['DELETE'])
def delete(message_id):
    cur = mysql.connection.cursor()
    cur.execute('DELETE FROM messages WHERE id = %s', [message_id])
    mysql.connection.commit()
    cur.close()
    return jsonify({'success': True, 'id': message_id})

@app.route('/health')
def health():
    """Health check endpoint"""
    try:
        cur = mysql.connection.cursor()
        cur.execute('SELECT 1')
        cur.close()
        return jsonify({'status': 'healthy', 'database': 'connected'}), 200
    except Exception as e:
        return jsonify({'status': 'unhealthy', 'error': str(e)}), 503

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5001, debug=True)