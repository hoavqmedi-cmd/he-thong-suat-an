
/* ===== Dữ liệu nền ===== */
const STAFF = [
  {id:'NV01',name:'Nguyễn Văn An'},{id:'NV02',name:'Trần Thị Bình'},
  {id:'NV03',name:'Lê Hoàng Cường'},{id:'NV04',name:'Phạm Thị Dung'},
  {id:'NV05',name:'Võ Minh Đức'},{id:'NV06',name:'Đặng Thị Hoa'},
  {id:'NV07',name:'Bùi Văn Khang'},{id:'NV08',name:'Hồ Thị Lan'},
  {id:'NV09',name:'Ngô Văn Minh'},{id:'NV10',name:'Đỗ Thị Nga'}
];
const ZONES = [
  {id:'KV1',name:'Khu 1',detail:'Tầng 2 · Khoa Khám',planned:62},
  {id:'KV2',name:'Khu 2',detail:'Tầng 3 · Hô hấp',planned:78},
  {id:'KV3',name:'Khu 3',detail:'Tầng 3 · Tim mạch',planned:55},
  {id:'KV4',name:'Khu 4',detail:'Tầng 4 · Tiêu hoá',planned:84},
  {id:'KV5',name:'Khu 5',detail:'Tầng 4 · Nội tổng hợp',planned:70},
  {id:'KV6',name:'Khu 6',detail:'Tầng 5 · Ngoại',planned:66},
  {id:'KV7',name:'Khu 7',detail:'Tầng 6 · Sản – Nhi',planned:58}
];
/* mẫu mặc định: KV1..KV7 -> NV01..NV07 */
let template = {KV1:'NV01',KV2:'NV02',KV3:'NV03',KV4:'NV04',KV5:'NV05',KV6:'NV06',KV7:'NV07'};
let assign = {...template};   // phân công cữ hiện tại
let saved = false;
let prog = {};                // tiến độ theo khu

function nameOf(id){const s=STAFF.find(x=>x.id===id);return s?s.name:'';}
function nowHM(){const d=new Date();return ('0'+d.getHours()).slice(-2)+':'+('0'+d.getMinutes()).slice(-2);}

/* ===== TAB A ===== */
function renderAssign(){
  document.getElementById('cuvA').textContent = document.getElementById('cuv').value;
  // đếm trùng
  const used = {};
  Object.values(assign).forEach(v=>{ if(v) used[v]=(used[v]||0)+1; });
  let html = `<div class="arow head"><div>Khu vực</div><div>Phạm vi</div><div>Dự kiến</div><div>Nhân viên giao</div></div>`;
  ZONES.forEach(z=>{
    const v = assign[z.id]||'';
    const cls = !v ? 'empty' : (used[v]>1?'dup':'');
    const opts = ['<option value="">— Chọn nhân viên —</option>']
      .concat(STAFF.map(s=>`<option value="${s.id}" ${s.id===v?'selected':''}>${s.name}</option>`)).join('');
    html += `<div class="arow">
      <div><div class="zname">${z.name}</div></div>
      <div class="zdet">${z.detail}</div>
      <div class="plan">${z.planned}<small>suất</small></div>
      <div><select class="${cls}" onchange="setAssign('${z.id}',this.value)">${opts}</select></div>
    </div>`;
  });
  document.getElementById('assign').innerHTML = html;
  renderBench();
  validateAssign();
}
function renderBench(){
  const usedIds = new Set(Object.values(assign).filter(Boolean));
  const free = STAFF.filter(s=>!usedIds.has(s.id));
  document.getElementById('bench').innerHTML = free.length
    ? free.map(s=>`<span class="pchip">${s.name}</span>`).join('')
    : '<span class="pchip none">Không còn nhân viên dự phòng</span>';
}
function setAssign(zid,val){ assign[zid]=val; saved=false; renderAssign(); }

