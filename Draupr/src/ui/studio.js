'use strict';
(()=>{
const $=id=>document.getElementById(id), schema=window.DRAUPR_SCHEMA, tools=Object.fromEntries(schema.tools.map(t=>[t.id,t]));
const E={create:'Create',edit:'Edit',materials:'Materials',library:'Library',project:'Project',geometry:'Geometry',placement:'Placement',advanced:'Advanced',draw:'Draw',place:'Place',noSelection:'Select a Draupr object in the model.',selection:'selected',mixed:'— Mixed —',ready:'Ready',connected:'Connected',preview:'Preview',all:'All',model:'In model',recent:'Recent',favorites:'Favorites',useMaterial:'Use this material',editMaterial:'Edit / duplicate',favorite:'Favorite',materialName:'Material name',color:'Color',opacity:'Opacity (%)',duplicateMaterial:'Create an independent duplicate first',duplicateName:'Duplicate name',sharedConfirm:'I understand this changes EVERY use of the shared material.',textureWidth:'Real texture width',textureHeight:'Real texture height',name:'Name',loadPreset:'Load',rename:'Rename',noPresets:'No saved presets yet.',reports:'Reports',health:'Model health',settings:'Settings',type:'Type',level:'Level',area:'Area (m²)',volume:'Volume (m³)',length:'Length',active:'Active',line:'Two endpoints',path:'Connected path',rectangle:'Opposite corners',rotated:'Rotated · three clicks',direction:'Position + direction',point:'Single point',host:'On a wall',onRoof:'On a roof',drawHint:'Click in the model. Type exact dimensions + Enter. Esc steps back.',noMaterial:'Choose a material first.',searchMaterials:'Find a material…',searchPresets:'Find a preset…',deleteConfirm:'Delete selected objects and any openings linked to selected walls? SketchUp Undo is available.',healConfirm:'Close all openings and remove the opening objects linked to these walls?',saved:'Saved',applied:'Changes applied',toolActive:'Tool active — click in the model.',changes:'changed',noChanges:'No changes to apply.',previewHint:'Wireframe preview. Click in the model or press Esc to exit.',usingDefaults:'Defaults for next object',selectPart:'Choose a part',nominalSize:'Nominal dimensions',choose:'Choose',readOnlyHosted:'Placement is controlled by the host wall.',cancelled:'Cancelled',done:'Done',presetName:'Preset name',missing:'Missing',objectLibrary:'Object Library',saveObject:'Save selection',browse:'Browse…',noObjects:'No saved objects yet.',sharedFolder:'SHARED FOLDER',openFolder:'Open folder',uncategorized:'Uncategorized',category:'Category',tags:'Tags',description:'Description',rotation:'Rotation (°)',scale:'Scale',exportMaterials:'Material totals CSV',exportLevels:'Level totals CSV',alignSurface:'Align to picked face',replace:'Replace',replaceConfirm:'Replace the one selected group or component?',roofIntersection:'Intersection guides',roofValley:'Valley flashing',roofJoin:'Join roof edge to face',modify:'Modify',modifyTools:'SELECTION TOOLS',align:'Align',alignFaces:'Align faces' ,walls:'Walls',roofs:'Roofs',wallTrim:'Trim / Extend to Corner',wallSplit:'Split wall',modifyHint:'Wall Corner: click the piece of each wall to keep; right-click for Butt, Miter, Square Off, and priority. Roof Join: click source edge, then target face.',builtInProfiles:'Built-in profiles',railingPresets:'Railing presets',localRailingSources:'LOCAL COMPONENT SOURCES',railingSourceModels:'Railing Source Models',railingSourceHint:'Draupr reads user-owned SKP files from this folder. Models are not included in the extension.',validSources:'valid sources',missingSources:'missing sources',dormerTypes:'Dormer types',drawPath:'Draw path',selectedEdges:'Selected edges',pickConnectedPath:'Pick connected path',generateFromPath:'Generate from path',pickPath:'Pick path',selectedEdgesHint:'Select one connected edge chain in SketchUp, then click Generate.',pickPathHint:'Click an edge or SketchUp curve to generate the object from its connected path.',topologyPath:'Topology & Path',splitAssembly:'Split Assembly / Knife',trimBoundary:'Trim / Extend to Boundary',alignBaseline:'Align Baseline',junctionsCorners:'Junctions & Corners',junctionSwitcher:'Junction Type',boundariesHeights:'Boundaries & Heights',attachTop:'Attach Top to Face',attachBase:'Attach Base to Face',detachBoundary:'Detach Boundaries',stepHeight:'Wall / Foundation Step',aperturesOpenings:'Apertures & Openings',healOpening:'Heal One Opening',splayOpening:'Splay / Deep Reveal',profilesSweeps:'Profiles & Sweeps',profileRegistration:'Registration, Flip & Returns',architecturalDetail:'Architectural Detailing',disassembleParts:'Disassemble to Parts',edgeDetail:'Edge Chamfer / Bullnose'};
document.querySelectorAll('[data-i18n]').forEach(el=>{E[el.dataset.i18n]??=el.textContent.trim()});
const iconPaths={
 create:'M12 3v18M3 12h18',
 edit:'M4 5h9v9H4zM10 20l3-.7L21 11l-3-3-8.3 8.3zM16 10l3 3',
 modify:'M14 5a5 5 0 0 0-6 6l-5 5 5 5 5-5a5 5 0 0 0 6-6l-3 1-3-3z',
 materials:'M4 14l7-7 7 7-7 7zM8 5l9 9M19 16c2 2 2 4 0 5-2-1-2-3 0-5',
 library:'M4 4h5v16H4zM11 4h4v16h-4zM17 5l3-1 3 15-3 1z',
 project:'M3 21V6h12v15M15 11h6v10M7 10h3M7 14h3M7 18h3M17 15h2M17 18h2M6 3h6',
 wall:'M3 7l13-3 5 3v12L8 22l-5-3zM8 10v12M8 10l13-3',
 curtain_wall:'M3 5l14-2 4 2v15L7 22l-4-2zM7 7v15M14 4v16M3 12l18-1M3 17l18-2',
 door:'M5 21V3h14v18M8 21V6h8v15M8 6l8 2M13 14h.1',
 window:'M4 5l13-2 3 2v14L7 21l-3-2zM7 7v14M13 4v16M4 12l16-1',
 column:'M8 4h8M7 7h10M9 7v11M15 7v11M7 18h10M8 21h8',
 foundation:'M10 3h4v9M6 12h12l3 8H3zM6 16h12',
 beam:'M5 4h14v4h-5v8h5v4H5v-4h5V8H5z',
 slab:'M3 10l13-5 5 4-13 5zM3 10v5l5 4 13-5V9M8 14v5',
 grid:'M7 3v18M17 3v18M3 7h18M3 17h18M5 5l4 4M15 15l4 4',
 stair:'M3 20h4v-4h4v-4h4V8h4V4M14 5h5v5M19 5l-8 8',
 roof:'M2 14l10-9 10 9M5 13l7-5 7 5v7H5zM12 8v12',
 railing:'M3 6h18M4 6v15M20 6v15M8 9v12M12 9v12M16 9v12M3 10h18',
 louver:'M5 4v16M19 4v16M5 7h14M6 11l12-3M6 15l12-3M6 19l12-3',
 ramp:'M3 20h18M4 17l16-9v9M13 8h7v7M20 8l-9 6',
 skylight:'M3 18L9 5h12l-6 13zM8 15l4-7h6l-4 7zM12 8l2 7',
 dormer:'M2 19l6-12 14 4M7 14l5-7 6 5v8H7zM12 7v13M9 16h6',
 molding:'M3 20h18M5 20V6h14v5h-8v5h5v4M8 9h8'
};
const actionIconPaths={
 modifySplit:'M3 6h18v12H3zM12 3v5M12 10v4M12 16v5M8 4l8 16',
 modifyTrim:'M4 6v12h8M18 4v16M11 12h9M16 8l4 4-4 4',
 modifyAlignBaseline:'M3 19h18M5 6h6v7H5zM14 9h5v6h-5zM8 13v6M16 15v4',
 alignFaces:'M4 6h7v12H4zM15 4h5v12h-5zM11 9h4M12 7l3 2-3 2M15 14h-4M14 12l-3 2 3 2',
 modifyJunction:'M4 4v16h5v-6h11V9H9V4z',
 wallTrim:'M4 5v14h8M20 5v14h-8M9 12h6M7 9l3 3-3 3M17 9l-3 3 3 3',
 attachTop:'M3 7l9-4 9 4M6 10v10h12V10M9 12l3-4 3 4M12 8v8',
 attachBase:'M5 4v12h14V4M3 20h18M9 13l3 4 3-4M12 8v9',
 detachBoundary:'M3 5l9-3 9 3M6 11v10h12V11M8 8h8M9 12l3-3 3 3',
 modifyStep:'M3 20h5v-5h5v-5h5V5h3M5 7h8l3-3M13 7l3 3',
 modifyHealOpening:'M3 5h18v14H3zM8 9h8v7H8zM8 12h8M12 9v7',
 modifySplayOpening:'M3 5h18v14H3zM8 8l8-2v12l-8-2zM8 8v8',
 modifySweep:'M4 19V9h6v6h4V7h6M16 4l4 3-4 3M7 12h3M12 15h3',
 modifyDisassemble:'M9 9h6v6H9zM9 9L4 4M15 9l5-5M9 15l-5 5M15 15l5 5M4 4h4M4 4v4M20 4h-4M20 4v4M4 20h4M4 20v-4M20 20h-4M20 20v-4',
 modifyEdgeDetail:'M4 20V4h16M4 20h16M13 4l7 7M20 11a9 9 0 0 1-9 9',
 roofIntersection:'M2 15l8-8 6 6 6-6M3 9l9 10L21 9M12 19V9',
 roofValley:'M3 7l9 11 9-11M3 18l9-5 9 5M12 7v11',
 roofJoin:'M2 17l8-9 5 5 7-7M10 8v12M15 13v7M7 16l3-3 3 3'
};
const iconLayers={
 create:{action:'M12 5v14M5 12h14'},
 edit:{target:'M10 20l3-.7L21 11',action:'M16 10l3 3'},
 modify:{target:'M3 16l5 5 5-5',action:'M14 5a5 5 0 0 0-6 6M19 10l-3 1-3-3'},
 materials:{target:'M4 14l7-7 7 7-7 7z',action:'M19 16c2 2 2 4 0 5-2-1-2-3 0-5'},
 library:{target:'M11 4h4v16',action:'M17 5l3-1 3 15-3 1'},
 project:{target:'M15 11h6v10',add:'M6 3h6'},
 wall:{target:'M3 7l13-3 5 3M8 10l13-3M8 10v12'},
 curtain_wall:{glass:'M7 7l7-2v6l-7 1zM7 13l7-1v8l-7 2zM15 5l6 2v4l-6 0zM15 12h6v8l-6 0z',target:'M7 7v15M14 4v16M3 12l18-1'},
 door:{target:'M8 21V6h8v15M8 6l8 2',action:'M13 14h.1'},
 window:{glass:'M7 7l6-2v7l-6 1zM14 5l6 2v4l-6 1zM7 14l6-1v7l-6 1zM14 13l6-1v7l-6 1z',target:'M7 7v14M13 4v16M4 12l16-1'},
 column:{target:'M9 7v11M15 7v11',add:'M7 7h10M7 18h10'},
 foundation:{target:'M6 12h12l3 8H3z',add:'M10 3h4v9'},
 beam:{target:'M10 8h4v8h-4z',add:'M5 4h14v4M5 16h14v4'},
 slab:{glass:'M3 10l13-5 5 4-13 5z',target:'M3 10v5l5 4 13-5V9'},
 grid:{target:'M7 3v18M17 3v18M3 7h18M3 17h18',action:'M5 5l4 4M15 15l4 4'},
 stair:{target:'M3 20h4v-4h4v-4h4V8h4V4',action:'M14 5h5v5M19 5l-8 8'},
 roof:{glass:'M2 14l10-9 10 9-10-6z',target:'M5 13l7-5 7 5M12 8v12'},
 railing:{target:'M3 6h18M3 10h18M4 6v15M20 6v15',add:'M8 9v12M12 9v12M16 9v12'},
 louver:{target:'M6 11l12-3M6 15l12-3M6 19l12-3',action:'M5 7h14'},
 ramp:{target:'M4 17l16-9v9',action:'M13 8h7v7M20 8l-9 6'},
 skylight:{glass:'M8 15l4-7h6l-4 7z',target:'M3 18L9 5h12l-6 13z'},
 dormer:{glass:'M9 16h6v4H9z',target:'M7 14l5-7 6 5v8H7z',action:'M2 19l6-12 14 4'},
 molding:{target:'M5 20V6h14v5h-8v5h5v4',action:'M8 9h8'}
};
const actionIconLayers={
 modifySplit:{remove:'M12 3v5M12 10v4M12 16v5M8 4l8 16',target:'M3 6h18v12H3z'},
 modifyTrim:{target:'M18 4v16',action:'M11 12h9M16 8l4 4-4 4'},
 modifyAlignBaseline:{target:'M3 19h18',action:'M8 13v6M16 15v4'},
 alignFaces:{target:'M15 4h5v12h-5z',action:'M11 9h4M12 7l3 2-3 2M15 14h-4M14 12l-3 2 3 2'},
 modifyJunction:{target:'M9 9h11v5H9',add:'M4 4v16h5'},
 wallTrim:{target:'M4 5v14h8M20 5v14h-8',action:'M9 12h6M7 9l3 3-3 3M17 9l-3 3 3 3'},
 attachTop:{target:'M3 7l9-4 9 4',action:'M9 12l3-4 3 4M12 8v8'},
 attachBase:{target:'M3 20h18',action:'M9 13l3 4 3-4M12 8v9'},
 detachBoundary:{target:'M3 5l9-3 9 3',remove:'M8 8h8',action:'M9 12l3-3 3 3'},
 modifyStep:{target:'M3 20h5v-5h5v-5h5V5h3',action:'M5 7h8l3-3M13 7l3 3'},
 modifyHealOpening:{add:'M8 9h8v7H8zM8 12h8M12 9v7',target:'M3 5h18v14H3z'},
 modifySplayOpening:{target:'M8 8l8-2v12l-8-2z',action:'M8 8v8'},
 modifySweep:{target:'M4 19V9h6v6h4V7h6',action:'M16 4l4 3-4 3'},
 modifyDisassemble:{target:'M9 9h6v6H9z',action:'M9 9L4 4M15 9l5-5M9 15l-5 5M15 15l5 5'},
 modifyEdgeDetail:{target:'M13 4l7 7M20 11a9 9 0 0 1-9 9',action:'M4 20V4h16'},
 roofIntersection:{target:'M12 19V9',action:'M2 15l8-8 6 6 6-6M3 9l9 10L21 9'},
 roofValley:{target:'M12 7v11',action:'M3 7l9 11 9-11M3 18l9-5 9 5'},
 roofJoin:{target:'M10 8v12M15 13v7',add:'M7 16l3-3 3 3'}
};
const iconSvg=(base,layers={},standardKey=null)=>{const standard=window.DRAUPR_STANDARD_ICONS?.[standardKey];if(standard)return `<svg class="icon icon-custom" viewBox="0 0 24 24" aria-hidden="true">${standard}</svg>`;return `<svg class="icon" viewBox="0 0 24 24" aria-hidden="true"><path class="icon-geometry" d="${base}"/>${layers.glass?`<path class="icon-glass" d="${layers.glass}"/>`:''}${layers.target?`<path class="icon-target" d="${layers.target}"/>`:''}${layers.action?`<path class="icon-action" d="${layers.action}"/>`:''}${layers.add?`<path class="icon-add" d="${layers.add}"/>`:''}${layers.remove?`<path class="icon-remove" d="${layers.remove}"/>`:''}</svg>`};
const icon=k=>iconSvg(iconPaths[k]||iconPaths.create,iconLayers[k],k);
const esc=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const copy=v=>JSON.parse(JSON.stringify(v));
const S={connected:false,prefs:{language:'en',theme:'light',units:'mm',keep_drawing:true},ws:'create',category:'envelope',kind:'wall',drafts:{},selection:[],bound:[],changes:{},materials:{items:[],names:[],total:0},source:'all',material:null,library:[],project:{levels:[{id:'ground',name:'Ground',elevation:'0 mm'}],activeLevel:'ground'},fieldTarget:null,sampleTarget:null,panel:null,projectTab:'levels',reports:[],pending:new Map(),seq:0,pathSource:'draw'};
schema.tools.forEach(t=>{S.drafts[t.id]=Object.fromEntries(t.fields.map(f=>[f.key,f.default]))});
const t=k=>S.prefs.language==='fa'?(window.DRAUPR_FA[k]||E[k]||k):(E[k]||k);
const label=x=>S.prefs.language==='fa'?(x.fa||x.label):x.label;
function notice(msg,kind='info'){$('statusText').textContent=msg;$('statusText').title=msg;$('status').classList.toggle('error',kind==='error')}
function request(action,payload={}){
 if(!S.connected && action!=='ready')return Promise.reject(new Error(t('offline')));
 return new Promise((resolve,reject)=>{
  const id=++S.seq, timer=setTimeout(()=>{S.pending.delete(id);reject(new Error('No response from SketchUp. Check the model and refresh Studio.'))},120000);
  S.pending.set(id,{resolve,reject,timer});
  try{window.sketchup.studioCommand(JSON.stringify({id,action,payload}))}catch(e){clearTimeout(timer);S.pending.delete(id);reject(e)}
 });
}
async function run(action,payload={},message=null){try{const data=await request(action,payload);if(message)notice(message,'success');return data}catch(e){notice(e.message,'error');throw e}}
function applyLanguage(){document.documentElement.lang=S.prefs.language;document.documentElement.dir=S.prefs.language==='fa'?'rtl':'ltr';document.body.dataset.theme=S.prefs.theme;$('language').value=S.prefs.language;document.querySelectorAll('[data-i18n]').forEach(el=>el.textContent=t(el.dataset.i18n));$('materialSearch').placeholder=t('searchMaterials');$('presetSearch').placeholder=t('searchPresets')}
function nav(){
 $('workspaces').innerHTML=['create','edit','modify','materials','library','project'].map(k=>{const name=t(k);return `<button data-workspace="${k}" class="${S.ws===k?'active':''}" aria-current="${S.ws===k?'page':'false'}" aria-label="${esc(name)}" title="${esc(name)}" data-tooltip="${esc(name)}">${icon(k)}<span class="sr-only">${esc(name)}</span></button>`}).join('');
 $('category').innerHTML=schema.categories.map(c=>`<option value="${c.id}" ${S.category===c.id?'selected':''}>${esc(label(c))}</option>`).join('');
 $('tools').innerHTML=schema.tools.filter(q=>q.category===S.category).map(q=>{const name=label(q);return `<button role="tab" aria-selected="${q.id===S.kind}" class="tool-icon-button ${q.id===S.kind?'active':''}" data-tool="${q.id}" aria-label="${esc(name)}" title="${esc(name)}" data-tooltip="${esc(name)}">${icon(q.id)}<span class="sr-only">${esc(name)}</span></button>`}).join('');
 ['create','edit','modify','materials','library','project'].forEach(k=>$('view-'+k).hidden=k!==S.ws);
}
function enhanceModifierIcons(){
 const ids=['modifySplit','modifyTrim','modifyAlignBaseline','alignFaces','modifyJunction','wallTrim','attachTop','attachBase','detachBoundary','modifyStep','modifyHealOpening','modifySplayOpening','modifySweep','modifyDisassemble','modifyEdgeDetail','roofIntersection','roofValley','roofJoin'];
 ids.forEach(id=>{const b=$(id);if(!b)return;const name=b.textContent.trim();b.classList.add('tool-icon-button');b.title=name;b.dataset.tooltip=name;b.setAttribute('aria-label',name);b.innerHTML=`${iconSvg(actionIconPaths[id]||iconPaths.modify,actionIconLayers[id],id)}<span class="sr-only">${esc(name)}</span>`});
}
function workspace(ws){S.ws=ws;nav();if(ws==='edit'&&!Object.keys(S.changes).length)bindSelection();if(ws==='materials'){materialTargets();renderPanels();loadMaterials()}if(ws==='library'){renderLibrary();loadLibraryObjects();loadRailingSources()}if(S.connected)request('preferences',{workspace:ws}).catch(()=>{})}
function preview(el,kind,p){
 const q=tools[kind];if(!q){el.innerHTML='';return}
 let summary=['width','length','height','depth'].filter(k=>p[k]!==undefined&&p[k]!=='__mixed__').slice(0,3).map(k=>`${label(q.fields.find(f=>f.key===k)||{label:k})}: ${p[k]}`).join(' · ');
 el.innerHTML=`<svg viewBox="0 0 110 70" aria-hidden="true"><path d="M12 28L62 8l36 16-50 23zM12 28v24l36 14 50-24V24M48 47v19" fill="none" stroke="currentColor" stroke-width="1.4"/><path d="M13 55l33 12M51 68l48-24" stroke="currentColor" stroke-dasharray="2 3"/></svg><div><b>${esc(label(q))}</b><small>${esc(summary||t('nominalSize'))}</small><div class="derived"></div></div>`;
}
function visible(f,p){return Object.entries(f.show||{}).every(([k,v])=>String(p[k])===String(v))&&Object.entries(f.showNot||{}).every(([k,v])=>String(p[k])!==String(v))}
function materialOptions(value){return [...new Set([value,...S.materials.names,...schema.tools.flatMap(q=>q.fields.filter(f=>f.type==='material').map(f=>f.default))])].filter(Boolean).map(m=>`<option value="${esc(m)}" ${m===value?'selected':''}>${esc(m)}</option>`).join('')}
function renderFields(container,fields,p,mode){
 container.innerHTML=['geometry','placement','materials','advanced'].map(section=>{
  const fs=fields.filter(f=>f.section===section);if(!fs.length)return '';
  return `<details ${section!=='advanced'?'open':''}><summary>${esc(t(section))}</summary><div class="field-grid">${fs.map(f=>{
   const v=p[f.key],id=`${mode}-${f.key}`,mixed=v==='__mixed__', disabled=mode==='edit'&&S.bound.some(x=>x.hosted)&&['rotation','z_offset','placement_mode','level_id','depth'].includes(f.key);let control='';
   if(f.type==='boolean')control=`<label class="check"><input id="${id}" data-key="${f.key}" type="checkbox" ${v===true?'checked':''} ${disabled?'disabled':''}><span>${esc(mixed?t('mixed'):label(f))}</span></label>`;
   else if(f.type==='select'||f.type==='level'){
    const opts=f.type==='level'?S.project.levels.map(l=>({value:l.id,label:l.name,fa:l.name})):f.options;
    control=`<select id="${id}" data-key="${f.key}" ${disabled?'disabled':''}>${mixed?`<option value="__mixed__">${esc(t('mixed'))}</option>`:''}${opts.map(o=>`<option value="${esc(o.value)}" ${String(o.value)===String(v)?'selected':''}>${esc(label(o))}</option>`).join('')}</select>`;
   }else if(f.type==='material')control=`<div class="material-input"><select id="${id}" data-key="${f.key}">${mixed?`<option value="__mixed__">${esc(t('mixed'))}</option>`:''}${materialOptions(mixed?'':v)}</select><button type="button" data-browse-field="${f.key}" data-mode="${mode}" title="${esc(t('choose'))}">…</button><button type="button" data-sample-field="${f.key}" data-mode="${mode}" title="${esc(t('sample'))}">⌖</button></div>`;
   else control=`<input id="${id}" data-key="${f.key}" ${f.type==='length'?'data-length="true"':''} type="${['integer','number'].includes(f.type)?'number':'text'}" ${f.type==='integer'?'step="1"':''} value="${esc(mixed?'':v)}" placeholder="${esc(mixed?t('mixed'):'')}" ${disabled?'disabled':''}>`;
   return `<div class="field ${mode==='edit'&&Object.prototype.hasOwnProperty.call(S.changes,f.key)?'dirty':''}" data-field="${f.key}" ${!visible(f,p)&&!mixed?'hidden':''}><label for="${id}" title="${esc(disabled?t('readOnlyHosted'):label(f))}">${esc(label(f))}</label>${control}<div class="error"></div></div>`;
  }).join('')}</div></details>`;
 }).join('');
 fields.forEach(f=>{if(f.type==='boolean'&&p[f.key]==='__mixed__'){const el=container.querySelector(`[data-key="${f.key}"]`);if(el)el.indeterminate=true}});
}
function moldingProfileSvg(points){const poly=points.map(p=>`${8+p[0]*48},${56-p[1]*48}`).join(' ');return `<svg viewBox="0 0 64 64" aria-hidden="true"><polygon points="${poly}"/></svg>`}
function renderMoldingProfiles(mode){
 const list=window.DRAUPR_MOLDING_PROFILES||[],container=$(mode==='create'?'createFields':'editFields'),row=container?.querySelector('[data-field="profile"]');if(!row||!list.length)return;
 const value=mode==='create'?S.drafts.molding.profile:editValues().profile;row.classList.add('molding-profile-field');row.querySelector('.molding-profile-gallery')?.remove();
 const gallery=document.createElement('div');gallery.className='molding-profile-gallery';gallery.innerHTML=`<div class="molding-profile-title">${esc(t('builtInProfiles'))}</div><div class="molding-profile-grid">${list.map(it=>`<button type="button" data-molding-profile="${esc(it.id)}" data-mode="${mode}" class="${it.id===value?'active':''}" title="${esc(it.label)}">${moldingProfileSvg(it.points)}<span>${esc(it.label)}</span></button>`).join('')}</div>`;row.appendChild(gallery)
}
function dormerTypeSvg(item){return `<svg viewBox="0 0 64 64" aria-hidden="true"><path d="${esc(item.path)}"/></svg>`}
function renderDormerTypes(mode){
 const list=window.DRAUPR_DORMER_TYPES||[],container=$(mode==='create'?'createFields':'editFields'),row=container?.querySelector('[data-field="dormer_type"]');if(!row||!list.length)return;
 const value=mode==='create'?S.drafts.dormer.dormer_type:editValues().dormer_type;row.classList.add('dormer-type-field');row.querySelector('.dormer-type-gallery')?.remove();
 const gallery=document.createElement('div');gallery.className='dormer-type-gallery';gallery.innerHTML=`<div class="dormer-type-title">${esc(t('dormerTypes'))}</div><div class="dormer-type-grid">${list.map(item=>`<button type="button" data-dormer-type="${esc(item.id)}" data-mode="${mode}" class="${item.id===value?'active':''}" title="${esc(S.prefs.language==='fa'?item.fa:item.label)}">${dormerTypeSvg(item)}<span>${esc(S.prefs.language==='fa'?item.fa:item.label)}</span></button>`).join('')}</div>`;row.appendChild(gallery)
}
function renderRailingPresets(mode){
 const list=window.DRAUPR_RAILING_PRESETS||[],container=$(mode==='create'?'createFields':'editFields'),row=container?.querySelector('[data-field="preset"]');if(!row||!list.length)return;
 const value=mode==='create'?S.drafts.railing.preset:editValues().preset;row.classList.add('railing-preset-field');row.querySelector('.railing-preset-gallery')?.remove();
 const gallery=document.createElement('div');gallery.className='railing-preset-gallery';gallery.innerHTML=`<div class="railing-preset-title">${esc(t('railingPresets'))}</div><div class="railing-preset-grid">${list.map(it=>`<button type="button" data-railing-preset="${esc(it.id)}" data-mode="${mode}" class="${it.id===value?'active':''}" title="${esc(it.label)}"><img src="${esc(it.thumbnail)}" alt=""><span>${esc(it.label)}</span></button>`).join('')}</div>`;row.appendChild(gallery)
}
function linearPathTool(q){return ['wall','curtain_wall','beam','railing','louver','molding'].includes(q.id)||(q.id==='foundation'&&(S.drafts.foundation||{}).foundation_type==='strip')}
function renderCreate(){
 nav();const q=tools[S.kind];$('toolTitle').textContent=label(q);renderFields($('createFields'),q.fields,S.drafts[S.kind],'create');if(q.id==='molding')renderMoldingProfiles('create');if(q.id==='railing')renderRailingPresets('create');if(q.id==='dormer')renderDormerTypes('create');preview($('createPreview'),S.kind,S.drafts[S.kind]);
 let modes=[q.mode];if(q.mode==='rectangle')modes=['rectangle','rotated'];if(q.id==='railing'||q.id==='curtain_wall')modes=['line','path'];if(q.id==='foundation'){const ft=(S.drafts.foundation||{}).foundation_type;modes=ft==='raft'?['rectangle','rotated']:ft==='strip'?['path']:['point'];}if(q.id==='skylight')modes=['host'];if(q.id==='dormer')modes=['host'];
 const linear=linearPathTool(q),source=$('pathSource');source.hidden=!linear;source.innerHTML=[['draw','drawPath'],['selected','selectedEdges'],['pick','pickConnectedPath']].map(([value,key])=>`<option value="${value}">${esc(t(key))}</option>`).join('');if(!['draw','selected','pick'].includes(S.pathSource))S.pathSource='draw';source.value=S.pathSource;
 $('drawMode').innerHTML=modes.map(m=>`<option value="${m}">${esc(m==='host'&&(q.id==='skylight'||q.id==='dormer')?t('onRoof'):t(m))}</option>`).join('');$('drawMode').hidden=linear&&S.pathSource!=='draw';
 if(linear&&S.pathSource==='selected'){$('draw').textContent=t('generateFromPath')+' '+label(q);$('drawHint').textContent=t('selectedEdgesHint')}else if(linear&&S.pathSource==='pick'){$('draw').textContent=t('pickPath')+' '+label(q);$('drawHint').textContent=t('pickPathHint')}else{$('draw').textContent=t((modes[0]==='point'||(modes[0]==='host'&&!['skylight','dormer'].includes(q.id)))?'place':'draw')+' '+label(q);$('drawHint').textContent=t('drawHint')}
 $('fromFace').disabled=q.mode!=='rectangle'&&q.id!=='molding'
}
function fieldSet(){if(!S.bound.length)return [];return tools[S.bound[0].kind].fields.filter(f=>S.bound.every(x=>tools[x.kind].fields.some(q=>q.key===f.key&&q.type===f.type)))}
function editValues(){const p={};for(const f of fieldSet()){const v=S.bound[0].params[f.key];p[f.key]=S.bound.every(x=>JSON.stringify(x.params[f.key])===JSON.stringify(v))?v:'__mixed__'}return Object.assign(p,S.changes)}
function strip(){const n=S.selection.length;$('selectionStrip').innerHTML=n?`${icon('edit')}<strong>${n} ${esc(t('selection'))}</strong><span>${esc(n===1?S.selection[0].name:'')}</span><button data-workspace="edit">${esc(t('edit'))}</button>`:`${icon('edit')}<span>${esc(t('noSelection'))}</span>`}
function bindSelection(){S.bound=copy(S.selection);S.changes={};$('selectionChanged').hidden=true;renderEdit()}
function selection(items){S.selection=items||[];strip();if(Object.keys(S.changes).length){$('selectionChanged').hidden=JSON.stringify(S.bound.map(x=>x.id))===JSON.stringify(S.selection.map(x=>x.id))}else bindSelection();if(S.ws==='materials'){materialTargets();renderPanels()}}
function renderEdit(){const any=S.bound.length>0;$('editEmpty').hidden=any;$('editEmpty').innerHTML=icon('edit')+esc(t('noSelection'));$('editFields').hidden=!any;$('editPreview').hidden=!any;$('legacyWarning').hidden=!S.bound.some(x=>x.legacy);$('editSummary').innerHTML=S.bound.map(x=>`<span class="chip">${esc(x.name)}</span>`).join('');for(const id of ['applyEdit','cancelEdit','previewEdit','duplicate','saveEditPreset','delete','heal'])$(id).disabled=!any||S.bound.some(x=>x.locked);$('previewEdit').disabled=S.bound.length!==1;if(any){renderFields($('editFields'),fieldSet(),editValues(),'edit');if(S.bound[0].kind==='molding')renderMoldingProfiles('edit');if(S.bound[0].kind==='railing')renderRailingPresets('edit');if(S.bound[0].kind==='dormer')renderDormerTypes('edit');preview($('editPreview'),S.bound[0].kind,editValues())}else $('editFields').innerHTML=''}
let validationTimer;
function changed(mode,key,value){if(value==='__mixed__')return;const p=mode==='create'?S.drafts[S.kind]:S.changes;p[key]=value;if(key==='assembly'){const m={concrete:'Draupr Concrete - Structural',brick:'Draupr Masonry - Brick',stud:'Draupr Timber - Oak'}[value];if(m){p.core_material=m;const input=$(mode+'-core_material');if(input)input.value=m}}const values=mode==='create'?p:editValues(),fields=mode==='create'?tools[S.kind].fields:fieldSet(),container=$(mode==='create'?'createFields':'editFields');container.querySelector(`[data-field="${key}"]`)?.classList.add('dirty');fields.forEach(f=>{const row=container.querySelector(`[data-field="${f.key}"]`);if(row)row.hidden=!visible(f,values)&&values[f.key]!=='__mixed__'});preview($(mode==='create'?'createPreview':'editPreview'),mode==='create'?S.kind:S.bound[0]?.kind,values);if(mode==='create'&&S.kind==='foundation'&&key==='foundation_type')renderCreate();clearTimeout(validationTimer);if(mode==='create'||S.bound.length===1)validationTimer=setTimeout(()=>validate(mode),450)}
async function validate(mode){if(!S.connected)return;const kind=mode==='create'?S.kind:S.bound[0]?.kind;if(!kind)return;const params=mode==='create'?S.drafts[kind]:Object.assign({},S.bound[0].params,S.changes),container=$(mode==='create'?'createFields':'editFields');container.querySelectorAll('.field').forEach(el=>{el.classList.remove('invalid');el.querySelector('.error').textContent=''});try{const d=await request('validate',{kind,params});const el=$(mode==='create'?'createPreview':'editPreview').querySelector('.derived');if(el&&d.derived)el.innerHTML=Object.entries(d.derived).filter(([k,v])=>v!==''&&k!=='warning').map(([k,v])=>`<small>${esc(k)}: ${esc(v)} </small>`).join('')+(d.derived.warning?`<div class="hint">${esc(d.derived.warning)}</div>`:'')}catch(e){for(const [key,message] of Object.entries(e.fields||{})){const row=container.querySelector(`[data-field="${key}"]`);if(row){row.classList.add('invalid');row.querySelector('.error').textContent=message}}}}
async function loadMaterials(){if(S.connected){try{S.materials=await request('materials',{query:$('materialSearch').value,source:S.source})}catch(e){notice(e.message,'error')}}renderMaterials()}
function materialTargets(){const defaults=$('materialScope').value==='defaults',kind=defaults?S.kind:(S.fieldTarget?.kind||S.selection[0]?.kind||S.kind),q=tools[kind];if(!q)return;$('textureAngle').disabled=defaults;const old=$('materialRole').value;$('materialRole').innerHTML=q.roles.map(r=>`<option value="${r.id}">${esc(label(r))}</option>`).join('');if(q.roles.some(r=>r.id===old))$('materialRole').value=old;const parts=S.selection.length===1?S.selection[0].parts:[];const selected=$('materialPart').value;$('materialPart').innerHTML=`<option value="">${esc(t('selectPart'))}</option>`+parts.map(p=>`<option value="${esc(p.key)}">${esc(p.name||p.key)}</option>`).join('');if(parts.some(p=>p.key===selected))$('materialPart').value=selected;$('materialPart').disabled=S.selection.length!==1;$('panelEditor').hidden=!(S.selection.length===1&&S.selection[0].kind==='curtain_wall')}
function renderMaterials(){
 $('materialSources').innerHTML=['all','model','library','favorites','recent'].map(k=>`<button data-source="${k}" class="${S.source===k?'active':''}">${esc(t(k))}</button>`).join('');
 let items=S.materials.items||[];const query=$('materialSearch').value.toLowerCase();if(!S.connected){items=items.filter(m=>m.name.toLowerCase().includes(query));if(S.source==='favorites')items=items.filter(m=>m.favorite)}
 $('materialCount').textContent=`${items.length} / ${S.materials.total||items.length}`;
 $('swatches').innerHTML=items.map(m=>{const c=/^#[0-9a-f]{6}$/i.test(m.color)?m.color:'#bdc9da',thumb=m.thumbnail?.startsWith('data:image/png;base64,')?m.thumbnail:null;return `<button class="swatch ${S.material===m.name?'active':''}" data-material="${esc(m.name)}" title="${esc(m.name)}"><span class="swatch-preview">${thumb?`<img src="${thumb}" alt="">`:`<div style="background:${c};opacity:${Math.max(0,Math.min(100,m.opacity??100))/100}"></div>`}</span><span class="swatch-name">${esc(m.name)}</span>${m.favorite?'<span class="star">★</span>':''}</button>`}).join('');
 const m=S.materials.items.find(m=>m.name===S.material);$('materialDetail').innerHTML=m?`<strong>${esc(m.name)}</strong><span>${esc(t('opacity'))}: ${m.opacity}</span><button id="toggleMaterialFavorite">${m.favorite?'★':'☆'} ${esc(t('favorite'))}</button><button id="openMaterialEditor">${esc(t('editMaterial'))}</button>`:'';
 const target=$('materialFieldTarget');target.hidden=!S.fieldTarget;if(S.fieldTarget){const f=tools[S.fieldTarget.kind].fields.find(f=>f.key===S.fieldTarget.key);target.innerHTML=`${esc(label(tools[S.fieldTarget.kind]))} · ${esc(label(f))}<div class="secondary-actions"><button data-use-field class="primary">${esc(t('useMaterial'))}</button><button data-cancel-field>${esc(t('cancel'))}</button></div>`}
 materialTargets();renderPanels();
}
function renderPanels(){const obj=S.selection.length===1?S.selection[0]:null;const show=obj?.kind==='curtain_wall';$('panelEditor').hidden=!show;if(!show)return;const nx=obj.derived.columns||1,ny=obj.derived.rows||1,overrides=obj.params.panel_overrides||{};$('panelMap').style.gridTemplateColumns=`repeat(${nx},minmax(28px,1fr))`;let html='';for(let j=ny-1;j>=0;j--)for(let i=0;i<nx;i++){const k=`panel_${j}_${i}`,type=overrides[k]?.type||'vision';html+=`<button class="${type==='spandrel'?'spandrel':type==='open'?'open':''} ${S.panel===k?'active':''}" data-panel="${k}" title="R${j+1} C${i+1}">${j+1}:${i+1}</button>`}$('panelMap').innerHTML=html}
function renderLibrary(){let list=S.library.filter(p=>p.name.toLowerCase().includes($('presetSearch').value.toLowerCase()));if($('favoriteOnly').classList.contains('active'))list=list.filter(p=>p.favorite);$('presets').innerHTML=list.length?list.map(p=>`<article class="preset">${icon(p.kind)}<h3>${esc(p.name)}</h3><small>${esc(label(tools[p.kind]))}</small><div class="secondary-actions"><button data-load-preset="${esc(p.id)}">${esc(t('loadPreset'))}</button><button data-favorite-preset="${esc(p.id)}">${p.favorite?'★':'☆'}</button><button data-rename-preset="${esc(p.id)}">${esc(t('rename'))}</button><button data-delete-preset="${esc(p.id)}" class="danger">×</button></div></article>`).join(''):`<div class="empty">${esc(t('noPresets'))}</div>`}
async function loadLibraryObjects(){if(!S.connected)return;try{const d=await request('libraryList',{});S.libraryFolder=d.folder;S.libraryItems=d.items||[]}catch(e){notice(e.message,'error')}renderLibraryObjects()}
function renderLibraryObjects(){const f=$('libraryFolder');if(f)f.value=S.libraryFolder||'';const g=$('libraryGrid');if(!g)return;const q=($('objectSearch')?.value||'').toLowerCase();const items=(S.libraryItems||[]).filter(it=>[it.name,it.category,it.description,...(it.tags||[])].join(' ').toLowerCase().includes(q));$('libraryStatus').textContent=`${items.length} / ${(S.libraryItems||[]).length}`;g.innerHTML=items.length?items.map(it=>`<article class="preset library-item">${it.thumb?`<img src="${it.thumb}" alt="">`:`<div class="thumb-empty">${icon('library')}</div>`}<h3>${esc(it.name)}</h3><small>${esc(it.category||t('uncategorized'))}${it.tags?.length?' · '+esc(it.tags.join(', ')):''}<br>${it.draupr?it.draupr+' param. ':''}${it.faces?it.faces+' faces ':''}· ${Math.ceil((it.size||0)/1024)} KB</small><div class="secondary-actions"><button data-lib-place="${esc(it.file)}">${esc(t('create'))}</button><button data-lib-replace="${esc(it.file)}">${esc(t('replace'))}</button><button data-lib-edit="${esc(it.file)}">${esc(t('edit'))}</button><button data-lib-rename="${esc(it.file)}">${esc(t('rename'))}</button><button data-lib-delete="${esc(it.file)}" class="danger">×</button></div></article>`).join(''):`<div class="empty">${esc(t('noObjects'))}</div>`}
async function loadRailingSources(){if(!S.connected)return;try{S.railingSources=await request('railingLibraryStatus',{})}catch(e){notice(e.message,'error')}renderRailingSources()}
function renderRailingSources(){const d=S.railingSources||{folder:'',sources:[],valid:0,missing:[]},f=$('railingLibraryFolder'),out=$('railingSourceStatus');if(f)f.value=d.folder||'';if(!out)return;out.innerHTML=`<b>${d.valid||0} ${esc(t('validSources'))}</b> · ${(d.missing||[]).length} ${esc(t('missingSources'))}<br>${(d.sources||[]).map(x=>`${x.valid?'✓':'✕'} ${esc(x.file)}${x.valid?' · '+Math.ceil((x.size||0)/1024)+' KB':''}`).join('<br>')}`;}

function projectNav(){const tabs=['levels','reports','health','settings'];$('projectTabs').innerHTML=tabs.map(k=>`<button class="${S.projectTab===k?'active':''}" data-project-tab="${k}">${esc(t(k))}</button>`).join('');tabs.forEach(k=>$('project-'+k).hidden=S.projectTab!==k)}
function renderLevels(){$('levels').innerHTML=S.project.levels.map(l=>`<div class="level-row" data-level-id="${esc(l.id)}"><input type="radio" name="activeLevel" value="${esc(l.id)}" ${l.id===S.project.activeLevel?'checked':''} aria-label="${esc(t('active'))}"><input data-level-name value="${esc(l.name)}" aria-label="${esc(t('name'))}"><input data-level-z value="${esc(l.elevation)}" aria-label="Elevation"><button data-remove-level="${esc(l.id)}" aria-label="Remove level">×</button></div>`).join('')}
function collectLevels(){S.project.levels=[...$('levels').querySelectorAll('.level-row')].map(row=>({id:row.dataset.levelId,name:row.querySelector('[data-level-name]').value,elevation:row.querySelector('[data-level-z]').value}));S.project.activeLevel=$('levels').querySelector('input:checked')?.value||S.project.levels[0]?.id}
function renderQuantities(){const oldType=$('reportType').value,oldLevel=$('reportLevel').value;const types=[...new Set(S.reports.map(r=>r.type))],levels=[...new Set(S.reports.map(r=>r.level))];$('reportType').innerHTML=`<option value="">${esc(t('all'))} · ${esc(t('type'))}</option>`+types.map(v=>`<option value="${esc(v)}">${esc(label(tools[v]||{label:v}))}</option>`).join('');$('reportLevel').innerHTML=`<option value="">${esc(t('all'))} · ${esc(t('level'))}</option>`+levels.map(v=>`<option value="${esc(v)}">${esc(v)}</option>`).join('');$('reportType').value=types.includes(oldType)?oldType:'';$('reportLevel').value=levels.includes(oldLevel)?oldLevel:'';const rows=S.reports.filter(r=>(!oldType||r.type===oldType)&&(!oldLevel||r.level===oldLevel));$('quantities').innerHTML=`<table><thead><tr>${['name','type','level','length','area','volume'].map(k=>`<th>${esc(t(k))}</th>`).join('')}</tr></thead><tbody>${rows.map(r=>`<tr><td>${esc(r.name)}${r.scaled?' ⚠':''}</td><td>${esc(label(tools[r.type]||{label:r.type}))}</td><td>${esc(r.level)}</td><td>${esc(r.length_display??r.length_mm??'—')}</td><td>${esc(r.area_m2??'—')}</td><td>${esc(r.volume_m3??'—')}</td></tr>`).join('')}</tbody></table>`}
function renderAll(){$('refresh').innerHTML='<svg class="icon" viewBox="0 0 24 24"><path d="M20 7v5h-5M20 12a8 8 0 1 0-2 6M20 12l-3-5"/></svg>';applyLanguage();nav();strip();renderCreate();renderEdit();renderMaterials();renderLibrary();projectNav();renderLevels();enhanceModifierIcons();if(S.ws==='library'){loadLibraryObjects();loadRailingSources();}$('units').value=S.prefs.units;$('theme').value=S.prefs.theme;$('keepDrawing').checked=S.prefs.keep_drawing}
let modalResolve;
function modal(title,body,submit=t('save')){return new Promise(resolve=>{$('modalTitle').textContent=title;$('modalBody').innerHTML=body;$('modalSubmit').textContent=submit;modalResolve=resolve;$('modal').showModal()})}
function closeModal(value=null){$('modal').close();if(modalResolve){modalResolve(value);modalResolve=null}}
async function confirmAction(message){return !!(await modal(t('choose'),`<p>${esc(message)}</p>`,t('apply')))}
function presetSource(){if(S.ws==='edit'&&S.bound.length===1)return {kind:S.bound[0].kind,params:Object.assign({},S.bound[0].params,S.changes)};return {kind:S.kind,params:S.drafts[S.kind]}}
async function savePreset(existing=null){const source=existing||presetSource();const data=await modal(t('savePreset'),`<label>${esc(t('presetName'))}<input name="name" required maxlength="100" value="${esc(existing?.name||'')}"></label>`);if(!data)return;S.library=await run('savePreset',{...source,name:data.name,id:existing?.id,favorite:existing?.favorite||false},t('saved'));renderLibrary()}
async function openMaterialEditor(){const m=S.materials.items.find(m=>m.name===S.material);if(!m)return;const data=await modal(t('editMaterial'),`<p>${esc(m.name)}</p><label class="check"><input name="duplicate" type="checkbox" checked><span>${esc(t('duplicateMaterial'))}</span></label><label>${esc(t('duplicateName'))}<input name="newName" value="${esc(m.name+' Copy')}"></label><div class="two-col"><label>${esc(t('color'))}<input name="color" type="color" value="${esc(m.color)}"></label><label>${esc(t('opacity'))}<input name="opacity" type="number" min="0" max="100" value="${m.opacity}"></label></div>${m.texture?`<div class="two-col"><label>${esc(t('textureWidth'))}<input name="textureWidth" value="${esc(m.size?.[0]||'1000 mm')}"></label><label>${esc(t('textureHeight'))}<input name="textureHeight" value="${esc(m.size?.[1]||'1000 mm')}"></label></div>`:''}<label class="check"><input name="confirmed" type="checkbox"><span>${esc(t('sharedConfirm'))}</span></label>`);if(!data)return;S.material=await run('editMaterial',{name:m.name,...data},t('saved'));await loadMaterials()}
function setFieldMaterial(target,name){if(!target)return;if(target.mode==='edit')changed('edit',target.key,name);else S.drafts[target.kind][target.key]=name;S.fieldTarget=null;S.sampleTarget=null;workspace(target.mode==='edit'?'edit':'create');if(target.mode==='edit')renderEdit();else{S.kind=target.kind;S.category=tools[target.kind].category;renderCreate()}}
function applyState(d){Object.assign(S.prefs,d.preferences||{});S.drafts=Object.assign(S.drafts,d.defaults||{});S.materials=d.materials||S.materials;S.project=d.project||S.project;S.library=d.library||[];S.category=schema.categories.some(c=>c.id===S.prefs.category)?S.prefs.category:'envelope';S.kind=tools[S.prefs.tool]?S.prefs.tool:'wall';S.category=tools[S.kind].category;S.ws=d.workspace||S.prefs.workspace||'create';if(!['create','edit','modify','materials','library','project'].includes(S.ws))S.ws='create';selection(d.selection||[]);renderAll()}
window.Draupr={state:S,receive(message){const d=message.payload||{};switch(message.type){case 'response':{const pending=S.pending.get(d.id);if(!pending)return;clearTimeout(pending.timer);S.pending.delete(d.id);if(d.ok)pending.resolve(d.data);else{const e=new Error(d.message||'Command failed');e.fields=d.fields;pending.reject(e)}break}case 'selection':selection(d.selection);break;case 'notice':notice(d.message,d.kind);break;case 'workspace':if(d.workspace)workspace(d.workspace);break;case 'sampled':S.material=d.material;if(S.sampleTarget)setFieldMaterial(S.sampleTarget,d.material);else{workspace('materials');loadMaterials()}break;case 'partPicked':request('selection').then(items=>{selection(items);S.panel=d.part;workspace('materials');materialTargets();$('materialScope').value='part';$('materialPart').value=d.part;$('materialRole').value=d.role;renderPanels()}).catch(e=>notice(e.message,'error'));break}}};
async function clicked(event){const b=event.target.closest('button');if(!b)return;
 if(b.dataset.workspace){workspace(b.dataset.workspace);return}
 if(b.dataset.tool){S.kind=b.dataset.tool;S.category=tools[S.kind].category;renderCreate();if(S.connected)request('preferences',{tool:S.kind,category:S.category}).catch(()=>{});return}
 if(b.dataset.moldingProfile){const mode=b.dataset.mode||'create',value=b.dataset.moldingProfile;if(mode==='create'){S.drafts.molding.profile=value;const el=$('create-profile');if(el)el.value=value;changed('create','profile',value);renderMoldingProfiles('create')}else{const el=$('edit-profile');if(el)el.value=value;changed('edit','profile',value);renderMoldingProfiles('edit')}return}
 if(b.dataset.dormerType){const mode=b.dataset.mode||'create',value=b.dataset.dormerType;if(mode==='create'){S.drafts.dormer.dormer_type=value;const el=$('create-dormer_type');if(el)el.value=value;changed('create','dormer_type',value);renderDormerTypes('create')}else{const el=$('edit-dormer_type');if(el)el.value=value;changed('edit','dormer_type',value);renderDormerTypes('edit')}return}
 if(b.dataset.railingPreset){const mode=b.dataset.mode||'create',value=b.dataset.railingPreset;if(mode==='create'){S.drafts.railing.preset=value;const el=$('create-preset');if(el)el.value=value;changed('create','preset',value);renderRailingPresets('create')}else{const el=$('edit-preset');if(el)el.value=value;changed('edit','preset',value);renderRailingPresets('edit')}return}
 if(b.dataset.source){S.source=b.dataset.source;await loadMaterials();return}
 if(b.dataset.material){S.material=b.dataset.material;renderMaterials();return}
 if(b.dataset.browseField){const mode=b.dataset.mode;S.fieldTarget={mode,kind:mode==='edit'?S.bound[0].kind:S.kind,key:b.dataset.browseField};workspace('materials');renderMaterials();return}
 if(b.dataset.sampleField){const mode=b.dataset.mode;S.sampleTarget={mode,kind:mode==='edit'?S.bound[0].kind:S.kind,key:b.dataset.sampleField};await run('sample',{},t('toolActive'));return}
 if(b.hasAttribute('data-use-field')){if(!S.material)throw new Error(t('noMaterial'));setFieldMaterial(S.fieldTarget,S.material);return}
 if(b.hasAttribute('data-cancel-field')){S.fieldTarget=null;renderMaterials();return}
 if(b.dataset.panel){S.panel=b.dataset.panel;$('materialScope').value='part';$('materialPart').value=S.panel;const p=S.selection[0].params.panel_overrides?.[S.panel];$('panelType').value=p?.type||'vision';renderPanels();return}
 if(b.dataset.libPlace){const d=await modal(t('placement'),`<div class="two-col"><label>${esc(t('rotation'))}<input name="rotation" type="number" value="0"></label><label>${esc(t('scale'))}<input name="scale" type="number" min="0.01" step="0.1" value="1"></label></div><label class="check"><input name="align" type="checkbox"><span>${esc(t('alignSurface'))}</span></label>`,t('create'));if(d)await run('libraryPlace',{file:b.dataset.libPlace,rotation:d.rotation,scale:d.scale,align:d.align},t('toolActive'));return}
 if(b.dataset.libReplace){if(await confirmAction(t('replaceConfirm'))){selection(await run('libraryReplace',{file:b.dataset.libReplace},t('done')))}return}
 if(b.dataset.libEdit){const it=S.libraryItems.find(x=>x.file===b.dataset.libEdit),d=await modal(t('edit'),`<label>${esc(t('category'))}<input name="category" value="${esc(it.category||'')}"></label><label>${esc(t('tags'))}<input name="tags" value="${esc((it.tags||[]).join(', '))}"></label><label>${esc(t('description'))}<input name="description" value="${esc(it.description||'')}"></label>`);if(d){await run('libraryMetadata',{file:it.file,...d},t('saved'));loadLibraryObjects()}return}
 if(b.dataset.libRename){const it=S.libraryItems.find(x=>x.file===b.dataset.libRename),d=await modal(t('rename'),`<label>${esc(t('name'))}<input name="name" value="${esc(it.name)}"></label>`);if(d){await run('libraryRename',{file:it.file,name:d.name},t('saved'));loadLibraryObjects()}return}
 if(b.dataset.libDelete){if(await confirmAction(t('delete')+'?')){await run('libraryDelete',{file:b.dataset.libDelete});loadLibraryObjects()}return}
 if(b.dataset.loadPreset){const p=S.library.find(p=>p.id===b.dataset.loadPreset);S.kind=p.kind;S.category=tools[p.kind].category;S.drafts[p.kind]=copy(p.params);workspace('create');renderCreate();return}
 if(b.dataset.favoritePreset){const p=S.library.find(p=>p.id===b.dataset.favoritePreset);S.library=await run('favoritePreset',{id:p.id,value:!p.favorite});renderLibrary();return}
 if(b.dataset.renamePreset){await savePreset(S.library.find(p=>p.id===b.dataset.renamePreset));return}
 if(b.dataset.deletePreset){if(await confirmAction(t('delete')+'?')){S.library=await run('deletePreset',{id:b.dataset.deletePreset});renderLibrary()}return}
 if(b.dataset.projectTab){S.projectTab=b.dataset.projectTab;projectNav();return}
 if(b.dataset.removeLevel){collectLevels();S.project.levels=S.project.levels.filter(l=>l.id!==b.dataset.removeLevel);if(S.project.activeLevel===b.dataset.removeLevel)S.project.activeLevel=S.project.levels[0]?.id;renderLevels();return}
 const id=b.id,ids=S.bound.map(x=>x.id);
 switch(id){
 case 'draw':case 'origin':case 'fromFace':{const kind=S.kind,params=S.drafts[kind];let action=id==='draw'?'draw':id==='origin'?'origin':'fromFace';if(id==='draw'&&!$('pathSource').hidden){action=S.pathSource==='selected'?'fromEdges':S.pathSource==='pick'?'pickPath':'draw'}await run(action,{kind,params,mode:$('drawMode').value},action==='draw'||action==='pickPath'?t('toolActive'):t('done'));request('defaults',{kind,params}).catch(()=>{});break}
 case 'refresh':if(Object.keys(S.changes).length&&!(await confirmAction(t('discard')+'?')))break;S.changes={};applyState(await run('refresh'));break;
 case 'saveDefaults':await run('defaults',{kind:S.kind,params:S.drafts[S.kind]},t('saved'));break;
 case 'refreshSelection':if(Object.keys(S.changes).length&&!(await confirmAction(t('discard')+'?')))break;S.changes={};selection(await run('selection'));break;
 case 'cancelEdit':S.changes={};bindSelection();break;
 case 'applyEdit':if(!Object.keys(S.changes).length){notice(t('noChanges'));break}{const result=await run('edit',{ids,changes:S.changes},t('applied'));S.changes={};selection(result)}break;
 case 'previewEdit':if(S.bound.length===1)await run('previewEdit',{id:ids[0],changes:S.changes},t('previewHint'));break;
 case 'duplicate':if(S.bound.length===1){const obj=S.bound[0];S.kind=obj.kind;S.category=tools[obj.kind].category;S.drafts[obj.kind]=Object.assign({},obj.params,S.changes);['name','mark'].forEach(k=>S.drafts[obj.kind][k]='');S.changes={};workspace('create');renderCreate();await run('draw',{kind:S.kind,params:S.drafts[S.kind],mode:S.kind==='foundation'?((S.drafts[S.kind]||{}).foundation_type==='raft'?'rectangle':(S.drafts[S.kind]||{}).foundation_type==='strip'?'path':'point'):tools[S.kind].mode},t('toolActive'))}break;
 case 'adopt':selection(await run('adopt',{},t('done')));break;
 case 'delete':if(await confirmAction(t('deleteConfirm'))){await run('delete',{ids,confirmed:true},t('done'));S.changes={};selection([])}break;
 case 'heal':if(await confirmAction(t('healConfirm'))){await run('heal',{ids,confirmed:true},t('done'));S.changes={};selection(await run('selection'))}break;
 case 'saveCreatePreset':case 'saveEditPreset':case 'saveLibraryPreset':await savePreset();break;
 case 'libraryBrowse':await run('librarySetFolder');loadLibraryObjects();break;
 case 'librarySave':{const data=await modal(t('saveObject'),`<label>${esc(t('name'))}<input name="name" required maxlength="100"></label><label>${esc(t('category'))}<input name="category"></label><label>${esc(t('tags'))}<input name="tags" placeholder="chair, classic, wood"></label><label>${esc(t('description'))}<input name="description"></label>`);if(data){await run('librarySave',data,t('saved'));loadLibraryObjects()}break}
 case 'libraryRefresh':loadLibraryObjects();break;
 case 'libraryOpenFolder':await run('libraryOpenFolder');break;
 case 'libraryDiagnostics':{const d=await run('libraryDiagnostics');$('libraryStatus').textContent=`${d.valid} valid · ${d.broken.length} broken`;if(d.broken.length)notice(d.broken.map(x=>x.file+': '+x.error).join(' | '),'error');break}
 case 'railingLibraryBrowse':await run('railingLibrarySetFolder');loadRailingSources();break;
 case 'railingLibraryOpen':await run('railingLibraryOpenFolder');break;
 case 'railingLibraryRefresh':loadRailingSources();break;
 case 'railingLibraryDiagnostics':{const d=await run('railingLibraryDiagnostics');S.railingSources=d;renderRailingSources();if(d.missing.length)notice(d.missing.join(', '),'error');break}
 case 'favoriteOnly':b.classList.toggle('active');renderLibrary();break;
 case 'importPresets':S.library=await run('importPresets');renderLibrary();break;
 case 'exportPresets':await run('exportPresets');break;
 case 'sample':S.sampleTarget=null;await run('sample',{},t('toolActive'));break;
 case 'pickPart':await run('pickPart',{},t('toolActive'));break;
 case 'importTexture':{const name=await run('importTexture');if(name)S.material=name;await loadMaterials();break}
 case 'toggleMaterialFavorite':{const m=S.materials.items.find(m=>m.name===S.material);await run('materialFavorite',{name:m.name,value:!m.favorite});await loadMaterials();break}
 case 'openMaterialEditor':await openMaterialEditor();break;
 case 'assignMaterial':{if(!S.material)throw new Error(t('noMaterial'));const scope=$('materialScope').value,role=$('materialRole').value;await run('assign',{material:S.material,scope,role,part:$('materialPart').value,angle:$('textureAngle').value,kind:S.kind,ids:S.selection.map(x=>x.id)},t('applied'));if(scope==='defaults'){tools[S.kind].roles.filter(r=>!role||r.id===role).forEach(r=>S.drafts[S.kind][r.key]=S.material);renderCreate()}else selection(await run('selection'));break}
 case 'applyPanel':if(!S.panel)throw new Error(t('selectPart'));await run('panel',{id:S.selection[0]?.id,part:S.panel,type:$('panelType').value,material:$('panelUseMaterial').checked?S.material||'':''},t('applied'));selection(await run('selection'));break;
 case 'addLevel':collectLevels();S.project.levels.push({id:'level-'+Date.now().toString(36)+'-'+Math.random().toString(36).slice(2,7),name:t('level')+' '+(S.project.levels.length+1),elevation:'3000 mm'});renderLevels();break;
 case 'saveLevels':collectLevels();S.project=await run('levels',{levels:S.project.levels,active:S.project.activeLevel},t('saved'));renderLevels();renderCreate();break;
 case 'loadQuantities':S.reports=await run('quantities');renderQuantities();break;
 case 'roofIntersection':case 'roofValley':case 'roofJoin':case 'alignFaces':case 'wallTrim':case 'wallSplit':case 'modifySplit':case 'modifyTrim':case 'modifyAlignBaseline':case 'modifyHealOpening':await run(id,{},['roofIntersection','roofValley'].includes(id)?t('done'):t('toolActive'));break;
 case 'attachTop':await run('modifyAttachBoundary',{boundary:'top'},t('toolActive'));break;
 case 'attachBase':await run('modifyAttachBoundary',{boundary:'base'},t('toolActive'));break;
 case 'detachBoundary':selection(await run('modifyDetachBoundary',{},t('done')));break;
 case 'modifyStep':{const d=await modal(t('stepHeight'),`<label>Step delta / اختلاف ارتفاع<input name="delta" value="300 mm"></label>`,t('apply'));if(d)await run('modifyStep',d,t('toolActive'));break}
 case 'modifyJunction':{const d=await modal(t('junctionSwitcher'),`<label>Junction type / نوع اتصال<select name="mode"><option value="butt_left">Butt · left through</option><option value="butt_right">Butt · right through</option><option value="miter">True miter</option><option value="square">Square off</option><option value="fillet">Radius fillet</option><option value="chamfer">Chamfer corner</option></select></label><label>Radius / شعاع<input name="radius" value="300 mm"></label>`,t('apply'));if(d)await run('modifyJunction',d,t('toolActive'));break}
 case 'modifySplayOpening':{const d=await modal(t('splayOpening'),`<div class="two-col"><label>Jamb splay (0–45°)<input name="angle" type="number" min="0" max="45" value="10"></label><label>Sill slope (0–15°)<input name="sillSlope" type="number" min="0" max="15" value="5"></label></div><label>Casing setback / عقب‌نشینی<input name="setback" value="25 mm"></label>`,t('apply'));if(d)await run('modifySplayOpening',d,t('toolActive'));break}
 case 'modifySweep':{const d=await modal(t('profileRegistration'),`<label>Profile anchor / نقطه مبنا<select name="anchor"><option value="left_top">Top Left</option><option value="center_top">Top Center</option><option value="right_top">Top Right</option><option value="left_middle">Middle Left</option><option value="center">Center</option><option value="right_middle">Middle Right</option><option value="left_bottom">Bottom Left</option><option value="center_bottom">Bottom Center</option><option value="right_bottom">Bottom Right</option></select></label><label class="check"><input name="flip" type="checkbox"><span>Flip normal / معکوس کردن سمت</span></label><label class="check"><input name="startReturn" type="checkbox"><span>Start return / برگشت ابتدا</span></label><label class="check"><input name="endReturn" type="checkbox"><span>End return / برگشت انتها</span></label><label>Return length / طول برگشت<input name="returnLength" value="50 mm"></label>`,t('apply'));if(d)await run('modifySweep',d,t('toolActive'));break}
 case 'modifyDisassemble':if(await confirmAction('Disassembly is one-way and removes parametric editing. Continue? / جداسازی یک‌طرفه است و ویرایش پارامتریک را حذف می‌کند. ادامه؟'))await run('modifyDisassemble',{ids:S.selection.map(x=>x.id),confirmed:true},t('done'));break;
 case 'modifyEdgeDetail':{const d=await modal(t('edgeDetail'),`<label>Style / نوع<select name="style"><option value="chamfer">Chamfer / پخ</option><option value="bullnose">Bullnose / گرده</option></select></label><label>Size / اندازه<input name="size" value="20 mm"></label><small>Preselect edges, or click Apply and then click a visible edge. / لبه‌ها را از قبل انتخاب کنید، یا پس از اعمال روی یک لبه کلیک کنید.</small>`,t('apply'));if(d)await run('modifyEdgeDetail',d,t('toolActive'));break}
 case 'exportQuantities':case 'exportSchedule':case 'exportMaterials':case 'exportLevels':case 'scenes':case 'diagnostics':await run(id);break;
 case 'sync':await run('sync',{},t('done'));selection(await run('selection'));break;
 case 'audit':{const data=await run('audit');$('auditResults').innerHTML=`<div class="card"><h2>${data.objects} ${esc(t('selection'))}</h2>${data.warnings.length?`<ul class="issues">${data.warnings.map(m=>`<li>${esc(m)}</li>`).join('')}</ul>`:esc(t('ready'))}</div>`;break}
 case 'nativeTest':{const data=await run('nativeTest');if(data)$('auditResults').innerHTML=`<div class="card"><pre>${esc(JSON.stringify(data,null,2))}</pre></div>`;break}
 case 'cancelTool':await run('cancelTool',{},t('ready'));break;
 case 'closeModal':case 'modalCancel':closeModal();break;
 }
}
document.addEventListener('click',e=>clicked(e).catch(e=>notice(e.message,'error')));
for(const mode of ['create','edit'])$(mode+'Fields').addEventListener('input',e=>{const el=e.target;if(!el.dataset.key)return;changed(mode,el.dataset.key,el.type==='checkbox'?el.checked:el.value)});
$('category').addEventListener('change',()=>{S.category=$('category').value;S.kind=schema.tools.find(q=>q.category===S.category).id;renderCreate()});
$('pathSource').addEventListener('change',()=>{S.pathSource=$('pathSource').value;renderCreate()});
$('language').addEventListener('change',()=>{S.prefs.language=$('language').value;renderAll();if(S.connected)request('preferences',{language:S.prefs.language}).catch(()=>{})});
for(const id of ['units','theme','keepDrawing'])$(id).addEventListener('change',async()=>{const key=id==='keepDrawing'?'keep_drawing':id;S.prefs[key]=id==='keepDrawing'?$(id).checked:$(id).value;applyLanguage();if(S.connected){if(id==='units')applyState(await run('changeUnits',{units:S.prefs.units},t('saved')));else await run('preferences',{[key]:S.prefs[key]},t('saved'))}});
$('materialScope').addEventListener('change',materialTargets);
let searchTimer;$('materialSearch').addEventListener('input',()=>{clearTimeout(searchTimer);searchTimer=setTimeout(loadMaterials,250)});$('presetSearch').addEventListener('input',renderLibrary);
$('reportType').addEventListener('change',renderQuantities);$('reportLevel').addEventListener('change',renderQuantities);
$('modalForm').addEventListener('submit',e=>{e.preventDefault();const d=Object.fromEntries(new FormData($('modalForm')));$('modalForm').querySelectorAll('input[type=checkbox][name]').forEach(el=>d[el.name]=el.checked);closeModal(d)});
$('modal').addEventListener('cancel',e=>{e.preventDefault();closeModal()});
function setNavCollapsed(value){
 document.body.classList.toggle('nav-collapsed',value);
 $('navCollapse').textContent=value?'▶':'◀';
 $('navCollapse').setAttribute('aria-expanded',String(!value));
 try{localStorage.setItem('draupr-nav-collapsed',value?'1':'0')}catch(_e){}
}
$('navCollapse').addEventListener('click',()=>setNavCollapsed(!document.body.classList.contains('nav-collapsed')));
try{setNavCollapsed(localStorage.getItem('draupr-nav-collapsed')==='1')}catch(_e){setNavCollapsed(false)}
function demoMaterials(){const names=[...new Set(schema.tools.flatMap(q=>q.fields.filter(f=>f.type==='material').map(f=>f.default)))];S.materials={names,total:names.length,items:names.map((name,i)=>({name,color:name.includes('Glass')?'#83bedb':name.match(/Timber|Walnut/)?'#aa815b':name.match(/Mullion|Steel/)?'#536072':name.includes('Brick')?'#af776a':'#c6c6bd',opacity:name.includes('Glass')?35:100,inModel:false,texture:false,favorite:false,category:'other'}))}}
async function connect(attempt=0){if(window.sketchup&&typeof window.sketchup.studioCommand==='function'){try{const d=await request('ready');S.connected=true;$('connection').textContent=t('connected');$('offline').hidden=true;applyState(d);notice(t('ready'));return}catch(e){notice(e.message,'error')}}if(attempt<10){setTimeout(()=>connect(attempt+1),200);return}S.connected=false;$('connection').textContent=t('preview');$('offline').hidden=false;notice(t('offline'))}
window.Draupr.__test={request,renderAll,bindSelection,workspace,tools,schema,esc};
demoMaterials();renderAll();connect();
$('objectSearch')?.addEventListener('input',renderLibraryObjects);
})();
