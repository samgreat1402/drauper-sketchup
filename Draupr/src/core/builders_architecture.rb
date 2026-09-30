# frozen_string_literal: true
require 'json'
module Draupr
  module Core
    module Builders
      module_function
      def stair_step(g,i,x,y,dx,dy,top,f,r,m,tm,constr)
        box(g.entities,'tread',"tread_#{i}",p3(x,y,top-f),dx,dy,f,tm)
        v=dx*dy*f
        if constr=='solid'
          box(g.entities,'structure',"riser_#{i}",p3(x,y),dx,dy,top-f,m);v+=dx*dy*(top-f)
        elsif constr=='closed'
          rw=[20.mm,dx].min
          box(g.entities,'structure',"riser_#{i}",p3(x,y,top-f-r),rw,dy,r,m);v+=rw*dy*r
        end
        v
      end
      def flight_stringers(g,key,a,b,w,m,mono)
        if mono
          bar_between(g.entities,'structure',"#{key}_mono",a,b,200.mm,200.mm,m)
        else
          v=a.vector_to(b);nrm=Geom::Vector3d.new(-v.y,v.x,0)
          if nrm.length>0.001
            nrm.normalize!
            [50.mm,w-50.mm].each_with_index do |off,oi|
              bar_between(g.entities,'structure',"#{key}_#{oi}",a.offset(nrm,off-w/2),b.offset(nrm,off-w/2),120.mm,120.mm,m)
            end
          end
        end
      end
      def build_stair(p)
        g=root('Stair',:stairs);n,r=Parameters.stair_values(p);w=p['width'];t=p['tread'];f=p['tread_thickness'];m=mat(p,'material',:concrete);tm=mat(p,'tread_material',:timber);volume=0.0;constr=p['construction'].to_s
        if p['turn']=='spiral'
          pole_r=60.mm
          pole_h=n*r+(p['railing'] ? p['rail_height'] : 300.mm)
          Parts.cylinder(g.entities,'structure','pole',ORIGIN,pole_r,pole_h,m,24)
          step_a=30.0*Math::PI/180
          ro=pole_r+w
          wi=80.mm
          wo=2*ro*Math.sin(step_a/2)*1.12
          n.times do |i|
            a=i*step_a;top=(i+1)*r
            pts=[p3(pole_r*0.5,-wi/2,top-f),p3(ro,-wo/2,top-f),p3(ro,wo/2,top-f),p3(pole_r*0.5,wi/2,top-f)]
            part=Parts.make(g.entities,'tread',"tread_#{i}",tm)
            tf=part.entities.add_face(pts)
            tf.pushpull(tf.normal.z>0 ? f : -f) if tf
            part.transformation=Geom::Transformation.rotation(ORIGIN,Z_AXIS,a)
            volume+=(wi+wo)/2*(ro-pole_r*0.5)*f
          end
          la=n*step_a
          plate=Parts.make(g.entities,'tread','exit_landing',tm)
          pf=plate.entities.add_face([p3(pole_r*0.5,-w/2,n*r-f),p3(ro,-w/2,n*r-f),p3(ro,w/2,n*r-f),p3(pole_r*0.5,w/2,n*r-f)])
          pf.pushpull(pf.normal.z>0 ? f : -f) if pf
          plate.transformation=Geom::Transformation.rotation(ORIGIN,Z_AXIS,la)
          if p['railing']
            rail=mat(p,'rail_material',:steel);rh=p['rail_height'];rr_out=ro-30.mm
            ids=(0...n).step(2).to_a
            ids.each { |i| a=i*step_a;Parts.cylinder(g.entities,'railing',"sp_post_#{i}",Geom::Point3d.new(rr_out*Math.cos(a),rr_out*Math.sin(a),(i+1)*r),10.mm,rh,rail,12) }
            ids.each_cons(2) { |i,j| a1=i*step_a;a2=j*step_a;bar_between(g.entities,'railing',"sp_rail_#{i}",Geom::Point3d.new(rr_out*Math.cos(a1),rr_out*Math.sin(a1),(i+1)*r+rh),Geom::Point3d.new(rr_out*Math.cos(a2),rr_out*Math.sin(a2),(j+1)*r+rh),45.mm,45.mm,rail) }
          end
          return write(g,volume_m3:volume*0.000016387064,rise_mm:n*r*25.4,actual_steps:n,actual_riser_mm:r*25.4)
        end
        if p['turn']=='winder'
          k=[[((n-2)/2.0).ceil,1].max,n-2].min
          k.times do |i|
            top=(i+1)*r;volume+=stair_step(g,i,i*t,0,t,w,top,f,r,m,tm,constr)
          end
          flight_stringers(g,'f1',p3(0,w/2,0),p3(k*t,w/2,k*r-150.mm),w,m,constr=='open') unless constr=='solid'
          x0=k*t
          [[p3(x0,0),p3(x0+w,0),p3(x0,w)],[p3(x0+w,0),p3(x0+w,w),p3(x0,w)]].each_with_index do |tri,wi|
            top=(k+wi+1)*r
            if constr=='solid'
              solid=Parts.make(g.entities,'structure',"winder_#{wi}",m)
              sf=solid.entities.add_face(tri.map { |q| Geom::Point3d.new(q.x,q.y,0) })
              sf.pushpull(sf.normal.z>0 ? top-f : -(top-f)) if sf
            else
              Parts.cylinder(g.entities,'structure',"winder_post_#{wi}",p3(x0+w-80.mm,w-80.mm),60.mm,top-f,m,16)
            end
            cap=Parts.make(g.entities,'tread',"winder_tread_#{wi}",tm)
            cf=cap.entities.add_face(tri.map { |q| Geom::Point3d.new(q.x,q.y,top-f) })
            cf.pushpull(cf.normal.z>0 ? f : -f) if cf
            volume+=w*w*top/2
          end
          (n-k-2).times do |j|
            top=(k+2+j+1)*r;volume+=stair_step(g,k+2+j,x0,w+j*t,w,t,top,f,r,m,tm,constr)
          end
          flight_stringers(g,'f2',p3(x0+w/2,w,(k+2)*r-150.mm),p3(x0+w/2,w+(n-k-2)*t,n*r-150.mm),w,m,constr=='open') unless constr=='solid'
        else
          k=p['turn']=='straight' ? n : (n/2.0).ceil
          k.times do |i|
            top=(i+1)*r;volume+=stair_step(g,i,i*t,0,t,w,top,f,r,m,tm,constr)
          end
          flight_stringers(g,'f1',p3(0,w/2,0),p3(k*t,w/2,k*r-150.mm),w,m,constr=='open') unless constr=='solid'
        end
        if p['turn']=='L'
          land=p['landing_depth'];top=k*r
          box(g.entities,'structure','landing_body',p3(k*t),land,w,top-f,m) if constr=='solid'
          Parts.cylinder(g.entities,'structure','landing_post',p3(k*t+land-80.mm,w-80.mm),60.mm,top-f,m,16) unless constr=='solid'
          box(g.entities,'tread','landing_top',p3(k*t,0,top-f),land,w,f,tm);volume+=land*w*top
          (n-k).times do |j|
            top=(k+j+1)*r;volume+=stair_step(g,k+j,k*t+land-w,w+j*t,w,t,top,f,r,m,tm,constr)
          end
          flight_stringers(g,'f2',p3(k*t+land-w/2,w,k*r-150.mm),p3(k*t+land-w/2,w+(n-k)*t,n*r-150.mm),w,m,constr=='open') unless constr=='solid'
        end
        if p['turn']=='U'
          land=p['landing_depth'];top=k*r
          box(g.entities,'structure','landing_body',p3(k*t),land,2*w,top-f,m) if constr=='solid'
          Parts.cylinder(g.entities,'structure','landing_post',p3(k*t+land-80.mm,2*w-80.mm),60.mm,top-f,m,16) unless constr=='solid'
          box(g.entities,'tread','landing_top',p3(k*t,0,top-f),land,2*w,f,tm);volume+=land*2*w*top
          (n-k).times do |j|
            top=(k+j+1)*r;bx=k*t+land-(j+1)*t;volume+=stair_step(g,k+j,bx,w,t,w,top,f,r,m,tm,constr)
          end
          flight_stringers(g,'f2',p3(k*t+land,1.5*w,k*r-150.mm),p3(k*t+land-(n-k)*t,1.5*w,n*r-150.mm),w,m,constr=='open') unless constr=='solid'
        end
        if p['railing']
          rail=mat(p,'rail_material',:steel);rh=p['rail_height']
          (0...k).step(2) { |i| Parts.cylinder(g.entities,'railing',"stair_post_a_#{i}",p3((i+0.5)*t,30.mm,(i+1)*r),20.mm,rh,rail,16) }
          bar_between(g.entities,'railing','stair_rail_a',p3(t/2,30.mm,r+rh),p3((k-0.5)*t,30.mm,k*r+rh),45.mm,45.mm,rail)
          if p['turn']=='L'
            land=p['landing_depth'];rest=n-k
            bar_between(g.entities,'railing','landing_rail',p3((k-0.5)*t,30.mm,k*r+rh),p3(k*t+land-30.mm,30.mm,k*r+rh),45.mm,45.mm,rail)
            bar_between(g.entities,'railing','landing_return',p3(k*t+land-30.mm,30.mm,k*r+rh),p3(k*t+land-30.mm,w,k*r+rh),45.mm,45.mm,rail)
            (0...rest).step(2) { |j| Parts.cylinder(g.entities,'railing',"stair_post_b_#{j}",p3(k*t+land-30.mm,w+(j+0.5)*t,(k+j+1)*r),20.mm,rh,rail,16) }
            bar_between(g.entities,'railing','stair_rail_b',p3(k*t+land-30.mm,w,k*r+rh),p3(k*t+land-30.mm,w+(rest-0.5)*t,n*r+rh),45.mm,45.mm,rail)
          end
          if p['turn']=='U'
            land=p['landing_depth'];rest=n-k
            bar_between(g.entities,'railing','landing_rail_u',p3((k-0.5)*t,30.mm,k*r+rh),p3(k*t+land-30.mm,30.mm,k*r+rh),45.mm,45.mm,rail)
            bar_between(g.entities,'railing','landing_edge_u',p3(k*t+land-30.mm,30.mm,k*r+rh),p3(k*t+land-30.mm,2*w-30.mm,k*r+rh),45.mm,45.mm,rail)
            (0...rest).step(2) { |j| bx=k*t+land-(j+0.5)*t;Parts.cylinder(g.entities,'railing',"stair_post_c_#{j}",p3(bx,2*w-30.mm,(k+j+1)*r),20.mm,rh,rail,16) }
            bar_between(g.entities,'railing','stair_rail_c',p3(k*t+land-30.mm,2*w-30.mm,k*r+rh),p3(k*t+land-(rest-0.5)*t,2*w-30.mm,n*r+rh),45.mm,45.mm,rail)
          end
          if p['turn']=='winder'
            rest=n-k-2
            (0...rest).step(2) { |j| Parts.cylinder(g.entities,'railing',"stair_post_w_#{j}",p3(x0+w-30.mm,w+(j+0.5)*t,(k+2+j+1)*r),20.mm,rh,rail,16) }
            bar_between(g.entities,'railing','stair_rail_w',p3(x0+w-30.mm,w,(k+2)*r+rh),p3(x0+w-30.mm,w+[rest-0.5,0.5].max*t,n*r+rh),45.mm,45.mm,rail)
          end
        end
        write(g,volume_m3:volume*0.000016387064,rise_mm:n*r*25.4,run_mm:n*t*25.4,actual_steps:n,actual_riser_mm:r*25.4)
      end
      def roof_faces(p)
        if p['roof_face_overrides'].is_a?(Array) && !p['roof_face_overrides'].empty?
          return p['roof_face_overrides'].map { |poly| poly.map { |a| p3(Parameters.coord(a[0]),Parameters.coord(a[1]),Parameters.coord(a[2])) } }
        end
        w=p['width'];d=p['depth'];o=p['overhang'];x0=-o;y0=-o;x1=w+o;y1=d+o
        if p['style']=='flat'
          if p['footprint'];raise 'A face-derived flat roof needs zero overhang. Offset the source face first.' if o>0;[footprint(p)]
          else;[[p3(x0,y0),p3(x1,y0),p3(x1,y1),p3(x0,y1)]];end
        else
          ww=x1-x0;dd=y1-y0;span=p['style']=='hip' ? [ww,dd].min/2 : (p['ridge_axis']=='x' ? dd : ww)/2
          rise=p['sizing_mode']=='pitch' ? span*Math.tan(p['pitch_deg']*Math::PI/180) : p['rise']
          c0=p3(x0,y0);c1=p3(x1,y0);c2=p3(x1,y1);c3=p3(x0,y1)
          if p['style']=='gable'
            if p['ridge_axis']=='x';a=p3(x0,d/2,rise);b=p3(x1,d/2,rise);[[c0,c1,b,a],[a,b,c2,c3]]
            else;a=p3(w/2,y0,rise);b=p3(w/2,y1,rise);[[c0,a,b,c3],[a,c1,c2,b]];end
          elsif p['style']=='shed'
            if p['ridge_axis']=='x';[[c0,c1,p3(x1,y1,rise),p3(x0,y1,rise)]]
            else;[[c0,p3(x1,y0,rise),p3(x1,y1,rise),c3]];end
          elsif p['style']=='gambrel'
            hb=rise*0.55
            if p['ridge_axis']=='x'
              b0=p3(x0,y0+dd*0.25,hb);b1=p3(x1,y0+dd*0.25,hb);b2=p3(x1,y1-dd*0.25,hb);b3=p3(x0,y1-dd*0.25,hb)
              a=p3(x0,d/2,rise);b=p3(x1,d/2,rise)
              [[c0,c1,b1,b0],[b0,b1,b,a],[a,b,b2,b3],[b3,b2,c2,c3]]
            else
              b0=p3(x0+ww*0.25,y0,hb);b1=p3(x0+ww*0.25,y1,hb);b2=p3(x1-ww*0.25,y1,hb);b3=p3(x1-ww*0.25,y0,hb)
              a=p3(w/2,y0,rise);b=p3(w/2,y1,rise)
              [[c0,b0,b1,c3],[b0,a,b,b1],[a,b3,b2,b],[b3,c1,c2,b2]]
            end
          elsif p['style']=='mansard'
            s=[span*0.4,ww*0.24,dd*0.24].min;zh=rise*0.75
            q0=p3(x0+s,y0+s,zh);q1=p3(x1-s,y0+s,zh);q2=p3(x1-s,y1-s,zh);q3=p3(x0+s,y1-s,zh)
            t0=p3(x0+s,y0+s,rise);t1=p3(x1-s,y0+s,rise);t2=p3(x1-s,y1-s,rise);t3=p3(x0+s,y1-s,rise)
            [[c0,c1,q1,q0],[c1,c2,q2,q1],[c2,c3,q3,q2],[c3,c0,q0,q3],[t0,t1,t2,t3]]
          elsif ww>=dd
            a=p3(x0+span,d/2,rise);b=p3(x1-span,d/2,rise);[[c0,c1,b,a],[c2,c3,a,b],[c3,c0,a],[c1,c2,b]]
          else
            a=p3(w/2,y0+span,rise);b=p3(w/2,y1-span,rise);[[c0,c1,a],[c1,c2,b,a],[c2,c3,b],[c3,c0,a,b]]
          end
        end
      end
      def point_in_poly?(pt,poly,n)
        ax=n.to_a.each_with_index.max_by { |v,_i| v.abs }[1]
        idx=[0,1,2]-[ax]
        us=poly.map { |q| [q.to_a[idx[0]],q.to_a[idx[1]]] }
        pu=pt.to_a[idx[0]];pv=pt.to_a[idx[1]]
        inside=false;j=us.length-1
        us.each_with_index do |(ui,vi),i|
          uj,vj=us[j]
          if (vi>pv)!=(vj>pv) && pu<(uj-ui)*(pv-vi)/(vj-vi)+ui
            inside=!inside
          end
          j=i
        end
        inside
      end
      def roof_holes_on(quad,openings,face_index=nil)
        return [] if openings.empty?
        v1=quad[0].vector_to(quad[1]);v2=quad[1].vector_to(quad[2]);n=v1.cross(v2);return [] if n.length<1e-9;n.normalize!
        openings.filter_map do |op|
          next if face_index && op.key?('face') && op['face'].to_i!=face_index
          o=p3(*op['o']);x=Geom::Vector3d.new(*op['x']);y=Geom::Vector3d.new(*op['y']);w=op['w'].to_f;dd=op['d'].to_f
          raw=op['poly'].is_a?(Array) && op['poly'].length>=3 ? op['poly'].map { |point| p3(*point) } : [o,o.offset(x,w),o.offset(x,w).offset(y,dd),o.offset(y,dd)]
          projected=raw.map { |point| point.offset(n,-quad[0].vector_to(point).dot(n)) }
          count=projected.length.to_f;c=Geom::Point3d.new(projected.sum(&:x)/count,projected.sum(&:y)/count,projected.sum(&:z)/count)
          next unless point_in_poly?(c,quad,n)
          next unless projected.all? { |point| point_in_poly?(point,quad,n) || quad.any? { |corner| corner.distance(point)<1.mm } }
          projected
        end
      end
      def roof_join_holes_on(p,face_index)
        (p['roof_join_holes'].is_a?(Array) ? p['roof_join_holes'] : []).select { |h| h['face'].to_i==face_index }.map { |h| h['points'].map { |a| p3(Parameters.coord(a[0]),Parameters.coord(a[1]),Parameters.coord(a[2])) } }.select { |poly| poly.length>=3 }
      end
      def build_roof(p,target=nil)
        g=target || root('Roof',:roofs);g.entities.clear! if target;w=p['width'];d=p['depth'];o=p['overhang'];th=p['thickness']
        faces=roof_faces(p)
        openings=p['roof_openings'].is_a?(Array) ? p['roof_openings'] : []
        if p['style']=='flat'
          pts=faces.first
          sheet_solid(g.entities,pts,th,p,'roof_flat',roof_holes_on(pts,openings,0)+roof_join_holes_on(p,0))
          area=polygon_area(pts);volume=area*th
        else
          ww=w+2*o;dd=d+2*o;span=p['style']=='hip' ? [ww,dd].min/2 : (p['ridge_axis']=='x' ? dd : ww)/2
          rise=p['sizing_mode']=='pitch' ? span*Math.tan(p['pitch_deg']*Math::PI/180) : p['rise']
          faces.each_with_index { |q,i| sheet_solid(g.entities,q,th,p,"roof_slope_#{i}",roof_holes_on(q,openings,i)+roof_join_holes_on(p,i)) }
          area=ww*dd/Math.cos(Math.atan2(rise,span));volume=ww*dd*th
        end
        write(g,area_m2:area*0.00064516,volume_m3:volume*0.000016387064)
      end
      def build_railing(p)
        g=root('Railing',:framing);raw=p['path_points'].is_a?(Array) ? p['path_points'].map { |a| p3(*a) } : [ORIGIN,p3(p['length'])];pts=PathFrames.clean(raw,p['closed']==true)
        if p['closed']!=true && pts.length>1 && p['return_length'].to_f>1.mm
          first=pts[0].vector_to(pts[1]);last=pts[-2].vector_to(pts[-1]);first.normalize!;last.normalize!
          first_side=Z_AXIS.cross(first);last_side=Z_AXIS.cross(last)
          if first_side.length>1e-9 && last_side.length>1e-9
            first_side.normalize!;last_side.normalize!
            if p['flip_profile']==true;first_side.reverse!;last_side.reverse!;end
            pts.unshift(pts.first.offset(first_side,p['return_length'].to_f)) if p['start_return']==true
            pts.push(pts.last.offset(last_side,p['return_length'].to_f)) if p['end_return']==true
          end
        end
        pm=mat(p,'post_material',:steel);rm=mat(p,'rail_material',:steel);h=p['height'];total=0.0
        if WarehouseRailings.preset?(p['preset'])
          bar=lambda { |key,a,b,w,d,m| bar_between(g.entities,'rail',key,a,b,w,d,m) }
          total=WarehouseRailings.build(g,p,pts,pm,rm,&bar)
          return write(g,length_mm:total*25.4,source:'SketchUp component library')
        end
        preset=RailingPresets.fetch(p['preset'])
        if preset
          thickness=p['ornament_thickness'].to_f;thickness=12.mm if thickness<=0
          pts.each_cons(2).with_index do |(a,b),si|
            v=a.vector_to(b);len=v.length;next if len<1.mm
            point_at=lambda { |x,z| a.offset(v,len*x).offset(Z_AXIS,h*z) }
            add_bar=lambda do |key,x1,z1,x2,z2,material=rm,size=thickness|
              q1=point_at.call(x1,z1);q2=point_at.call(x2,z2);bar_between(g.entities,'rail',"preset_#{si}_#{key}",q1,q2,size,size,material) if q1.distance(q2)>=2.mm
            end
            family=preset['family'];spacing=[p['infill_spacing'].to_f,20.mm].max;bay_spacing=[p['post_spacing'].to_f,100.mm].max
            member_count=[(len/spacing).ceil,2].max;bay_count=[(len/bay_spacing).ceil,1].max
            count=%w[cross diamond arch greek cross_circle].include?(family) ? bay_count : member_count
            count=bay_count if family=='glass_posts';gauge=preset.fetch('gauge',1.0).to_f;orn=[thickness*gauge,4.mm].max
            unless family=='glass_frameless'
              add_bar.call('bottom',0.0,0.08,1.0,0.08,rm,[orn*1.5,16.mm].max);add_bar.call('top',0.0,0.94,1.0,0.94,rm,[orn*1.8,20.mm].max)
              add_bar.call('left',0.02,0.08,0.02,0.94,pm,[orn*1.5,16.mm].max);add_bar.call('right',0.98,0.08,0.98,0.94,pm,[orn*1.5,16.mm].max)
            else
              add_bar.call('top',0.0,0.94,1.0,0.94,rm,[orn*1.8,20.mm].max)
            end
            case family
            when 'vertical'
              (1...count).each { |i| x=i.to_f/count;add_bar.call("v#{i}",x,0.1,x,0.92,rm,orn) }
            when 'horizontal'
              rails=[preset['rails'].to_i,3].max;(1...rails).each { |i| z=0.08+0.86*i.to_f/rails;add_bar.call("h#{i}",0.03,z,0.97,z,rm,orn) }
            when 'grid'
              (1...count).each { |i| x=i.to_f/count;add_bar.call("gv#{i}",x,0.1,x,0.92,rm,orn) };[0.3,0.5,0.7].each_with_index { |z,i| add_bar.call("gh#{i}",0.03,z,0.97,z,rm,orn) }
            when 'cross'
              (0...count).each { |i| x1=i.to_f/count;x2=(i+1).to_f/count;add_bar.call("xa#{i}",x1,0.12,x2,0.9,rm,orn);add_bar.call("xb#{i}",x1,0.9,x2,0.12,rm,orn) }
            when 'diamond'
              (0...count).each { |i| x1=i.to_f/count;xm=(i+0.5)/count.to_f;x2=(i+1).to_f/count;add_bar.call("da#{i}",x1,0.5,xm,0.9,rm,orn);add_bar.call("db#{i}",xm,0.9,x2,0.5,rm,orn);add_bar.call("dc#{i}",x1,0.5,xm,0.12,rm,orn);add_bar.call("dd#{i}",xm,0.12,x2,0.5,rm,orn) }
            when 'glass_frameless','glass_posts'
              gm=mat(p,'infill_material',:glass_clear);part=Parts.make(g.entities,'glass',"preset_glass_#{si}",gm);p1=point_at.call(0.02,0.1);p2=point_at.call(0.98,0.1);face=part.entities.add_face(p1,p2,p2.offset(Z_AXIS,h*0.82),p1.offset(Z_AXIS,h*0.82));if face;face.material=gm;face.back_material=gm;face.pushpull(10.mm);end
              if family=='glass_posts';(1...count).each { |i| x=i.to_f/count;add_bar.call("m#{i}",x,0.1,x,0.92,pm,[orn*1.5,16.mm].max) };end
            when 'baluster'
              (1...count).each { |i| x=i.to_f/count;d=(i.even? ? 1 : -1)*0.018;add_bar.call("ba#{i}",x,0.1,x+d,0.35,rm,orn);add_bar.call("bb#{i}",x+d,0.35,x-d,0.65,rm,orn);add_bar.call("bc#{i}",x-d,0.65,x,0.92,rm,orn) }
            when 'double'
              (1...count).each { |i| x=i.to_f/count;add_bar.call("dl#{i}",x-0.012,0.1,x-0.012,0.92,rm,orn);add_bar.call("dr#{i}",x+0.012,0.1,x+0.012,0.92,rm,orn) }
            when 'arch'
              (0...count).each do |i|;x1=i.to_f/count;x2=(i+1).to_f/count;last=[x1,0.5];6.times do |j|;a=Math::PI-(Math::PI*j/5.0);q=[(x1+x2)/2+Math.cos(a)*(x2-x1)/2,0.5+Math.sin(a)*0.4];add_bar.call("ar#{i}_#{j}",last[0],last[1],q[0],q[1],rm,orn) if j>0;last=q;end;add_bar.call("ap#{i}",x1,0.1,x1,0.5,rm,orn);end
            when 'scroll'
              (1...count).each do |i|;x=i.to_f/count;last=[x,0.1];(1..8).each { |j| z=0.1+0.82*j/8.0;nx=x+Math.sin(j*Math::PI/2)*0.025;add_bar.call("sc#{i}_#{j}",last[0],last[1],nx,z,rm,orn);last=[nx,z] };end
            when 'greek'
              (0...count).each do |i|;x1=i.to_f/count;x2=(i+1).to_f/count;seq=[[x1,0.3],[x1+0.2/count,0.3],[x1+0.2/count,0.75],[x2-0.2/count,0.75],[x2-0.2/count,0.42],[x1+0.35/count,0.42],[x1+0.35/count,0.62],[x2-0.35/count,0.62]];seq.each_cons(2).with_index { |(u,vv),j| add_bar.call("gk#{i}_#{j}",u[0],u[1],vv[0],vv[1],rm,orn) };end
            when 'spear'
              (1...count).each { |i| x=i.to_f/count;add_bar.call("sp#{i}",x,0.1,x,0.78,rm,orn);add_bar.call("sl#{i}",x-0.018,0.78,x,0.92,rm,orn);add_bar.call("sr#{i}",x+0.018,0.78,x,0.92,rm,orn) }
            when 'ring','cross_circle'
              (1...count).each do |i|;x=i.to_f/count;add_bar.call("rv#{i}",x,0.1,x,0.92,rm,orn) if family=='ring';last=nil;12.times do |j|;a=2*Math::PI*j/12;q=[x+Math.cos(a)*0.035,0.52+Math.sin(a)*0.10];add_bar.call("rg#{i}_#{j}",last[0],last[1],q[0],q[1],rm,orn) if last;last=q;end;first=[x+0.035,0.52];add_bar.call("rg#{i}_c",last[0],last[1],first[0],first[1],rm,orn);end
              if family=='cross_circle';(0...count).each { |i| x1=i.to_f/count;x2=(i+1).to_f/count;add_bar.call("cx#{i}",x1,0.12,x2,0.9,rm,orn);add_bar.call("cy#{i}",x1,0.9,x2,0.12,rm,orn) };end
            else
              (1...count).each { |i| x=i.to_f/count;add_bar.call("ov#{i}",x,0.1,x,0.92,rm,orn);add_bar.call("oa#{i}",x-0.03,0.5,x,0.66,rm,orn);add_bar.call("ob#{i}",x,0.66,x+0.03,0.5,rm,orn);add_bar.call("oc#{i}",x+0.03,0.5,x,0.34,rm,orn);add_bar.call("od#{i}",x,0.34,x-0.03,0.5,rm,orn) }
            end
            total+=len
          end
          return write(g,length_mm:total*25.4)
        end
        infill=p['infill'].to_s
        pts.each_cons(2).with_index do |(a,b),si|
          v=a.vector_to(b);len=v.length;next if len<1.mm;n=[(len/p['post_spacing']).ceil,1].max
          post_pts=(0..n).map { |i| a.offset(v,len*i/n.to_f) }
          if infill=='balusters'
            bn=[(len/125.mm).ceil,1].max
            bpts=(0..bn).map { |i| a.offset(v,len*i/bn.to_f) }
            bpts.each_with_index { |pt,i| next if si>0 && i==0;br=p['post_diameter']/2*0.7;Parts.cylinder(g.entities,'post',"baluster_#{si}_#{i}",pt,br,h-100.mm,pm,16);Parts.cylinder(g.entities,'post',"baluster_foot_#{si}_#{i}",pt,br*1.6,60.mm,pm,16) }
          else
            post_pts.each_with_index { |pt,i| next if si>0 && i==0;Parts.cylinder(g.entities,'post',"post_#{si}_#{i}",pt,p['post_diameter']/2,h,pm,20) }
          end
          bar_between(g.entities,'rail',"rail_#{si}",a.offset(Z_AXIS,h),b.offset(Z_AXIS,h),p['rail_width'],p['rail_thickness'],rm);total+=len
          case infill
          when 'glass'
            gm=mat(p,'infill_material',:glass_clear)
            n.times do |i|
              p1=post_pts[i].offset(v,p['post_diameter']/2);p2=post_pts[i+1].offset(v,-p['post_diameter']/2);glen=p1.distance(p2);next if glen<10.mm
              panel=box(g.entities,'glass',"glass_#{si}_#{i}",p3(p1.x,p1.y-6.mm,100.mm),glen,12.mm,h-160.mm,gm);panel.transformation=Geom::Transformation.rotation(p1,Z_AXIS,Math.atan2(v.y,v.x))
            end
          when 'cable'
            n.times do |i|
              p1=post_pts[i].offset(v,p['post_diameter']/2);p2=post_pts[i+1].offset(v,-p['post_diameter']/2)
              5.times do |ci|;cz=120.mm+ci*(h-220.mm)/4;bar_between(g.entities,'cable',"cable_#{si}_#{i}_#{ci}",p1.offset(Z_AXIS,cz),p2.offset(Z_AXIS,cz),6.mm,6.mm,rm);end
            end
          end
        end
        write(g,length_mm:total*25.4)
      end
      def build_louver(p)
        if p['path_points'].is_a?(Array) && p['path_points'].length>1
          g=root('Louvers',:framing);pts=p['path_points'].map { |a| p3(*a) };total=0.0
          pts.each_cons(2).with_index do |(a,b),i|
            v=a.vector_to(b);len=v.length;next if len<1.mm;q=p.merge('width'=>len);q.delete('path_points');part=Geometry.with_entities(g.entities) { build_louver(q) }
            x=v.normalize;y=Z_AXIS.cross(x);y=Y_AXIS.clone if y.length<1e-8;y.normalize!;z=x.cross(y);z.normalize!;part.transformation=Geom::Transformation.axes(a,x,y,z);part.name="louver segment #{i+1}";total+=len
          end
          return write(g,length_mm:total*25.4,area_m2:total*p['height']*0.00064516)
        end
        g=root('Louvers',:framing);m=mat(p,'material',:mullion_dark)
        p['count'].times do |i|
          z=p['height']*i/p['count'].to_f;blade=box(g.entities,'blade',"blade_#{i}",p3(0,-p['blade_depth']/2,-p['blade_thickness']/2),p['width'],p['blade_depth'],p['blade_thickness'],m)
          blade.transformation=Geom::Transformation.new(p3(0,0,z))*Geom::Transformation.rotation(ORIGIN,X_AXIS,p['blade_angle']*Math::PI/180)
        end
        write(g,area_m2:p['width']*p['height']*0.00064516)
      end
      def build_ramp(p)
        g=root('Ramp',:stairs);m=mat(p,'material',:concrete)
        len=p['length'].to_f;w=p['width'].to_f;rise=p['rise'].to_f
        part=Parts.make(g.entities,'structure','ramp_body',m)
        f=part.entities.add_face(p3(0,0,0),p3(len,0,0),p3(len,0,rise))
        f.pushpull(f.normal.y>0 ? w : -w) if f
        if p['rails']
          rail=mat(p,'rail_material',:steel);rh=p['rail_height']
          [30.mm,w-30.mm].each do |y|
            n=[(len/1500.mm).ceil,1].max
            (0..n).each do |i|
              x=len*i/n.to_f;z=rise*x/len
              Parts.cylinder(g.entities,'railing',"ramp_post_#{y.to_i}_#{i}",p3(x,y,z),20.mm,rh,rail,16)
            end
            bar_between(g.entities,'railing',"ramp_rail_#{y.to_i}",p3(0,y,rh),p3(len,y,rise+rh),45.mm,45.mm,rail)
          end
        end
        write(g,volume_m3:len*w*rise/2*0.000016387064,rise_mm:rise*25.4,run_mm:len*25.4)
      end
      def build_skylight(p)
        g=root('Skylight',:roofs);fm=mat(p,'frame_material',:mullion_dark);gm=mat(p,'glass_material',:glass_clear)
        w=p['width'].to_f;d=p['depth'].to_f;ch=p['height'].to_f;f=p['frame'].to_f;gt=12.mm
        box(g.entities,'frame','curb_l',p3(0,0,0),f,d,ch,fm)
        box(g.entities,'frame','curb_r',p3(w-f,0,0),f,d,ch,fm)
        box(g.entities,'frame','curb_f',p3(f,0,0),w-2*f,f,ch,fm)
        box(g.entities,'frame','curb_b',p3(f,d-f,0),w-2*f,f,ch,fm)
        box(g.entities,'frame','rim_l',p3(0,0,ch),f,d,f*0.6,fm)
        box(g.entities,'frame','rim_r',p3(w-f,0,ch),f,d,f*0.6,fm)
        box(g.entities,'frame','rim_f',p3(f,0,ch),w-2*f,f,f*0.6,fm)
        box(g.entities,'frame','rim_b',p3(f,d-f,ch),w-2*f,f,f*0.6,fm)
        lid=box(g.entities,'glass','skylight_glass',p3(f,f,ch+f*0.6),w-2*f,d-2*f,gt,gm)
        ang=p['pitch'].to_f
        lid.transformation=Geom::Transformation.rotation(p3(0,f,ch+f*0.6),X_AXIS,ang*Math::PI/180) if ang.abs>0.001
        write(g,area_m2:w*d*0.00064516)
      end
      # Dormer coordinates: X is across the host slope, Y is horizontal uphill,
      # and Z is vertical. The front face is at Y=0. A portion of the front wall
      # may sit below the roof penetration line; only its roof projection is above Z=0.
      def dormer_profile(type,w,eave,rise)
        case type
        when 'gabled'
          [[0.0,eave],[w/2.0,eave+rise],[w,eave]]
        when 'hipped','flat'
          [[0.0,eave],[w,eave]]
        when 'shed'
          [[0.0,eave],[w,eave]]
        when 'pointed'
          [[0.0,eave],[w/2.0,eave+rise*1.25],[w,eave]]
        when 'trapezoidal'
          [[0.0,eave],[w*0.28,eave+rise],[w*0.72,eave+rise],[w,eave]]
        when 'eyebrow','segmental','barrel'
          count=20
          (0..count).map do |index|
            x=w*index/count.to_f;t=index/count.to_f;u=2.0*t-1.0
            factor=case type
                   when 'eyebrow' then 1.0-(u.abs**3)
                   when 'barrel' then Math.sqrt([1.0-u*u,0.0].max)
                   else 1.0-u*u
                   end
            [x,eave+rise*factor]
          end
        else
          [[0.0,eave],[w,eave]]
        end
      end
      # Derive every rear join from the exact intersection of the Dormer roof
      # planes with the host. Fit the requested vertical dimensions only when
      # the drawn uphill depth cannot contain them safely.
      def dormer_solution(p)
        w=p['width'].to_f;drawn=p['depth'].to_f;slope=p['host_slope'].to_f;type=p.fetch('dormer_type','gabled').to_s
        raise 'Dormer width must be greater than 500 mm. / عرض دورمر باید بیشتر از ۵۰۰ میلی‌متر باشد.' unless w>500.mm
        raise 'Dormer depth must be greater than 300 mm. / عمق دورمر باید بیشتر از ۳۰۰ میلی‌متر باشد.' unless drawn>300.mm
        raise 'The selected host roof is too flat for this Dormer. / سقف میزبان انتخاب‌شده برای این دورمر بیش از حد تخت است.' unless slope>0.02
        requested_eave=[p['height'].to_f,300.mm].max;requested_rise=[p['rise'].to_f,80.mm].max;depth=drawn;host_z=slope*depth
        raise 'The drawn Dormer footprint is too shallow for this roof slope. Draw farther uphill. / محدوده دورمر برای این شیب کم‌عمق است؛ آن را بیشتر به سمت بالا بکشید.' if host_z<350.mm
        # The drawn rectangle is a minimum placement footprint, not a hard
        # ceiling on Dormer height. Use the remaining selected roof face up to
        # its ridge/edge when available; only scale dimensions when the real
        # host face cannot contain the requested rear intersection.
        max_depth=[p.fetch('host_max_depth',drawn*2.0).to_f,drawn].max
        max_host_z=slope*max_depth
        clearance=[[max_host_z*0.035,45.mm].max,120.mm].min
        available=max_host_z-clearance;simple=type=='flat';rise_factor=type=='pointed' ? 1.25 : 1.0
        requested_total=requested_eave+(simple ? 0.0 : requested_rise*rise_factor);fit_scale=[available/[requested_total,1.mm].max,1.0].min;eave=requested_eave*fit_scale;rise=requested_rise*fit_scale
        if eave<250.mm
          minimum_rise=simple ? 0.0 : 60.mm
          raise 'The Dormer footprint cannot provide a usable front wall. Increase its uphill depth. / محدوده دورمر ارتفاع کافی برای دیوار جلو ندارد؛ عمق سربالایی را افزایش دهید.' if available<250.mm+minimum_rise
          eave=250.mm;rise=simple ? requested_rise*fit_scale : (available-eave)/rise_factor;fit_scale=[fit_scale,eave/requested_eave].min
        end
        overhang=[[w*0.055,70.mm].max,180.mm].min;profile=dormer_profile(type,w,eave,rise)
        panels,join_profile,front_profile,side_edges=dormer_roof_panels(type,w,profile,eave,rise,slope,overhang)
        front_edges=front_profile.each_cons(2).map { |a,b| [p3(a[0],-overhang,a[1]),p3(b[0],-overhang,b[1])] }
        body_ratio=0.88;x0=w*(1.0-body_ratio)/2.0;x1=w-x0
        rear=join_profile.reverse.map { |x,z| p3(x0+(x/w)*(x1-x0),z/slope,z) }
        opening=[p3(x0,0,0),p3(x1,0,0)]+rear
        side_z=type=='shed' ? eave+rise : eave;side_y=side_z/slope;actual_depth=join_profile.map { |_x,z| z/slope }.max
        {'opening'=>opening,'actual_depth'=>actual_depth,'drawn_depth'=>drawn,'host_max_depth'=>max_depth,'auto_extended'=>actual_depth>drawn+1.mm,'geometry_contract'=>'roof-hosted-dormer-v6','auto_fitted'=>fit_scale<0.9999,'fit_scale'=>fit_scale,'direction_only'=>false,'wall_height'=>eave,'fitted_rise'=>rise,'front_base'=>0.0,'eave'=>eave,'profile'=>profile,'front_profile'=>front_profile,'panels'=>panels,'front_edges'=>front_edges,'side_edges'=>side_edges,'cheek_join'=>[side_y,side_z],'side_rear_z'=>side_z,'overhang'=>overhang}
      end
      def extend_dormer_profile(profile,overhang)
        left_a,left_b=profile[0],profile[1];right_a,right_b=profile[-2],profile[-1]
        left_slope=(left_b[1]-left_a[1])/(left_b[0]-left_a[0]);right_slope=(right_b[1]-right_a[1])/(right_b[0]-right_a[0])
        [[-overhang,left_a[1]-left_slope*overhang]]+profile+[[right_b[0]+overhang,right_b[1]+right_slope*overhang]]
      end
      def dormer_roof_panels(type,w,profile,eave,rise,slope,overhang)
        if type=='hipped'
          front_profile=[[-overhang,eave],[w+overhang,eave]]
          left=p3(-overhang,-overhang,eave);right=p3(w+overhang,-overhang,eave);ridge=p3(w/2.0,0,eave+rise)
          rear_left=p3(-overhang,eave/slope,eave);rear_ridge=p3(w/2.0,(eave+rise)/slope,eave+rise);rear_right=p3(w+overhang,eave/slope,eave)
          sides=[[-overhang,-overhang,eave,eave/slope,eave,eave/slope,eave,eave],[w+overhang,-overhang,eave,eave/slope,eave,eave/slope,eave,eave]]
          return [[[left,right,ridge],[left,ridge,rear_ridge,rear_left],[right,rear_right,rear_ridge,ridge]],[[0.0,eave],[w/2.0,eave+rise],[w,eave]],front_profile,sides]
        end
        if type=='shed'
          rear_z=eave+rise;rear_y=rear_z/slope
          front_profile=[[-overhang,eave],[w+overhang,eave]]
          panel=[p3(-overhang,-overhang,eave),p3(w+overhang,-overhang,eave),p3(w+overhang,rear_y,rear_z),p3(-overhang,rear_y,rear_z)]
          sides=[[-overhang,-overhang,eave,rear_y,rear_z,rear_y,eave,rear_z],[w+overhang,-overhang,eave,rear_y,rear_z,rear_y,eave,rear_z]]
          return [[panel],[[0.0,rear_z],[w,rear_z]],front_profile,sides]
        end
        front_profile=extend_dormer_profile(profile,overhang)
        last_segment=profile.length-2
        panels=profile.each_cons(2).with_index.map do |(a,b),index|
          a=front_profile.first if index.zero?
          b=front_profile.last if index==last_segment
          [p3(a[0],-overhang,a[1]),p3(b[0],-overhang,b[1]),p3(b[0],b[1]/slope,b[1]),p3(a[0],a[1]/slope,a[1])]
        end
        left=front_profile.first;right=front_profile.last
        sides=[[left[0],-overhang,left[1],left[1]/slope,left[1],profile.first[1]/slope,profile.first[1],profile.first[1]],[right[0],-overhang,right[1],right[1]/slope,right[1],profile.last[1]/slope,profile.last[1],profile.last[1]]]
        [panels,profile,front_profile,sides]
      end
      def build_dormer(p)
        build_dormer_procedural(p)
      end
      def soften_dormer_station(part,station)
        part.entities.grep(Sketchup::Edge).each do |edge|
          next unless edge.vertices.all? { |vertex| (vertex.position.x-station).abs<=0.5.mm }
          edge.hidden=true;edge.soft=true;edge.smooth=true
        end
      end
      def dormer_window_layout(width,height,shutters=false)
        side_ratio=shutters ? 0.29 : 0.22
        side_limit=shutters ? 0.35 : 0.32
        side_margin=[[width*side_ratio,70.mm].max,width*side_limit].min
        sill=[[height*0.20,35.mm].max,height*0.27].min
        head=[[height*0.18,35.mm].max,height*0.25].min
        window_width=width-2.0*side_margin;window_height=height-sill-head
        return nil if window_width<180.mm || window_height<120.mm
        {'x'=>side_margin,'z'=>sill,'width'=>window_width,'height'=>window_height}
      end
      def build_dormer_shutter(entities,key,x,z,w,h,wall_t,material)
        face_y=-wall_t-25.mm;depth=9.mm;stile=[[[w*0.14,16.mm].max,26.mm].min,w*0.24].min;rail=[stile,22.mm].max
        box(entities,'trim',"#{key}_left",p3(x,face_y,z),stile,depth,h,material)
        box(entities,'trim',"#{key}_right",p3(x+w-stile,face_y,z),stile,depth,h,material)
        box(entities,'trim',"#{key}_top",p3(x+stile,face_y,z+h-rail),w-2*stile,depth,rail,material)
        box(entities,'trim',"#{key}_bottom",p3(x+stile,face_y,z),w-2*stile,depth,rail,material)
        box(entities,'trim',"#{key}_middle",p3(x+stile,face_y,z+h*0.48-rail/2),w-2*stile,depth,rail,material)
        inner_h=h-2*rail;count=[[(inner_h/48.mm).floor,5].max,12].min;step=inner_h/count.to_f;slat_h=[step*0.24,6.mm].max
        count.times do |index|
          slat_z=z+rail+step*(index+0.36)
          box(entities,'trim',"#{key}_slat_#{index+1}",p3(x+stile,face_y-2.mm,slat_z),w-2*stile,depth+4.mm,slat_h,material)
        end
      end
      def build_dormer_window(entities,layout,wall_t,wall_height,materials,shutters=false)
        x=layout['x'];z=layout['z'];w=layout['width'];h=layout['height'];frame=[[[w,h].min*0.055,18.mm].max,28.mm].min
        box(entities,'siding','front_sill',p3(0,-wall_t,0),x*2+w,wall_t,z,materials[:siding])
        box(entities,'siding','front_left',p3(0,-wall_t,z),x,wall_t,h,materials[:siding])
        box(entities,'siding','front_right',p3(x+w,-wall_t,z),x,wall_t,h,materials[:siding])
        box(entities,'siding','front_head',p3(0,-wall_t,z+h),x*2+w,wall_t,wall_height-z-h,materials[:siding])
        box(entities,'frame','window_left',p3(x,-wall_t-15.mm,z),frame,wall_t+25.mm,h,materials[:frame])
        box(entities,'frame','window_right',p3(x+w-frame,-wall_t-15.mm,z),frame,wall_t+25.mm,h,materials[:frame])
        box(entities,'frame','window_bottom',p3(x+frame,-wall_t-15.mm,z),w-2*frame,wall_t+25.mm,frame,materials[:frame])
        box(entities,'frame','window_top',p3(x+frame,-wall_t-15.mm,z+h-frame),w-2*frame,wall_t+25.mm,frame,materials[:frame])
        box(entities,'glass','window_glass',p3(x+frame,-wall_t-10.mm,z+frame),w-2*frame,10.mm,h-2*frame,materials[:glass])
        mullion=[frame*0.72,16.mm].max
        box(entities,'frame','window_mullion',p3(x+w/2-mullion/2,-wall_t-16.mm,z+frame),mullion,wall_t+27.mm,h-2*frame,materials[:frame]) if w>320.mm
        rail=[frame*0.72,16.mm].max
        box(entities,'frame','window_meeting_rail',p3(x+frame,-wall_t-17.mm,z+h*0.46-rail/2),w-2*frame,wall_t+28.mm,rail,materials[:frame]) if h>300.mm
        if h>460.mm
          glazing_bar=[rail*0.55,8.mm].max
          [0.25,0.70].each_with_index do |ratio,index|
            box(entities,'frame',"window_glazing_bar_#{index+1}",p3(x+frame,-wall_t-18.mm,z+h*ratio-glazing_bar/2),w-2*frame,wall_t+29.mm,glazing_bar,materials[:frame])
          end
        end
        casing=[[[w,h].min*0.055,22.mm].max,36.mm].min;face_y=-wall_t-24.mm;face_depth=10.mm
        box(entities,'trim','window_casing_left',p3(x-casing,face_y,z-casing),casing,face_depth,h+2*casing,materials[:trim])
        box(entities,'trim','window_casing_right',p3(x+w,face_y,z-casing),casing,face_depth,h+2*casing,materials[:trim])
        box(entities,'trim','window_casing_head',p3(x,face_y,z+h),w,face_depth,casing,materials[:trim])
        box(entities,'trim','window_casing_apron',p3(x,face_y,z-casing),w,face_depth,casing,materials[:trim])
        cap_depth=wall_t+30.mm
        box(entities,'trim','window_drip_cap',p3(x-casing-8.mm,-wall_t-26.mm,z+h+casing),w+2*casing+16.mm,cap_depth,10.mm,materials[:trim])
        box(entities,'trim','window_sill_projection',p3(x-casing-8.mm,-wall_t-28.mm,z-casing-14.mm),w+2*casing+16.mm,wall_t+36.mm,14.mm,materials[:trim])
        if shutters
          total_width=x*2+w;corner=[[total_width*0.018,24.mm].max,36.mm].min;gap=18.mm
          available=x-casing-corner-2*gap;shutter_width=[[available*0.82,90.mm].max,w*0.30].min
          if shutter_width>=80.mm
            build_dormer_shutter(entities,'shutter_left',x-casing-gap-shutter_width,z-casing,shutter_width,h+2*casing,wall_t,materials[:trim])
            build_dormer_shutter(entities,'shutter_right',x+w+casing+gap,z-casing,shutter_width,h+2*casing,wall_t,materials[:trim])
          end
        end
      end
      def dormer_roof_clearance_at(solution,x,thickness)
        drops=solution['panels'].filter_map do |points|
          xs=points.map(&:x);next unless x>=xs.min-0.5.mm && x<=xs.max+0.5.mm
          normal=points[0].vector_to(points[1]).cross(points[0].vector_to(points[2]));next if normal.length<1e-9
          normal.normalize!;thickness/[normal.z.abs,0.10].max
        end
        (drops.max || thickness)+2.mm
      end
      def build_dormer_front(entities,p,solution,wall_t,materials)
        width=p['width'].to_f;eave=solution['eave'].to_f;thickness=p['thickness'].to_f
        edge_clearance=[dormer_roof_clearance_at(solution,0.0,thickness),dormer_roof_clearance_at(solution,width,thickness)].max
        height=solution['wall_height'].to_f-edge_clearance
        raise 'The Dormer roof is too thick for the fitted front wall. Increase the footprint depth or reduce roof thickness. / ضخامت سقف برای دیوار جلوی دورمر زیاد است؛ عمق را افزایش یا ضخامت را کاهش دهید.' unless height>120.mm
        show_window=p['window']!=false && p['window'].to_s!='false'
        shutters=show_window && p.fetch('dormer_type','gabled').to_s=='gabled' && p['shutters']!=false && p['shutters'].to_s!='false' && width>=1000.mm && height>=350.mm
        layout=show_window ? dormer_window_layout(width,height,shutters) : nil
        if layout;build_dormer_window(entities,layout,wall_t,height,materials,shutters)
        else;box(entities,'siding','front_wall',p3(0,-wall_t,0),width,wall_t,height,materials[:siding]);end
        profile=solution['profile'];crown=[p3(0,-wall_t,height),p3(width,-wall_t,height)]+profile[1...-1].to_a.reverse.map { |x,z| p3(x,-wall_t,z-dormer_roof_clearance_at(solution,x,thickness)) }
        if crown.length>=3 && crown.any? { |point| point.z>height+1.mm }
          part=Parts.make(entities,'siding','front_crown',materials[:siding]);face=part.entities.add_face(crown);raise 'Could not construct Dormer front crown.' unless face
          face.material=materials[:siding];face.back_material=materials[:siding]
          # The crown is drawn on the exterior plane at Y=-wall_t. Extrude it
          # toward Y=0, never outward in front of the window facade.
          inward=face.normal.y<0 ? -wall_t : wall_t
          face.pushpull(inward)
        end
        casing=[[width*0.018,24.mm].max,36.mm].min;depth=10.mm
        box(entities,'trim','facade_trim_left',p3(0,-wall_t-depth,0),casing,depth,height,materials[:trim])
        box(entities,'trim','facade_trim_right',p3(width-casing,-wall_t-depth,0),casing,depth,height,materials[:trim])
        box(entities,'trim','facade_trim_sill',p3(casing,-wall_t-depth,0),width-2*casing,depth,casing,materials[:trim])
        return_depth=[[wall_t*0.60,40.mm].max,70.mm].min
        box(entities,'trim','corner_return_left',p3(0,-wall_t,0),casing,wall_t+return_depth,height,materials[:trim])
        box(entities,'trim','corner_return_right',p3(width-casing,-wall_t,0),casing,wall_t+return_depth,height,materials[:trim])
      end
      def build_dormer_cheeks(entities,width,solution,wall_t,thickness,material)
        join_y,join_z=solution['cheek_join'];eave=solution['eave'].to_f
        [[0.0,'left',wall_t],[width,'right',-wall_t]].each do |x,name,extrusion|
          clearance=dormer_roof_clearance_at(solution,x,thickness);top_front=eave-clearance;top_rear=join_z-clearance
          part=Parts.make(entities,'siding',"cheek_#{name}",material);face=part.entities.add_face(p3(x,0,0),p3(x,join_y,top_rear),p3(x,0,top_front));raise 'Could not construct solid Dormer cheek.' unless face
          face.material=material;face.back_material=material;Parts.tag_face(face,'siding',"cheek_#{name}_face");face.pushpull(extrusion)
        end
      end
      def build_dormer_front_details(entities,solution,fascia_width,fascia_depth,materials)
        curved=solution['profile'].length>10
        outer=solution['front_profile'].map { |x,z| p3(x,-solution['overhang'].to_f,z) }
        last_fascia=outer.length-2
        outer.each_cons(2).with_index do |(a,b),index|
          lower_a=a.offset(Z_AXIS,-fascia_width);lower_b=b.offset(Z_AXIS,-fascia_width);part=Parts.make(entities,'fascia',"rake_fascia_#{index+1}",materials[:fascia])
          face=part.entities.add_face(a,b,lower_b,lower_a);raise 'Could not construct Dormer rake fascia.' unless face;face.material=materials[:fascia];face.back_material=materials[:fascia];face.pushpull(-fascia_depth)
          if curved
            soften_dormer_station(part,a.x) if index>0
            soften_dormer_station(part,b.x) if index<last_fascia
          end
        end
      end
      def build_dormer_roof_shell(entities,type,solution,thickness,material)
        curved=%w[eyebrow segmental barrel].include?(type);last_panel=solution['panels'].length-1
        solution['panels'].each_with_index do |points,index|
          normal=points[0].vector_to(points[1]).cross(points[0].vector_to(points[2]));raise "#{type.capitalize} Dormer produced a degenerate roof panel." if normal.length<1e-9;normal.normalize!
          raise "#{type.capitalize} Dormer produced a non-planar roof panel." unless points.all? { |point| points[0].vector_to(point).dot(normal).abs<0.05.mm }
          part=Parts.make(entities,'roof',"dormer_roof_#{index+1}",material);face=part.entities.add_face(points);raise "Could not construct #{type} Dormer roof panel #{index+1}." unless face
          face.reverse! if face.normal.z<0;face.material=material;face.back_material=material;face.pushpull(-thickness)
          if curved
            soften_dormer_station(part,points[0].x) if index>0
            soften_dormer_station(part,points[1].x) if index<last_panel
          end
        end
      end
      def build_dormer_procedural(p)
        solution=dormer_solution(p);group=root('Dormer',:roofs);width=p['width'].to_f;type=p.fetch('dormer_type','gabled').to_s
        front_window=p['window']!=false && p['window'].to_s!='false'
        materials={wall:mat(p,'wall_material',:wall_finish),siding:mat(p,'siding_material',:siding_light),roof:mat(p,'roof_material',:roof_shingle),frame:mat(p,'frame_material',:mullion_dark),trim:mat(p,'trim_material',:trim_light),fascia:mat(p,'fascia_material',:mullion_dark),glass:mat(p,'glass_material',:glass_clear)}
        wall_t=[[width*0.05,60.mm].max,120.mm].min;thickness=p['thickness'].to_f;fascia_width=[[width*0.022,26.mm].max,44.mm].min;fascia_depth=12.mm
        build_dormer_front(group.entities,p,solution,wall_t,materials);build_dormer_cheeks(group.entities,width,solution,wall_t,thickness,materials[:siding])
        build_dormer_front_details(group.entities,solution,fascia_width,fascia_depth,materials)
        build_dormer_roof_shell(group.entities,type,solution,thickness,materials[:roof])
        shutters=front_window && type=='gabled' && p['shutters']!=false && p['shutters'].to_s!='false' && width>=1000.mm && solution['wall_height'].to_f>=350.mm
        write(group,area_m2:width*solution['wall_height'].to_f*0.00064516,host_slope_rise_mm:p['host_slope_rise'].to_f*25.4,dormer_type:type,joined_depth_mm:solution['actual_depth']*25.4,roof_overhang_mm:solution['overhang'].to_f*25.4,reference_geometry:"#{type} exact host-plane intersection",drawn_depth_mm:solution['drawn_depth'].to_f*25.4,geometry_contract:solution['geometry_contract'],solid_cheeks:true,roof_shell_provides_soffit:true,separate_soffit_faces:false,shutters:shutters,siding_texture:true,roof_underside_clearance:true,physical_window_opening:front_window,window_reveals:front_window,fascia_width_mm:fascia_width*25.4,visual_refinement:'reference-gabled-v2',auto_extended:solution['auto_extended'],auto_fitted:solution['auto_fitted'],fit_scale:solution['fit_scale'])
      end
      def build_molding(p)
        g=root('Molding',:framing);m=mat(p,'material',:wall_finish)
        h=p['height'].to_f;pr=p['projection'].to_f
        prof=case p['profile'].to_s
        when 'crown'
          [[1.0,0.0]]+(1..5).map { |i| a=i*Math::PI/12;[Math.cos(a),Math.sin(a)] }+[[0.0,1.0],[0.0,0.0]]
        when 'cove'
          [[1.0,0.0]]+(1..5).map { |i| a=i*Math::PI/12;[1.0-Math.sin(a),1.0-Math.cos(a)] }+[[0.0,1.0],[0.0,0.0]]
        when 'chair_rail'
          [[0.0,0.0],[0.7,0.0],[1.0,0.35],[0.85,0.65],[0.5,1.0],[0.0,1.0]]
        else
          [[0.0,0.0],[1.0,0.0],[1.0,0.12],[0.55,0.2],[0.45,1.0],[0.0,1.0]]
        end
        catalog_profile=MoldingProfiles.fetch(p['profile'])
        if catalog_profile
          prof=catalog_profile['points'].map { |q| [q[0].to_f,q[1].to_f] }
        elsif p['profile'].to_s=='custom'
          cp=p['profile_points'];raise 'Pick a profile face first: More actions (...) then From selected face.' unless cp.is_a?(Array) && cp.length>2
          prof=cp.map { |q| [q[0].to_f,q[1].to_f] }
        end
        custom=p['profile'].to_s=='custom'
        if catalog_profile && p['preserve_profile_ratio']!=false
          sz=h;sy=h*catalog_profile['aspect'].to_f
        else
          sy=custom ? 1.0 : pr;sz=custom ? 1.0 : h
        end
        closed=p['closed']==true;pts=PathFrames.clean((p['path_points']||[]).map { |a| p3(*a) },closed)
        if !closed && p['return_length'].to_f>1.mm
          first_direction=pts[0].vector_to(pts[1]);first_direction.normalize!;first_side=Z_AXIS.cross(first_direction);first_side.normalize!;first_side.reverse! if p['flip_profile']==true
          last_direction=pts[-2].vector_to(pts[-1]);last_direction.normalize!;last_side=Z_AXIS.cross(last_direction);last_side.normalize!;last_side.reverse! if p['flip_profile']==true
          pts.unshift(pts.first.offset(first_side,p['return_length'].to_f)) if p['start_return']==true
          pts.push(pts.last.offset(last_side,p['return_length'].to_f)) if p['end_return']==true
        end
        segments=PathFrames.segments(pts,closed)
        raise 'Molding path contains a zero-length segment.' if segments.any? { |a,b| a.distance(b)<1.mm }
        total=segments.sum { |a,b| a.distance(b) }
        tangent=segments.first[0].vector_to(segments.first[1]);tangent.normalize!;surface=p['path_surface_normal'];side=nil
        if surface.is_a?(Array) && surface.length>=3
          candidate=Geom::Vector3d.new(surface[0].to_f,surface[1].to_f,surface[2].to_f);dot=candidate.dot(tangent)
          candidate=Geom::Vector3d.new(candidate.x-tangent.x*dot,candidate.y-tangent.y*dot,candidate.z-tangent.z*dot);side=candidate if candidate.length>1e-8
        end
        side||=Z_AXIS.cross(tangent);side=X_AXIS.cross(tangent) if side.length<1e-8;raise 'Cannot orient the molding profile on this path.' if side.length<1e-8
        side.normalize!;side.reverse! if p['flip_profile']==true
        rotation=p['profile_rotation'].to_f*Math::PI/180.0;side.transform!(Geom::Transformation.rotation(ORIGIN,tangent,rotation)) if rotation.abs>1e-8
        up=tangent.cross(side);raise 'Cannot calculate molding profile frame.' if up.length<1e-8;up.normalize!
        part=Parts.make(g.entities,'molding','molding_sweep',m);entities=part.entities;anchor=MoldingProfiles.anchor(prof,p['profile_anchor'])
        profile_points=Builders.clean_points(prof.map { |py,pz| pts.first.offset(side,(py-anchor[0])*sy).offset(up,(pz-anchor[1])*sz) })
        profile_face=entities.add_face(profile_points);raise 'The molding profile is invalid or self-intersecting.' unless profile_face
        profile_face.reverse! if profile_face.normal.dot(tangent)<0
        path_edges=segments.map { |a,b| entities.add_line(a,b) }.compact;raise 'Could not construct the complete molding path.' unless path_edges.length==segments.length
        succeeded=profile_face.followme(path_edges);raise 'SketchUp Follow Me could not sweep the complete molding path.' unless succeeded
        path_edges.each { |edge| edge.erase! if edge.valid? && edge.faces.empty? }
        entities.grep(Sketchup::Face).each_with_index do |face,face_index|
          face.material=m;face.back_material=m;Parts.tag_face(face,'molding',"molding_surface_#{face_index}")
        end
        entities.grep(Sketchup::Edge).each do |edge|
          next unless edge.faces.length==2
          edge_angle=edge.faces[0].normal.angle_between(edge.faces[1].normal)
          if edge_angle<50.0*Math::PI/180.0;edge.soft=true;edge.smooth=true;end
        end
        write(g,length_mm:total*25.4,segment_count:segments.length)
      end

    end
  end
end
