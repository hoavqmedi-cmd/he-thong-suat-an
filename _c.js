/* ===== Dữ liệu mẫu (Bếp dịch vụ – cữ Trưa) ===== */
const SEED = [
  {id:'S01', name:'Nguyễn Văn An', bn:'BN-10231', floor:'Tầng 3', khoa:'Khoa Hô hấp', room:'Phòng 301', bed:'Giường 1', dish:'Cháo thịt bằm', code:'CD01', warn:'Dị ứng hải sản'},
  {id:'S02', name:'Trần Thị Bình', bn:'BN-10232', floor:'Tầng 3', khoa:'Khoa Hô hấp', room:'Phòng 301', bed:'Giường 2', dish:'Cơm mềm', code:'CD02', warn:''},
  {id:'S03', name:'Lê Hoàng Cường', bn:'BN-10240', floor:'Tầng 3', khoa:'Khoa Hô hấp', room:'Phòng 302', bed:'Giường 1', dish:'Súp xay', code:'CD05', ml:250, warn:''},
  {id:'S04', name:'Phạm Thị Dung', bn:'BN-10245', floor:'Tầng 3', khoa:'Khoa Tim mạch', room:'Phòng 310', bed:'Giường 3', dish:'Cơm nhạt (ít muối)', code:'CD07', warn:'Hạn chế muối'},
  {id:'S05', name:'Võ Minh Đức', bn:'BN-10260', floor:'Tầng 4', khoa:'Khoa Tiêu hoá', room:'Phòng 401', bed:'Giường 1', dish:'Cơm thường', code:'CD03', warn:'Nhịn ăn sau 10h (nội soi)'},
  {id:'S06', name:'Đặng Thị Hoa', bn:'BN-10261', floor:'Tầng 4', khoa:'Khoa Tiêu hoá', room:'Phòng 401', bed:'Giường 2', dish:'Cháo cá', code:'CD01', warn:''},
  {id:'S07', name:'Bùi Văn Khang', bn:'BN-10268', floor:'Tầng 4', khoa:'Khoa Tiêu hoá', room:'Phòng 405', bed:'Giường 1', dish:'Sữa qua sonde', code:'CD06', ml:200, warn:'Bơm chậm'},
  {id:'S08', name:'Hồ Thị Lan', bn:'BN-10275', floor:'Tầng 4', khoa:'Khoa Nội tổng hợp', room:'Phòng 412', bed:'Giường 4', dish:'Cơm mềm', code:'CD02', warn:''}
];
const REASONS = ['BN vắng','BN từ chối','Đã xuất viện','Đang thủ thuật','Sai suất / trùng suất','Khác'];

let suats = [];
let cur = null;          // suất đang thao tác thất bại
let selReason = null, selHandle = null;
let suppN = 0;

/* mốc đóng cửa sửa = 1 tiếng sau giờ kết thúc cữ. Demo: dùng cờ giả lập */
let windowOpen = true;

function resetDemo(){
  suppN = 0;
  suats = SEED.map(s=>({...s, status:'pending', reason:'', note:'', handle:'', supp:false, ts:'', editedBy:''}));
  windowOpen = true;
  render();
  toast('Đã tải dữ liệu cữ '+document.getElementById('cuv').value);
}

function nowHM(){const d=new Date();return ('0'+d.getHours()).slice(-2)+':'+('0'+d.getMinutes()).slice(-2);}

/* ===== Render ===== */
function render(){
  const pend = suats.filter(s=>s.status==='pending');
  const done = suats.filter(s=>s.status!=='pending');
  const ok = suats.filter(s=>s.status==='ok').length;
  const fail = suats.filter(s=>s.status==='fail').length;
  const total = suats.length;

  document.getElementById('c1').textContent = pend.length;
  document.getElementById('c2').textContent = done.length;
  document.getElementById('pn').textContent = ok;
  document.getElementById('pt').textContent = total;
  document.getElementById('pbar').style.width = total? (ok/total*100)+'%':'0%';

  /* Tab 1 — gom theo Tầng → Khoa → Phòng (có lọc tìm kiếm) */
  const v1 = document.getElementById('view1');
  const q = (document.getElementById('q').value||'').trim().toLowerCase();
  const list = q ? pend.filter(s => (s.name+' '+s.bn).toLowerCase().includes(q)) : pend;
  if(!pend.length){ v1.innerHTML = '<div class="empty">🎉 Đã xử lý hết suất của cữ này.<br>Xem kết quả ở tab “Đã giao / kết quả”.</div>'; }
  else if(!list.length){ v1.innerHTML = '<div class="empty">Không tìm thấy suất nào khớp “'+q+'”.</div>'; }
  else{
    let html='', floor='', khoa='', room='';
    list.forEach(s=>{
      if(s.floor!==floor){floor=s.floor; khoa=''; room=''; html+=`<div class="floor">${floor}</div>`;}
      if(s.khoa!==khoa){khoa=s.khoa; room=''; html+=`<div class="khoa">🏥 ${khoa}</div>`;}
      if(s.room!==room){room=s.room; html+=`<div class="room">${room}</div>`;}
      html+=card(s);
    });
    v1.innerHTML = html;
  }

  /* Tab 2 — kết quả */
  const v2 = document.getElementById('view2');
  let h = `<div class="sum">
      <div class="chip ok"><span>${ok}</span><small>Giao OK</small></div>
      <div class="chip fail"><span>${fail}</span><small>Thất bại</small></div>
    </div>`;
  if(!done.length){ h += '<div class="empty">Chưa có suất nào được xử lý.</div>'; }
  else{ done.slice().reverse().forEach(s=> h+=resultItem(s)); }
  v2.innerHTML = h;
}

