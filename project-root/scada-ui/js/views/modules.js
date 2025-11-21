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
