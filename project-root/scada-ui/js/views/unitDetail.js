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
