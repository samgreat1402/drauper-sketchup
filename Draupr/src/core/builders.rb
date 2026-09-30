# frozen_string_literal: true
module Draupr
  module Core
    module Builders
      module_function
      def root(name,tag);Geometry.group("Draupr #{name}",tag);end
      def p3(x=0,y=0,z=0);Geom::Point3d.new(x.to_f,y.to_f,z.to_f);end
      def mat(p,key,fallback);Parts.material_for(p,key,fallback);end
      def box(e,role,key,o,w,d,h,m);Parts.box(e,role,key,o,w,d,h,m);end
      def write(g,v);Metadata.write(g,v);g;end
      def build(kind,p)
        raise 'Unsupported object builder' unless respond_to?("build_#{kind}")
        send("build_#{kind}",p)
      end
      def clean_points(points)
        out=[];points.each { |p| out<<p if out.empty? || out.last.distance(p)>0.001 }
        out.pop if out.length>1 && out.first.distance(out.last)<0.001;out
      end
      def polygon_area(pts)
        pts.each_with_index.sum { |a,i| b=pts[(i+1)%pts.length];a.x.to_f*b.y.to_f-b.x.to_f*a.y.to_f }.abs/2
      end
      def face(e,pts,m,role,key)
        f=e.add_face(clean_points(pts));raise "Cannot construct #{key}" unless f
        f.material=m;f.back_material=m;Parts.tag_face(f,role,key);f
      end
      def point_segment_distance(point,a,b)
        vector=a.vector_to(b);length=vector.length;return point.distance(a) if length<1e-9
        vector.normalize!;station=[[a.vector_to(point).dot(vector),0.0].max,length].min
        point.distance(a.offset(vector,station))
      end
      def polygon_contains_or_touches?(point,polygon,normal)
        point_in_poly?(point,polygon,normal) || polygon.each_with_index.any? { |a,index| point_segment_distance(point,a,polygon[(index+1)%polygon.length])<=0.1.mm }
      end
      def erase_planar_region(entities,polygon,normal)
        points=clean_points(polygon);return 0 if points.length<3
        n=normal.clone;n.normalize!
        points.each_with_index { |point,index| entities.add_line(point,points[(index+1)%points.length]) }
        # Explicitly seed the coplanar inner face. On some SketchUp versions,
        # four independently added edges do not form the inner region until a
        # face is requested, even though they already split the outer sheet.
        entities.add_face(points)
        matches=entities.grep(Sketchup::Face).select do |candidate|
          next false unless candidate.valid? && candidate.normal.parallel?(n)
          vertices=candidate.vertices.map(&:position)
          vertices.all? { |vertex| points[0].vector_to(vertex).dot(n).abs<=0.1.mm && polygon_contains_or_touches?(vertex,points,n) }
        end
        matches.each { |candidate| candidate.erase! if candidate.valid? };matches.length
      end
      def sheet_solid(e,pts,th,p,key,holes=[])
        up=clean_points(pts);g=e.add_group;g.name=key;g.layer=Sketchup.active_model.layers[0]
        down=up.map { |a| p3(a.x,a.y,a.z-th) }
        top=face(g.entities,up,mat(p,'top_material',:timber),'top',"#{key}_top");top.reverse! if top && top.normal.z<0
        under=face(g.entities,down.reverse,mat(p,'underside_material',:wall_finish),'underside',"#{key}_underside");under.reverse! if under && under.normal.z>0
        up.each_with_index { |a,i| j=(i+1)%up.length;face(g.entities,[a,down[i],down[j],up[j]],mat(p,'edge_material',:timber),'edge',"#{key}_edge_#{i}") }
        holes.each_with_index do |hp,hi|
          hd=hp.map { |a| p3(a.x,a.y,a.z-th) }
          normal=up[0].vector_to(up[1]).cross(up[1].vector_to(up[2]));raise "Cannot resolve #{key} opening plane" if normal.length<1e-9;normal.normalize!
          removed_top=erase_planar_region(g.entities,hp,normal);removed_bottom=erase_planar_region(g.entities,hd,normal)
          raise "Cannot cut #{key} opening #{hi+1}" if removed_top<1 || removed_bottom<1
          hp.each_with_index do |a,i|
            j=(i+1)%hp.length;b=hp[j]
            boundary=up.each_index.find { |edge_index| edge_next=(edge_index+1)%up.length;point_segment_distance(a,up[edge_index],up[edge_next])<=0.1.mm && point_segment_distance(b,up[edge_index],up[edge_next])<=0.1.mm }
            if boundary
              cutter=[a,hd[i],hd[j],b];side_normal=cutter[0].vector_to(cutter[1]).cross(cutter[1].vector_to(cutter[2]))
              erase_planar_region(g.entities,cutter,side_normal) if side_normal.length>1e-9
            else
              face(g.entities,[a,hd[i],hd[j],b],mat(p,'edge_material',:timber),'edge',"#{key}_hole_#{hi}_edge_#{i}")
            end
          end
        end
        g
      end
      def footprint(p)
        p['footprint'].is_a?(Array) && p['footprint'].length>=3 ? p['footprint'].map { |a| p3(*a) } : [p3,p3(p['width']),p3(p['width'],p['depth']),p3(0,p['depth'])]
      end
      def bar_between(e,role,key,a,b,w,h,m)
        x=a.vector_to(b);return nil if x.length<0.5.mm
        len=x.length;x.normalize!
        reference=[X_AXIS,Y_AXIS,Z_AXIS].min_by { |axis| x.dot(axis).abs }
        y=reference.cross(x);return nil if y.length<1e-9;y.normalize!
        z=x.cross(y);return nil if z.length<1e-9;z.normalize!
        part=box(e,role,key,p3(0,-w/2,-h/2),len,w,h,m);part.transformation=Geom::Transformation.axes(a,x,y,z);part
      end
      def build_column(p)
        g=root('Column',:columns);m=mat(p,'material',:concrete)
        if p['shape']=='round'
          Parts.cylinder(g.entities,'structure','column',ORIGIN,p['radius'],p['height'],m,40);v=Math::PI*p['radius']**2*p['height']
        else
          box(g.entities,'structure','column',p3(-p['width']/2,-p['depth']/2),p['width'],p['depth'],p['height'],m);v=p['width']*p['depth']*p['height']
        end
        write(g,volume_m3:v*0.000016387064)
      end
      def build_foundation(p)
        g=root('Foundation',:foundations);type=p['foundation_type'].to_s;m=mat(p,'material',:foundation)
        if type=='raft'
          w=p['width'].to_f;d=p['depth'].to_f;h=p['height'].to_f
          box(g.entities,'structure','raft_slab',p3(0,0,-h),w,d,h,m)
          volume=w*d*h
          if p['edge_beam']
            eb=[300.mm,w*0.2,d*0.2].min
            box(g.entities,'structure','edge_front',p3(0,0,-2*h),w,eb,h,m)
            box(g.entities,'structure','edge_back',p3(0,d-eb,-2*h),w,eb,h,m)
            box(g.entities,'structure','edge_left',p3(0,eb,-2*h),eb,d-2*eb,h,m)
            box(g.entities,'structure','edge_right',p3(w-eb,eb,-2*h),eb,d-2*eb,h,m)
            volume+=2*w*eb*h+2*(d-2*eb)*eb*h
          end
          write(g,volume_m3:volume*0.000016387064,area_m2:w*d*0.00064516)
        elsif type=='strip'
          pts=PathFrames.clean((p['path_points']||[]).map { |a| p3(*a) },p['closed']==true)
          sw=p['width'].to_f;sd=p['height'].to_f;segments=PathFrames.segments(pts,p['closed']==true);total=segments.sum { |a,b| a.distance(b) }
          polygons=Geometry.wall_path_polygons(pts,-sw/2.0,sw/2.0,p['closed']==true)
          offsets=p['segment_z_offsets']||{}
          polygons.each_with_index do |poly,index|
            part=Parts.make(g.entities,'structure',"strip_continuous_#{index}",m);offset=offsets.fetch(index.to_s,offsets.fetch(index,0.0)).to_f
            base=poly.map { |point| point.offset(Z_AXIS,-sd+offset) };face=Geometry.add_prism(part.entities,base,sd,m)
            raise 'Could not construct continuous strip foundation. / ساخت فونداسیون نواری پیوسته ممکن نشد.' unless face
          end
          write(g,volume_m3:total*sw*sd*0.000016387064,length_mm:total*25.4,continuous_path:true)
        else
          box(g.entities,'structure','footing',p3(-p['width']/2,-p['depth']/2),p['width'],p['depth'],p['height'],m)
          write(g,volume_m3:p['width']*p['depth']*p['height']*0.000016387064)
        end
        g
      end
      def build_beam(p)
        g=root('Beam',:beams);y0=case p['alignment'];when 'inside' then 0;when 'outside' then -p['width'];else -p['width']/2;end;m=mat(p,'material',:concrete)
        raw=p['path_points'].is_a?(Array) ? p['path_points'].map { |a| p3(*a) } : [ORIGIN,p3(p['length'])];pts=PathFrames.clean(raw,false);total=0.0
        PathFrames.segments(pts,false).each_with_index do |(a,b),i|
          v=a.vector_to(b);len=v.length;next if len<1.mm;x=v.normalize;y=Z_AXIS.cross(x);y=Y_AXIS.clone if y.length<1e-8;y.normalize!;z=x.cross(y);z.normalize!
          part=box(g.entities,'structure',"beam_#{i}",p3(0,y0),len,p['width'],p['height'],m);part.transformation=Geom::Transformation.axes(a,x,y,z);total+=len
        end
        write(g,length_mm:total*25.4,volume_m3:total*p['width']*p['height']*0.000016387064)
      end
      def build_slab(p)
        g=root('Slab',:slabs);pts=footprint(p)
        sheet_solid(g.entities,pts.map { |a| a.offset(Z_AXIS,p['thickness']) },p['thickness'],p,'slab')
        a=polygon_area(pts);write(g,area_m2:a*0.00064516,volume_m3:a*p['thickness']*0.000016387064)
      end
      def grid_positions(p,axis)
        if p['layout_mode']=='custom'
          text=p[axis=='x' ? 'bays_x' : 'bays_y'].to_s
          bays=text.split(/[,;\n]+/).map { |v| Parameters.length(v) }
          raise 'Enter at least one positive bay width.' if bays.empty? || bays.any? { |v| v<=1.mm }
          bays.each_with_object([0.0]) { |v,a| a<<a.last+v }
        else
          count=p[axis=='x' ? 'count_x' : 'count_y'].to_i;spacing=p[axis=='x' ? 'spacing_x' : 'spacing_y']
          (0...count).map { |i| i*spacing }
        end
      end
      def grid_label(index)
        value=index.to_i+1;label=''
        while value>0
          value,remainder=(value-1).divmod(26);label=(65+remainder).chr+label
        end
        label
      end
      def build_grid(p)
        g=root('Grid',:documentation);e=g.entities;ex=900.mm;xs=grid_positions(p,'x');ys=grid_positions(p,'y');lx=xs.last;ly=ys.last
        xs.each_with_index { |x,i| a=p3(x,-ex);b=p3(x,ly+ex);e.add_cline(a,b);e.add_circle(a,Z_AXIS,180.mm,24);e.add_text((i+1).to_s,a) }
        ys.each_with_index { |y,j| a=p3(-ex,y);b=p3(lx+ex,y);e.add_cline(a,b);e.add_circle(a,Z_AXIS,180.mm,24);e.add_text(grid_label(j),a) };g
      end
      def curtain_lines(total,spacing,count,mode,distribution)
        if mode=='count' || distribution=='equal'
          n=mode=='count' ? count.to_i : (total/spacing).ceil;n=[n,1].max;(0..n).map { |i| total*i/n.to_f }
        else
          lines=[0.0];x=spacing;while x<total-0.001;lines<<x;x+=spacing;end;lines<<total;lines
        end
      end
      def clear_bay_lines(total,n,member)
        clear=(total-(n+1)*member)/n.to_f
        raise 'Frame members leave no clear panel.' if clear<=1.mm
        [0.0]+(1...n).map { |i| member+clear+(i-1)*(clear+member)+member/2 }+[total]
      end
      def curtain_grid(p)
        if p['grid_mode']=='count' || p['distribution']=='equal'
          nx,ny=Parameters.curtain_counts(p)
          return [clear_bay_lines(p['width'],nx,p['mullion_width']),clear_bay_lines(p['height'],ny,p['transom_width'])]
        end
        [curtain_lines(p['width'],p['grid_x'],p['count_x'],p['grid_mode'],p['distribution']),curtain_lines(p['height'],p['grid_y'],p['count_y'],p['grid_mode'],p['distribution'])]
      end
      def build_curtain_wall(p)
        if p['path_points'].is_a?(Array) && p['path_points'].length>1
          g=root('Curtain Wall',:curtain_frames);closed=p['closed']==true;pts=PathFrames.clean(p['path_points'].map { |a| p3(*a) },closed);segments=PathFrames.segments(pts,closed)
          total=0.0;panels=0
          segments.each_with_index do |(a,b),i|
            v=a.vector_to(b);len=v.length;next if len<1.mm
            q=p.merge('width'=>len,'omit_start_mullion'=>(i>0 || closed),'omit_end_mullion'=>false);q.delete('path_points');q['closed']=false
            part=Geometry.with_entities(g.entities) { build_curtain_wall(q) }
            part.name="curtain segment #{i+1}"
            x=v.normalize;y=Z_AXIS.cross(x);y=Y_AXIS.clone if y.length<1e-8;y.normalize!;z=x.cross(y);z.normalize!;part.transformation=Geom::Transformation.axes(a,x,y,z)
            total+=len;panels+=Parameters.curtain_counts(q).inject(:*)
          end
          return write(g,length_mm:total*25.4,area_m2:total*p['height']*0.00064516,panels:panels)
        end
        g=root('Curtain Wall',:curtain_frames);xs,zs=curtain_grid(p);w=p['mullion_width'];t=p['transom_width'];d=p['mullion_depth']
        mm=mat(p,'mullion_material',:mullion_dark);tm=mat(p,'transom_material',:mullion_dark);gm=mat(p,'glass_material',:glass_clear);im=mat(p,'panel_material',:steel)
        xs.each_with_index do |x,i|
          next if i==0 && p['omit_start_mullion']==true
          next if i==xs.length-1 && p['omit_end_mullion']==true
          x0=i==0 ? 0.0 : (i==xs.length-1 ? x-w : x-w/2);box(g.entities,'mullion',"mullion_#{i}",p3(x0),w,d,p['height'],mm)
        end
        ranges=xs.each_cons(2).with_index.map { |(a,b),i| [a+(i==0 ? w : w/2),b-(i==xs.length-2 ? w : w/2)] }
        zs.each_with_index do |z,j|
          z0=j==0 ? 0 : (j==zs.length-1 ? z-t : z-t/2)
          ranges.each_with_index do |(x1,x2),i|
            raise 'Bay too narrow: use Equal bays or reduce frame size.' if x2-x1<=1.mm
            box(g.entities,'transom',"transom_#{j}_#{i}",p3(x1,0,z0),x2-x1,d,t,tm)
          end
        end
        area=0.0;count=0;ov=p.fetch('panel_overrides',{})
        ranges.each_with_index do |(x1,x2),i|
          zs.each_cons(2).with_index do |(za,zb),j|
            z1=za+(j==0 ? t : t/2);z2=zb-(j==zs.length-2 ? t : t/2)
            raise 'Bay too short: use Equal bays or reduce transom size.' if z2-z1<=1.mm
            key="panel_#{j}_#{i}";o=ov.fetch(key,{});next if o['type']=='open';opaque=o['type']=='spandrel'
            m=o['material'].to_s.empty? ? (opaque ? im : gm) : Materials.by_name_or_default(o['material'],opaque ? :steel : :glass_clear)
            thick=opaque ? [25.mm,d].min : p['glass_thickness']
            pane=box(g.entities,opaque ? 'infill' : 'glass',key,p3(x1,(d-thick)/2,z1),x2-x1,thick,z2-z1,m)
            pane.set_attribute(Parts::DICT,'row',j);pane.set_attribute(Parts::DICT,'column',i);pane.name="Panel R#{j+1} C#{i+1}"
            area+=(x2-x1)*(z2-z1);count+=1
          end
        end
        write(g,area_m2:area*0.00064516,panels:count)
      end
      def opening_frame(g,p,window)
        m=mat(p,'frame_material',:mullion_dark);w=p['width'];h=p['height'];f=p['frame'];d=p['depth']+15.mm;z=window ? p['sill'] : 0
        box(g.entities,'frame','frame_left',p3(0,-7.5.mm,z),f,d,h,m);box(g.entities,'frame','frame_right',p3(w-f,-7.5.mm,z),f,d,h,m)
        box(g.entities,'frame','frame_header',p3(f,-7.5.mm,z+h-f),w-2*f,d,f,m)
        box(g.entities,'frame','frame_sill',p3(f,-7.5.mm,z),w-2*f,d,f,m) if window
      end
      def flip_contents(g,p)
        return unless p['flip'];g.entities.transform_entities(Geom::Transformation.scaling(p3(p['width']/2,p['depth']/2),1,-1,1),g.entities.to_a)
      end
      def build_door(p)
        g=root('Door',:openings);opening_frame(g,p,false);f=p['frame'];w=p['width']-2*f;t=p['leaf_thickness'];y=(p['depth']-t)/2;type=p['door_type'].to_s
        lm=mat(p,'leaf_material',:door_leaf);fm=mat(p,'frame_material',:mullion_dark)
        case type
        when 'double'
          lw=(w-6.mm)/2
          [0,1].each do |idx|
            x0=f+idx*(lw+6.mm)
            leaf=box(g.entities,'leaf',"door_leaf_#{idx}",p3(x0,y),lw,t,p['height']-f,lm)
            pivot=p3(idx==0 ? f : p['width']-f,y)
            dir=idx==0 ? 1 : -1
            leaf.transformation=Geom::Transformation.rotation(pivot,Z_AXIS,p['swing_angle']*Math::PI/180*dir)
          end
        when 'sliding'
          off=(p['handing']=='right' ? 1 : -1)*w
          tx=[f,f+off].min
          box(g.entities,'frame','sliding_track',p3(tx,y-15.mm,p['height']+20.mm),2*w,40.mm,40.mm,fm)
          box(g.entities,'leaf','door_leaf',p3(f+off,y),w,t,p['height']-f,lm)
        when 'glazed'
          h=p['height']-f;st=f*0.9;gt=12.mm
          gm=mat(p,'glass_material',:glass_clear)
          box(g.entities,'leaf','glazed_stile_l',p3(f,y),st,t,h,lm)
          box(g.entities,'leaf','glazed_stile_r',p3(f+w-st,y),st,t,h,lm)
          box(g.entities,'leaf','glazed_rail_b',p3(f+st,y),w-2*st,t,h*0.22,lm)
          box(g.entities,'leaf','glazed_rail_m',p3(f+st,y,h*0.55),w-2*st,t,st,lm)
          box(g.entities,'leaf','glazed_rail_t',p3(f+st,y,h-st),w-2*st,t,st,lm)
          box(g.entities,'glass','glazed_panel',p3(f+st,(p['depth']-gt)/2,h*0.22),w-2*st,gt,h*0.33,gm)
          box(g.entities,'leaf','glazed_lower',p3(f+st,y+t*0.2,h*0.02),w-2*st,t*0.6,h*0.18,lm)
        else
          leaf=box(g.entities,'leaf','door_leaf',p3(f,y),w,t,p['height']-f,lm)
          pivot=p3(p['handing']=='right' ? p['width']-f : f,y)
          leaf.transformation=Geom::Transformation.rotation(pivot,Z_AXIS,p['swing_angle']*Math::PI/180*(p['handing']=='right' ? -1 : 1))
        end
        flip_contents(g,p);write(g,area_m2:p['width']*p['height']*0.00064516)
      end
      def build_window(p)
        g=root('Window',:openings);f=p['frame'];w=p['width'];h=p['height'];d=p['depth'];z=p['sill'];type=p['window_type'].to_s
        fm=mat(p,'frame_material',:mullion_dark);gm=mat(p,'glass_material',:glass_clear);gt=p['glass_thickness']
        sf=f*0.7
        case type
        when 'double_hung'
          opening_frame(g,p,true)
          sh=(h-2*f)/2
          [[0,3.mm],[1,-3.mm]].each do |idx,yoff|
            z0=z+f+idx*sh;sy=(d-gt)/2+yoff
            box(g.entities,'frame',"sash#{idx}_stile_l",p3(f,sy,z0),sf,gt,sh,fm)
            box(g.entities,'frame',"sash#{idx}_stile_r",p3(w-f-sf,sy,z0),sf,gt,sh,fm)
            box(g.entities,'frame',"sash#{idx}_rail_b",p3(f+sf,sy,z0),w-2*f-2*sf,gt,idx==0 ? f : sf,fm)
            box(g.entities,'frame',"sash#{idx}_rail_t",p3(f+sf,sy,z0+sh-sf),w-2*f-2*sf,gt,sf,fm)
            box(g.entities,'glass',"sash#{idx}_glass",p3(f+sf,sy,z0+sf),w-2*f-2*sf,gt,sh-2*sf,gm)
          end
        when 'casement'
          opening_frame(g,p,true)
          sw=(w-2*f)/2;sy=(d-gt)/2
          [0,1].each do |idx|
            x0=f+idx*sw
            box(g.entities,'frame',"cas#{idx}_stile_l",p3(x0,sy,z+f),sf,gt,h-2*f,fm)
            box(g.entities,'frame',"cas#{idx}_stile_r",p3(x0+sw-sf,sy,z+f),sf,gt,h-2*f,fm)
            box(g.entities,'frame',"cas#{idx}_rail_b",p3(x0+sf,sy,z+f),sw-2*sf,gt,sf,fm)
            box(g.entities,'frame',"cas#{idx}_rail_t",p3(x0+sf,sy,z+h-f-sf),sw-2*sf,gt,sf,fm)
            box(g.entities,'glass',"cas#{idx}_glass",p3(x0+sf,sy,z+f+sf),sw-2*sf,gt,h-2*f-2*sf,gm)
          end
        when 'sliding'
          opening_frame(g,p,true)
          overlap=40.mm;sw=(w-2*f+overlap)/2
          [[0,3.mm],[1,-3.mm]].each do |idx,yoff|
            x0=f+idx*(sw-overlap);sy=(d-gt)/2+yoff
            box(g.entities,'frame',"sld#{idx}_stile_l",p3(x0,sy,z+f),sf,gt,h-2*f,fm)
            box(g.entities,'frame',"sld#{idx}_stile_r",p3(x0+sw-sf,sy,z+f),sf,gt,h-2*f,fm)
            box(g.entities,'frame',"sld#{idx}_rail_b",p3(x0+sf,sy,z+f),sw-2*sf,gt,sf,fm)
            box(g.entities,'frame',"sld#{idx}_rail_t",p3(x0+sf,sy,z+h-f-sf),sw-2*sf,gt,sf,fm)
            box(g.entities,'glass',"sld#{idx}_glass",p3(x0+sf,sy,z+f+sf),sw-2*sf,gt,h-2*f-2*sf,gm)
          end
        when 'arched'
          d2=d+15.mm
          rise=[(w-2*f)/2,(h-2*f)*0.5].min
          zs=z+h-f-rise
          box(g.entities,'frame','frame_left',p3(0,-7.5.mm,z),f,d2,zs-z,fm)
          box(g.entities,'frame','frame_right',p3(w-f,-7.5.mm,z),f,d2,zs-z,fm)
          box(g.entities,'frame','frame_sill',p3(f,-7.5.mm,z),w-2*f,d2,f,fm)
          cx=w/2;ri=(w-2*f)/2;ro=ri+f
          nseg=12
          band=(0..nseg).map { |i| a=Math::PI-i*Math::PI/nseg;p3(cx+ro*Math.cos(a),-7.5.mm,zs+ro*Math.sin(a)) }
          band_inner=(0..nseg).map { |i| a=i*Math::PI/nseg;p3(cx+ri*Math.cos(a),-7.5.mm,zs+ri*Math.sin(a)) }
          bp=Parts.make(g.entities,'frame','arch_band',fm)
          bf=bp.entities.add_face(band+band_inner)
          bf.pushpull(bf.normal.y>0 ? d2 : -d2) if bf
          spand=(0..nseg).map { |i| a=Math::PI-i*Math::PI/nseg;p3(cx+ro*Math.cos(a),-7.5.mm,zs+ro*Math.sin(a)) }
          spand += [p3(w,-7.5.mm,z+h),p3(0,-7.5.mm,z+h)]
          sp=Parts.make(g.entities,'frame','arch_spandrel',fm)
          spf=sp.entities.add_face(spand)
          spf.pushpull(spf.normal.y>0 ? d2 : -d2) if spf
          gpts=[p3(f,(d-gt)/2,z+f),p3(f,(d-gt)/2,zs)]
          gpts += (1...nseg).map { |i| a=Math::PI-i*Math::PI/nseg;p3(cx+ri*Math.cos(a),(d-gt)/2,zs+ri*Math.sin(a)) }
          gpts += [p3(w-f,(d-gt)/2,zs),p3(w-f,(d-gt)/2,z+f)]
          gp=Parts.make(g.entities,'glass','window_glass_0',gm)
          gf=gp.entities.add_face(gpts)
          gf.pushpull(gf.normal.y>0 ? gt : -gt) if gf
          nmu=p['mullions'];inner=w-2*f
          centers=(1..nmu).map { |i| f+i*inner/(nmu+1.0) }
          centers.each_with_index { |x,i| box(g.entities,'frame',"window_mullion_#{i}",p3(x-f/2,-7.5.mm,z+f),f,d2,zs-z-f,fm) }
        else
          opening_frame(g,p,true)
          n=p['mullions'];inner=w-2*f
          centers=(1..n).map { |i| f+i*inner/(n+1.0) }
          centers.each_with_index { |x,i| box(g.entities,'frame',"window_mullion_#{i}",p3(x-f/2,-7.5.mm,z+f),f,d+15.mm,h-2*f,fm) }
          edges=[f]+centers.flat_map { |x| [x-f/2,x+f/2] }+[w-f]
          edges.each_slice(2).with_index { |(a,b),i| box(g.entities,'glass',"window_glass_#{i}",p3(a,(d-gt)/2,z+f),b-a,gt,h-2*f,gm) }
        end
        flip_contents(g,p);write(g,area_m2:w*h*0.00064516)
      end
    end
  end
end
