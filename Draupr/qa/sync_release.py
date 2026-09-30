from pathlib import Path
import json,re
r=Path(__file__).resolve().parents[2]
rel=json.loads((r/'Draupr/src/config/release.json').read_text());schema_path=r/'Draupr/src/config/schema.json';schema=json.loads(schema_path.read_text());schema['version']=rel['version']
tool_count=len(schema['tools']);field_count=sum(len(t.get('fields',[])) for t in schema['tools']);assert tool_count==rel['tool_count'];assert field_count==rel['field_count']
schema_path.write_text(json.dumps(schema,ensure_ascii=False,indent=2)+'\n');(r/'Draupr/src/ui/schema.js').write_text('window.DRAUPR_SCHEMA = '+json.dumps(schema,ensure_ascii=False,indent=2)+';\n')
panel=r/'Draupr/src/ui/panel.html';s=panel.read_text();s=re.sub(r'<small id="version">[^<]+</small>',f'<small id="version">{rel["version"]} · {rel["status"]}</small>',s);panel.write_text(s)
audit={'release':f'{rel["version"]} {rel["status"]}','tool_count':tool_count,'field_count':field_count,'workspace_count':rel['workspace_count'],'data_schema_version':rel['data_schema_version'],'tool_field_counts':{t['id']:len(t.get('fields',[])) for t in schema['tools']},'tool_ids':[t['id'] for t in schema['tools']],'unique_tool_ids':len({t['id'] for t in schema['tools']})==tool_count,'schema_js_generated':True,'native_tested':False}
(r/'Draupr/qa/schema-audit.json').write_text(json.dumps(audit,indent=2)+'\n')
tool_lines='\n'.join(f'- [ ] `{t["id"]}`: create, edit, transform, delete, Undo/Redo, save/reload' for t in schema['tools'])
accept=f"""# Draupr {rel["version"]} Native Acceptance Checklist\n\n**Status:** not executed in the build sandbox. `native_tested` remains false.\n\nGenerated scope: **{tool_count} tools**, **{field_count} fields**, **{rel["workspace_count"]} workspaces**.\n\n## Tool matrix\n\n{tool_lines}\n\n## Relationship and persistence gates\n\n- [ ] Hosted openings: two per wall/roof; move, resize, delete, heal, Undo/Redo, save/reload.\n- [ ] Wall junctions: Butt/Miter/Square Off at 45°, 60°, 90°, 120°, and 135°; swap priority and edit peers.\n- [ ] Roof edge-to-face joins: gable/hip, target holes, multiple joins, Undo/Redo, save/reload.\n- [ ] Local railings: configure folder, validate all expected filenames, horizontal/sloped/L paths.\n- [ ] Molding: horizontal/sloped/connected paths, 35 profiles, anchor/flip/rotation/smoothing.\n- [ ] Preferences migrate from legacy `.040` keys without losing values.\n- [ ] Legacy object inference flags ambiguous levels and never silently adopts the active level.\n- [ ] Plan/Elevation scene command is idempotent and uses the active Project level.\n- [ ] Test EN/FA, RTL, 420/610/900 px, all unit modes, Windows/macOS, and supported SketchUp versions.\n\nDo not mark the release Stable or set `native_tested` true until applicable native cases pass.\n"""
(r/'Draupr/qa/NATIVE_ACCEPTANCE.md').write_text(accept)
# Synchronize only current-release headings; never rewrite historical release notes.
patterns={
 'README.md':(r'^# Draupr Studio [^\n]+',f'# Draupr Studio {rel["version"]} — {rel["status"]}'),
 'DRAUPR_BUILD_REPORT.md':(r'^# Draupr [^\n]+ Build Report',f'# Draupr {rel["version"]} {rel["status"]} Build Report'),
 'DRAUPR_DEVELOPER_GUIDE.md':(r'^# Draupr v[^ ]+',f'# Draupr v{rel["version"]}')}
for name,(pattern,replacement) in patterns.items():
 p=r/name
 if p.exists():
  x=p.read_text();x=re.sub(pattern,replacement,x,count=1,flags=re.M);p.write_text(x)
print(rel['version'],tool_count,field_count)