function issues(){
  const list=[];
  const empties=ZONES.filter(z=>!assign[z.id]).map(z=>z.name);
  if(empties.length) list.push('Chưa gán nhân viên cho: '+empties.join(', '));
  const cnt={}; Object.entries(assign).forEach(([z,v])=>{if(v)(cnt[v]=cnt[v]||[]).push(z)});
  Object.entries(cnt).forEach(([v,zs])=>{ if(zs.length>1) list.push(nameOf(v)+' bị gán trùng '+zs.length+' khu ('+zs.join(', ')+')'); });
  return list;
}
function validateAssign(){
  const b=document.getElementById('banA'); const errs=issues();
  document.getElementById('saveBtn').disabled = errs.length>0;
  if(errs.length){ b.className='banner warn'; b.innerHTML='⚠️ Cần xử lý trước khi lưu:<ul>'+errs.map(e=>'<li>'+e+'</li>').join('')+'</ul>'; }
  else if(saved){ b.className='banner ok'; b.innerHTML='✓ Đã lưu phân công cữ '+document.getElementById('cuv').value+' — chuyển sang tab Giám sát để theo dõi.'; }
  else{ b.className='banner'; b.innerHTML=''; }
}
function saveAssign(){
  if(issues().length) return;
  saved=true; initProg(); validateAssign(); toast('✓ Đã lưu phân công cữ '+document.getElementById('cuv').value);
}
function saveTemplate(){ template={...assign}; toast('💾 Đã lưu mẫu mặc định'); }
function applyTemplate(){ assign={...template}; saved=false; renderAssign(); toast('↺ Đã áp mẫu mặc định'); }

/* ===== TAB B ===== */
function initProg(){
  prog={};
  ZONES.forEach(z=>{
    const total=z.planned;
    const delivered=Math.round(total*(0.3+Math.random()*0.5));
    const failed=Math.round(delivered*0.05*Math.random());
    prog[z.id]={total,delivered,failed,returned:Math.round(failed*0.6),ts:nowHM()};
  });
}
function zoneStatus(p){
  const pct=p.delivered/p.total;
  if(pct>=1) return {k:'done',t:'Hoàn tất'};
  if(pct>=0.7) return {k:'near',t:'Sắp xong'};
  if(pct>=0.45) return {k:'going',t:'Đang giao'};
  return {k:'slow',t:'Chậm'};
}
function barColor(k){return k==='done'?'#16a34a':k==='near'?'#2563eb':k==='slow'?'#dc2626':'#f59e0b';}

function renderMonitor(){
  if(!Object.keys(prog).length) initProg();
  let tot=0,ok=0,fail=0,ret=0;
  ZONES.forEach(z=>{const p=prog[z.id];tot+=p.total;ok+=p.delivered;fail+=p.failed;ret+=p.returned;});
  document.getElementById('mTot').textContent=tot;
  document.getElementById('mOk').textContent=ok;
  document.getElementById('mPct').textContent=tot?Math.round(ok/tot*100)+'%':'0%';
  document.getElementById('mFail').textContent=fail;
  document.getElementById('mRet').textContent=ret;
  document.getElementById('oBar').style.width=tot?(ok/tot*100)+'%':'0%';

  // cảnh báo tổng
  const alerts=[];
  ZONES.forEach(z=>{
    const p=prog[z.id]; const s=zoneStatus(p);
    if(s.k==='slow') alerts.push('🐢 '+z.name+' ('+z.detail+') đang chậm — '+nameOf(assign[z.id]));
    if(p.delivered && p.failed/Math.max(p.delivered,1)>0.1) alerts.push('❗ '+z.name+' tỷ lệ thất bại cao ('+p.failed+'/'+p.delivered+')');
  });
  const b=document.getElementById('banB');
  if(alerts.length){ b.className='banner warn'; b.innerHTML='Cần chú ý:<ul>'+alerts.map(a=>'<li>'+a+'</li>').join('')+'</ul>'; }
  else{ b.className='banner ok'; b.innerHTML='✓ Các khu đang đúng tiến độ.'; }

  // lưới khu
  let html='';
  ZONES.forEach(z=>{
    const p=prog[z.id]; const s=zoneStatus(p); const pct=Math.round(p.delivered/p.total*100);
    const left=p.total-p.delivered-p.failed;
    const nv=assign[z.id];
    html+=`<div class="zcard" onclick="openZone('${z.id}')">
      <div class="top">
        <div>
          <div class="zn">${z.name} · <span style="font-weight:600;color:var(--muted);font-size:13px">${z.detail}</span></div>
          <div class="nv ${nv?'':'no'}">${nv?'👤 '+nameOf(nv):'⚠️ Chưa gán nhân viên'}</div>
        </div>
        <span class="st ${s.k}">${s.t}</span>
      </div>
      <div class="zbar"><i style="width:${pct}%;background:${barColor(s.k)}"></i></div>
      <div class="zmeta">
        <span><b>${p.delivered}</b><span class="mut">/${p.total} đã giao (${pct}%)</span></span>
        <span class="mut">Còn <b style="color:var(--ink)">${left<0?0:left}</b></span>
        <span class="fail">✗ ${p.failed}</span>
      </div>
      <div class="upd">🕒 Cập nhật ${p.ts}</div>
    </div>`;
  });
  document.getElementById('zgrid').innerHTML=html;
}

