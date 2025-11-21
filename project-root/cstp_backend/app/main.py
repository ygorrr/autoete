# app/main.py

from fastapi import FastAPI

from app.routes import router as cstp_router

app = FastAPI(
    title="CSTP Monitoring and Control Backend",
    version="0.1.0",
)

# include routes
app.include_router(cstp_router)


@app.get("/health", tags=["system"])
async def health_check():
    return {"status": "ok"}
