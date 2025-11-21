#!/bin/bash

set -e

ROOT="scada-ui"

echo "Creating SCADA UI folder structure..."
mkdir -p "$ROOT/css"
mkdir -p "$ROOT/js/views"

###############################################
# index.html
###############################################
cat > "$ROOT/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>C-STP SCADA Dashboard</title>
  <link rel="stylesheet" href="css/style.css" />
</head>
<body>

<header class="topbar">
  <div class="topbar-left">
    <span class="logo">C-STP SCADA</span>
    <nav class="topnav">
      <button data-view="overview">Overview</button>
      <button data-view="modules">Modules</button>
      <button data-view="alarms">Alarms</button>
    </nav>
  </div>
  <div class="topbar-right">
    <div id="health-indicator" class="health health-unknown">
      <span class="dot"></span>
      <span id="health-text">Checking...</span>
    </div>
  </div>
</header>

<div class="layout">
  <aside class="sidebar">
    <h3>Modules</h3>
    <ul id="sidebar-modules"></ul>
  </aside>

  <main class="content">
    <section id="view-overview" class="view"></section>
    <section id="view-modules" class="view" style="display:none;"></section>
    <section id="view-module-detail" class="view" style="display:none;"></section>
    <section id="view-unit-detail" class="view" style="display:none;"></section>
    <section id="view-alarms" class="view" style="display:none;"></section>
  </main>
</div>

<script src="js/utils.js"></script>
<script src="js/api.js"></script>
<script src="js/views/overview.js"></script>
script src="js/views/modules.js"></script>
<script src="js/views/moduleDetail.js"></script>
<script src="js/views/unitDetail.js"></script>
<script src="js/views/alarms.js"></script>
<script src="js/app.js"></script>

</body>
</html>
EOF

###############################################
# css/style.css
###############################################
cat > "$ROOT/css/style.css" << 'EOF'
/* Basic styling for SCADA skeleton */

* { box-sizing: border-box; margin: 0; padding: 0; }

body {
  font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  background: #f3f4f6;
  color: #111827;
}

.topbar {
  display: flex;
  justify-content: space-between;
  background: #111827;
  color: white;
  padding: 8px 16px;
}

.topnav button {
  margin-right: 8px;
  padding: 4px 10px;
  border-radius: 4px;
  background: #1f2937;
  color: white;
  border: none;
}

.layout {
  display: grid;
  grid-template-columns: 220px 1fr;
  height: calc(100vh - 42px);
}

.sidebar {
  background: #111827;
  color: #e5e7eb;
  padding: 12px;
}

.content {
  padding: 16px;
  overflow-y: auto;
}

.card {
  background: white;
  padding: 10px;
  border-radius: 8px;
  margin-bottom: 12px;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.12);
}

.card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 12px;
}

.table {
  width: 100%;
  border-collapse: collapse;
}

.table th,
.table td {
  padding: 4px 6px;
  border-bottom: 1px solid #e5e7eb;
}
EOF

###############################################
# js/utils.js
###############################################
cat > "$ROOT/js/utils.js" << 'EOF'
function el(tag, options = {}) {
  const node = document.createElement(tag);
  if (options.className) node.className = options.className;
  if (options.text) node.textContent = options.text;
  if (options.html) node.innerHTML = options.html;
  if (options.attrs) {
    for (const [k, v] of Object.entries(options.attrs)) {
      node.setAttribute(k, v);
    }
  }
  return node;
}

function clearElement(node) {
  while (node.firstChild) node.removeChild(node.firstChild);
}
EOF

###############################################
# js/api.js
###############################################
cat > "$ROOT/js/api.js" << 'EOF'
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
EOF

###############################################
# js/views/overview.js
###############################################
cat > "$ROOT/js/views/overview.js" << 'EOF'
async function renderOverviewView() {
  const container = document.getElementById("view-overview");
  clearElement(container);

  const info = await apiGetPlantOverview();

  container.appendChild(el("div", {
    className: "view-title",
    text: "Plant Overview"
  }));

  const card = el("div", { className: "card" });
  card.innerHTML = `
    <h3>KPI Summary</h3>
    Flow In: ${info.flow_in} m³/h<br/>
    Flow Out: ${info.flow_out} m³/h<br/>
    Energy: ${info.energy_kw} kW
  `;
  container.appendChild(card);
}
EOF

###############################################
# js/views/modules.js
###############################################
cat > "$ROOT/js/views/modules.js" << 'EOF'
async function renderModulesView() {
  const container = document.getElementById("view-modules");
  clearElement(container);

  container.appendChild(el("div", {
    className: "view-title",
    text: "Modules"
  }));

  const modules = await apiGetModules();

  const grid = el("div", { className: "card-grid" });

  modules.forEach(m => {
    const card = el("div", { className: "card" });
    card.innerHTML = `
      <h3>${m.name}</h3>
      <div>${m.type}</div>
      <div>Status: ${m.status}</div>
      <button class="btn-sm" data-module="${m.id}">Open</button>
    `;
    grid.appendChild(card);
  });

  container.appendChild(grid);

  container.querySelectorAll("button[data-module]").forEach(btn =>
    btn.addEventListener("click", () =>
      showModuleDetail(Number(btn.getAttribute("data-module")))
    )
  );
}
EOF

