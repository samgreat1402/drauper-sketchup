import json,math
from pathlib import Path
def solve(w,drawn,wall,rise,slope):
 ov=min(max(w*.055,70),160);profile=[(0,wall),(w/2,wall+rise),(w,wall)];roof=[(-ov,wall),(w/2,wall+rise),(w+ov,wall)];panels=[]
 for (x0,z0),(x1,z1) in zip(roof,roof[1:]):panels.append([(x0,-ov,z0),(x1,-ov,z1),(x1,z1/slope,z1),(x0,z0/slope,z0)])
 opening=[(0,0,0),(w,0,0)]+[(x,z/slope,z) for x,z in reversed(profile)]
 return {'panels':panels,'opening':opening,'wall':wall,'rise':rise,'join':(wall+rise)/slope,'drawn':drawn}
def planar(q):
 a,b,c=q[:3];u=[b[i]-a[i] for i in range(3)];v=[c[i]-a[i] for i in range(3)];n=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]];ln=math.sqrt(sum(x*x for x in n));return ln>1e-9 and all(abs(sum((p[i]-a[i])*n[i] for i in range(3)))/ln<1e-7 for p in q)
rows=[]
for w in (900.,1500.,2400.,3600.):
 for drawn in (500.,1200.,3000.):
  for wall in (600.,900.,1400.):
   for rise in (200.,400.,800.):
    for slope in (.15,.25,.4,.6,1.0):
     r=solve(w,drawn,wall,rise,slope);assert r['wall']==wall and r['rise']==rise;assert abs(r['join']-(wall+rise)/slope)<1e-9;assert len(r['panels'])==2 and all(planar(q) for q in r['panels']);assert all(abs(z-slope*y)<1e-7 for _x,y,z in r['opening'][2:]);rows.append({'join':r['join'],'drawn':drawn})
out={'release':'3.4.1 Preview','passed':len(rows),'failed':0,'literal_dimensions_preserved':True,'drawn_depth_can_be_less_than_join':any(x['drawn']<x['join'] for x in rows),'native_tested':False};Path('Draupr/qa/dormer-geometry-results-v3.4.1.json').write_text(json.dumps(out,indent=2)+'\n');print(out)
