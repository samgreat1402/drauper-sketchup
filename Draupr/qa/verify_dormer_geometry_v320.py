import math,json
from pathlib import Path

def sub(a,b):return tuple(a[i]-b[i] for i in range(3))
def cross(a,b):return (a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
def dot(a,b):return sum(a[i]*b[i] for i in range(3))
def norm(a):return math.sqrt(dot(a,a))
def planar(poly,tol=1e-7):
 n=cross(sub(poly[1],poly[0]),sub(poly[2],poly[0]));ln=norm(n)
 return ln>1e-8 and max(abs(dot(sub(q,poly[0]),n))/ln for q in poly)<tol

def profile(kind,w,eave,rise):
 if kind in ('gabled','pointed'):return [(0,eave),(w/2,eave+rise),(w,eave)]
 if kind=='trapezoidal':return [(0,eave),(.28*w,eave+rise),(.72*w,eave+rise),(w,eave)]
 if kind in ('eyebrow','segmental','barrel'):
  out=[]
  for i in range(21):
   x=w*i/20;t=i/20;u=2*t-1
   f=1-abs(u)**3 if kind=='eyebrow' else (math.sqrt(max(0,1-u*u)) if kind=='barrel' else 1-u*u)
   out.append((x,eave+rise*f))
  return out
 return [(0,eave),(w,eave)]

def solve(kind,w,d,h,req,host):
 s=host/d;panels=[]
 if kind=='shed':
  m=max(0,min(req/d,s*.55));den=s-m;e=den*d*.82;j=e/den;z=s*j
  panels=[[(0,0,e),(w,0,e),(w,j,z),(0,j,z)]];opening=[(0,0,0),(w,0,0),(w,j,z),(0,j,z)];prof=[(0,e),(w,e)]
 elif kind=='flat':
  m=0;e=s*d*.78;j=e/s;panels=[[(0,0,e),(w,0,e),(w,j,e),(0,j,e)]];opening=[(0,0,0),(w,0,0),(w,j,e),(0,j,e)];prof=[(0,e),(w,e)]
 elif kind=='hipped':
  m=s*.15;den=s-m;peak=den*d*.84;ratio=req/max(h+req,1);rise=min(max(peak*ratio,peak*.18),peak*.52);e=peak-rise;sy=e/den;ry=peak/den;rs=min(d*.22,sy*.48)
  lf=(0,0,e);rf=(w,0,e);r0=(w/2,rs,peak+m*rs);rr=(w/2,ry,s*ry);lr=(0,sy,s*sy);rj=(w,sy,s*sy)
  panels=[[lf,rf,r0],[lf,r0,rr,lr],[rf,rj,rr,r0]];opening=[(0,0,0),(w,0,0),rj,rr,lr];prof=[(0,e),(w,e)]
 else:
  m=s*.18
  den=s-m
  peak=den*d*.84
  ratio=req/max(h+req,1)
  minimum=peak*(.10 if kind=='eyebrow' else .16)
  maximum=peak*(.62 if kind=='pointed' else .48)
  rise=min(max(peak*ratio,minimum),maximum)
  if kind=='eyebrow': rise*=.62
  e=peak-rise
  prof=profile(kind,w,e,rise)
  for (x0,z0),(x1,z1) in zip(prof,prof[1:]):
   y0=z0/den;y1=z1/den;panels.append([(x0,0,z0),(x1,0,z1),(x1,y1,s*y1),(x0,y0,s*y0)])
  opening=[(0,0,0),(w,0,0)]+[(x,z/den,s*z/den) for x,z in reversed(prof)]
 actual=max(q[1] for q in opening);e=prof[0][1]
 return {'panels':panels,'opening':opening,'actual':actual,'base':e-h,'eave':e,'profile':prof,'slope':s}

expected={'gabled':2,'hipped':3,'shed':1,'eyebrow':20,'segmental':20,'barrel':20,'flat':1,'pointed':2,'trapezoidal':3}
checks=[]
for d in (1500.,3000.,5000.):
 for host_ratio in (.25,.45,.75):
  for kind,count in expected.items():
   r=solve(kind,1800.,d,1200.,600.,d*host_ratio)
   assert len(r['panels'])==count,(kind,len(r['panels']))
   assert all(planar(poly) for poly in r['panels']),(kind,'nonplanar')
   assert r['actual']<=d+1e-7,(kind,r['actual'],d)
   assert r['base']<r['eave']
   # All non-front opening points lie exactly on z=slope*y.
   assert all(abs(q[2]-r['slope']*q[1])<1e-7 for q in r['opening'][2:]),kind
   assert all(norm(cross(sub(poly[1],poly[0]),sub(poly[2],poly[0])))>1e-6 for poly in r['panels']),kind
   checks.append({'type':kind,'depth':d,'host_ratio':host_ratio,'panels':count,'join_depth':round(r['actual'],3),'front_base':round(r['base'],3)})
# Type silhouettes must not collapse to one generic profile.
sigs={kind:tuple(round(z,2) for _,z in solve(kind,1800,3000,1200,600,1500)['profile']) for kind in expected}
assert len(set(sigs.values()))>=7,sigs
out={'release':'3.2.0 Preview','passed':len(checks),'failed':0,'cases':checks,'distinct_profile_signatures':len(set(sigs.values())),'note':'Pure geometry contract; SketchUp native smoke test still required.'}
Path('Draupr/qa/dormer-geometry-results-v3.2.0.json').write_text(json.dumps(out,indent=2)+'\n')
print(json.dumps({'passed':len(checks),'failed':0,'distinct_profiles':out['distinct_profile_signatures']}))
