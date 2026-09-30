# frozen_string_literal: true
module Draupr
  module Core
    module WallJunctions
      TOL=0.5.mm
      module_function
      def copy(value);Marshal.load(Marshal.dump(value));end
      def chain_points(p)
        pts=(p['path_points']||[]).map { |q| Walls.point(q) };out=[]
        pts.each do |q|
          next if !out.empty? && out[-1].distance(q)<1.mm
          if out.length>=2
            a,b=out[-2],out[-1];u=a.vector_to(b);v=b.vector_to(q)
            if u.length>1.mm && v.length>1.mm && u.cross(v).length/(u.length*v.length)<1e-6 && u.dot(v)>0
              out[-1]=q;next
            end
          end
          out<<q
        end
        out
      end
      def segment_params(base,a,b,index,total)
        p=copy(base);p['path_points']=[Walls.xyz(a),Walls.xyz(b)];p['length']=a.distance(b).to_f;p['closed']=false
        %w[wall_joins wall_end_overrides end_trims openings legacy_segments].each { |key| p.delete(key) }
        p['name']="#{base['name']} #{index+1}/#{total}" unless base['name'].to_s.empty?
        p
      end
      def rebuild_pair_in_operation(sol)
        pa,pb,_=apply_solution(sol);a=sol[:a][:wall];b=sol[:b][:wall]
        [ModifyTools.rebuild_wall(a,pa),ModifyTools.rebuild_wall(b,pb)]
      end
      def join_chain_in_operation(groups)
        uids=groups.map { |g| Objects.id(g) }
        (0...uids.length-1).each do |i|
          a=Objects.get(uids[i]);b=Objects.get(uids[i+1]);pa=Objects.params(a);pb=Objects.params(b)
          ap=pa['path_points'].map { |q| Walls.point(q).transform(a.transformation) };bp=pb['path_points'].map { |q| Walls.point(q).transform(b.transformation) }
          next if (ap[0].z-ap[1].z).abs>TOL || (bp[0].z-bp[1].z).abs>TOL
          ua=horizontal_vector(ap[0],ap[1]);ub=horizontal_vector(bp[0],bp[1]);next if ua.cross(ub).length<0.01
          sol=solve(a,nil,b,nil,'miter',0,'end','start');rebuild_pair_in_operation(sol)
        end
        uids.map { |uid| Objects.get(uid) }
      end
      def create_path_segments(p,tr,parent=nil)
        raise 'Curved or closed wall paths stay as one object. / مسیر دیوار منحنی یا بسته یک آبجکت باقی می‌ماند.' if p['closed']==true || p['path_curve']==true
        pts=chain_points(p);raise 'A wall path needs at least two distinct points. / مسیر دیوار حداقل دو نقطه متفاوت می‌خواهد.' if pts.length<2
        parent||=Sketchup.active_model.active_entities
        groups=pts.each_cons(2).with_index.map { |(a,b),i| Objects.create('wall',segment_params(p,a,b,i,pts.length-1),tr,parent) }
        join_chain_in_operation(groups)
      end
      def distance_to_segment(point,a,b)
        v=a.vector_to(b);return point.distance(a) if v.length<1e-9
        len=v.length;v.normalize!;t=[[a.vector_to(point).dot(v),0.0].max,len].min;point.distance(a.offset(v,t))
      end
      def segmentize_for_junction(wall,local_click)
        p=Objects.params(wall);pts=chain_points(p)
        return [wall,false] if pts.length==2 && p['closed']!=true
        raise 'Closed wall loops must be split before joining. / حلقه بسته دیوار باید پیش از اتصال تقسیم شود.' if p['closed']==true
        raise 'Curved walls cannot use straight-wall junctions. / دیوار منحنی از اتصال دیوار مستقیم پشتیبانی نمی‌کند.' if p['path_curve']==true
        raise 'Move or remove hosted openings before converting this wall path. / پیش از تبدیل مسیر دیوار، بازشوهای متصل را جابه‌جا یا حذف کنید.' unless Walls.holes(wall).empty?
        raise 'A wall path needs at least two distinct points. / مسیر دیوار حداقل دو نقطه متفاوت می‌خواهد.' if pts.length<2
        index=pts.each_cons(2).with_index.map { |(a,b),i| [distance_to_segment(local_click,a,b),i] }.min_by(&:first)[1]
        tr=wall.transformation;parent=Geometry.parent_entities(wall);material=wall.material;hidden=wall.hidden?
        groups=pts.each_cons(2).with_index.map do |(a,b),i|
          g=Objects.create('wall',segment_params(p,a,b,i,pts.length-1),tr,parent);g.material=material;g.hidden=hidden;g
        end
        wall.erase!;groups=join_chain_in_operation(groups);[groups[index],true]
      end
      def wall_params!(wall)
        raise 'Pick a Draupr wall.' unless Objects.valid?(wall) && Metadata.read(wall)['type']=='wall'
        p=Objects.params(wall)
        raise 'Wall junctions currently support straight, two-point walls only.' unless p['path_points'].is_a?(Array) && p['path_points'].length==2 && !p['closed']
        raise 'Move or remove hosted openings before joining this wall.' unless Walls.holes(wall).empty?
        raise 'Wall must be vertical and unscaled.' unless wall.transformation.zaxis.parallel?(Z_AXIS) && (wall.transformation.xaxis.length-1.0).abs<1e-6 && (wall.transformation.yaxis.length-1.0).abs<1e-6
        p
      end
      def horizontal_vector(a,b)
        v=a.vector_to(b);v=Geom::Vector3d.new(v.x,v.y,0.0);raise 'Wall centerline has no horizontal direction.' if v.length<1e-8;v.normalize;end
      def line_intersection(a,b)
        q=Geom.intersect_line_line(a,b);raise 'Wall boundary lines do not intersect.' unless q;q
      end
      def wall_info(wall,local_click=nil,end_key=nil)
        p=wall_params!(wall);local=p['path_points'].map { |q| Walls.point(q) };active=local.map { |q| q.transform(wall.transformation) }
        raise 'Joined walls must have the same base elevation.' if (active[0].z-active[1].z).abs>TOL
        dir=horizontal_vector(active[0],active[1]);normal=dir.cross(Z_AXIS);normal.normalize!;off0,off1=Geometry.alignment_offsets(p['thickness'],p['alignment'])
        click=local_click && local_click.transform(wall.transformation)
        {wall:wall,p:p,local:local,points:active,a:active[0],b:active[1],dir:dir,normal:normal,offsets:[off0,off1],click:click,end_key:end_key}
      end
      def center_hit(a,b)
        raise 'Walls must belong to the same editing context.' unless Geometry.parent_entities(a[:wall]).equal?(Geometry.parent_entities(b[:wall]))
        raise 'Joined walls must have the same base elevation.' if (a[:a].z-b[:a].z).abs>TOL
        hit=line_intersection([a[:a],a[:dir]],[b[:a],b[:dir]])
        Geom::Point3d.new(hit.x,hit.y,(a[:a].z+b[:a].z)/2.0)
      end
      def select_kept_ray(info,hit)
        scalars=info[:points].map { |q| hit.vector_to(q).dot(info[:dir]) }
        if info[:end_key]
          replace=info[:end_key].to_s=='start' ? 0 : 1
        elsif scalars[0]*scalars[1] < -TOL*TOL
          c=hit.vector_to(info[:click]).dot(info[:dir]);keep=(c-scalars[0]).abs<=(c-scalars[1]).abs ? 0 : 1;replace=1-keep
        else
          replace=scalars[0].abs<=scalars[1].abs ? 0 : 1
        end
        keep=1-replace;u=horizontal_vector(hit,info[:points][keep]);discard=scalars[replace]*scalars[keep]<-TOL*TOL ? [info[:points][replace],hit] : nil
        info.merge(replace:replace,keep:keep,end_key:(replace==0 ? 'start':'end'),kept_point:info[:points][keep],u:u,discard:discard)
      end
      def offset_line(info,offset);[info[:a].offset(info[:normal],offset),info[:dir]];end
      def pair_on_line(info,cap_line,offsets)
        offsets.map { |off| line_intersection(offset_line(info,off),cap_line) }
      end
      def local_pair(info,pair);pair.map { |q| w=q.transform(info[:wall].transformation.inverse);[w.x,w.y,w.z] };end
      def override_on_line(info,cap_line)
        layers=Walls.profile(info[:p]).map { |a,b,_,_| local_pair(info,pair_on_line(info,cap_line,[a,b])) }
        {'full'=>local_pair(info,pair_on_line(info,cap_line,info[:offsets])),'layers'=>layers}
      end
      def choose_boundary(owner,traveller,hit,which)
        candidates=owner[:offsets].map do |off|
          line=offset_line(owner,off);q=line_intersection([traveller[:a],traveller[:dir]],line);[hit.vector_to(q).dot(traveller[:u]),line]
        end
        which==:near ? candidates.max_by(&:first)[1] : candidates.min_by(&:first)[1]
      end
      def solve_caps(a,b,hit,mode,priority)
        mode=mode.to_s;raise 'Join mode must be butt, miter or square.' unless %w[butt miter square].include?(mode)
        if mode=='miter'
          raise 'Miter currently requires equal wall thickness and matching alignment.' if (a[:p]['thickness']-b[:p]['thickness']).abs>TOL || a[:p]['alignment']!=b[:p]['alignment']
          seam=a[:u]+b[:u];raise 'Cannot miter opposite or parallel wall rays.' if seam.length<1e-8;seam.normalize!;line=[hit,seam]
          return [override_on_line(a,line),override_on_line(b,line)]
        end
        primary,secondary=priority.to_i==1 ? [b,a] : [a,b]
        primary_cap=choose_boundary(secondary,primary,hit,:far);secondary_cap=choose_boundary(primary,secondary,hit,:near)
        po=override_on_line(primary,primary_cap);so=override_on_line(secondary,secondary_cap)
        priority.to_i==1 ? [so,po] : [po,so]
      end
      def solve(wall_a,click_a,wall_b,click_b,mode='butt',priority=0,end_a=nil,end_b=nil)
        raise 'Choose two different walls.' if wall_a==wall_b
        a=wall_info(wall_a,click_a,end_a);b=wall_info(wall_b,click_b,end_b);hit=center_hit(a,b);a=select_kept_ray(a,hit);b=select_kept_ray(b,hit)
        cross=a[:u].cross(b[:u]).length;raise 'Walls are parallel or nearly parallel.' if cross<0.01
        oa,ob=solve_caps(a,b,hit,mode,priority)
        {a:a,b:b,hit:hit,overrides:[oa,ob],mode:mode.to_s,priority:priority.to_i,
         kept:[[a[:kept_point],hit],[b[:kept_point],hit]],discard:[a[:discard],b[:discard]].compact,caps:[oa['full'].map { |q| Walls.point(q).transform(wall_a.transformation) },ob['full'].map { |q| Walls.point(q).transform(wall_b.transformation) }]}
      end
      def endpoint_hash(p,key);p[key]=copy(p[key]||{});p[key];end
      def detach_conflicting_peer(existing,current_uid)
        return unless existing.is_a?(Hash) && existing['peer_uid']
        peer=Objects.get(existing['peer_uid']);peer_p=Objects.params(peer);join_id=existing['join_id'].to_s
        match=(peer_p['wall_joins']||{}).find { |_key,record| record['join_id'].to_s==join_id && record['peer_uid'].to_s==current_uid.to_s }
        return unless match
        peer_end=match[0];peer_p['wall_joins'].delete(peer_end);(peer_p['wall_end_overrides']||{}).delete(peer_end);peer_p.delete('end_trims')
        ModifyTools.rebuild_wall(peer,peer_p)
      rescue RuntimeError=>error
        raise unless error.message=='Object no longer exists. Refresh selection.'
      end
      def apply_solution(sol,join_id=nil)
        a,b=sol[:a],sol[:b];pa,pb=copy(a[:p]),copy(b[:p]);join_id||=SecureRandom.uuid;uid_a=Objects.id(a[:wall]);uid_b=Objects.id(b[:wall])
        [[a,pa,sol[:overrides][0],uid_b,b[:end_key]],[b,pb,sol[:overrides][1],uid_a,a[:end_key]]].each do |info,p,over,peer_uid,peer_end|
          existing=(p['wall_joins']||{})[info[:end_key]]
          if existing && existing['peer_uid'].to_s!=peer_uid.to_s
            detach_conflicting_peer(existing,Objects.id(info[:wall]));p['wall_joins'].delete(info[:end_key]);(p['wall_end_overrides']||{}).delete(info[:end_key])
          end
          local_hit=sol[:hit].transform(info[:wall].transformation.inverse);p['path_points'][info[:replace]]=[local_hit.x,local_hit.y,local_hit.z]
          p['end_trims']=(p['end_trims']||[]).reject { |cut| cut['seg'].to_i==(info[:replace]==0 ? 0 : p['path_points'].length-2) }
          endpoint_hash(p,'wall_end_overrides')[info[:end_key]]=over
          endpoint_hash(p,'wall_joins')[info[:end_key]]={'join_id'=>join_id,'peer_uid'=>peer_uid,'peer_end'=>peer_end,'mode'=>sol[:mode],'priority_uid'=>(sol[:priority]==0 ? uid_a : uid_b),'solver_version'=>1}
        end
        [pa,pb,join_id]
      end
      def commit(wall_a,click_a,wall_b,click_b,mode='butt',priority=0)
        Transactions.run('Join standalone Draupr walls') do
          wall_a,_converted_a=segmentize_for_junction(wall_a,click_a);wall_b,_converted_b=segmentize_for_junction(wall_b,click_b)
          sol=solve(wall_a,click_a,wall_b,click_b,mode,priority);ga,gb=rebuild_pair_in_operation(sol)
          s=Sketchup.active_model.selection;s.clear;s.add(ga);s.add(gb)
        end;true
      end
      def preview(wall_a,click_a,wall_b,click_b,mode='butt',priority=0);solve(wall_a,click_a,wall_b,click_b,mode,priority);end
      def refresh_join(join_id)
        members=Objects.all.select do |g|
          next false unless Metadata.read(g)['type']=='wall'
          (Objects.params(g)['wall_joins']||{}).values.any? { |j| j['join_id'].to_s==join_id.to_s }
        end
        raise 'Joined wall peer is missing.' unless members.length==2
        a,b=members;pa=Objects.params(a);ra=(pa['wall_joins']||{}).find { |_k,j| j['join_id'].to_s==join_id.to_s };pb=Objects.params(b);rb=(pb['wall_joins']||{}).find { |_k,j| j['join_id'].to_s==join_id.to_s };raise 'Wall join metadata is incomplete.' unless ra&&rb
        mode=ra[1]['mode']||'butt';primary=ra[1]['priority_uid'];priority=Objects.id(a).to_s==primary.to_s ? 0 : 1
        sol=solve(a,nil,b,nil,mode,priority,ra[0],rb[0]);na,nb,_=apply_solution(sol,join_id);ModifyTools.rebuild_wall(a,na);ModifyTools.rebuild_wall(b,nb);true
      end
      def refresh_for_ids(ids)
        join_ids=ids.flat_map do |uid|
          g=Objects.get(uid);next [] unless Metadata.read(g)['type']=='wall'
          (Objects.params(g)['wall_joins']||{}).values.map { |j| j['join_id'] }
        end.compact.uniq
        join_ids.each { |jid| refresh_join(jid) };true
      end
    end
  end
end