###############################################
# js/views/moduleDetail.js
###############################################
cat > "$ROOT/js/views/moduleDetail.js" << 'EOF'
async function renderModuleDetailView(moduleId) {
  const container = document.getElementById("view-module-detail");
  clearElement(container);

  const info = await apiGetModuleDetail(moduleId);

  container.appendChild(el("div", {
    className: "view-title",
    text: `${info.name} – ${info.type}`
  }));

  const grid = el("div", { className: "card-grid" });

  info.units.forEach(u => {
    const card = el("div", { className: "card" });
    card.innerHTML = `
      <h3>${u.name}</h3>
      <div>Status: ${u.status}</div>
      <button class="btn-sm"
              data-unit="${u.id}"
              data-module="${info.id}">
        Open Unit
      </button>
    `;
    grid.appendChild(card);
  });

  container.appendChild(grid);

  container.querySelectorAll("button[data-unit]").forEach(btn =>
    btn.addEventListener("click", () =>
      showUnitDetail(
        Number(btn.getAttribute("data-module")),
        btn.getAttribute("data-unit")
      )
    )
  );
}
EOF

###############################################
# js/views/unitDetail.js
###############################################
cat > "$ROOT/js/views/unitDetail.js" << 'EOF'
async function renderUnitDetailView(moduleId, unitId) {
  const container = document.getElementById("view-unit-detail");
  clearElement(container);

  const info = await apiGetUnitDetail(moduleId, unitId);

  container.appendChild(el("div", {
    className: "view-title",
    text: info.name
  }));

  const table = el("table", { className: "table" });
  let rows = "";
  info.tags.forEach(t => {
    rows += `
      <tr>
        <td>${t.tag}</td>
        <td>${t.desc}</td>
        <td>${t.value}</td>
        <td>${t.unit}</td>
      </tr>
    `;
  });

  table.innerHTML = `
    <thead>
      <tr><th>Tag</th><th>Description</th><th>Value</th><th>Unit</th></tr>
    </thead>
    <tbody>${rows}</tbody>
  `;
  container.appendChild(table);
}
EOF

###############################################
# js/views/alarms.js
###############################################
cat > "$ROOT/js/views/alarms.js" << 'EOF'
async function renderAlarmsView() {
  const container = document.getElementById("view-alarms");
  clearElement(container);

  container.appendChild(el("div", {
    className: "view-title",
    text: "Alarms"
  }));

  const alarms = await apiGetAlarms();

  const table = el("table", { className: "table" });
  let rows = "";

  alarms.forEach(a => {
    rows += `
      <tr>
        <td>${a.ts}</td>
        <td>${a.module}</td>
        <td>${a.unit}</td>
        <td>${a.severity}</td>
        <td>${a.message}</td>
      </tr>
    `;
  });

  table.innerHTML = `
    <thead>
      <tr>
        <th>Timestamp</th>
        <th>Module</th>
        <th>Unit</th>
        <th>Severity</th>
        <th>Message</th>
      </tr>
    </thead>
    <tbody>${rows}</tbody>
  `;
  container.appendChild(table);
}
EOF

###############################################
# js/app.js
###############################################
cat > "$ROOT/js/app.js" << 'EOF'
let currentModuleId = null;
let currentUnitId = null;

function showView(name) {
  document.querySelectorAll(".view").forEach(v => v.style.display = "none");

  if (name === "overview") {
    document.getElementById("view-overview").style.display = "block";
    renderOverviewView();
  } else if (name === "modules") {
    document.getElementById("view-modules").style.display = "block";
    renderModulesView();
  } else if (name === "module-detail") {
    document.getElementById("view-module-detail").style.display = "block";
    renderModuleDetailView(currentModuleId);
  } else if (name === "unit-detail") {
    document.getElementById("view-unit-detail").style.display = "block";
    renderUnitDetailView(currentModuleId, currentUnitId);
  } else if (name === "alarms") {
    document.getElementById("view-alarms").style.display = "block";
    renderAlarmsView();
  }
}

function showModuleDetail(moduleId) {
  currentModuleId = moduleId;
  showView("module-detail");
}

function showUnitDetail(moduleId, unitId) {
  currentModuleId = moduleId;
  currentUnitId = unitId;
  showView("unit-detail");
}

async function populateSidebarModules() {
  const list = document.getElementById("sidebar-modules");
  clearElement(list);
  const modules = await apiGetModules();
  modules.forEach(m => {
    const li = el("li");
    const btn = el("button", { text: `${m.id} – ${m.name}` });
    btn.addEventListener("click", () => showModuleDetail(m.id));
    li.appendChild(btn);
    list.appendChild(li);
  });
}

async function updateHealthIndicator() {
  const h = await apiHealth();
  const node = document.getElementById("health-indicator");
  const label = document.getElementById("health-text");
  node.classList.remove("health-ok", "health-bad");
  if (h.ok) {
    node.classList.add("health-ok");
    label.textContent = "Online";
  } else {
    node.classList.add("health-bad");
    label.textContent = "Offline";
  }
}

window.addEventListener("DOMContentLoaded", async () => {
  // top nav
  document.querySelectorAll(".topnav button").forEach(btn => {
    btn.addEventListener("click", () => showView(btn.getAttribute("data-view")));
  });

  await populateSidebarModules();
  await updateHealthIndicator();
  setInterval(updateHealthIndicator, 15000);

  showView("overview");
});
EOF

###############################################
echo "SCADA dashboard skeleton successfully created in $ROOT/"
###############################################
