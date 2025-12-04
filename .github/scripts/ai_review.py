
import os
import openai

openai.api_key = os.getenv("OPENAI_API_KEY")

diff_file = ".github/scripts/diff.txt"
with open(diff_file, "r") as f:
    diff_content = f.read()

prompt = f"""
Du er en erfaren kodeanmelder. Gi en kort, konstruktiv review av følgende endringer:
{diff_content}
"""

response = openai.ChatCompletion.create(
    model="gpt-4",
    messages=[{"role": "system", "content": "Du er en ekspert på kodekvalitet."},
              {"role": "user", "content": prompt}],
    temperature=0.2
)

print(response.choices[0].message["content"])
