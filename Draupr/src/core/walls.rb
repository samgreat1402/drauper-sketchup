# frozen_string_literal: true
module Draupr
  module Core
    module Walls
      EPS=0.5.mm
      module_function
      def point(a);Geom::Point3d.new(a.map { |v| Parameters.coord(v) });end
      def xyz(p);[p.x.to_f,p.y.to_f,p.z.to_f];end
      def profile(p)
        a,b=Geometry.alignment_offsets(p['thickness'],p['alignment'])
        if p['wall_type']=='cavity'
          leaf=(p['thickness']-p['cavity_width'])/2;[[a,a+leaf,'inner',p['inner_material']],[b-leaf,b,'outer',p['outer_material']]]
        elsif p['assembly']=='custom';[[a,b,'core',p['core_material']]]
        else
          core=p['core_material']
          [[a,a+p['inner_thickness'],'inner',p['inner_material']],[a+p['inner_thickness'],b-p['outer_thickness'],'core',core],[b-p['outer_thickness'],b,'outer',p['outer_material']]]
        end
      end
      def apply_end_overrides(polygons,full,p,count)
        overrides=p['wall_end_overrides']||{}
        [['start',0,0,3],['end',count-1,1,2]].each do |key,seg,i0,i1|
          o=overrides[key];next unless o && seg && seg>=0 && full[seg]
          if o['full'].is_a?(Array) && o['full'].length==2;full[seg][i0]=point(o['full'][0]);full[seg][i1]=point(o['full'][1]);end
          (o['layers']||[]).each_with_index do |pair,li|;next unless polygons[li]&&polygons[li][seg]&&pair.is_a?(Array)&&pair.length==2;polygons[li][seg][i0]=point(pair[0]);polygons[li][seg][i1]=point(pair[1]);end
        end
      end
      def geometry(p)
        return p['legacy_segments'] if p['legacy_segments']
        pts=Builders.clean_points((p['path_points']||[[0,0,0],[p['length'],0,0]]).map { |a| point(a) })
        raise 'A wall needs two distinct points.' if pts.length<2
        closed=p['closed']==true && pts.length>2;layers=profile(p)
        polygons=layers.map { |a,b,_,_| Geometry.wall_path_polygons(pts,a,b,closed) }
        a,b=Geometry.alignment_offsets(p['thickness'],p['alignment']);full=Geometry.wall_path_polygons(pts,a,b,closed)
        count=closed ? pts.length : pts.length-1;apply_end_overrides(polygons,full,p,count)
        height_overrides=p['segment_height_overrides']||{}
        (0...count).map do |i|
          q=full[i];cs=Geometry.midpoint(q[0],q[3]);ce=Geometry.midpoint(q[1],q[2]);height=height_overrides.fetch(i.to_s,height_overrides.fetch(i,p['height'])).to_f
          raise 'Wall segment height must be positive. / ارتفاع بخش دیوار باید مثبت باشد.' if height<=1.mm
          {'cs'=>xyz(cs),'ce'=>xyz(ce),'height'=>height,'depth'=>p['thickness'],'layers'=>layers.each_with_index.map { |l,j| {'quad'=>polygons[j][i].map { |pt| xyz(pt) },'role'=>l[2],'material'=>l[3]} }}
        end
      end
      def segments(g)
        d=Metadata.read(g);return JSON.parse(d['wall_segments']) if d['wall_segments']
        Tools::Walls::Carve.segments_from(d).map do |s|
          {'cs'=>xyz(s[:cs]),'ce'=>xyz(s[:ce]),'height'=>s[:height].to_f,'depth'=>d.fetch('thickness_mm',200).to_f.mm.to_f,'layers'=>s[:layers].each_with_index.map { |l,i| {'quad'=>l['quad'].map { |q| xyz(q) },'role'=>s[:layers].length==1 ? 'core' : (i==0 ? 'inner' : (i==s[:layers].length-1 ? 'outer' : 'core')),'material'=>l['m']} }}
        end
      end
      def holes(g)
        JSON.parse(g.get_attribute('Draupr','openings','[]')).map { |o| o.merge('t1'=>Parameters.coord(o['t1']),'t2'=>Parameters.coord(o['t2']),'z0'=>Parameters.coord(o['z0']),'z1'=>Parameters.coord(o['z1']),'seg'=>(o['seg']||0).to_i) }
      end
      def clip(points,cut,dir,positive)
        out=[]
        points.each_with_index do |a,i|
          b=points[(i+1)%points.length];da=cut.vector_to(a).dot(dir);db=cut.vector_to(b).dot(dir);ia=positive ? da>=-1e-9 : da<=1e-9;ib=positive ? db>=-1e-9 : db<=1e-9;out<<a if ia
          if ia!=ib && (da-db).abs>1e-12
            t=da/(da-db);out<<Geom::Point3d.new(a.x+(b.x-a.x)*t,a.y+(b.y-a.y)*t,a.z+(b.z-a.z)*t)
          end
        end
        Builders.clean_points(out)
      end
      def clip_range(q,cs,d,a,b);clip(clip(q,cs.offset(d,a),d,true),cs.offset(d,b),d,false);end
      def complement(ranges,lo,hi)
        out=[];cursor=lo
        ranges.sort_by(&:first).each { |a,b| a=[[a,lo].max,hi].min;b=[[b,lo].max,hi].min;next if b-a<EPS;out<<[cursor,a] if a-cursor>EPS;cursor=[cursor,b].max }
        out<<[cursor,hi] if hi-cursor>EPS;out
      end
      def check_holes(segs,holes)
        holes.each do |o|
          s=segs[o.fetch('seg',0)];raise 'Opening segment is missing.' unless s
          len=point(s['cs']).distance(point(s['ce']))
          raise 'An opening no longer fits. Resize or move the opening first.' if o['t1'] < -EPS || o['t2']>len+EPS || o['z0']<0 || o['z1']>s['height']+EPS
        end
        holes.combination(2) { |a,b| next unless a.fetch('seg',0)==b.fetch('seg',0);raise 'Openings overlap.' if a['t1']<b['t2']-EPS && b['t1']<a['t2']-EPS && a['z0']<b['z1']-EPS && b['z0']<a['z1']-EPS }
      end
      def constraint_record(p,key);record=p[key];record.is_a?(Hash) ? record : nil;end
      def plane_z(plane,point,fallback)
        return fallback unless plane.is_a?(Array) && plane.length==4
        hit=Geom.intersect_line_plane([Geom::Point3d.new(point.x,point.y,fallback),Z_AXIS],plane.map(&:to_f))
        raise 'Wall boundary plane is vertical. / صفحه مرزی دیوار عمودی است.' unless hit;hit.z
      end
      def point_segment_distance(point,a,b)
        vector=a.vector_to(b);return point.distance(a) if vector.length<1e-9;length=vector.length;vector.normalize!;station=[[a.vector_to(point).dot(vector),0.0].max,length].min;point.distance(a.offset(vector,station))
      end
      def surface_contains?(surface,query,fallback,tolerance=2.mm)
        polygon=Array(surface['polygon']).map { |value| point(value) };return false if polygon.length<3
        plane=surface['plane'];hit=Geom.intersect_line_plane([Geom::Point3d.new(query.x,query.y,fallback),Z_AXIS],plane);return false unless hit
        normal=polygon[0].vector_to(polygon[1]).cross(polygon[1].vector_to(polygon[2]));return false if normal.length<1e-9;normal.normalize!
        Builders.point_in_poly?(hit,polygon,normal) || polygon.each_with_index.any? { |a,index| point_segment_distance(hit,a,polygon[(index+1)%polygon.length])<=tolerance.to_f }
      end
      def surface_edge_distance(surface,query,fallback)
        polygon=Array(surface['polygon']).map { |value| point(value) };return Float::INFINITY if polygon.length<3
        hit=Geom.intersect_line_plane([Geom::Point3d.new(query.x,query.y,fallback),Z_AXIS],surface['plane']);return Float::INFINITY unless hit
        polygon.each_with_index.map { |a,index| point_segment_distance(hit,a,polygon[(index+1)%polygon.length]) }.min
      end
      def boundary_z(record,point_value,fallback)
        return fallback unless record.is_a?(Hash)
        point_value=point_value.is_a?(Geom::Point3d) ? point_value : point(point_value)
        surfaces=record['surfaces']
        if surfaces.is_a?(Array) && !surfaces.empty?
          tolerance=record.fetch('edge_tolerance',2.mm).to_f;surface=surfaces.find { |candidate| surface_contains?(candidate,point_value,fallback,0.0) }
          surface=surfaces.select { |candidate| surface_contains?(candidate,point_value,fallback,tolerance) }.min_by { |candidate| surface_edge_distance(candidate,point_value,fallback) } unless surface
          surface=surfaces.min_by { |candidate| surface_edge_distance(candidate,point_value,fallback) } if !surface&&record['allow_nearest_surface']==true
          raise 'The wall footprint extends outside the selected roof envelope. / محدوده دیوار از پوشش سقف انتخاب‌شده بیرون است.' unless surface
          return plane_z(surface['plane'],point_value,fallback)
        end
        plane_z(record['plane'],point_value,fallback)
      end
      def segment_intersection_xy(a,b,c,d)
        abx=b.x-a.x;aby=b.y-a.y;cdx=d.x-c.x;cdy=d.y-c.y;den=abx*cdy-aby*cdx
        return nil if den.abs<1e-9
        acx=c.x-a.x;acy=c.y-a.y;t=(acx*cdy-acy*cdx)/den;u=(acx*aby-acy*abx)/den
        return nil unless t.between?(-1e-8,1.0+1e-8) && u.between?(-1e-8,1.0+1e-8)
        Geom::Point3d.new(a.x+abx*t,a.y+aby*t,a.z+(b.z-a.z)*t)
      end
      def constraint_cut_stations(record,quad,cs,ce,dir,lo,hi)
        surfaces=record.is_a?(Hash) ? record['surfaces'] : nil
        return [] unless surfaces.is_a?(Array) && surfaces.length>1
        probes=quad.each_with_index.map { |value,index| [value,quad[(index+1)%quad.length]] }
        probes<<[cs,ce]
        stations=surfaces.flat_map do |surface|
          polygon=Array(surface['polygon']).map { |value| point(value) }
          next [] if polygon.length<3
          polygon.each_with_index.flat_map do |a,index|
            b=polygon[(index+1)%polygon.length]
            probes.filter_map do |c,d|
              hit=segment_intersection_xy(a,b,c,d);next unless hit
              station=cs.vector_to(hit).dot(dir)
              station if station>lo+EPS && station<hi-EPS
            end
          end
        end
        stations.sort.each_with_object([]) { |station,out| out<<station if out.empty? || station-out.last>EPS }
      end
      def add_cap_faces(entities,points,reverse,material)
        ordered=reverse ? points.reverse : points;faces=[]
        (1...ordered.length-1).each do |index|;face=entities.add_face(ordered[0],ordered[index],ordered[index+1]);raise 'Could not triangulate attached wall cap. / مثلث‌بندی سطح دیوار متصل ممکن نشد.' unless face;face.material=material;face.back_material=material;faces<<face;end;faces
      end
      def variable_piece(entities,quad,base_z,height,z0,z1,base_constraint,top_constraint,material)
        bottom=quad.map do |point_value|
          z=z0<=EPS ? boundary_z(base_constraint,point_value,base_z) : base_z+z0
          Geom::Point3d.new(point_value.x,point_value.y,z)
        end
        top=quad.map do |point_value|
          z=z1>=height-EPS ? boundary_z(top_constraint,point_value,base_z+height) : base_z+z1
          Geom::Point3d.new(point_value.x,point_value.y,z)
        end
        raise 'Attached boundaries cross or collapse the wall. / مرزهای متصل دیوار را قطع یا حذف می‌کنند.' if bottom.zip(top).any? { |a,b| b.z-a.z<=1.mm }
        add_cap_faces(entities,bottom,true,material);add_cap_faces(entities,top,false,material)
        quad.length.times do |index|
          j=(index+1)%quad.length;face=entities.add_face(bottom[index],bottom[j],top[j],top[index]);raise 'Could not build attached wall side. / ساخت وجه جانبی دیوار متصل ممکن نشد.' unless face;face.material=material;face.back_material=material
        end
        area=Builders.polygon_area(quad);average=bottom.zip(top).sum { |a,b| b.z-a.z }/bottom.length.to_f;area*average
      end
      def hide_opening_cut_edges(entities,cs,dir,stations)
        return if stations.empty?
        entities.grep(Sketchup::Edge).each do |edge|
          start_station=cs.vector_to(edge.start.position).dot(dir);end_station=cs.vector_to(edge.end.position).dot(dir)
          edge.hidden=true if stations.any? { |cut| (start_station-cut).abs<=EPS && (end_station-cut).abs<=EPS }
        end
      end
      def build(p,segs=nil,openings=nil)
        segs||=geometry(p);segs=trim_segments(segs,p.fetch('end_trims',[]));ops=openings||p.fetch('openings',[]);check_holes(segs,ops)
        g=Geometry.group('Draupr Wall',:walls);volume=0.0;area=0.0;length=0.0
        segs.each_with_index do |s,si|
          cs=point(s['cs']);ce=point(s['ce']);dir=cs.vector_to(ce);len=dir.length;dir.normalize!;h=s['height'];length+=len
          holes=ops.select { |o| o.fetch('seg',0)==si && o['t2']-o['t1']>EPS };area+=len*h-holes.sum { |o| (o['t2']-o['t1'])*(o['z1']-o['z0']) }
          base_constraint=constraint_record(p,'base_constraint');top_constraint=constraint_record(p,'top_constraint')
          s['layers'].each_with_index do |l,li|
            q=l['quad'].map { |a| point(a) };material=Materials.by_name_or_default(l['material'],:wall_default);part=Parts.make(g.entities,l['role'],"wall_#{si}_#{l['role']}_#{li}",material)
            spread=Math.tan(holes.map { |opening| opening['jamb_splay'].to_f }.max.to_f.degrees)*s['depth'].to_f*(s['layers'].length<=1 ? 0.5 : (li.to_f/(s['layers'].length-1)-0.5).abs)
            layer_holes=holes.map { |opening| opening.merge('t1'=>opening['t1']-spread,'t2'=>opening['t2']+spread,'z0'=>opening['z0']-[Math.tan(opening['sill_slope'].to_f.degrees)*s['depth'].to_f,opening['casing_setback'].to_f].max) }
            lo,hi=q.map { |pt| cs.vector_to(pt).dot(dir) }.minmax
            roof_cuts=constraint_cut_stations(top_constraint,q,cs,ce,dir,lo,hi)+constraint_cut_stations(base_constraint,q,cs,ce,dir,lo,hi)
            cuts=([lo,hi]+roof_cuts+layer_holes.flat_map { |o| [o['t1'],o['t2']] }.select { |t| t>lo && t<hi }).sort.uniq
            opening_cut_stations=cuts.select { |station| station>lo+EPS && station<hi-EPS }
            cuts.each_cons(2) do |a,b|
              next if b-a<=EPS;mid=(a+b)/2;active=layer_holes.select { |o| o['t1']<=mid && o['t2']>=mid };quad=clip_range(q,cs,dir,a,b)
              next if quad.length<3 || Builders.polygon_area(quad)<0.0008
              complement(active.map { |o| [o['z0'],o['z1']] },0.0,h).each do |z0,z1|
                piece=part.entities.add_group;pts=quad.map { |pt| Geom::Point3d.new(pt.x,pt.y,cs.z+z0) }
                if base_constraint || top_constraint
                  volume+=variable_piece(piece.entities,quad,cs.z,h,z0,z1,base_constraint,top_constraint,material)
                else
                  raise 'Wall piece failed; original retained.' unless Geometry.add_prism(piece.entities,pts,z1-z0,nil)
                  volume+=Builders.polygon_area(quad)*(z1-z0)
                end
                hide_opening_cut_edges(piece.entities,cs,dir,opening_cut_stations)
              end
            end
          end
        end
        raise 'Openings remove the entire wall.' if volume<=0
        s=segs.first;Metadata.write(g,{type:'wall',wall_segments:JSON.generate(segs),openings:JSON.generate(ops),height_mm:p['height']*25.4,thickness_mm:p['thickness']*25.4,length_mm:length*25.4,area_m2:area*0.00064516,volume_m3:volume*0.000016387064,x1:s['cs'][0],y1:s['cs'][1],z1:s['cs'][2],x2:s['ce'][0],y2:s['ce'][1],z2:s['ce'][2]});g
      end
      def recut(wall,ops)
        raise 'Wall is locked.' if wall.locked?
        p=Objects.params(wall);g=Geometry.with_entities(Geometry.parent_entities(wall)) { build(p,segments(wall),ops) }
        Objects.copy_identity(wall,g);g.set_attribute('Draupr','entity_pid',g.persistent_id);p['openings']=ops;g.set_attribute('Draupr','openings',JSON.generate(ops));g.set_attribute('Draupr','params_json',JSON.generate(p));Parts.apply_overrides(g,p.fetch('part_overrides',{}));wall.erase!;g
      end
    end
    module Builders
      module_function
      def build_wall(p);Walls.build(p);end
    end
  end
end
