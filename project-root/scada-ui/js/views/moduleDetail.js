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