function simulate(){
  ZONES.forEach(z=>{
    const p=prog[z.id];
    const room=p.total-p.delivered-p.failed;
    if(room>0){
      const step=Math.min(room,Math.ceil(p.total*(0.05+Math.random()*0.12)));
      const newFail=Math.random()<0.3?1:0;
      p.delivered+=Math.max(0,step-newFail);
      p.failed+=newFail; if(newFail&&Math.random()<0.6)p.returned+=1;
      p.ts=nowHM();
    }
  });
  renderMonitor(); toast('🔄 Đã cập nhật tiến độ');
}

/* ===== Modal ===== */
function openZone(zid){
  const z=ZONES.find(x=>x.id===zid); const p=prog[zid];
  document.getElementById('mTitle').textContent=z.name+' · '+z.detail;
  document.getElementById('mSub').textContent='Phụ trách: '+(assign[zid]?nameOf(assign[zid]):'(chưa gán)')+
    ' · Đã giao '+p.delivered+'/'+p.total+' · Thất bại '+p.failed;
  // danh sách suất mẫu
  const names=['Nguyễn V. A','Trần T. B','Lê H. C','Phạm T. D','Võ M. Đ','Đặng T. H','Bùi V. K','Hồ T. L','Ngô V. M','Đỗ T. N'];
  let h='';
  for(let i=0;i<10;i++){
    const st = i<7?'done':(i===7?'fail':'pend');
    const badge = st==='done'?'<span class="st done">✅ Đã giao</span>':
                  st==='fail'?'<span class="st slow">❌ Thất bại</span>':
                  '<span class="st going">⏳ Cần giao</span>';
    h+=`<div class="mli"><div><div class="nm">${names[i]}</div>
      <div class="lc">BN-10${300+i} · Phòng ${z.id.slice(2)}0${i+1} · Giường ${i%4+1}</div></div>${badge}</div>`;
  }
  document.getElementById('mList').innerHTML=h;
  document.getElementById('ov').classList.add('show');
}
function closeModal(){document.getElementById('ov').classList.remove('show');}

/* ===== Chung ===== */
function show(t){
  document.getElementById('tabA').classList.toggle('on',t==='A');
  document.getElementById('tabB').classList.toggle('on',t==='B');
  document.getElementById('viewA').style.display=t==='A'?'block':'none';
  document.getElementById('viewB').style.display=t==='B'?'block':'none';
  if(t==='A') renderAssign(); else renderMonitor();
}
function onCuv(){ saved=false; renderAssign(); initProg(); toast('Đã chuyển sang cữ '+document.getElementById('cuv').value); }

let toastT;
function toast(m){const el=document.getElementById('toast');el.textContent=m;el.classList.add('show');
  clearTimeout(toastT);toastT=setTimeout(()=>el.classList.remove('show'),1800);}

document.getElementById('date').textContent=new Date().toLocaleDateString('vi-VN',{weekday:'long',day:'2-digit',month:'2-digit',year:'numeric'});
initProg();
renderAssign();
