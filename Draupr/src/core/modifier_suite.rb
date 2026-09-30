# frozen_string_literal: true
module Draupr
  module Core
    module ModifyTools
      PATH_KINDS=%w[wall curtain_wall beam railing louver molding foundation].freeze
      module_function

      def bilingual(en,fa);I18n.message(en,fa);end
      def object_kind(object);Metadata.read(object)['type'].to_s;end
      def ensure_editable!(object,kinds=nil)
        raise bilingual('Pick a Draupr object.','یک آبجکت Draupr انتخاب کنید.') unless Objects.valid?(object)
        raise bilingual('The object is locked.','آبجکت قفل است.') if object.locked?
        kind=object_kind(object);raise bilingual('This modifier does not support that object type.','این اصلاح‌گر از این نوع آبجکت پشتیبانی نمی‌کند.') if kinds && !kinds.include?(kind)
        [kind,Objects.params(object)]
      end
      def path_points!(object,allow_closed=false)
        kind,p=ensure_editable!(object,PATH_KINDS);raise bilingual('Raft and pad foundations do not have editable paths.','فونداسیون گسترده و منفرد مسیر قابل ویرایش ندارند.') if kind=='foundation' && p['foundation_type'].to_s!='strip'
        raise bilingual('Closed paths must be opened before this operation.','پیش از این عملیات مسیر بسته را باز کنید.') if p['closed']==true && !allow_closed
        points=(p['path_points']||[]).map { |value| numeric_point(value) }
        raise bilingual('The object needs at least two path points.','آبجکت حداقل دو نقطه مسیر می‌خواهد.') if points.length<2
        [kind,p,points]
      end
      def rebuild_parametric(old,kind,p,preserve_uid=true)
        parent=Geometry.parent_entities(old);tr=old.transformation;uid=preserve_uid ? (old.get_attribute('Draupr','uid')||SecureRandom.uuid) : SecureRandom.uuid
        replacement=Objects.create(kind,p,tr,parent,uid);Objects.copy_identity(old,replacement) if preserve_uid
        replacement.transformation=tr;Objects.capture(replacement,kind,p,uid);old.erase!;ObjectIndex.invalidate;replacement
      end
      def nearest_on_path(points,local)
        points.each_cons(2).with_index.map do |(a,b),index|
          vector=a.vector_to(b);length=vector.length;next if length<1.mm
          vector.normalize!;station=[[a.vector_to(local).dot(vector),0.0].max,length].min;point=a.offset(vector,station)
          [point.distance(local),index,point,station,length]
        end.compact.min_by(&:first)
      end
      def knife_solution(object,local)
        kind,p,points=path_points!(object,true);closed=p['closed']==true;points=points+[points.first] if closed;p['openings']=Walls.holes(object) if kind=='wall'
        nearest=nearest_on_path(points,local);raise bilingual('No valid path segment was found.','بخش مسیر معتبری پیدا نشد.') unless nearest
        distance,index,cut,station,length=nearest;clearance=Walls::EPS
        # Internal polyline nodes are valid BIM split stations. Only the two true
        # assembly endpoints are protected against zero-length/sliver children.
        if station<=clearance
          if index>0;node=index;cut=points[node];return {kind:kind,p:p,points:points,distance:distance,index:index,cut:cut,station:0.0,length:length,node_index:node,first_override_max:node-1,second_override_origin:node,closed:closed};end
          raise bilingual('The cut is too close to the assembly start.','محل برش بیش از حد به ابتدای مونتاژ نزدیک است.')
        elsif length-station<=clearance
          node=index+1
          if node<points.length-1;cut=points[node];return {kind:kind,p:p,points:points,distance:distance,index:index,cut:cut,station:length,length:length,node_index:node,first_override_max:node-1,second_override_origin:node,closed:closed};end
          raise bilingual('The cut is too close to the assembly end.','محل برش بیش از حد به انتهای مونتاژ نزدیک است.')
        end
        {kind:kind,p:p,points:points,distance:distance,index:index,cut:cut,station:station,length:length,first_override_max:index,second_override_origin:index,closed:closed}
      end
      def split_indexed_values(values,index,side)
        source=(values||{}).transform_keys(&:to_s);out={}
        source.each do |segment,value|
          old_index=segment.to_i
          if side==:first;out[old_index.to_s]=value if old_index<=index
          elsif old_index>=index;out[(old_index-index).to_s]=value;end
        end;out
      end
      def endpoint_only(hash,key);value=hash.is_a?(Hash) ? hash[key] : nil;value ? {key=>Marshal.load(Marshal.dump(value))} : {};end
      def split_wall_openings(openings,solution)
        first=[];second=[];index=solution[:index]
        Array(openings).each do |opening|
          record=Marshal.load(Marshal.dump(opening));segment=record.fetch('seg',0).to_i
          if solution[:node_index]
            node=solution[:node_index]
            if segment<node;first<<record
            else;record['seg']=segment-node;second<<record;end
          elsif segment<index;first<<record
          elsif segment>index;record['seg']=segment-index;second<<record
          else
            station=solution[:station].to_f
            if record['t2']<=station+Walls::EPS;first<<record
            elsif record['t1']>=station-Walls::EPS
              record['seg']=0;record['t1']-=station;record['t2']-=station;second<<record
            else
              raise bilingual('Move the Knife outside the hosted opening before splitting.','پیش از برش، چاقو را بیرون از بازشوی متصل قرار دهید.')
            end
          end
        end
        [first,second]
      end
      def split_parameters(p,solution)
        index=solution[:index];cut=solution[:cut];points=solution[:points]
        if solution[:node_index];node=solution[:node_index];first=points[0..node];second=points[node..]
        else;first=points[0..index]+[cut];second=[cut]+points[(index+1)..];end
        p1=Marshal.load(Marshal.dump(p));p2=Marshal.load(Marshal.dump(p));p1['path_points']=first.map(&:to_a);p2['path_points']=second.map(&:to_a)
        if solution[:closed];p1['closed']=false;p2['closed']=false;end
        p1['name']="#{p['name']} A" unless p['name'].to_s.empty?;p2['name']="#{p['name']} B" unless p['name'].to_s.empty?
        p1.delete('end_trims');p2.delete('end_trims')
        if solution[:kind]=='wall'
          p1['wall_joins']=endpoint_only(p['wall_joins'],'start');p2['wall_joins']=endpoint_only(p['wall_joins'],'end')
          p1['wall_end_overrides']=endpoint_only(p['wall_end_overrides'],'start');p2['wall_end_overrides']=endpoint_only(p['wall_end_overrides'],'end')
          p1['segment_height_overrides']=split_indexed_values(p['segment_height_overrides'],solution[:first_override_max],:first);p2['segment_height_overrides']=split_indexed_values(p['segment_height_overrides'],solution[:second_override_origin],:second)
          p1['openings'],p2['openings']=split_wall_openings(p['openings'],solution)
        elsif solution[:kind]=='foundation'
          p1['segment_z_offsets']=split_indexed_values(p['segment_z_offsets'],solution[:first_override_max],:first);p2['segment_z_offsets']=split_indexed_values(p['segment_z_offsets'],solution[:second_override_origin],:second)
        end
        [p1,p2]
      end
      def relink_split_peer(record,old_uid,new_uid)
        return unless record.is_a?(Hash) && old_uid.to_s!=new_uid.to_s
        peer=Objects.get(record['peer_uid']);peer_p=Objects.params(peer);peer_end=record['peer_end'].to_s;peer_record=(peer_p['wall_joins']||{})[peer_end]
        raise bilingual('The joined peer metadata is incomplete; repair the junction before splitting.','اطلاعات اتصال دیوار مقابل ناقص است؛ پیش از برش اتصال را ترمیم کنید.') unless peer_record && peer_record['peer_uid'].to_s==old_uid.to_s
        peer_record['peer_uid']=new_uid;rebuild_parametric(peer,'wall',peer_p,true)
      end
      def relink_split_openings(old_uid,wall,openings)
        host=Hosts.host_ref(wall)
        Array(openings).each do |opening|
          oid=opening['oid'].to_s;next if oid.empty?
          object=Objects.all.find { |candidate| Objects.id(candidate).to_s==oid };next unless object
          records=Hosts.records(object).map do |record|
            record['id'].to_s==old_uid.to_s ? record.merge(host).merge('seg'=>opening.fetch('seg',0).to_i) : record
          end
          object.set_attribute('Draupr','hosts_json',JSON.generate(records))
        end
      end
      def split_path(object,local)
        solution=knife_solution(object,local);kind=solution[:kind];p=solution[:p];p1,p2=split_parameters(p,solution);parent=Geometry.parent_entities(object);tr=object.transformation;old_uid=Objects.id(object)
        start_join=(p['wall_joins']||{})['start'];end_join=(p['wall_joins']||{})['end'];keep_first=start_join || !end_join;uid1=keep_first ? old_uid : SecureRandom.uuid;uid2=keep_first ? SecureRandom.uuid : old_uid
        Transactions.run('Knife Split Draupr assembly') do
          a=Objects.create(kind,p1,tr,parent,uid1);b=Objects.create(kind,p2,tr,parent,uid2)
          relink_split_peer(start_join,old_uid,uid1) if kind=='wall';relink_split_peer(end_join,old_uid,uid2) if kind=='wall'
          object.erase!;ObjectIndex.invalidate
          if kind=='wall';relink_split_openings(old_uid,a,p1['openings']);relink_split_openings(old_uid,b,p2['openings']);end
          selection=Sketchup.active_model.selection;selection.clear;selection.add(a);selection.add(b)
        end;true
      end
      def split_preview_path(object,local)
        solution=knife_solution(object,local);cut=solution[:cut];points=solution[:points];index=solution[:index];direction=points[index].vector_to(points[index+1]);direction.normalize!;side=Z_AXIS.cross(direction);side=Y_AXIS.clone if side.length<1e-8;side.normalize!
        bounds=object.definition.bounds
        width_hint=case solution[:kind]
        when 'wall' then solution[:p]['thickness'].to_f
        when 'foundation' then solution[:p]['width'].to_f
        when 'beam' then solution[:p]['width'].to_f
        else [solution[:p]['thickness'].to_f,solution[:p]['width'].to_f,solution[:p]['depth'].to_f].max
        end
        half_width=[[[width_hint/2.0+75.mm,150.mm].max,750.mm].min,150.mm].max
        left=-half_width;right=half_width;bottom=[bounds.min.z,cut.z].min-10.mm;top=[bounds.max.z,cut.z+500.mm].max+10.mm
        base_left=Geom::Point3d.new(cut.x,cut.y,bottom).offset(side,left);base_right=Geom::Point3d.new(cut.x,cut.y,bottom).offset(side,right);top_right=Geom::Point3d.new(base_right.x,base_right.y,top);top_left=Geom::Point3d.new(base_left.x,base_left.y,top)
        [base_left,base_right,top_right,top_left]
      end
      def trim_path_to_plane(object,local_click,world_plane)
        kind,p,points=path_points!(object);first=local_click.distance(points.first)<=local_click.distance(points.last);endpoint=first ? points.first : points.last;neighbor=first ? points[1] : points[-2]
        raise bilingual('Pick close to the first or last path segment.','نزدیک اولین یا آخرین بخش مسیر کلیک کنید.') if points.length>2 && nearest_on_path(points,local_click)[1].between?(1,points.length-3)
        active_to_world=Sketchup.active_model.edit_transform;object_to_world=active_to_world*object.transformation;world_endpoint=endpoint.transform(object_to_world);world_neighbor=neighbor.transform(object_to_world);direction=world_neighbor.vector_to(world_endpoint);direction.reverse! if first
        hit=Geom.intersect_line_plane([world_endpoint,direction],world_plane);raise bilingual('The path is parallel to the target boundary.','مسیر با مرز هدف موازی است.') unless hit
        local_hit=hit.transform(object_to_world.inverse);raise bilingual('Trim/extend would create a zero-length segment.','برش یا امتداد یک بخش با طول صفر ایجاد می‌کند.') if local_hit.distance(neighbor)<10.mm
        if kind=='wall'
          end_key=first ? 'start':'end';join=(p['wall_joins']||{})[end_key]
          raise bilingual('The selected wall end is joined. Pick the free end or detach its junction first.','انتهای انتخاب‌شده دیوار متصل است؛ انتهای آزاد را انتخاب کنید یا ابتدا اتصال را جدا کنید.') if join
          # Explicit boundary trimming supersedes stale automatic overlap cuts. Keeping them can
          # clip an L-chain segment twice and report that its endpoint is inside another wall.
          p.delete('end_trims');(p['wall_end_overrides']||{}).delete(end_key)
        end
        replacement=p['path_points'].map { |value| value.map(&:to_f) };replacement[first ? 0 : -1]=local_hit.to_a;p['path_points']=replacement
        Transactions.run('Trim or extend Draupr path') { rebuild_parametric(object,kind,p,true) };true
      end
      def align_baselines(reference,target)
        rk,rp,rpts=path_points!(reference);tk,tp,tpts=path_points!(target);raise bilingual('Choose two different path objects.','دو آبجکت مسیر متفاوت انتخاب کنید.') if reference==target
        ref_a=rpts.first.transform(reference.transformation);ref_b=rpts.last.transform(reference.transformation);tar_a=tpts.first.transform(target.transformation);tar_b=tpts.last.transform(target.transformation)
        ref_direction=ref_a.vector_to(ref_b);target_direction=tar_a.vector_to(tar_b);raise bilingual('A baseline has zero length.','یکی از خطوط مبنا طول صفر دارد.') if ref_direction.length<1.mm || target_direction.length<1.mm
        ref_direction.normalize!;target_direction.normalize!;angle=target_direction.angle_between(ref_direction);axis=target_direction.cross(ref_direction);axis=Z_AXIS if axis.length<1e-8;rotation=Geom::Transformation.rotation(tar_a,axis,angle);rotated=tar_a.transform(rotation);delta=rotated.vector_to(ref_a);transform=Geom::Transformation.translation(delta)*rotation
        Transactions.run('Align Draupr baselines') { target.transformation=transform*target.transformation };true
      end
      def plane_height(plane,point)
        hit=Geom.intersect_line_plane([Geom::Point3d.new(point.x,point.y,0),Z_AXIS],plane);raise bilingual('Boundary plane is vertical.','صفحه مرزی عمودی است.') unless hit;hit.z
      end
      def roof_boundary_surfaces(wall,roof,boundary)
        raise bilingual('The selected object is not a Draupr roof.','آبجکت انتخاب‌شده سقف Draupr نیست.') unless Objects.valid?(roof) && object_kind(roof)=='roof'
        roof_params=Objects.params(roof);offset=boundary.to_s=='top' ? -roof_params['thickness'].to_f : 0.0
        active=Sketchup.active_model.edit_transform;roof_to_world=active*roof.transformation;world_to_wall=(active*wall.transformation).inverse
        Builders.roof_faces(roof_params).map do |polygon|
          local=polygon.map { |point| Geom::Point3d.new(point.x,point.y,point.z+offset).transform(roof_to_world).transform(world_to_wall) }
          raise bilingual('A roof slope is degenerate.','یکی از شیب‌های سقف نامعتبر است.') if local.length<3
          {'plane'=>Geom.fit_plane_to_points(*local.first(3)).map(&:to_f),'polygon'=>local.map(&:to_a)}
        end
      end
      def attach_roof_boundary(wall,boundary,roof)
        kind,p=ensure_editable!(wall,['wall'])
        raise bilingual('Boundary must be top or base.','مرز باید بالا یا پایین باشد.') unless %w[top base].include?(boundary.to_s)
        surfaces=roof_boundary_surfaces(wall,roof,boundary);tolerance=[[p['thickness'].to_f/2.0+50.mm,25.mm].max,250.mm].min;record={'surfaces'=>surfaces,'edge_tolerance'=>tolerance,'allow_nearest_surface'=>true,'target'=>{'object_uid'=>Objects.id(roof),'type'=>'roof','model_guid'=>(Sketchup.active_model.guid rescue nil)},'mode'=>'roof_envelope','solver_version'=>4}
        points=(p['path_points']||[]).map { |value| numeric_point(value) };points.each { |point| Walls.boundary_z(record,point,p['height'].to_f) }
        p["#{boundary}_constraint"]=record
        Transactions.run("Attach wall #{boundary} to roof envelope") { rebuild_parametric(wall,'wall',p,true) };true
      end
      def attach_boundary(wall,boundary,local_plane,target_ref={})
        kind,p=ensure_editable!(wall,['wall'])
        raise bilingual('Boundary must be top or base.','مرز باید بالا یا پایین باشد.') unless %w[top base].include?(boundary.to_s)
        points=(p['path_points']||[]).map { |value| numeric_point(value) };points.each { |point| plane_height(local_plane,point) }
        p["#{boundary}_constraint"]={'plane'=>local_plane.map(&:to_f),'target'=>target_ref,'mode'=>'face','solver_version'=>1}
        Transactions.run("Attach wall #{boundary}") { rebuild_parametric(wall,'wall',p,true) };true
      end
      def detach_boundaries(wall)
        _kind,p=ensure_editable!(wall,['wall']);p.delete('top_constraint');p.delete('base_constraint');Transactions.run('Detach wall boundaries') { rebuild_parametric(wall,'wall',p,true) };true
      end
      def step_at(object,local,delta)
        kind,p,points=path_points!(object);raise bilingual('Remove hosted openings before stepping this wall.','پیش از پله‌دار کردن دیوار، بازشوهای متصل را حذف کنید.') if kind=='wall' && !Walls.holes(object).empty?
        nearest=nearest_on_path(points,local);raise bilingual('No valid path segment was found.','بخش مسیر معتبری پیدا نشد.') unless nearest
        _distance,index,point,_station,length=nearest;raise bilingual('Step point is too close to an endpoint.','نقطه پله بیش از حد به انتهای مسیر نزدیک است.') if point.distance(points[index])<10.mm || point.distance(points[index+1])<10.mm
        points.insert(index+1,point);p['path_points']=points.map(&:to_a)
        key=kind=='foundation' ? 'segment_z_offsets' : 'segment_height_overrides';source=(p[key]||{}).transform_keys(&:to_s);shifted={}
        source.each { |segment,value| i=segment.to_i;shifted[(i>index ? i+1 : i).to_s]=value.to_f }
        base=kind=='foundation' ? shifted.fetch(index.to_s,0.0) : shifted.fetch(index.to_s,p['height'].to_f);shifted[index.to_s]=base;shifted[(index+1).to_s]=base+delta.to_f;p[key]=shifted
        Transactions.run('Step Draupr path') { rebuild_parametric(object,kind,p,true) };true
      end
      def nearest_wall_opening(wall,world_point)
        local=Transforms.world_point_to_local(wall,world_point);segments=Walls.segments(wall)
        Walls.holes(wall).map do |opening|
          segment=segments[opening['seg'].to_i];next unless segment
          a=Walls.point(segment['cs']);b=Walls.point(segment['ce']);direction=a.vector_to(b);next if direction.length<1.mm;direction.normalize!
          station=a.vector_to(local).dot(direction);height=local.z-a.z
          dx=station<opening['t1'] ? opening['t1']-station : (station>opening['t2'] ? station-opening['t2'] : 0.0)
          dz=height<opening['z0'] ? opening['z0']-height : (height>opening['z1'] ? height-opening['z1'] : 0.0)
          [Math.sqrt(dx*dx+dz*dz),opening]
        end.compact.min_by(&:first)
      end
      def heal_opening(opening,world_point=nil)
        kind=object_kind(opening)
        if %w[door window skylight dormer].include?(kind)
          ensure_editable!(opening,%w[door window skylight dormer]);Transactions.run('Heal Draupr opening') { Hosts.remove(opening) };return true
        end
        ensure_editable!(opening,['wall']);match=nearest_wall_opening(opening,world_point);raise bilingual('No hosted wall opening was found near the click.','هیچ بازشوی متصل دیوار نزدیک کلیک پیدا نشد.') unless match
        record=match[1];oid=record['oid'].to_s
        Transactions.run('Heal Draupr wall opening') do
          Walls.recut(opening,Walls.holes(opening).reject { |item| item['oid'].to_s==oid })
          linked=Objects.all.find { |object| Objects.id(object).to_s==oid };linked.erase! if linked&&linked.valid?
        end
        true
      end
      def splay_opening(opening,angle,sill_slope,setback)
        kind,old=ensure_editable!(opening,%w[door window]);raise bilingual('Jamb splay must be between 0° and 45°.','زاویه پخی چهارچوب باید بین ۰ تا ۴۵ درجه باشد.') unless angle.to_f.between?(0,45);raise bilingual('Sill slope must be between 0° and 15°.','شیب زیرپنجره باید بین ۰ تا ۱۵ درجه باشد.') unless sill_slope.to_f.between?(0,15)
        p=Marshal.load(Marshal.dump(old));p['jamb_splay']=angle.to_f;p['sill_slope']=sill_slope.to_f;p['casing_setback']=setback.to_f
        Transactions.run('Splay Draupr opening') { Hosts.edit_opening(opening,old,p,{'jamb_splay'=>angle,'sill_slope'=>sill_slope,'casing_setback'=>setback}) };true
      end
      def modify_sweep(object,anchor,flip,start_return,end_return,return_length)
        kind,p=ensure_editable!(object,%w[molding railing]);p['profile_anchor']=anchor.to_s unless anchor.to_s.empty?;p['flip_profile']=flip==true;p['start_return']=start_return==true;p['end_return']=end_return==true;p['return_length']=return_length.to_f
        Transactions.run('Modify Draupr sweep') { rebuild_parametric(object,kind,p,true) };true
      end
      def disassemble(objects)
        raise bilingual('Select at least one Draupr object.','حداقل یک آبجکت Draupr انتخاب کنید.') if objects.empty?
        Transactions.run('Disassemble Draupr objects') do
          selection=Sketchup.active_model.selection;selection.clear
          objects.each do |object|
            ensure_editable!(object);Parts.independent_tree(object);object.delete_attribute('Draupr');children=object.entities.grep(Sketchup::Group);result=object.explode;Array(result).grep(Sketchup::Group).each { |group| selection.add(group) };children.each { |group| selection.add(group) if group.valid? }
          end
          ObjectIndex.invalidate
        end;true
      end
      def detail_edges(edges,style,size)
        raise bilingual('Select one or more edges first.','ابتدا یک یا چند لبه انتخاب کنید.') if edges.empty?;raise bilingual('Detail size must be positive.','اندازه جزئیات باید مثبت باشد.') unless size.to_f>0
        Transactions.run("Create #{style} edge detail") do
          root=Sketchup.active_model.active_entities.add_group;root.name="Draupr #{style.capitalize} Edge Detail";material=Materials.by_name_or_default(nil,:concrete)
          edges.each_with_index do |edge,index|
            a=edge.start.position;b=edge.end.position;vector=a.vector_to(b);next if vector.length<1.mm
            if style.to_s=='bullnose';Builders.bar_between(root.entities,'detail',"bullnose_#{index}",a,b,size.to_f/2,size.to_f/2,material)
            else
              direction=vector.normalize;side=Z_AXIS.cross(direction);side=Y_AXIS.clone if side.length<1e-8;side.normalize!;part=Parts.make(root.entities,'detail',"chamfer_#{index}",material);face=part.entities.add_face(a,a.offset(side,size),a.offset(Z_AXIS,-size));face.pushpull(vector.length) if face
            end
          end
          root.set_attribute('Draupr_Detail','style',style.to_s);root.set_attribute('Draupr_Detail','size',size.to_f)
          selection=Sketchup.active_model.selection;selection.clear;selection.add(root)
        end;true
      end
      def resolved_target_plane(record)
        target=record.is_a?(Hash) ? record['target'] : nil;return nil unless target.is_a?(Hash) && target['persistent_id']
        model=Sketchup.active_model;face=model.find_entity_by_persistent_id(target['persistent_id'].to_i);return nil unless face&&face.valid?&&face.is_a?(Sketchup::Face)
        transform=Geom::Transformation.new
        Array(target['instance_path']).each do |persistent_id|
          instance=model.find_entity_by_persistent_id(persistent_id.to_i);return nil unless instance&&instance.valid?&&instance.respond_to?(:transformation);transform=transform*instance.transformation
        end
        points=face.vertices.first(3).map { |vertex| vertex.position.transform(transform) };return nil if points.length<3;Geom.fit_plane_to_points(*points)
      rescue StandardError=>error
        Diag.log_error('Resolve modifier boundary',error);nil
      end
      def refresh_boundary_constraints
        walls=Objects.all.select { |object| Metadata.read(object)['type']=='wall' }
        walls.each do |wall|
          p=Objects.params(wall);changed=false
          %w[top_constraint base_constraint].each do |key|
            record=p[key];next unless record.is_a?(Hash);target=record['target']||{}
            if record['mode']=='roof_envelope' && target['object_uid']
              roof=Objects.get(target['object_uid']);next unless roof&&roof.valid?&&object_kind(roof)=='roof'
              surfaces=roof_boundary_surfaces(wall,roof,key.start_with?('top') ? 'top':'base')
              if record['surfaces']!=surfaces;record['surfaces']=surfaces;changed=true;end
              next
            end
            world_plane=resolved_target_plane(record);next unless world_plane
            object_to_world=Transforms.entity_to_world(wall);normal=Geom::Vector3d.new(world_plane[0],world_plane[1],world_plane[2]);point=Geom.intersect_line_plane([ORIGIN,normal],world_plane);next unless point
            axis=normal.cross(Z_AXIS);axis=normal.cross(X_AXIS) if axis.length<1e-8;axis.normalize!;second=normal.cross(axis);second.normalize!;inverse=object_to_world.inverse
            local_plane=Geom.fit_plane_to_points(point.transform(inverse),point.offset(axis,1000.mm).transform(inverse),point.offset(second,1000.mm).transform(inverse))
            if record['plane']!=local_plane;record['plane']=local_plane.map(&:to_f);changed=true;end
          end
          rebuild_parametric(wall,'wall',p,true) if changed
        end;true
      end
      def junction_record(wall,local)
        _kind,p=ensure_editable!(wall,['wall']);points=(p['path_points']||[]).map { |value| numeric_point(value) };key=local.distance(points.first)<=local.distance(points.last) ? 'start':'end';record=(p['wall_joins']||{})[key];raise bilingual('This endpoint is not joined.','این انتهای دیوار اتصال ندارد.') unless record
        [key,record,Objects.get(record['peer_uid'])]
      end
      def set_junction(wall,local,mode,radius=300.mm)
        key,record,peer=junction_record(wall,local);peer_p=Objects.params(peer);peer_key=record['peer_end'];click_a=numeric_point(Objects.params(wall)['path_points'][key=='start' ? 0 : -1]);click_b=numeric_point(peer_p['path_points'][peer_key=='start' ? 0 : -1])
        if %w[fillet chamfer].include?(mode.to_s);return corner_connector(wall,click_a,peer,click_b,mode.to_s,radius.to_f);end
        solver_mode=mode.to_s.start_with?('butt') ? 'butt' : mode.to_s;priority=mode.to_s=='butt_right' ? 1 : 0
        Transactions.run('Switch Draupr wall junction') do
          solution=WallJunctions.solve(wall,click_a,peer,click_b,solver_mode,priority,key,peer_key);a,b,_join_id=WallJunctions.apply_solution(solution,record['join_id']);rebuild_parametric(wall,'wall',a,true);rebuild_parametric(peer,'wall',b,true)
        end;true
      end
      def corner_connector(wall_a,click_a,wall_b,click_b,mode,radius)
        raise bilingual('Corner radius must be positive.','شعاع گوشه باید مثبت باشد.') unless radius>10.mm
        info_a=WallJunctions.wall_info(wall_a,click_a);info_b=WallJunctions.wall_info(wall_b,click_b);hit=WallJunctions.center_hit(info_a,info_b);a=WallJunctions.select_kept_ray(info_a,hit);b=WallJunctions.select_kept_ray(info_b,hit);dot=[[a[:u].dot(b[:u]),-0.999999].max,0.999999].min;theta=Math.acos(dot);raise bilingual('Corner angle is too shallow.','زاویه گوشه بیش از حد کم است.') if theta<5.degrees || theta>175.degrees
        tangent=mode=='chamfer' ? radius : radius/Math.tan(theta/2.0);raise bilingual('Radius is too large for the wall lengths.','شعاع برای طول دیوارها بیش از حد بزرگ است.') if tangent>a[:kept_point].distance(hit)-10.mm || tangent>b[:kept_point].distance(hit)-10.mm
        ta=hit.offset(a[:u],tangent);tb=hit.offset(b[:u],tangent);connector=[ta,tb]
        if mode=='fillet'
          bisector=a[:u]+b[:u];bisector.normalize!;center=hit.offset(bisector,radius/Math.sin(theta/2.0));angle_a=Math.atan2(ta.y-center.y,ta.x-center.x);angle_b=Math.atan2(tb.y-center.y,tb.x-center.x);delta=angle_b-angle_a;delta-=2*Math::PI while delta>Math::PI;delta+=2*Math::PI while delta<-Math::PI;connector=(0..12).map { |index| angle=angle_a+delta*index/12.0;Geom::Point3d.new(center.x+Math.cos(angle)*radius,center.y+Math.sin(angle)*radius,hit.z) }
        end
        pa=Marshal.load(Marshal.dump(a[:p]));pb=Marshal.load(Marshal.dump(b[:p]));pa['path_points'][a[:replace]]=ta.transform(wall_a.transformation.inverse).to_a;pb['path_points'][b[:replace]]=tb.transform(wall_b.transformation.inverse).to_a
        [[pa,a[:end_key]],[pb,b[:end_key]]].each do |params,end_key|;(params['wall_joins']||{}).delete(end_key);(params['wall_end_overrides']||{}).delete(end_key);end
        connector_p=Marshal.load(Marshal.dump(pa));%w[wall_joins wall_end_overrides end_trims].each { |field| connector_p.delete(field) };connector_p['path_points']=connector.map(&:to_a);connector_p['path_curve']=mode=='fillet';connector_p['name']="#{mode.capitalize} corner"
        parent=Geometry.parent_entities(wall_a);raise bilingual('Walls must share one editing context.','دیوارها باید در یک زمینه ویرایش باشند.') unless parent.equal?(Geometry.parent_entities(wall_b))
        Transactions.run("Create Draupr #{mode} corner") do
          rebuild_parametric(wall_a,'wall',pa,true);rebuild_parametric(wall_b,'wall',pb,true);connector_wall=Objects.create('wall',connector_p,Geom::Transformation.new,parent);selection=Sketchup.active_model.selection;selection.clear;selection.add(connector_wall)
        end;true
      end
    end
  end
end
