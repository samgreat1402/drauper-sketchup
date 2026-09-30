import math,json
from pathlib import Path
TYPES=['gabled','hipped','shed','eyebrow','segmental','barrel','flat','pointed','trapezoidal']
COUNTS={'gabled':2,'hipped':3,'shed':1,'eyebrow':20,'segmental':20,'barrel':20,'flat':1,'pointed':2,'trapezoidal':3}
FACT={'gabled':(.43,.24),'pointed':(.38,.30),'trapezoidal':(.43,.21),'eyebrow':(.45,.10),'segmental':(.44,.16),'barrel':(.40,.23)}
def sub(a,b):return tuple(x-y for x,y in zip(a,b))
def cross(a,b):return (a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
def dot(a,b):return sum(x*y for x,y in zip(a,b))
def norm(a):return math.sqrt(dot(a,a))
def planar(poly):
 n=cross(sub(poly[1],poly[0]),sub(poly[2],poly[0]));ln=norm(n)
 return ln>1e-8 and max(abs(dot(sub(q,poly[0]),n))/ln for q in poly)<1e-7
def profile(k,w,e,r):
 if k in ('gabled','pointed'):return [(0,e),(w/2,e+r),(w,e)]
 if k=='trapezoidal':return [(0,e),(.28*w,e+r),(.72*w,e+r),(w,e)]
 out=[]
 for i in range(21):
  x=w*i/20;t=i/20;u=2*t-1
  f=1-abs(u)**3 if k=='eyebrow' else (math.sqrt(max(0,1-u*u)) if k=='barrel' else 1-u*u)
  out.append((x,e+r*f))
 return out
def solve(k,w,d,wh,rr,host):
 s=host/d;ov=min(max(w*.045,55),120);panels=[]
 if k=='shed':
  e=min(wh,host*.42);m=s*.25;den=s-m;j=e/den;z=s*j;panels=[[(-ov,-ov,e-m*ov),(w+ov,-ov,e-m*ov),(w+ov,j,z),(-ov,j,z)]];opening=[(0,0,0),(w,0,0),(w,j,z),(0,j,z)];front=[(0,e),(w,e)]
 elif k=='flat':
  e=min(wh,host*.48);j=e/s;panels=[[(-ov,-ov,e),(w+ov,-ov,e),(w+ov,j,e),(-ov,j,e)]];opening=[(0,0,0),(w,0,0),(w,j,e),(0,j,e)];front=[(0,e),(w,e)]
 elif k=='hipped':
  e=min(wh,host*.44);r=min(rr,host*.22);peak=e+r;sy=e/s;ry=peak/s;rs=min(d*.20,sy*.44);lf=(-ov,-ov,e);rf=(w+ov,-ov,e);rc=(w/2,rs,peak);re=(w/2,ry,s*ry);ll=(-ov,sy,s*sy);lr=(w+ov,sy,s*sy);panels=[[lf,rf,rc],[lf,rc,re,ll],[rf,lr,re,rc]];opening=[(0,0,0),(w,0,0),(w,sy,s*sy),re,(0,sy,s*sy)];front=[(0,e),(w,e)]
 else:
  ef,rf=FACT[k];e=min(wh,host*ef);r=min(rr,host*rf);scale=min(1,host*.68/(e+r));e*=scale;r*=scale;front=profile(k,w,e,r);roof=[(x-ov,z) for x,z in profile(k,w+2*ov,e,r)]
  for (x0,z0),(x1,z1) in zip(roof,roof[1:]):
   y0=z0/s;y1=z1/s;panels.append([(x0,-ov,z0),(x1,-ov,z1),(x1,y1,s*y1),(x0,y0,s*y0)])
  opening=[(0,0,0),(w,0,0)]+[(x,z/s,s*z/s) for x,z in reversed(front)]
 return {'panels':panels,'opening':opening,'depth':max(q[1] for q in opening),'wall':front[0][1],'front':front,'slope':s,'overhang':ov}
rows=[]
for d in (1500.,2500.,3500.,5000.,8000.):
 for host in (500.,900.,1500.,2600.):
  for wh,rr in ((600.,250.),(900.,400.),(1800.,900.)):
   for k in TYPES:
    r=solve(k,1800,d,wh,rr,host);assert len(r['panels'])==COUNTS[k];assert all(planar(p) for p in r['panels']);assert r['depth']<=d*.90+1e-7,(k,r['depth']/d);assert 0<r['wall']<=wh;assert all(abs(q[2]-r['slope']*q[1])<1e-7 for q in r['opening'][2:]);assert max(q[1] for p in r['panels'] for q in p)<=d*.90+1e-7;rows.append({'type':k,'join_ratio':round(r['depth']/d,3),'panels':COUNTS[k]})
sigs={(len(solve(k,1800,3500,900,400,1500)['panels']),tuple(round(z,2) for _,z in solve(k,1800,3500,900,400,1500)['front'])) for k in TYPES};assert len(sigs)>=8
out={'release':'3.3.0 Preview','passed':len(rows),'failed':0,'max_join_ratio':max(r['join_ratio'] for r in rows),'distinct_topologies':len(sigs),'cases':rows,'native_tested':False};Path('Draupr/qa/dormer-geometry-results-v3.3.0.json').write_text(json.dumps(out,indent=2)+'\n');print(json.dumps({k:out[k] for k in ('passed','failed','max_join_ratio','distinct_topologies')}))
