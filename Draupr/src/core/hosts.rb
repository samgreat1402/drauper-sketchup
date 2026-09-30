# frozen_string_literal: true
module Draupr
  module Core
    module Hosts
      module_function
      def records(g);JSON.parse(g.get_attribute('Draupr','hosts_json','[]'));end
      def hosts_for(g);records(g).filter_map { |record| begin;resolve_record_host(g,record);rescue StandardError;nil;end };end
      def ensure_uid(g)
        uid=g.get_attribute('Draupr','uid');unless uid;uid=SecureRandom.uuid;g.set_attribute('Draupr','uid',uid);end;uid
      end
      def host_ref(host);{'id'=>ensure_uid(host),'pid'=>host.persistent_id};end
      def resolve_record_host(g,record)
        if record['pid'] && Sketchup.active_model.respond_to?(:find_entity_by_persistent_id)
          candidate=Sketchup.active_model.find_entity_by_persistent_id(record['pid'].to_i)
          return candidate if candidate && Objects.valid?(candidate) && Objects.id(candidate)==record['id'].to_s
        end
        Objects.get(record['id'])
      rescue RuntimeError => error
        raise unless error.message=='Object no longer exists. Refresh selection.'
        object_uid=g.get_attribute('Draupr','uid')
        matches=Objects.all.select { |candidate| Metadata.read(candidate)['type']=='roof' && roof_holes(candidate).any? { |opening| opening['oid']==object_uid } }
        raise error unless matches.length==1
        matches.first
      end
      def repair_record_host!(g,record)
        host=resolve_record_host(g,record);replacement=host_ref(host)
        repaired=records(g).map { |item| item==record ? item.merge(replacement) : item }
        Transactions.run('Repair Draupr host link') { g.set_attribute('Draupr','hosts_json',JSON.generate(repaired)) }
        host
      end
      def frame(wall,index,p,offset=nil)
        s=Walls.segments(wall)[index];raise 'Wall segment is missing.' unless s
        a=Walls.point(s['cs']);b=Walls.point(s['ce']);x=a.vector_to(b);len=x.length;x.normalize!
        raise 'Wall must be horizontal in its local coordinates.' if x.z.abs>0.0001
        y=Z_AXIS.cross(x);y.normalize!;t=offset.nil? ? p['host_offset'].to_f : offset.to_f;sill=p.fetch('sill',0.0);height=p['height'];width=p['width'];depth=s['depth']
        raise 'Opening does not fit the wall length.' if t<0 || t+width>len+Walls::EPS
        raise 'Opening does not fit the wall height.' if sill<0 || sill+height>s['height']+Walls::EPS
        wp=Objects.params(wall);cavity=wp['legacy_cavity_width'].to_f;type=wp['legacy_cavity_type'].to_s
        if type.start_with?('cavity-')
          shift=(cavity+depth)/2;a=a.offset(x.cross(Z_AXIS),type=='cavity-inner' ? -shift : shift);depth=2*depth+cavity
        end
        origin=a.offset(x,t).offset(y,-depth/2)
        {'transform'=>wall.transformation*Geom::Transformation.axes(origin,x,y,Z_AXIS),'depth'=>depth,'record'=>{'seg'=>index,'t1'=>t,'t2'=>t+width,'z0'=>sill,'z1'=>sill+height,'jamb_splay'=>p['jamb_splay'].to_f,'sill_slope'=>p['sill_slope'].to_f,'casing_setback'=>p['casing_setback'].to_f},'segment'=>s}
      end
      def targets(wall,index)
        out=[[wall,index]];p=Objects.params(wall);type=p['legacy_cavity_type'].to_s;return out unless type.start_with?('cavity-')
        s=Walls.segments(wall)[index];a=Walls.point(s['cs']);b=Walls.point(s['ce']);dir=a.vector_to(b);len=dir.length;dir.normalize!
        Geometry.parent_entities(wall).grep(Sketchup::Group).each do |g|
          next unless g!=wall && Objects.valid?(g) && Metadata.read(g)['type']=='wall' && g.transformation.to_a==wall.transformation.to_a
          q=Objects.params(g);next unless q['legacy_cavity_type'].to_s.start_with?('cavity-') && q['legacy_cavity_type']!=type
          ss=Walls.segments(g).first;aa=Walls.point(ss['cs']);bb=Walls.point(ss['ce']);dd=aa.vector_to(bb);next if dd.length<1.mm || (dd.length-len).abs>1.mm;dd.normalize!
          delta=a.vector_to(aa);expected=s['depth']+p['legacy_cavity_width'].to_f
          out<<[g,0] if dd.dot(dir)>0.99999 && delta.dot(dir).abs<1.mm && (delta.length-expected).abs<1.mm
        end;out
      end
      def place(kind,p,wall,index,offset)
        Transactions.run("Place Draupr #{kind}") do
          raise 'Enter the containing group before placing an opening.' unless Geometry.parent_entities(wall)==Sketchup.active_model.active_entities
          p=p.merge('host_offset'=>offset.to_f,'rotation'=>0.0,'z_offset'=>0.0);f=frame(wall,index,p);p['depth']=f['depth'];Parameters.normalize(kind,{},p)
          oid=SecureRandom.uuid;recs=[]
          targets(wall,index).each do |host,seg|
            hid=ensure_uid(host);r=frame(host,seg,p)['record'].merge('oid'=>oid);ops=Walls.holes(host)+[r];Walls.check_holes(Walls.segments(host),ops)
            recs<<host_ref(host).merge('seg'=>seg);Walls.recut(host,ops)
          end
          g=Objects.create(kind,p,f['transform'],Sketchup.active_model.active_entities,oid);g.set_attribute('Draupr','hosts_json',JSON.generate(recs));g
        end
      end
      def edit_opening(g,oldp,p,changes)
        recs=records(g);raise 'Linked host is missing.' if recs.empty?
        first=resolve_record_host(g,recs.first)
        return edit_roof_opening(g,first,oldp,p,changes) if Metadata.read(first)['type']=='roof'
        raise 'Hosted objects follow the wall: edit sill, host offset or facing instead of elevation/rotation.' if p['rotation']!=oldp['rotation'] || p['z_offset']!=oldp['z_offset'] || p['level_id']!=oldp['level_id']
        uid=ensure_uid(g);f=frame(first,recs.first['seg'],p);p['depth']=f['depth']
        recs.each do |rec|
          host=resolve_record_host(g,rec);r=frame(host,rec['seg'],p)['record'].merge('oid'=>uid);ops=Walls.holes(host).reject { |o| o['oid']==uid }+[r]
          Walls.check_holes(Walls.segments(host),ops);Walls.recut(host,ops)
        end
        kind=Metadata.read(g)['type'];ng=Objects.create(kind,p,f['transform'],Geometry.parent_entities(g),uid);Objects.copy_identity(g,ng);ng.transformation=f['transform'];Objects.capture(ng,kind,p,uid);g.erase!;ng
      end
      def reposition_for_wall(wall)
        uid=wall.get_attribute('Draupr','uid');return unless uid
        Objects.all.select { |o| records(o).first && records(o).first['id']==uid }.each do |g|
          rec=records(g).first;p=Objects.params(g);f=frame(wall,rec['seg'],p);p['depth']=f['depth'];kind=Metadata.read(g)['type'];oid=g.get_attribute('Draupr','uid')
          ng=Objects.create(kind,p,f['transform'],Geometry.parent_entities(g),oid);Objects.copy_identity(g,ng);ng.transformation=f['transform']
          refreshed=records(g).map { |item| item['id']==uid ? item.merge(host_ref(wall)) : item };ng.set_attribute('Draupr','hosts_json',JSON.generate(refreshed))
          Objects.capture(ng,kind,p,oid);g.erase!
        end
      end
      def remove(g)
        raise 'Object is locked.' if g.locked?
        uid=ensure_uid(g)
        if %w[wall roof].include?(Metadata.read(g)['type'])
          Objects.all.select { |o| records(o).any? { |r| r['id']==uid } }.each { |o| remove(o) if o.valid? }
          current=Objects.get(uid);current.erase!;return
        end
        records(g).each do |rec|
          next unless Objects.all.any? { |o| Objects.id(o)==rec['id'] }
          host=Objects.get(rec['id'])
          if Metadata.read(host)['type']=='roof'
            roof_recut(host,roof_holes(host).reject { |o| o['oid']==uid })
          else
            Walls.recut(host,Walls.holes(host).reject { |o| o['oid']==uid })
          end
        end
        g.erase! if g.valid?
      end
      def roof_holes(g);JSON.parse(g.get_attribute('Draupr','roof_openings','[]'));end
      def normalize_roof_record(roof_params,rec)
        raw_o=Geom::Point3d.new(*rec['o']);raw_x=Geom::Vector3d.new(*rec['x']);raw_y=Geom::Vector3d.new(*rec['y']);w=rec['w'].to_f;d=rec['d'].to_f
        raise 'Roof opening dimensions are invalid.' if raw_x.length<1e-8 || raw_y.length<1e-8 || w<=1.mm || d<=1.mm
        raw_x.normalize!;raw_y.normalize!;raw_poly=rec['poly'].is_a?(Array) && rec['poly'].length>=3 ? rec['poly'].map { |point| Geom::Point3d.new(*point) } : [raw_o,raw_o.offset(raw_x,w),raw_o.offset(raw_x,w).offset(raw_y,d),raw_o.offset(raw_y,d)];center=Geom::Point3d.new(raw_poly.sum(&:x)/raw_poly.length.to_f,raw_poly.sum(&:y)/raw_poly.length.to_f,raw_poly.sum(&:z)/raw_poly.length.to_f)
        candidates=Builders.roof_faces(roof_params).each_with_index.filter_map do |quad,index|
          n=quad[0].vector_to(quad[1]).cross(quad[1].vector_to(quad[2]));next if n.length<1e-9;n.normalize!;next if n.z<0.0001
          distance=quad[0].vector_to(center).dot(n);projected=center.offset(n,-distance);next unless Builders.point_in_poly?(projected,quad,n)
          [distance.abs,index,quad,n]
        end
        preferred=rec.key?('face') ? candidates.find { |_distance,index,_quad,_n| index==rec['face'].to_i } : nil
        chosen=preferred || candidates.min_by(&:first);raise 'The roof opening no longer lies on a valid roof face.' unless chosen
        _distance,index,quad,n=chosen
        x=Geom::Vector3d.new(raw_x.x-n.x*raw_x.dot(n),raw_x.y-n.y*raw_x.dot(n),raw_x.z-n.z*raw_x.dot(n));raise 'Cannot align the roof opening to its host face.' if x.length<1e-8;x.normalize!
        y=n.cross(x);y.normalize!;y.reverse! if y.dot(raw_y)<0
        distance=quad[0].vector_to(raw_o).dot(n);o=raw_o.offset(n,-distance)
        projected_poly=raw_poly.map { |point| point.offset(n,-quad[0].vector_to(point).dot(n)) };rec.merge('o'=>o.to_a,'x'=>x.to_a,'y'=>y.to_a,'w'=>w,'d'=>d,'face'=>index,'poly'=>projected_poly.map(&:to_a))
      end
      def roof_recut(roof,ops)
        raise 'Roof is locked.' if roof.locked?
        p=Objects.params(roof);ops=ops.map { |rec| normalize_roof_record(p,rec) }
        # Validate in a disposable group, then rebuild only the root's children.
        probe=Geometry.with_entities(Geometry.parent_entities(roof)) { Builders.build_roof(p.merge('roof_openings'=>ops)) };probe.erase! if probe&&probe.valid?
        original_pid=roof.persistent_id;Builders.build_roof(p.merge('roof_openings'=>ops),roof)
        p['roof_openings']=ops
        roof.set_attribute('Draupr','roof_openings',JSON.generate(ops));roof.set_attribute('Draupr','params_json',JSON.generate(p));roof.set_attribute('Draupr','entity_pid',original_pid)
        Parts.apply_overrides(roof,p.fetch('part_overrides',{}));roof
      end
      def roof_opening_polygon(rec)
        return rec['poly'].map { |point| Geom::Point3d.new(*point) } if rec['poly'].is_a?(Array) && rec['poly'].length>=3
        o=Geom::Point3d.new(*rec['o']);x=Geom::Vector3d.new(*rec['x']);y=Geom::Vector3d.new(*rec['y']);[o,o.offset(x,rec['w']),o.offset(x,rec['w']).offset(y,rec['d']),o.offset(y,rec['d'])]
      end
      def roof_openings_overlap?(a,b)
        return false if a.key?('face') && b.key?('face') && a['face'].to_i!=b['face'].to_i
        pa=roof_opening_polygon(a);pb=roof_opening_polygon(b);normal=pa[0].vector_to(pa[1]).cross(pa[1].vector_to(pa[2]));return false if normal.length<1e-9;normal.normalize!
        edges=pa.each_with_index.map { |point,index| point.vector_to(pa[(index+1)%pa.length]) }+pb.each_with_index.map { |point,index| point.vector_to(pb[(index+1)%pb.length]) }
        axes=edges.filter_map { |edge| axis=normal.cross(edge);next if axis.length<1e-9;axis.normalize!;axis }
        axes.all? do |axis|
          aa=pa.map { |point| Geom::Vector3d.new(point.x,point.y,point.z).dot(axis) };bb=pb.map { |point| Geom::Vector3d.new(point.x,point.y,point.z).dot(axis) };[aa.max,bb.max].min-[aa.min,bb.min].max>0.5.mm
        end
      end
      def roof_object_placement(kind,p,roof,rec)
        o=Geom::Point3d.new(*rec['o']);x=Geom::Vector3d.new(*rec['x']);surface_y=Geom::Vector3d.new(*rec['y'])
        if kind.to_s=='dormer'
          horizontal_y=Geom::Vector3d.new(surface_y.x,surface_y.y,0);raise 'This roof face is too steep for a dormer.' if horizontal_y.length<0.05
          horizontal_factor=horizontal_y.length;horizontal_y.normalize!;horizontal_y.reverse! if horizontal_y.dot(surface_y)<0
          depth=rec['d'].to_f*horizontal_factor;host_rise=rec['d'].to_f*surface_y.z
          q=p.merge('width'=>rec['w'].to_f,'depth'=>depth,'host_slope_rise'=>host_rise,'host_slope'=>host_rise/[depth,0.0001].max,'host_surface_factor'=>horizontal_factor,'placement_mode'=>'surface','z_offset'=>0.0,'rotation'=>0.0)
          [q,roof.transformation*Geom::Transformation.axes(o,x,horizontal_y,Z_AXIS)]
        else
          q=p.merge('width'=>rec['w'].to_f,'depth'=>rec['d'].to_f,'placement_mode'=>'surface','z_offset'=>0.0,'rotation'=>0.0)
          z=x.cross(surface_y);[q,roof.transformation*Geom::Transformation.axes(o,x,surface_y,z)]
        end
      end
      def dormer_record(rec,p)
        solution=Builders.dormer_solution(p);o=Geom::Point3d.new(*rec['o']);x=Geom::Vector3d.new(*rec['x']);surface_y=Geom::Vector3d.new(*rec['y']);factor=p['host_surface_factor'].to_f
        poly=solution['opening'].map { |point| o.offset(x,point.x).offset(surface_y,point.y/[factor,0.0001].max) }
        rec.merge('poly'=>poly.map(&:to_a))
      end
      def place_on_roof(kind,p,roof,frame)
        Transactions.run("Place Draupr #{kind} on roof") do
          raise 'Enter the containing group before placing on this roof.' unless Geometry.parent_entities(roof)==Sketchup.active_model.active_entities
          oid=SecureRandom.uuid;hid=ensure_uid(roof);roof_params=Objects.params(roof)
          rec=normalize_roof_record(roof_params,frame['record'].merge('oid'=>oid));p,object_transform=roof_object_placement(kind,p,roof,rec);rec=dormer_record(rec,p) if kind.to_s=='dormer';rec=normalize_roof_record(roof_params,rec)
          existing=roof_holes(roof).map { |item| normalize_roof_record(roof_params,item) };raise 'Opening overlaps an existing roof opening.' if existing.any? { |item| roof_openings_overlap?(rec,item) }
          # Build first. A geometry error leaves the original roof untouched.
          g=Objects.create(kind,p,object_transform,Sketchup.active_model.active_entities,oid)
          rebuilt_roof=roof_recut(roof,existing+[rec]);rebuilt_roof.set_attribute('Draupr','roof_opening_count',existing.length+1)
          g.set_attribute('Draupr','hosts_json',JSON.generate([host_ref(rebuilt_roof)]));g
        end
      end
      def edit_roof_opening(g,roof,oldp,p,changes)
        raise 'Hosted objects follow the roof: edit type and dimensions instead of elevation/rotation.' if p['rotation']!=oldp['rotation'] || p['z_offset']!=oldp['z_offset'] || p['level_id']!=oldp['level_id']
        uid=ensure_uid(g);hid=ensure_uid(roof);kind=Metadata.read(g)['type'];roof_params=Objects.params(roof);all=roof_holes(roof).map { |item| normalize_roof_record(roof_params,item) };old_rec=all.find { |item| item['oid']==uid };raise 'Roof opening record is missing.' unless old_rec
        surface_y=Geom::Vector3d.new(*old_rec['y']);factor=kind=='dormer' ? Geom::Vector3d.new(surface_y.x,surface_y.y,0).length : 1.0;surface_depth=kind=='dormer' ? p['depth'].to_f/[factor,0.0001].max : p['depth'].to_f
        rec=normalize_roof_record(roof_params,old_rec.merge('w'=>p['width'].to_f,'d'=>surface_depth));p,tr=roof_object_placement(kind,p,roof,rec);rec=dormer_record(rec,p) if kind=='dormer';rec=normalize_roof_record(roof_params,rec)
        others=all.reject { |item| item['oid']==uid };raise 'Edited opening overlaps another roof opening.' if others.any? { |item| roof_openings_overlap?(rec,item) }
        # Create the replacement before replacing the host; the transaction is all-or-nothing.
        ng=Objects.create(kind,p,tr,Geometry.parent_entities(g),uid);Objects.copy_identity(g,ng);ng.transformation=tr;Objects.capture(ng,kind,p,uid)
        rebuilt=roof_recut(roof,others+[rec]);rebuilt.set_attribute('Draupr','roof_opening_count',others.length+1)
        ng.set_attribute('Draupr','hosts_json',JSON.generate([host_ref(rebuilt)]));g.erase! if g.valid?;ng
      end
      def sync
        Transactions.run('Synchronize Draupr openings') do
          # Explicit synchronization avoids destructive model edits inside
          # selection observers, and keeps Undo/Redo predictable.
          walls=Objects.all.select { |g| Metadata.read(g)['type']=='wall' };existing=Objects.all.map { |g| g.get_attribute('Draupr','uid') }.compact
          walls.each do |wall|
            ops=Walls.holes(wall);clean=ops.reject { |o| o['oid'] && !existing.include?(o['oid']) };wall=Walls.recut(wall,clean) if clean.length!=ops.length
            last=wall.get_attribute('Draupr','last_transform')
            if last && JSON.parse(last)!=wall.transformation.to_a
              reposition_for_wall(wall);wall.set_attribute('Draupr','last_transform',JSON.generate(wall.transformation.to_a))
            end
          end
          Objects.all.select { |g| !records(g).empty? }.each do |g|
            last=g.get_attribute('Draupr','last_transform');next unless last && JSON.parse(last)!=g.transformation.to_a
            rec=records(g).first;wall=Objects.get(rec['id']);s=Walls.segments(wall)[rec['seg']];cs=Walls.point(s['cs']);ce=Walls.point(s['ce']);dir=cs.vector_to(ce);dir.normalize!
            relative=wall.transformation.inverse*g.transformation
            raise 'Rotated openings need to be placed on the wall again.' unless relative.xaxis.parallel?(dir) && relative.xaxis.dot(dir)>0 && relative.zaxis.parallel?(Z_AXIS) && relative.zaxis.z>0 && relative.yaxis.dot(Z_AXIS.cross(dir))>0
            raise 'Edit hosted dimensions in Studio instead of using native Scale.' if [relative.xaxis,relative.yaxis,relative.zaxis].any? { |a| (a.length-1).abs>0.00001 }
            old=Objects.params(g);p=old.dup;p['host_offset']=cs.vector_to(relative.origin).dot(dir)
            expected=wall.transformation.inverse*frame(wall,rec['seg'],p)['transform']
            normal=Z_AXIS.cross(dir);normal.normalize!
            raise 'Opening moved away from its host plane. Undo that move or place it on a wall again.' if relative.origin.vector_to(expected.origin).dot(normal).abs>1.mm
            rise=relative.origin.z-cs.z
            if Metadata.read(g)['type']=='window';p['sill']+=rise
            elsif rise.abs>Walls::EPS;raise 'Doors must stay at the wall base.';end
            edit_opening(g,old,p,{})
          end
          ModifyTools.refresh_boundary_constraints
        end
      end
    end
  end
end
