// script.js - separated JS
// Keeps the same API contract: POST /check_result with {registration_number, date_of_birth}

function formatDate(dstr){
  if(!dstr) return '';
  const d = new Date(dstr + 'T00:00:00');
  if(isNaN(d)) return dstr;
  return d.toLocaleDateString(undefined, { year:'numeric', month:'short', day:'numeric' });
}

function showMessage(msg, type='info'){
  const area = document.getElementById('messageArea');
  if(!area) return;
  if(type === 'error'){
    area.innerHTML = `<div style="padding:10px;border-radius:8px;background:#fff0f0;color:#7a1010;border:1px solid #ffd6d6">${msg}</div>`;
  } else {
    area.innerHTML = `<div style="padding:10px;border-radius:8px;background:#e8f4ff;color:#02346f">${msg}</div>`;
  }
}

function clearForm(){
  document.getElementById('regNo').value = '';
  document.getElementById('dob').value = '';
  document.getElementById('messageArea').innerHTML = '';
  hideResult();
}

function hideResult(){
  const r = document.getElementById('resultArea');
  r.hidden = true;
  r.innerHTML = '';
}

function validateForm(regNo, dob){
  if(!regNo || regNo.trim().length < 3){
    showMessage('Please enter a valid Registration Number.', 'error');
    return false;
  }
  if(!dob){
    showMessage('Please select Date of Birth.', 'error');
    return false;
  }
  const dobDate = new Date(dob);
  if(dobDate > new Date()) {
    showMessage('Date of Birth cannot be in the future.', 'error');
    return false;
  }
  return true;
}

async function submitForm(){
  const regNo = document.getElementById('regNo').value.trim();
  const dob = document.getElementById('dob').value;

  if(!validateForm(regNo, dob)) return;

  const btn = document.getElementById('checkBtn');
  btn.disabled = true;
  btn.textContent = 'Checking...';
  showMessage('Looking up your result...');

  try {
    const res = await fetch('/check_result', {
      method: 'POST',
      headers: {'Content-Type':'application/json'},
      body: JSON.stringify({ registration_number: regNo, date_of_birth: dob })
    });

    const data = await res.json();
    btn.disabled = false;
    btn.textContent = 'Check Result';

    if(!res.ok){
      showMessage(data.error || 'Server error. Try again later.', 'error');
      hideResult();
      return;
    }

    renderResult(data);
    showMessage('Result loaded.', 'info');
  } catch (err) {
    btn.disabled = false;
    btn.textContent = 'Check Result';
    showMessage('Network or server error. Please try again later.', 'error');
    console.error(err);
  }
}

function renderResult(payload){
  const container = document.getElementById('resultArea');
  container.hidden = false;
  container.innerHTML = '';

  const stu = payload.student;

  const top = document.createElement('div');
  top.className = 'student-top';
  top.innerHTML = `
    <div class="student-info">
      <h3>${stu.student_name}</h3>
      <div class="student-meta">
        Reg No: <strong>${stu.registration_number}</strong> &nbsp;&nbsp;
        Roll No: <strong>${stu.roll_number}</strong><br>
        Course: <strong>${stu.course_name}</strong> &nbsp;&nbsp; Semester: <strong>${stu.semester}</strong> &nbsp;&nbsp; Academic Year: <strong>${stu.academic_year}</strong><br>
        DOB: <strong>${formatDate(stu.date_of_birth)}</strong>
      </div>
    </div>
    <div class="controls">
      <button class="btn primary" onclick="window.print()">Print / Save PDF</button>
    </div>
  `;
  container.appendChild(top);

  // Table
  const tableWrap = document.createElement('div');
  tableWrap.innerHTML = `<h3 style="margin-top:12px;color:#08326b">Subject-wise Results</h3>`;
  const table = document.createElement('table');
  table.className = 'results-table';
  table.innerHTML = `<thead><tr>
    <th>Subject Code</th><th>Subject Name</th><th>Internal</th><th>External</th><th>Total</th><th>Grade</th><th>Status</th>
  </tr></thead><tbody></tbody>`;
  const tbody = table.querySelector('tbody');

  payload.results.forEach(r=>{
    const tr = document.createElement('tr');
    const statusClass = r.status === 'Pass' ? 'status pass' : 'status fail';
    tr.innerHTML = `<td>${r.subject_code}</td>
                    <td>${r.subject_name}</td>
                    <td>${r.internal_marks}</td>
                    <td>${r.external_marks}</td>
                    <td>${r.total_marks} / ${r.max_marks}</td>
                    <td>${r.grade || '-'}</td>
                    <td class="${statusClass}">${r.status}</td>`;
    tbody.appendChild(tr);
  });

  tableWrap.appendChild(table);
  container.appendChild(tableWrap);

  // Summary
  const s = payload.summary;
  const sumWrap = document.createElement('div');
  sumWrap.className = 'summary';
  sumWrap.innerHTML = `
    <div class="box"><div class="label">Total Obtained</div><div class="value">${s.total_obtained}</div></div>
    <div class="box"><div class="label">Maximum Marks</div><div class="value">${s.total_max}</div></div>
    <div class="box"><div class="label">Percentage</div><div class="value">${s.percentage.toFixed(2)}%</div></div>
    <div class="box"><div class="label">Grade</div><div class="value">${s.grade}</div></div>
    <div class="box"><div class="label">Result</div><div class="value ${s.status === 'Pass' ? 'status pass' : 'status fail'}">${s.status}</div></div>
  `;
  container.appendChild(sumWrap);
}

// Expose to window (for inline onclick)
window.submitForm = submitForm;
window.clearForm = clearForm;
