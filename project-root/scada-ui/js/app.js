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
