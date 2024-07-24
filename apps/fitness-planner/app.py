import streamlit as st
import openai
from datetime import datetime, timedelta

# Set your OpenAI API key
openai.api_key = st.secrets["OPENAI_API_KEY"]

st.title("AI Fitness Planner")

# User inputs
age = st.number_input("Your age", min_value=1, max_value=120, value=30)
weight = st.number_input("Your weight (in kg)", min_value=1.0, max_value=300.0, value=70.0)
height = st.number_input("Your height (in cm)", min_value=1, max_value=300, value=170)
fitness_level = st.select_slider("Your fitness level", options=["Beginner", "Intermediate", "Advanced"])
goal = st.selectbox("Your fitness goal", ["Lose weight", "Build muscle", "Improve cardiovascular health", "Increase flexibility"])
days_per_week = st.slider("How many days per week can you workout?", min_value=1, max_value=7, value=3)
equipment = st.multiselect("Available equipment", ["None", "Dumbbells", "Resistance bands", "Treadmill", "Stationary bike", "Yoga mat"])

def generate_fitness_plan(prompt):
    try:
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "You are a professional fitness trainer creating personalized workout plans."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=1000
        )
        return response.choices[0].message.content
    except Exception as e:
        st.error(f"Error generating fitness plan: {str(e)}")
        return None

if st.button("Generate Fitness Plan"):
    if age and weight and height and fitness_level and goal and days_per_week:
        equipment_str = ", ".join(equipment) if equipment else "No equipment"
        
        prompt = f"""Create a {days_per_week}-day weekly fitness plan for a {age}-year-old individual weighing {weight} kg and {height} cm tall. 
        Their fitness level is {fitness_level}, and their goal is to {goal}. 
        They have access to the following equipment: {equipment_str}.
        Provide a day-by-day breakdown of exercises, including sets, reps, and duration for each exercise. 
        Also, include warm-up and cool-down routines, and any dietary suggestions that align with their fitness goal."""
        
        with st.spinner("Generating your fitness plan..."):
            fitness_plan = generate_fitness_plan(prompt)
        
        if fitness_plan:
            st.subheader("Your AI-generated Fitness Plan:")
            st.write(fitness_plan)
    else:
        st.error("Please fill in all the required information.")

st.sidebar.header("About")
st.sidebar.info("This AI Fitness Planner uses OpenAI's GPT-3.5 model to generate personalized workout plans based on your input and goals.")