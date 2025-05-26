FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY . .

# Expose port
EXPOSE 8000

# Create a main.py file to serve the ML service
RUN echo "from fastapi import FastAPI\nimport uvicorn\nfrom route_optimizer import *\n\napp = FastAPI(title='Freight Flow ML Service')\n\n@app.get('/health')\ndef health_check():\n    return {'status': 'healthy'}\n\nif __name__ == '__main__':\n    uvicorn.run(app, host='0.0.0.0', port=8000)" > main.py

# Start the service
CMD ["python", "main.py"] 