#!/usr/bin/python3

from flask import Flask, request, redirect, url_for, render_template
from markupsafe import escape


app = Flask(__name__)
entries = []


@app.route('/')
def main_page():
    return render_template('main.html', messages=entries)


@app.route('/add', methods=['get', 'post'])
def add_entry():
    content = request.values.get('content')
    entries.insert(0, escape(content[0:1024]))
    del entries[13:]
    return redirect(url_for('main_page'))


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080)
