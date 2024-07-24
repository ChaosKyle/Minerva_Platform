import streamlit as st

st.set_page_config(page_title="Minerva Calendar", layout="wide")

st.title("Minerva Calendar")

# Replace this URL with your public Google Calendar URL
calendar_url = "https://calendar.google.com/calendar/embed?src=your_calendar_id%40group.calendar.google.com"

# Embed the Google Calendar
st.components.v1.iframe(calendar_url, height=600, scrolling=True)

st.sidebar.header("About")
st.sidebar.info("This app embeds a Google Calendar for easy access to your schedule.")

# Instructions for users
st.markdown("""
### How to use:
1. View your calendar events directly on this page.
2. Click on any event for more details.
3. Use the controls at the top of the calendar to change views or navigate between dates.

To add or modify events, please use your Google Calendar app or visit [Google Calendar](https://calendar.google.com) directly.
""")