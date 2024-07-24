import streamlit as st
import openai
from datetime import datetime, timedelta

# Set your OpenAI API key
openai.api_key = st.secrets["OPENAI_API_KEY"]

st.title("AI Travel Planner")

destination = st.text_input("Where do you want to go?")
start_date = st.date_input("Start date of your trip")
end_date = st.date_input("End date of your trip")
interests = st.multiselect("What are your interests?", ["History", "Food", "Nature", "Art", "Adventure", "Relaxation"])

def generate_travel_plan(prompt):
    try:
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "You are a helpful travel assistant."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=500
        )
        return response.choices[0].message.content
    except Exception as e:
        st.error(f"Error generating travel plan: {str(e)}")
        return None

if st.button("Generate Travel Plan"):
    if destination and start_date and end_date and interests:
        duration = (end_date - start_date).days + 1
        interests_str = ", ".join(interests)
        
        prompt = f"Create a {duration}-day travel itinerary for {destination}. The trip starts on {start_date} and ends on {end_date}. The traveler is interested in {interests_str}. Provide a day-by-day breakdown of activities, including suggested places to visit, eat, and stay."
        
        with st.spinner("Generating your travel plan..."):
            travel_plan = generate_travel_plan(prompt)
        
        if travel_plan:
            st.subheader("Your AI-generated Travel Plan:")
            st.write(travel_plan)
    else:
        st.error("Please fill in all the required information.")

st.sidebar.header("About")
st.sidebar.info("This AI Travel Planner uses OpenAI's GPT-3.5 model to generate personalized travel itineraries based on your preferences.")