import math,json
from pathlib import Path
def sub(a,b):return tuple(a[i]-b[i] for i in range(3))
def cross(a,b):return (a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
def dot(a,b):return sum(a[i]*b[i] for i in range(3))
def norm(a):return math.sqrt(dot(a,a))
def planar(poly):
 n=cross(sub(poly[1],poly[0]),sub(poly[2],poly[0]));ln=norm(n)
 return ln>1e-8 and max(abs(dot(sub(q,poly[0]),n))/ln for q in poly)<1e-7
def profile(k,w,e,r):
 if k in ('gabled','pointed'):return [(0,e),(w/2,e+r),(w,e)]
 if k=='trapezoidal':return [(0,e),(.28*w,e+r),(.72*w,e+r),(w,e)]
 if k in ('eyebrow','segmental','barrel'):
  out=[]
  for i in range(21):
   x=w*i/20;t=i/20;u=2*t-1;f=1-abs(u)**3 if k=='eyebrow' else (math.sqrt(max(0,1-u*u)) if k=='barrel' else 1-u*u);out.append((x,e+r*f))
  return out
 return [(0,e),(w,e)]
def solve(k,w,d,h,req,host):
 s=host/d;P=[]
 if k=='shed':
  m=s*.2;den=s-m;e=min(max(h*.62,300),den*d*1.8);j=e/den;z=s*j;P=[[(0,0,e),(w,0,e),(w,j,z),(0,j,z)]];O=[(0,0,0),(w,0,0),(w,j,z),(0,j,z)];F=[(0,e),(w,e)]
 elif k=='flat':
  e=min(max(h*.62,300),s*d*1.6);j=e/s;P=[[(0,0,e),(w,0,e),(w,j,e),(0,j,e)]];O=[(0,0,0),(w,0,0),(w,j,e),(0,j,e)];F=[(0,e),(w,e)]
 elif k=='hipped':
  m=s*.15;den=s-m;de=max(h*.62,300);dr=max(req*.72,160);scale=min(1,den*d*1.9/(de+dr));e=de*scale;r=dr*scale;peak=e+r;sy=e/den;ry=peak/den;rs=min(d*.28,sy*.48);lf=(0,0,e);rf=(w,0,e);r0=(w/2,rs,peak+m*rs);rr=(w/2,ry,s*ry);lr=(0,sy,s*sy);rj=(w,sy,s*sy);P=[[lf,rf,r0],[lf,r0,rr,lr],[rf,rj,rr,r0]];O=[(0,0,0),(w,0,0),rj,rr,lr];F=[(0,e),(w,e)]
 else:
  m=s*.18;den=s-m;factor={'eyebrow':.30,'segmental':.55,'barrel':.72,'pointed':1.05,'trapezoidal':.65}.get(k,.72);de=max(h*.62,300);dr=max(req*factor,90 if k=='eyebrow' else 160);scale=min(1,den*d*2/(de+dr));e=de*scale;r=dr*scale;F=profile(k,w,e,r)
  for (x0,z0),(x1,z1) in zip(F,F[1:]):y0=z0/den;y1=z1/den;P.append([(x0,0,z0),(x1,0,z1),(x1,y1,s*y1),(x0,y0,s*y0)])
  O=[(0,0,0),(w,0,0)]+[(x,z/den,s*z/den) for x,z in reversed(F)]
 return {'panels':P,'opening':O,'depth':max(q[1] for q in O),'eave':F[0][1],'base':F[0][1]-h,'s':s,'profile':F}
expected={'gabled':2,'hipped':3,'shed':1,'eyebrow':20,'segmental':20,'barrel':20,'flat':1,'pointed':2,'trapezoidal':3};rows=[]
for d in (1500.,3000.,5000.):
 for hr in (.25,.45,.75):
  for k,c in expected.items():
   r=solve(k,1800,d,1200,600,d*hr);assert len(r['panels'])==c;assert all(planar(q) for q in r['panels']);assert r['depth']<=d*2.02+1e-7;assert r['eave']>=1200*.24;assert all(abs(q[2]-r['s']*q[1])<1e-7 for q in r['opening'][2:]);rows.append({'type':k,'depth':d,'host_ratio':hr,'panels':c,'join_ratio':round(r['depth']/d,3),'visible_eave_ratio':round(r['eave']/1200,3)})
sigs={k:tuple(round(z,2) for _,z in solve(k,1800,3000,1200,600,1500)['profile']) for k in expected};assert len(set(sigs.values()))>=7
out={'release':'3.2.1 Preview','passed':len(rows),'failed':0,'cases':rows,'distinct_profile_signatures':len(set(sigs.values())),'max_join_ratio':max(x['join_ratio'] for x in rows),'minimum_visible_eave_ratio':min(x['visible_eave_ratio'] for x in rows),'native_tested':False};Path('Draupr/qa/dormer-geometry-results-v3.2.1.json').write_text(json.dumps(out,indent=2)+'\n');print(json.dumps({k:out[k] for k in ('passed','failed','distinct_profile_signatures','max_join_ratio','minimum_visible_eave_ratio')}))