function card(s){
  return `<div class="card ${s.supp?'add':''}">
    <div class="crow">
      <div>
        <div class="name">${s.name}</div>
        <div class="bn">${s.bn}</div>
        <div class="loc">${s.room} · ${s.bed} · ${s.khoa}</div>
      </div>
      ${s.supp?'<span class="tagadd">BỔ SUNG '+s.ts+'</span>':''}
    </div>
    <div class="dish">🍲 <b>${s.dish}</b><span class="code">${s.code}</span>${s.ml?' <span class="ml">'+s.ml+'ml</span>':''}</div>
    ${s.warn?`<div class="warn">⚠️ ${s.warn}</div>`:''}
    <div class="acts">
      <button class="btn ok" onclick="deliver('${s.id}')">✅ Đã giao</button>
      <button class="btn fail" onclick="openFail('${s.id}')">❌ Thất bại</button>
    </div>
  </div>`;
}

function resultItem(s){
  const ok = s.status==='ok';
  let h = `<div class="ri">
    <div class="st">
      <div>
        <div class="name" style="font-size:16px">${s.name} ${s.supp?'<span class="tagadd">BS</span>':''}</div>
        <div class="meta"><b>${s.bn}</b> · ${s.room} · ${s.bed} · ${s.khoa}<br>🍲 <b>${s.dish}</b> ${s.code}${s.ml?' · '+s.ml+'ml':''}</div>
      </div>
      <span class="badge ${ok?'ok':'fail'}">${ok?'✅ Đã giao':'❌ Thất bại'}</span>
    </div>`;
  if(!ok){
    h += `<div class="meta">Lý do: <b>${s.reason}${s.reason==='Khác'&&s.note?': '+s.note:''}</b></div>
      <span class="handle ${s.handle==='Đem về bếp'?'bep':'dd'}">${s.handle==='Đem về bếp'?'↩️ Đem về bếp':'🏥 Gửi ĐD khoa'}</span>`;
  }
  h += `<div class="log">🕒 ${s.ts}${s.editedBy?' · ✎ sửa bởi '+s.editedBy:''}</div>`;
  h += `<div class="fixrow">${ windowOpen
        ? `<button class="fix" onclick="editStatus('${s.id}')">✎ Sửa trạng thái</button>`
        : `<button class="fix lock" onclick="lockedMsg()">🔒 Đã đóng cữ</button>` }</div>`;
  h += `</div>`;
  return h;
}

/* ===== Thao tác ===== */
function deliver(id){
  const s = suats.find(x=>x.id===id); if(!s) return;
  s.status='ok'; s.ts=nowHM(); s.reason=''; s.handle=''; s.note='';
  render(); toast('✅ Đã giao '+s.bn);
}

function openFail(id){
  cur = suats.find(x=>x.id===id); if(!cur) return;
  selReason=null; selHandle=null;
  document.getElementById('ovwho').textContent = cur.bn+' · '+cur.room+' · '+cur.bed;
  const rc = document.getElementById('reasons');
  rc.innerHTML = REASONS.map(r=>`<button onclick="pickR(this,'${r}')">${r}</button>`).join('');
  document.getElementById('note').style.display='none';
  document.getElementById('note').value='';
  document.querySelectorAll('.hbtn').forEach(b=>b.classList.remove('sel'));
  syncGo();
  document.getElementById('ov').classList.add('show');
}
function pickR(btn,r){
  selReason=r;
  document.querySelectorAll('#reasons button').forEach(b=>b.classList.remove('sel'));
  btn.classList.add('sel');
  document.getElementById('note').style.display = (r==='Khác')?'block':'none';
  syncGo();
}
function pickH(btn){
  selHandle = btn.dataset.h;
  document.querySelectorAll('.hbtn').forEach(b=>b.classList.remove('sel'));
  btn.classList.add('sel');
  syncGo();
}
function syncGo(){
  const ok = selReason && selHandle && !(selReason==='Khác' && !document.getElementById('note').value.trim());
  document.getElementById('go').classList.toggle('ready', !!ok);
}
document.getElementById('note').addEventListener('input', syncGo);

function confirmFail(){
  const note = document.getElementById('note').value.trim();
  if(!selReason || !selHandle) { toast('Cần đủ lý do + cách xử lý'); return; }
  if(selReason==='Khác' && !note){ toast('Nhập ghi chú cho lý do "Khác"'); return; }
  cur.status='fail'; cur.reason=selReason; cur.note=note; cur.handle=selHandle; cur.ts=nowHM();
  closeSheet();
  render();
  toast(selHandle==='Đem về bếp' ? '↩️ Đã đẩy về bếp (Suất trả về)' : '🏥 Đã gửi điều dưỡng khoa');
}
function closeSheet(){ document.getElementById('ov').classList.remove('show'); cur=null; }

/* Sửa trạng thái: đưa suất quay lại Cần giao, ghi vết */
function editStatus(id){
  const s = suats.find(x=>x.id===id); if(!s) return;
  if(!windowOpen){ lockedMsg(); return; }
  s.status='pending'; s.editedBy='Người giao'
