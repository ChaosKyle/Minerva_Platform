import streamlit as st
from transformers import AutoTokenizer, AutoModelForCausalLM
import torch
from datetime import datetime, timedelta

# Load the model and tokenizer
@st.cache_resource
def load_model():
    model_name = "bigscience/bloomz-1b7"  # You can change this to a different model if preferred
    tokenizer = AutoTokenizer.from_pretrained(model_name)
    model = AutoModelForCausalLM.from_pretrained(model_name)
    return tokenizer, model

tokenizer, model = load_model()

def get_ai_travel_suggestions(prompt):
    inputs = tokenizer(prompt, return_tensors="pt")
    with torch.no_grad():
        outputs = model.generate(**inputs, max_length=1000, num_return_sequences=1)
    return tokenizer.decode(outputs[0], skip_special_tokens=True)

st.title("AI Travel Planner")

destination = st.text_input("Where do you want to go?")
start_date = st.date_input("Start date of your trip")
end_date = st.date_input("End date of your trip")
interests = st.multiselect("What are your interests?", ["History", "Food", "Nature", "Art", "Adventure", "Relaxation"])

if st.button("Generate Travel Plan"):
    if destination and start_date and end_date and interests:
        duration = (end_date - start_date).days
        interests_str = ", ".join(interests)
        
        prompt = f"""Create a {duration}-day travel itinerary for {destination}. The trip starts on {start_date} and ends on {end_date}. 
        The traveler is interested in {interests_str}. Provide a day-by-day breakdown of activities, including suggested places to visit, eat, and stay.
        Travel Itinerary:
        """
        
        with st.spinner("Generating your travel plan..."):
            travel_plan = get_ai_travel_suggestions(prompt)
        
        st.subheader("Your AI-generated Travel Plan:")
        st.write(travel_plan)
    else:
        st.error("Please fill in all the required information.")

st.sidebar.header("About")
st.sidebar.info("This AI Travel Planner uses a local language model to generate personalized travel itineraries based on your preferences.")