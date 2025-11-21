1. Recommended Top-Level Structure

```bash
project-root/
│
├── scada-ui/                # Front-end dashboard (HTML/JS/CSS)
│   ├── index.html
│   ├── css/
│   ├── js/
│   ├── img/
│   └── ...
│
├── cstp_julia_service/      # Julia plant model + control loops + low-level API
│   ├── Project.toml
│   ├── VirtualCSTPService.jl
│   ├── src/
│   │   ├── plant_model.jl
│   │   ├── controllers.jl
│   │   ├── endpoints.jl
│   │   └── utils/
│   └── test/
│
├── cstp_backend/            # Python FastAPI backend (REST API + DB + auth)
│   ├── app/
│   │   ├── main.py
│   │   ├── routes/
│   │   ├── services/
│   │   ├── models/
│   │   ├── schemas/
│   │   ├── db/
│   │   ├── core/
│   │   └── config.py
│   ├── requirements.txt
│   └── tests/
│
└── README.md
```