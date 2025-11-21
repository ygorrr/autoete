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
