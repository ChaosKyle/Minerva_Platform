from flask import Flask, render_template, request, redirect, url_for
from datetime import datetime

app = Flask(__name__)

meals = []

@app.route('/')
def index():
    return render_template('index.html', meals=meals)

@app.route('/add', methods=['POST'])
def add_meal():
    meal_name = request.form.get('meal_name')
    meal_type = request.form.get('meal_type')
    calories = request.form.get('calories')
    if meal_name and meal_type:
        meals.append({
            'name': meal_name,
            'type': meal_type,
            'calories': calories,
            'date': datetime.now()
        })
    return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8082)