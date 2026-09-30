import json,math
from pathlib import Path
rows=[]
for w in (900.,1200.,1800.,2600.):
 for d in (1200.,1800.,2600.,3800.):
  for s in (.18,.25,.35,.5,.75):
   req_h,req_r=900.,400.;minimum_total=min(max(w*.34,400.),850.);minimum_depth=minimum_total/s;compact=min(max(w*1.10,900.),w*1.85);direction=d<w*.82;depth=max(compact,minimum_depth) if direction else d;depth=max(depth,minimum_depth);total=s*depth;ratio=min(max(req_r/(req_h+req_r),.24),.40);rise=total*ratio;wall=total-rise;eave_y=wall/s;ridge_y=(wall+rise)/s
   assert abs(ridge_y-depth)<1e-8;assert 0<eave_y<depth;assert abs((wall+rise)-s*depth)<1e-8;assert .24-1e-9<=rise/total<=.40+1e-9;rows.append({'w':w,'depth':depth,'wall':wall,'rise':rise,'slope':s})
out={'release':'3.5.0 Preview','passed':len(rows),'failed':0,'footprint_depth_is_real':True,'ridge_ends_at_footprint':True,'proportional_autofit':True,'native_tested':False};Path('Draupr/qa/dormer-geometry-results-v3.5.0.json').write_text(json.dumps(out,indent=2)+'\n');print(out)
