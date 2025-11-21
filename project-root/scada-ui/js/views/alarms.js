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
