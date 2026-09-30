# frozen_string_literal: true
module Draupr
  module Core
    module RoofTools
      module_function

      EPS=1.mm
      def owning_roof(entity)
        q=[entity];seen={}
        until q.empty?
          e=q.shift;next unless e && e.respond_to?(:valid?) && e.valid?;next if seen[e.object_id];seen[e.object_id]=true
          return e if Objects.valid?(e) && Metadata.read(e)['type']=='roof'
          parent=e.respond_to?(:parent) ? e.parent : nil
          parent=parent.parent if parent.is_a?(Sketchup::Entities)
          q.concat(parent.instances) if parent.is_a?(Sketchup::ComponentDefinition)
        end
        nil
      end
      def selected_roofs
        roofs=Sketchup.active_model.selection.to_a.map { |e| owning_roof(e) }.compact.uniq
        raise "Select exactly two Draupr roofs (found #{roofs.length}). You may select a roof or any nested roof part." unless roofs.length==2
        roofs
      end
      def selected_roof_operands
        items=Sketchup.active_model.selection.to_a.map do |e|
          owner=owning_roof(e)
          next nil unless owner
          if e.is_a?(Sketchup::Group) && e!=owner
            e
          else
            owner
          end
        end.compact.uniq
        raise "Select exactly two roof groups or solid slope parts (found #{items.length})." unless items.length==2
        items
      end
      def world_faces(roof)
        p=Objects.params(roof);tr=Transforms.entity_to_world(roof)
        Builders.roof_faces(p).map { |poly| poly.map { |q| q.transform(tr) } }
      end
      def plane(poly)
        n=poly[0].vector_to(poly[1]).cross(poly[1].vector_to(poly[2]))
        return nil if n.length<EPS
        n.normalize!;n.reverse! if n.z<0
        [n,n.x*poly[0].x+n.y*poly[0].y+n.z*poly[0].z]
      end
      def line_point(n1,d1,n2,d2,dir)
        ax=[dir.x.abs,dir.y.abs,dir.z.abs].each_with_index.max[1]
        if ax==0
          det=n1.y*n2.z-n1.z*n2.y;return nil if det.abs<1e-10
          Geom::Point3d.new(0,(d1*n2.z-n1.z*d2)/det,(n1.y*d2-d1*n2.y)/det)
        elsif ax==1
          det=n1.x*n2.z-n1.z*n2.x;return nil if det.abs<1e-10
          Geom::Point3d.new((d1*n2.z-n1.z*d2)/det,0,(n1.x*d2-d1*n2.x)/det)
        else
          det=n1.x*n2.y-n1.y*n2.x;return nil if det.abs<1e-10
          Geom::Point3d.new((d1*n2.y-n1.y*d2)/det,(n1.x*d2-d1*n2.x)/det,0)
        end
      end
      def clip_interval(point,dir,poly)
        ts=[]
        poly.each_with_index do |a,i|
          b=poly[(i+1)%poly.length]
          q=Geom.intersect_line_line([point,dir],[a,a.vector_to(b)])
          next unless q
          next if (a.distance(q)+q.distance(b)-a.distance(b)).abs>2.mm
          ts<<point.vector_to(q).dot(dir)
        end
        poly.each do |q|
          v=point.vector_to(q);proj=v.dot(dir)
          ts<<proj if v.length>0 && v.cross(dir).length<2.mm
        end
        ts.uniq.sort.then { |a| a.length>=2 ? [a.first,a.last] : nil }
      end
      def segments
        a,b=selected_roofs;out=[]
        world_faces(a).each do |pa|
          pla=plane(pa);next unless pla
          world_faces(b).each do |pb|
            plb=plane(pb);next unless plb
            dir=pla[0].cross(plb[0]);next if dir.length<1e-8;dir.normalize!
            point=line_point(pla[0],pla[1],plb[0],plb[1],dir);next unless point
            ia=clip_interval(point,dir,pa);ib=clip_interval(point,dir,pb);next unless ia&&ib
            lo=[ia[0],ib[0]].max;hi=[ia[1],ib[1]].min;next if hi-lo<EPS
            p1=point.offset(dir,lo);p2=point.offset(dir,hi)
            out<<[p1,p2,pla[0],plb[0]]
          end
        end
        out
      end
      def model_transform(entity);Transforms.entity_to_world(entity);end
      def distance_to_segment(point,a,b)
        v=a.vector_to(b);len=v.length;return point.distance(a) if len<1e-9;v.normalize!;t=[[a.vector_to(point).dot(v),0].max,len].min;point.distance(a.offset(v,t))
      end
      def picked_face_index(roof,world_point,normal_hint=nil)
        tr=model_transform(roof)
        candidates=Builders.roof_faces(Objects.params(roof)).each_with_index.filter_map do |poly,i|
          wp=poly.map { |q| q.transform(tr) };pl=plane(wp);next unless pl
          dist=(pl[0].x*world_point.x+pl[0].y*world_point.y+pl[0].z*world_point.z-pl[1]).abs
          projected=world_point.offset(pl[0],-((pl[0].x*world_point.x+pl[0].y*world_point.y+pl[0].z*world_point.z)-pl[1]))
          inside=Builders.point_in_poly?(projected,wp,pl[0]);orientation=normal_hint ? (1.0-normal_hint.dot(pl[0]).abs)*100000.mm : 0.0;[(inside ? dist : dist+1000.m)+orientation,i,wp,pl]
        end
        candidates.min_by(&:first)
      end
      def picked_edge(roof,world_point)
        hit=picked_face_index(roof,world_point);raise 'No roof slope was found at the picked edge.' unless hit
        _score,fi,poly,_pl=hit
        edge=(0...poly.length).map { |i| [distance_to_segment(world_point,poly[i],poly[(i+1)%poly.length]),i] }.min_by(&:first)
        raise 'Click closer to a visible roof boundary edge.' if edge[0]>300.mm
        [fi,edge[1],poly]
      end
      def ordered_on_plane(points,normal)
        pts=[];points.each { |p| pts<<p unless pts.any? { |q| q.distance(p)<1.mm } };return pts if pts.length<3
        center=Geom::Point3d.new(pts.sum(&:x)/pts.length,pts.sum(&:y)/pts.length,pts.sum(&:z)/pts.length)
        x=pts[0].vector_to(pts[1]);dot=x.dot(normal);x=Geom::Vector3d.new(x.x-normal.x*dot,x.y-normal.y*dot,x.z-normal.z*dot);x=X_AXIS.clone if x.length<1e-8;x.normalize!;y=normal.cross(x);y.normalize!
        pts.sort_by { |q| v=center.vector_to(q);Math.atan2(v.dot(y),v.dot(x)) }
      end
      def face_projection_axes(normal)
        dropped=normal.to_a.each_with_index.max_by { |value,_index| value.abs }[1]
        ([0,1,2]-[dropped]).freeze
      end
      def projected_pair(point,axes);values=point.to_a;[values[axes[0]],values[axes[1]]];end
      def clipped_face_polygon(subject,clip_polygon,normal)
        return [] if subject.length<3 || clip_polygon.length<3
        axes=face_projection_axes(normal);clip_2d=clip_polygon.map { |point| projected_pair(point,axes) }
        signed_area=clip_2d.each_with_index.sum { |a,index| b=clip_2d[(index+1)%clip_2d.length];a[0]*b[1]-b[0]*a[1] }
        orientation=signed_area<0 ? -1.0 : 1.0;output=subject.dup
        clip_polygon.each_with_index do |clip_a,index|
          clip_b=clip_polygon[(index+1)%clip_polygon.length];ca=projected_pair(clip_a,axes);cb=projected_pair(clip_b,axes);input=output;output=[];break if input.empty?
          input.each_with_index do |current,current_index|
            previous=input[(current_index-1)%input.length];pc=projected_pair(current,axes);pp=projected_pair(previous,axes)
            current_side=orientation*((cb[0]-ca[0])*(pc[1]-ca[1])-(cb[1]-ca[1])*(pc[0]-ca[0]))
            previous_side=orientation*((cb[0]-ca[0])*(pp[1]-ca[1])-(cb[1]-ca[1])*(pp[0]-ca[0]))
            edge_tolerance=0.1.mm*Math.sqrt((cb[0]-ca[0])**2+(cb[1]-ca[1])**2)
            current_inside=current_side>=-edge_tolerance;previous_inside=previous_side>=-edge_tolerance
            if current_inside!=previous_inside
              dx=pc[0]-pp[0];dy=pc[1]-pp[1];ex=cb[0]-ca[0];ey=cb[1]-ca[1];denominator=dx*ey-dy*ex
              unless denominator.abs<1e-12
                t=((ca[0]-pp[0])*ey-(ca[1]-pp[1])*ex)/denominator
                output<<Geom::Point3d.new(previous.x+(current.x-previous.x)*t,previous.y+(current.y-previous.y)*t,previous.z+(current.z-previous.z)*t)
              end
            end
            output<<current if current_inside
          end
        end
        cleaned=[];output.each { |point| cleaned<<point if cleaned.empty? || cleaned.last.distance(point)>0.1.mm }
        cleaned.pop if cleaned.length>1 && cleaned.first.distance(cleaned.last)<0.1.mm;cleaned
      end
      def convex_envelope_on_plane(points,normal)
        axes=face_projection_axes(normal);unique=[]
        points.each do |point|
          pair=projected_pair(point,axes)
          unique<<[pair[0],pair[1],point] unless unique.any? { |entry| (entry[0]-pair[0]).abs<0.1.mm && (entry[1]-pair[1]).abs<0.1.mm }
        end
        return unique.map { |entry| entry[2] } if unique.length<4
        sorted=unique.sort_by { |entry| [entry[0],entry[1]] }
        cross=lambda { |o,a,b| (a[0]-o[0])*(b[1]-o[1])-(a[1]-o[1])*(b[0]-o[0]) }
        lower=[];sorted.each { |entry| lower.pop while lower.length>=2 && cross.call(lower[-2],lower[-1],entry)<=0;lower<<entry }
        upper=[];sorted.reverse_each { |entry| upper.pop while upper.length>=2 && cross.call(upper[-2],upper[-1],entry)<=0;upper<<entry }
        (lower[0...-1]+upper[0...-1]).map { |entry| entry[2] }
      end
      def rebuild_roof(old,p)
        uid=Objects.id(old);tr=old.transformation;parent=Geometry.parent_entities(old)
        ng=Objects.create('roof',p,tr,parent,uid);Objects.copy_identity(old,ng);ng.transformation=tr;Objects.capture(ng,'roof',p,uid);old.erase!;ng
      end
      def join_edge_to_face(source,source_point,target,target_point,target_normal=nil)
        raise 'The source and target must be different roofs.' if source==target
        sfi,ei,selected_poly=picked_edge(source,source_point);thit=picked_face_index(target,target_point,target_normal);raise 'No target roof face was found.' unless thit
        _score,tfi,tpoly,tplane=thit;target_normal=tplane[0];target_plane=[tpoly[0],target_normal]
        source_tr=model_transform(source);source_inv=source_tr.inverse;source_faces=Builders.roof_faces(Objects.params(source));world_faces=source_faces.map { |poly| poly.map { |q| q.transform(source_tr) } }
        edge_a=selected_poly[ei];edge_b=selected_poly[(ei+1)%selected_poly.length];edge_vec=edge_a.vector_to(edge_b)
        boundary_normal=edge_vec.cross(Z_AXIS);raise 'Select a sloped or horizontal roof-end edge.' if boundary_normal.length<1e-8;boundary_normal.normalize!
        matching=[]
        world_faces.each_with_index do |poly,fi|
          poly.each_with_index do |a,i|
            b=poly[(i+1)%poly.length]
            da=edge_a.vector_to(a).dot(boundary_normal).abs;db=edge_a.vector_to(b).dot(boundary_normal).abs
            matching<<[fi,i,poly] if da<2.mm&&db<2.mm
          end
        end
        raise 'No connected roof-end edges were found.' if matching.empty?
        sp=Objects.params(source);faces=source_faces.map { |poly| poly.map { |q| [q.x.to_f,q.y.to_f,q.z.to_f] } };join_strips=[];envelope_points=[];down=source_tr.zaxis;down_scale=down.length;down.normalize!;thickness=sp['thickness'].to_f*down_scale
        matching.each do |fi,i,poly|
          count=poly.length;ai=i;bi=(i+1)%count;pi=(i-1)%count;ni=(i+2)%count
          na=Geom.intersect_line_plane([poly[pi],poly[pi].vector_to(poly[ai])],target_plane);nb=Geom.intersect_line_plane([poly[bi],poly[bi].vector_to(poly[ni])],target_plane)
          raise 'A connected source edge cannot reach the target face plane.' unless na&&nb
          raise 'The joined roof end would be excessively long.' if na.distance(poly[ai])>100.m||nb.distance(poly[bi])>100.m
          la=na.transform(source_inv);lb=nb.transform(source_inv);faces[fi][ai]=[la.x,la.y,la.z];faces[fi][bi]=[lb.x,lb.y,lb.z]
          lower_prev=poly[pi].offset(down,-thickness);lower_a=poly[ai].offset(down,-thickness);lower_b=poly[bi].offset(down,-thickness);lower_next=poly[ni].offset(down,-thickness)
          ua=Geom.intersect_line_plane([lower_prev,lower_prev.vector_to(lower_a)],target_plane);ub=Geom.intersect_line_plane([lower_b,lower_b.vector_to(lower_next)],target_plane)
          strip=ordered_on_plane([na,nb,ub,ua].compact,target_normal);raise 'A source slope did not form a closed target-face strip.' if strip.length<3
          clipped=clipped_face_polygon(strip,tpoly,target_normal);join_strips<<clipped if clipped.length>=3;envelope_points.concat(strip)
        end
        envelope=convex_envelope_on_plane(envelope_points,target_normal);destination_cut=clipped_face_polygon(envelope,tpoly,target_normal)
        raise 'The extended source roof end does not overlap the selected target face. Pick the facing roof slope.' if destination_cut.length<3
        target_inv=model_transform(target).inverse;hole_outlines=[destination_cut.map { |q| point=q.transform(target_inv);[point.x,point.y,point.z] }]
        sp['roof_face_overrides']=faces;sp['roof_join']={'target_id'=>Objects.id(target),'target_face'=>tfi,'edge_plane'=>[boundary_normal.x,boundary_normal.y,boundary_normal.z],'strip_count'=>join_strips.length,'destination_cut'=>'source_end_envelope'}
        tp=Objects.params(target);holes=tp['roof_join_holes'].is_a?(Array) ? tp['roof_join_holes'].dup : [];holes.reject! { |h| h['source_id']==Objects.id(source) };hole_outlines.each { |points| holes<<{'source_id'=>Objects.id(source),'face'=>tfi,'points'=>points} };tp['roof_join_holes']=holes
        src=nil;tgt=nil
        Transactions.run('Join complete roof end to target face') do
          src=rebuild_roof(source,sp);tgt=rebuild_roof(target,tp);Sketchup.active_model.selection.clear;Sketchup.active_model.selection.add(src);Sketchup.active_model.selection.add(tgt)
        end
        [src,tgt]
      end
      def solid_slope_copies(roof)
        root=roof.copy
        exploded=root.explode || []
        parts=exploded.select { |e| e.is_a?(Sketchup::Group) && e.valid? && e.volume.to_f.abs>1e-6 }
        if parts.empty?
          exploded.grep(Sketchup::Group).each do |g|
            next unless g.valid?
            nested=g.explode || [];parts.concat(nested.select { |e| e.is_a?(Sketchup::Group) && e.valid? && e.volume.to_f.abs>1e-6 })
          end
        end
        parts
      end
      def bounds_overlap?(a,b)
        box=a.bounds.intersect(b.bounds);box && box.valid? && box.width>0.1.mm && box.depth>0.1.mm && box.height>0.1.mm
      end
      def join_selected
        raise 'The legacy frozen solid-union roof command is disabled. Use Modify → Join roof edge to face to preserve parametric source roofs.'
      end
      def join_roofs(roofs,allow_frozen: false)
        raise 'Frozen roof assembly creation requires an explicit developer opt-in.' unless allow_frozen
        roofs=roofs.compact.uniq;raise 'Pick two different Draupr roofs.' unless roofs.length==2
        raise 'Join/Trim Roofs requires SketchUp Pro solid tools.' unless roofs.first.respond_to?(:outer_shell)
        result=nil
        Transactions.run('Join Draupr roofs — frozen assembly') do
          parts=roofs.flat_map { |roof| solid_slope_copies(roof) }
          raise 'No valid solid roof slopes were found in the picked roofs.' if parts.length<2
          merges=0;changed=true
          while changed
            changed=false
            parts.each_with_index do |a,i|
              next unless a.valid?
              ((i+1)...parts.length).each do |j|
                b=parts[j];next unless b && b.valid? && bounds_overlap?(a,b)
                joined=nil
                begin
                  joined=a.outer_shell(b)
                  joined=a.union(b) if (!joined || !joined.valid?) && a.valid? && b.valid? && a.respond_to?(:union)
                rescue StandardError
                  joined=nil
                end
                next unless joined && joined.valid?
                parts[i]=joined;parts.delete_at(j);merges+=1;changed=true;break
              end
              break if changed
            end
          end
          raise 'The roof solids overlap visually, but SketchUp Solid Tools could not merge any slope pair.' if merges==0
          container=Sketchup.active_model.active_entities.add_group;container.name='Draupr Joined Roof (Frozen)'
          parts.select(&:valid?).each do |part|
            container.entities.add_instance(part.definition,part.transformation);part.erase!
          end
          container.set_attribute('Draupr','assembly_status','frozen');container.set_attribute('Draupr','parametric',false);container.set_attribute('Draupr','data_schema',DataSchema::VERSION);container.set_attribute('Draupr','joined_roof_source_ids',JSON.generate(roofs.map { |g| Objects.valid?(g) ? Objects.id(g) : "pid:#{g.persistent_id}" }))
          Sketchup.active_model.selection.clear;Sketchup.active_model.selection.add(container);result=container
        end
        result
      end
      def create(mode='intersection')
        segs=segments
        raise 'The selected roof surfaces do not intersect.' if segs.empty?
        Transactions.run(mode=='valley' ? 'Create Draupr roof valley' : 'Create Draupr roof intersections') do
          g=Sketchup.active_model.active_entities.add_group
          g.name=mode=='valley' ? 'Draupr Roof Valley' : 'Draupr Roof Intersections'
          mat=Materials.by_name_or_default('',mode=='valley' ? :steel : :mullion_dark)
          segs.each_with_index do |(a,b,n1,n2),i|
            if mode=='valley'
              v=a.vector_to(b);len=v.length;v.normalize!
              [n1,n2].each_with_index do |n,j|
                across=v.cross(n);across.normalize!;across.reverse! if across.z<0
                p0=a.offset(across,150.mm).offset(n,5.mm)
                p1=b.offset(across,150.mm).offset(n,5.mm)
                part=Parts.make(g.entities,'valley',"valley_#{i}_#{j}",mat)
                face=part.entities.add_face(a.offset(n,5.mm),b.offset(n,5.mm),p1,p0)
                face.pushpull(face.normal.dot(n)>0 ? 5.mm : -5.mm) if face
              end
            else
              edge=g.entities.add_line(a,b);edge.layer=Sketchup.active_model.layers[0] if edge
            end
          end
          Sketchup.active_model.selection.clear;Sketchup.active_model.selection.add(g)
        end
        segs.length
      end
    end
  end
end
