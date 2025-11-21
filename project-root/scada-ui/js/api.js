const API_BASE = "http://localhost:8001";

async function apiHealth() {
  try {
    const res = await fetch(API_BASE + "/health");
    return { ok: res.ok };
  } catch (err) {
    return { ok: false };
  }
}

async function apiGetPlantOverview() {
  return {
    flow_in: 30.2,
    flow_out: 29.8,
    energy_kw: 4.3,
    modules: [
      { id: 1, name: "Module 1", type: "Biological", status: "OK", flow: 5.1 },
      { id: 2, name: "Module 2", type: "Biological", status: "WARN", flow: 5.0 },
      { id: 3, name: "Module 3", type: "Biological", status: "OK", flow: 5.1 },
      { id: 4, name: "Module 4", type: "Biological", status: "OK", flow: 5.2 },
      { id: 5, name: "Module 5", type: "Polishing", status: "OK", flow: 4.8 },
      { id: 6, name: "Module 6", type: "Sludge", status: "OK", flow: 0.0 }
    ]
  };
}

async function apiGetModules() {
  const ov = await apiGetPlantOverview();
  return ov.modules;
}

async function apiGetModuleDetail(id) {
  return {
    id,
    name: `Module ${id}`,
    type: id <= 4 ? "Biological" : id === 5 ? "Polishing" : "Sludge",
    units: [
      { id: "u1", name: "Unit 1", type: "Reactor", status: "OK" },
      { id: "u2", name: "Unit 2", type: "Reactor", status: "OK" }
    ]
  };
}

async function apiGetUnitDetail(moduleId, unitId) {
  return {
    moduleId,
    unitId,
    name: `Unit ${unitId}`,
    tags: [
      { tag: "DO", desc: "Dissolved Oxygen", value: 2.1, unit: "mg/L" },
      { tag: "pH", desc: "pH", value: 7.0, unit: "-" }
    ],
    alarms: []
  };
}

async function apiGetAlarms() {
  return [
    { ts: "2025-11-20T10:05:00Z", module: 2, unit: "u1", severity: "HIGH", message: "Low DO" }
  ];
}
