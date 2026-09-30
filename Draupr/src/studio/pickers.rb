# frozen_string_literal: true
module Draupr
  module Studio
    module Picking
      module_function
      def paths(view,x,y,aperture=nil)
        ph=view.pick_helper;aperture ? ph.do_pick(x,y,aperture) : ph.do_pick(x,y);(0...ph.count).map { |index| ph.path_at(index)||[] }
      end
      def path(view,x,y);paths(view,x,y).first||[];end
      def object_in(path);path.find { |e| Core::Objects.valid?(e) };end
      def effective_material(path,view,x,y)
        leaf=path.last
        if leaf.is_a?(Sketchup::Face)
          tr=Sketchup.active_model.edit_transform;path[0...-1].each { |e| tr=tr*e.transformation if e.respond_to?(:transformation) }
          back=leaf.normal.transform(tr).dot(view.pickray(x,y)[1])>0
          material=back ? leaf.back_material : leaf.material
          return material if material
        end
        path.reverse_each { |e| next if e.is_a?(Sketchup::Face);return e.material if e.respond_to?(:material) && e.material };nil
      end
      def wire_bounds(view,path,color=[44,139,221])
        e=path.reverse.find { |v| v.is_a?(Sketchup::Group) || v.is_a?(Sketchup::Face) };return unless e
        index=path.index(e);tr=Sketchup.active_model.edit_transform
        path[0...index].each { |v| tr=tr*v.transformation if v.respond_to?(:transformation) }
        b=e.bounds;pts=(0..7).map { |i| b.corner(i).transform(tr) }
        edges=[[0,1],[1,3],[3,2],[2,0],[4,5],[5,7],[7,6],[6,4],[0,4],[1,5],[2,6],[3,7]]
        view.drawing_color=color;view.line_width=3;view.draw(GL_LINES,edges.flat_map { |a,b| [pts[a],pts[b]] })
      end
    end
    module PathCreation
      LINEAR_KINDS=%w[wall curtain_wall beam railing louver molding foundation].freeze
      module_function
      def supported?(kind,p)
        LINEAR_KINDS.include?(kind.to_s) && (kind.to_s!='foundation' || p['foundation_type'].to_s=='strip')
      end
      def selected_edges
        edges=Sketchup.active_model.selection.grep(Sketchup::Edge)
        raise 'Select one connected, non-branching edge path. / یک مسیر لبه پیوسته و بدون انشعاب انتخاب کنید.' if edges.empty?
        edges
      end
      def connected_edges(edge)
        return edge.curve.edges if edge.respond_to?(:curve) && edge.curve
        edge.all_connected.grep(Sketchup::Edge)
      end
      def order_edges(edges)
        edges=edges.select { |e| e.valid? }.uniq
        raise 'The selected path has no valid edges. / مسیر انتخاب‌شده لبه معتبر ندارد.' if edges.empty?
        adjacency=Hash.new { |h,k| h[k]=[] };vertices={}
        edges.each do |edge|
          [edge.start,edge.end].each { |vertex| vertices[vertex.object_id]=vertex;adjacency[vertex.object_id]<<edge }
        end
        raise 'The selected path branches. Select one chain without junctions. / مسیر انتخاب‌شده انشعاب دارد؛ یک زنجیره بدون اتصال فرعی انتخاب کنید.' if adjacency.values.any? { |list| list.length>2 }
        endpoints=adjacency.select { |_key,list| list.length==1 }.keys
        raise 'The selected edges are not one open or closed chain. / لبه‌ها یک زنجیره باز یا بسته تشکیل نمی‌دهند.' unless endpoints.length==2 || endpoints.empty?
        current=vertices[(endpoints.first || edges.first.start.object_id)];visited={};points=[current.position]
        loop do
          edge=adjacency[current.object_id].find { |candidate| !visited[candidate.object_id] };break unless edge
          visited[edge.object_id]=true;current=edge.start==current ? edge.end : edge.start;points<<current.position
        end
        raise 'The selected edges are disconnected. / لبه‌های انتخاب‌شده از هم جدا هستند.' unless visited.length==edges.length
        closed=points.length>2 && points.first.distance(points.last)<0.001;points.pop if closed
        [points,closed]
      end
      def surface_normal(edges)
        face=edges.lazy.flat_map { |edge| edge.faces }.find { |candidate| candidate.valid? }
        return nil unless face
        normal=face.normal.clone;normal.normalize!;normal
      rescue StandardError
        nil
      end
      def create(kind,p,edges,reverse=false)
        raise 'This object type does not support edge-path generation. / این نوع آبجکت از ساخت بر اساس مسیر لبه پشتیبانی نمی‌کند.' unless supported?(kind,p)
        points,closed=order_edges(edges);points.reverse! if reverse
        normal=surface_normal(edges);offset=p['z_offset'].to_f
        if offset.abs>0.0001
          axis=normal || Z_AXIS;points=points.map { |point| point.offset(axis,offset) }
        end
        origin=points.first;local=points.map { |point| vector=origin.vector_to(point);[vector.x,vector.y,vector.z] }
        q=p.merge('path_points'=>local,'closed'=>closed,'length'=>points.each_cons(2).sum { |a,b| a.distance(b) },'z_offset'=>0.0,'rotation'=>0.0)
        q['length']+=points.last.distance(points.first) if closed
        q['path_surface_normal']=[normal.x,normal.y,normal.z] if normal
        q=Core::Parameters.normalize(kind,{},q);tr=Geom::Transformation.new(origin)
        split_wall=kind=='wall' && local.length>2 && !closed
        q=Core::Walls.with_end_trims(q,tr,Sketchup.active_model.active_entities) if kind=='wall' && !split_wall
        created=[]
        Core::Transactions.run("Create Draupr #{kind} from edge path") do
          created=split_wall ? Core::WallJunctions.create_path_segments(q,tr) : [Core::Objects.create(kind,q,tr)]
          selection=Sketchup.active_model.selection;selection.clear;created.each { |object| selection.add(object) }
        end
        UI::Dialog.notify("Created from #{edges.length} selected edge#{edges.length==1 ? '' : 's'}. / آبجکت از #{edges.length} لبه انتخاب‌شده ساخته شد.",'success')
        created
      end
    end
    class ConnectedPathPicker
      def initialize(kind,p);@kind=kind;@p=p;@edges=[];@error=nil;end
      def activate;Sketchup.set_status_text('Pick Connected Path: click an edge chain or curve. Esc exits. / یک زنجیره لبه یا منحنی را کلیک کنید.');end
      def onCancel(_reason,view);Sketchup.active_model.select_tool(nil);view.invalidate;end
      def onMouseMove(_flags,x,y,view)
        path=Picking.path(view,x,y);edge=path.reverse.find { |entity| entity.is_a?(Sketchup::Edge) };@edges=[];@error=nil
        if edge
          begin;candidate=PathCreation.connected_edges(edge);PathCreation.order_edges(candidate);@edges=candidate
          rescue StandardError=>e;@error=e.message;end
        end
        Sketchup.set_status_text(@error ? "Draupr: #{@error}" : 'Click to generate from highlighted path. / برای ساخت از مسیر مشخص‌شده کلیک کنید.');view.invalidate
      end
      def onLButtonDown(_flags,_x,_y,view)
        raise(@error || 'Hover a valid connected edge path first. / ابتدا روی یک مسیر لبه معتبر بروید.') if @edges.empty?
        PathCreation.create(@kind,@p,@edges);@edges=[];Sketchup.active_model.select_tool(nil) unless Core::Preferences.get('keep_drawing',true);view.invalidate
      rescue StandardError=>e;Core::Diag.log_error('Connected path creation',e);UI::Dialog.notify(e.message,'error');end
      def draw(view)
        return if @edges.empty?;tr=Sketchup.active_model.edit_transform;view.drawing_color=[37,108,216];view.line_width=5
        view.draw(GL_LINES,@edges.flat_map { |edge| [edge.start.position.transform(tr),edge.end.position.transform(tr)] })
      end
    end
    class MaterialPicker
      def initialize(mode='sample');@mode=mode;@path=[];end
      def activate;Sketchup.set_status_text(@mode=='sample' ? 'Draupr: click to sample a face or inherited material. Esc cancels.' : 'Draupr: click an object part. Esc cancels.');end
      def onMouseMove(_f,x,y,v);@path=Picking.path(v,x,y);v.invalidate;end
      def onCancel(_r,v);Sketchup.active_model.select_tool(nil);v.invalidate;end
      def deactivate(v);v.invalidate;end
      def onLButtonDown(_f,x,y,v)
        path=Picking.path(v,x,y)
        if @mode=='sample'
          m=Picking.effective_material(path,v,x,y);raise 'The face has no assigned material.' unless m
          Core::Materials.recent(m.name);UI::Dialog.event('sampled',{'material'=>m.name})
        else
          g=Picking.object_in(path);raise 'Pick a Draupr object part.' unless g
          raise 'Enter the containing group before editing this part.' unless Core::Geometry.parent_entities(g)==Sketchup.active_model.active_entities
          part=path.reverse.find { |e| e.respond_to?(:get_attribute) && e.get_attribute(Core::Parts::DICT,'key') }
          raise 'Legacy geometry needs a reviewed parameter edit before part selection.' unless part
          sel=Sketchup.active_model.selection;sel.clear;sel.add(g)
          UI::Dialog.event('partPicked',{'id'=>Core::Objects.id(g),'part'=>part.get_attribute(Core::Parts::DICT,'key'),'role'=>part.get_attribute(Core::Parts::DICT,'role')})
        end
        Sketchup.active_model.select_tool(nil)
      rescue StandardError => e;UI::Dialog.notify(e.message,'error');end
      def draw(view);Picking.wire_bounds(view,@path);end
    end
    class OpeningTool
      def initialize(kind,p);@kind=kind;@p=p;@ip=Sketchup::InputPoint.new;@frame=nil;end
      def activate;Sketchup.set_status_text('Draupr: hover a wall and click to place. Measurements accepts left-edge offset. Esc exits.');Sketchup.set_status_text('Host offset',SB_VCB_LABEL);end
      def enableVCB?;true;end
      def deactivate(v);v.invalidate;end
      def onCancel(_r,v);Sketchup.active_model.select_tool(nil);v.invalidate;end
      def onMouseMove(_flags,x,y,v)
        @frame=nil;@wall=nil;path=Picking.path(v,x,y);wall=Picking.object_in(path)
        return unless wall && Core::Metadata.read(wall)['type']=='wall'
        raise 'Enter the containing group to work on this wall.' unless Core::Geometry.parent_entities(wall)==Sketchup.active_model.active_entities
        @ip.pick(v,x,y);return unless @ip.valid?
        local=@ip.position.transform(Sketchup.active_model.edit_transform.inverse).transform(wall.transformation.inverse)
        candidates=Core::Walls.segments(wall).each_with_index.map do |s,i|
          a=Core::Walls.point(s['cs']);b=Core::Walls.point(s['ce']);d=a.vector_to(b);len=d.length;d.normalize!;t=a.vector_to(local).dot(d)
          near=a.offset(d,[[t,0].max,len].min);dist=Geom::Point3d.new(local.x,local.y,near.z).distance(near)
          [dist,i,t,len]
        end
        _,index,t,len=candidates.min_by(&:first);offset=[[t-@p['width']/2,0].max,[len-@p['width'],0].max].min
        @frame=Core::Hosts.frame(wall,index,@p,offset);@wall=wall;@index=index;@offset=offset
        ops=Core::Walls.holes(wall)+[@frame['record']];Core::Walls.check_holes(Core::Walls.segments(wall),ops)
        Sketchup.set_status_text(Core::Parameters.display_length(offset),SB_VCB_VALUE);@invalid=false;v.invalidate
      rescue StandardError => e
        @invalid=true;Sketchup.set_status_text("Draupr: #{e.message}");v.invalidate
      ensure
        v.invalidate
      end
      def onUserText(text,v)
        raise 'Hover a wall first.' unless @wall && @wall.valid?
        @offset=Core::Parameters.length(text);@frame=Core::Hosts.frame(@wall,@index,@p,@offset)
        Core::Walls.check_holes(Core::Walls.segments(@wall),Core::Walls.holes(@wall)+[@frame['record']]);@invalid=false;place;v.invalidate
      rescue StandardError => e;UI::Dialog.notify(e.message,'error');end
      def onLButtonDown(_f,_x,_y,v);place if @frame && !@invalid;v.invalidate;end
      def place
        return unless @wall && @wall.valid?
        g=Core::Hosts.place(@kind,@p,@wall,@index,@offset);sel=Sketchup.active_model.selection;sel.clear;sel.add(g)
        UI::Dialog.notify('Opening placed and wall cut.','success');@frame=nil;@wall=nil
        Sketchup.active_model.select_tool(nil) unless Core::Preferences.get('keep_drawing',true)
      rescue StandardError => e;Core::Diag.log_error('Opening placement',e);UI::Dialog.notify(e.message,'error');end
      def draw(v)
        return unless @frame
        p=@p;z=p.fetch('sill',0);w=p['width'];h=p['height'];d=@frame['depth'];tr=Sketchup.active_model.edit_transform*@frame['transform']
        a=[[0,0,z],[w,0,z],[w,0,z+h],[0,0,z+h]].map { |pt| Geom::Point3d.new(pt).transform(tr) };b=[[0,d,z],[w,d,z],[w,d,z+h],[0,d,z+h]].map { |pt| Geom::Point3d.new(pt).transform(tr) }
        v.drawing_color=@invalid ? [225,65,65] : [26,155,99];v.line_width=3;v.draw(GL_LINE_LOOP,a);v.draw(GL_LINE_LOOP,b);v.draw(GL_LINES,a.zip(b).flatten)
      end
    end
    class RoofOpeningDrawTool
      def initialize(kind,p);@kind=kind;@p=p;@ip=Sketchup::InputPoint.new;@host_uid=nil;reset;end
      def reset;@roof=nil;@quad=nil;@face_index=nil;@origin=nil;@x=nil;@y=nil;@n=nil;@start=nil;@cursor=nil;@plane=nil;@frame=nil;end
      def activate;label=@kind=='dormer' ? 'Dormer' : 'Skylight';Sketchup.set_status_text("Draw #{label}: click first roof corner, then opposite corner. Repeat or press Esc. / گوشه اول و سپس گوشه مقابل را روی سقف کلیک کنید.");Sketchup.set_status_text('Width x Depth',SB_VCB_LABEL);end
      def enableVCB?;true;end
      def onCancel(_r,v);if @start;reset;v.invalidate;else;Sketchup.active_model.select_tool(nil);end;end
      def roof_at(v,xs,ys)
        Picking.paths(v,xs,ys).each do |path|;roof=path.find { |entity| Core::Objects.valid?(entity) && Core::Metadata.read(entity)['type']=='roof' };return roof if roof;end;nil
      end
      def setup_first(v,xs,ys)
        model=Sketchup.active_model;ph=v.pick_helper;ph.do_pick(xs,ys,6);candidates=[]
        ph.count.times do |index|
          path=ph.path_at(index);next unless path
          roof=path.find { |entity| Core::Objects.valid?(entity) && Core::Metadata.read(entity)['type']=='roof' };next unless roof
          next if @host_uid && Core::Objects.id(roof)!=@host_uid
          face=path.reverse.find { |entity| entity.is_a?(Sketchup::Face) };next unless face
          leaf_transform=ph.transformation_at(index);active_normal=face.normal.transform(leaf_transform);next if active_normal.length<1e-9;active_normal.normalize!;next if active_normal.z<0.02
          ip=Sketchup::InputPoint.new;ip.pick(v,xs,ys);next unless ip.valid?;active_point=ip.position.transform(model.edit_transform.inverse);local=active_point.transform(roof.transformation.inverse)
          rp=Core::Objects.params(roof);best=nil
          Core::Builders.roof_faces(rp).each_with_index do |quad,face_index|
            n=quad[0].vector_to(quad[1]).cross(quad[1].vector_to(quad[2]));next if n.length<1e-9;n.normalize!;n.reverse! if n.z<0
            distance=quad[0].vector_to(local).dot(n);projected=local.offset(n,-distance);next unless Core::Builders.point_in_poly?(projected,quad,n)
            world_n=n.transform(roof.transformation).transform(model.edit_transform);world_n.normalize!;alignment=world_n.dot(active_normal)
            score=distance.abs+(1.0-alignment.abs)*1000.mm;best=[score,quad,face_index,n,projected,active_point,world_n] if !best||score<best[0]
          end
          candidates<<[ph.depth_at(index),roof,*best[1..]] if best
        end
        # If a host is locked and the click passes through an opening, intersect its
        # semantic roof planes instead of accepting another object under the cursor.
        if candidates.empty? && @host_uid
          roof=Core::Objects.get(@host_uid);ray=v.pickray(xs,ys);tr=model.edit_transform*roof.transformation
          Core::Builders.roof_faces(Core::Objects.params(roof)).each_with_index do |quad,face_index|
            n=quad[0].vector_to(quad[1]).cross(quad[1].vector_to(quad[2]));next if n.length<1e-9;n.normalize!;n.reverse! if n.z<0
            wn=n.transform(tr);wn.normalize!;world=Geom.intersect_line_plane(ray,[quad[0].transform(tr),wn]);next unless world
            local=world.transform(tr.inverse);next unless Core::Builders.point_in_poly?(local,quad,n)
            candidates<<[ray[0].distance(world),roof,quad,face_index,n,local,world,wn]
          end
        end
        raise 'Click an actual visible slope of the selected Draupr roof. / روی شیب واقعی و قابل‌مشاهده سقف انتخاب‌شده کلیک کنید.' if candidates.empty?
        _depth,roof,quad,face_index,n,local,world,world_normal=candidates.min_by(&:first);xaxis=Z_AXIS.cross(n);xaxis=X_AXIS.clone if xaxis.length<1e-8;xaxis.normalize!;yaxis=n.cross(xaxis);yaxis.normalize!
        @roof=roof;@host_uid=Core::Objects.id(roof);@quad=quad;@face_index=face_index;@n=n;@x=xaxis;@y=yaxis;@start=local;@plane=[world,world_normal]
      end
      def update_cursor(v,xs,ys)
        return unless @start&&@roof&&@roof.valid?
        ray=v.pickray(xs,ys);world=Geom.intersect_line_plane(ray,@plane);return unless world
        @cursor=world.transform(Sketchup.active_model.edit_transform.inverse).transform(@roof.transformation.inverse)
        d=@start.vector_to(@cursor);u=d.dot(@x);vv=d.dot(@y);corner=@start;corner=corner.offset(@x,u) if u<0;corner=corner.offset(@y,vv) if vv<0;w=u.abs;dep=vv.abs
        return @frame=nil if w<5.mm||dep<5.mm
        pts=[corner,corner.offset(@x,w),corner.offset(@x,w).offset(@y,dep),corner.offset(@y,dep)]
        return @frame=nil unless pts.all? { |q| Core::Builders.point_in_poly?(q,@quad,@n) }
        rec={'o'=>[corner.x,corner.y,corner.z],'x'=>@x.to_a,'y'=>@y.to_a,'w'=>w,'d'=>dep,'face'=>@face_index}
        @frame={'record'=>rec,'transform'=>@roof.transformation*Geom::Transformation.axes(corner,@x,@y,@n)};Sketchup.set_status_text("#{Core::Parameters.display_length(w)} x #{Core::Parameters.display_length(dep)}",SB_VCB_VALUE)
      end
      def onMouseMove(_f,xs,ys,v);@ip.pick(v,xs,ys);update_cursor(v,xs,ys);v.invalidate;end
      def onLButtonDown(_f,xs,ys,v)
        if !@start;setup_first(v,xs,ys)
        else
          update_cursor(v,xs,ys);raise 'The drawn roof-hosted object must fit entirely on one roof face.' unless @frame
          p=@p.merge('width'=>@frame['record']['w'],'depth'=>@frame['record']['d']);host_id=Core::Objects.id(@roof);g=Core::Hosts.place_on_roof(@kind,p,@roof,@frame)
          sel=Sketchup.active_model.selection;sel.clear;sel.add(g);label=@kind=='dormer' ? 'Dormer' : 'Skylight';UI::Dialog.notify("#{label} drawn, hosted, and roof opening cut. The same roof remains locked for another insertion. / آبجکت ساخته شد و همان سقف برای درج بعدی قفل می‌ماند.",'success');@host_uid=host_id;reset
          begin;@roof=Core::Objects.get(@host_uid);rescue StandardError;@roof=nil;end
        end
        v.invalidate
      rescue StandardError=>e;Core::Diag.log_error('Draw roof opening',e);UI::Dialog.notify(e.message,'error');end
      def draw(v)
        return unless @frame&&@roof&&@roof.valid?;r=@frame['record'];o=Geom::Point3d.new(*r['o']);x=Geom::Vector3d.new(*r['x']);y=Geom::Vector3d.new(*r['y']);tr=Sketchup.active_model.edit_transform*@roof.transformation
        pts=[o,o.offset(x,r['w']),o.offset(x,r['w']).offset(y,r['d']),o.offset(y,r['d'])].map { |q| q.transform(tr) };v.drawing_color=[26,155,99];v.line_width=4;v.draw(GL_LINE_LOOP,pts)
      end
    end
    class RoofOpeningTool
      def initialize(kind,p);@kind=kind;@p=p;@ip=Sketchup::InputPoint.new;@frame=nil;@roof=nil;@invalid=false;end
      def activate;Sketchup.set_status_text('Draupr: hover a roof face and click to place. Esc exits.');end
      def enableVCB?;false;end
      def deactivate(v);v.invalidate;end
      def onCancel(_r,v);Sketchup.active_model.select_tool(nil);v.invalidate;end
      def onMouseMove(_flags,x,y,v)
        @frame=nil;@roof=nil;@invalid=false
        path=Picking.path(v,x,y);roof=Picking.object_in(path)
        return v.invalidate unless roof && Core::Metadata.read(roof)['type']=='roof'
        raise 'Enter the containing group to work on this roof.' unless Core::Geometry.parent_entities(roof)==Sketchup.active_model.active_entities
        @ip.pick(v,x,y);return unless @ip.valid?
        local=@ip.position.transform(Sketchup.active_model.edit_transform.inverse).transform(roof.transformation.inverse)
        rp=Core::Objects.params(roof)
        Core::Builders.roof_faces(rp).each do |quad|
          v1=quad[0].vector_to(quad[1]);v2=quad[1].vector_to(quad[2]);n=v1.cross(v2);next if n.length<1e-9;n.normalize!
          next if n.z<0.0001
          dist=quad[0].vector_to(local).dot(n);next if dist.abs>250.mm
          next unless Core::Builders.point_in_poly?(local,quad,n)
          x=Z_AXIS.cross(n);x=X_AXIS.clone if x.length<0.000001;x.normalize!
          y=n.cross(x);y.normalize!
          o=local.offset(n,-dist)
          w2=@p['width'].to_f/2;d2=@p['depth'].to_f/2
          us=quad.map { |q| o.vector_to(q).dot(x) };vs=quad.map { |q| o.vector_to(q).dot(y) }
          if us.min>-w2+1.mm || us.max<w2-1.mm || vs.min>-d2+1.mm || vs.max<d2-1.mm
            @invalid=true;@roof=roof
            Sketchup.set_status_text('Draupr: the object does not fit this slope at the cursor. Move toward the middle or shrink it.')
            return v.invalidate
          end
          corner=o.offset(x,-w2).offset(y,-d2)
          rec={'o'=>[corner.x,corner.y,corner.z],'x'=>x.to_a,'y'=>y.to_a,'w'=>@p['width'].to_f,'d'=>@p['depth'].to_f}
          @frame={'record'=>rec,'transform'=>roof.transformation*Geom::Transformation.axes(corner,x,y,n)}
          @roof=roof
          Sketchup.set_status_text('Draupr: click to place on this roof face. Esc exits.')
          return v.invalidate
        end
        v.invalidate
      rescue StandardError => e
        @invalid=true;Sketchup.set_status_text("Draupr: #{e.message}")
        v.invalidate
      end
      def onLButtonDown(_f,_x,_y,v)
        place if @frame && !@invalid;v.invalidate
      end
      def place
        return unless @roof && @roof.valid? && @frame
        g=Core::Hosts.place_on_roof(@kind,@p,@roof,@frame)
        sel=Sketchup.active_model.selection;sel.clear;sel.add(g)
        UI::Dialog.notify('Placed and roof cut.','success');@frame=nil;@roof=nil
        Sketchup.active_model.select_tool(nil) unless Core::Preferences.get('keep_drawing',true)
      rescue StandardError => e;Core::Diag.log_error('Roof opening placement',e);UI::Dialog.notify(e.message,'error');end
      def draw(v)
        return unless @frame
        rec=@frame['record'];o=Geom::Point3d.new(*rec['o']);x=Geom::Vector3d.new(*rec['x']);y=Geom::Vector3d.new(*rec['y'])
        pts=[o,o.offset(x,rec['w']),o.offset(x,rec['w']).offset(y,rec['d']),o.offset(y,rec['d'])].map { |q| q.transform(Sketchup.active_model.edit_transform*@roof.transformation) }
        v.drawing_color=@invalid ? [225,65,65] : [26,155,99];v.line_width=3;v.draw(GL_LINE_LOOP,pts)
      end
    end
    class LibraryPlacementTool
      def initialize(data,options={})
        @data = data
        @options=options
        @rotation=options.fetch('rotation',0).to_f
        @scale=options.fetch('scale',1).to_f
        @align=options['align']==true || options['align'].to_s=='true'
        @base=nil
        @ip = Sketchup::InputPoint.new
        @bounds = data['bounds']
      end
      def activate;Sketchup.set_status_text("Draupr: click to place '#{@data['name']}'. Left/Right rotates 15°. Type angle,scale in Measurements.");Sketchup.set_status_text('Angle, scale',SB_VCB_LABEL);end
      def enableVCB?;true;end
      def onKeyDown(key,_repeat,_flags,view)
        if key==VK_LEFT;@rotation-=15
        elsif key==VK_RIGHT;@rotation+=15
        else;return;end
        Sketchup.set_status_text("#{@rotation.round(1)}°, #{@scale.round(3)}",SB_VCB_VALUE);view.invalidate
      end
      def onUserText(text,view)
        parts=text.to_s.split(/[,;x]/).map(&:strip);@rotation=parts[0].to_f unless parts[0].to_s.empty?;@scale=parts[1].to_f if parts[1] && parts[1].to_f>0
        Sketchup.set_status_text("#{@rotation.round(1)}°, #{@scale.round(3)}",SB_VCB_VALUE);view.invalidate
      end
      def deactivate(v);v.invalidate;end
      def onCancel(_r,v);Sketchup.active_model.select_tool(nil);v.invalidate;end
      def onMouseMove(_f,x,y,v);@ip.pick(v,x,y);@base=placement_transform if @ip.valid?;v.invalidate;end
      def onLButtonDown(_f,_x,_y,v)
        return unless @ip.valid?
        Core::LibraryService.place(@data,@ip.position,nil,{'base_transform'=>placement_transform})
        Sketchup.active_model.select_tool(nil) unless Core::Preferences.get('keep_drawing',true)
        v.invalidate
      rescue StandardError => e;UI::Dialog.notify(e.message,'error');end
      def placement_transform
        model=Sketchup.active_model
        origin=@ip.position.transform(model.edit_transform.inverse)
        n=Z_AXIS.clone
        if @align && @ip.face
          n=@ip.face.normal.clone;n.reverse! if n.z<0;n.normalize!
        end
        dot=X_AXIS.dot(n);x=Geom::Vector3d.new(1-n.x*dot,-n.y*dot,-n.z*dot)
        if x.length<0.001
          dot=Y_AXIS.dot(n);x=Geom::Vector3d.new(-n.x*dot,1-n.y*dot,-n.z*dot)
        end
        x.normalize!;y=n.cross(x);y.normalize!
        Geom::Transformation.axes(origin,x,y,n)*Geom::Transformation.rotation(ORIGIN,Z_AXIS,@rotation*Math::PI/180.0)*Geom::Transformation.scaling(@scale)
      end
      def draw(v)
        return unless @ip.valid? && @bounds
        lo,hi=@bounds
        tr=Sketchup.active_model.edit_transform*placement_transform
        c=[]
        [lo[2],hi[2]].each do |z|
          [[lo[0],lo[1]],[hi[0],lo[1]],[hi[0],hi[1]],[lo[0],hi[1]]].each { |x,y| c << Geom::Point3d.new(x.mm,y.mm,z.mm).transform(tr) }
        end
        edges=[[0,1],[1,2],[2,3],[3,0],[4,5],[5,6],[6,7],[7,4],[0,4],[1,5],[2,6],[3,7]]
        v.drawing_color=[36,114,184];v.line_width=2;v.draw(GL_LINES,edges.map { |a,b| [c[a],c[b]] }.flatten)
      end
    end
    class WallSplitTool
      def initialize;@ip=Sketchup::InputPoint.new;@wall=nil;@guide=nil;end
      def activate;Sketchup.set_status_text('Split Wall: hover for cut preview, then click. Esc exits.');end
      def onSetCursor;id=ModifyCursor.knife;id ? (::UI.set_cursor(id);true) : false;end
      def onCancel(_r,v);Sketchup.active_model.select_tool(nil);v.invalidate;end
      def onMouseMove(_f,x,y,v);@ip.pick(v,x,y);@wall=Picking.object_in(Picking.path(v,x,y));@wall=nil unless @wall&&Core::Metadata.read(@wall)['type']=='wall';@guide=nil;if @wall&&@ip.valid?;local=@ip.position.transform(Sketchup.active_model.edit_transform.inverse).transform(@wall.transformation.inverse);@guide=Core::ModifyTools.split_preview(@wall,local).map { |q| q.transform(@wall.transformation).transform(Sketchup.active_model.edit_transform) };end;v.invalidate;rescue StandardError;@guide=nil;end
      def onLButtonDown(_f,_x,_y,v);raise 'Hover an editable Draupr wall first.' unless @wall&&@ip.valid?;local=@ip.position.transform(Sketchup.active_model.edit_transform.inverse).transform(@wall.transformation.inverse);Core::ModifyTools.split_wall(@wall,local);@wall=nil;@guide=nil;v.invalidate;rescue StandardError=>e;UI::Dialog.notify(e.message,'error');end
      def draw(v);return unless @guide;v.drawing_color=[235,55,45];v.line_width=4;v.draw(GL_LINES,[@guide[0],@guide[1],@guide[0],@guide[2]]);end
    end
    module ModifyCursor
      module_function
      def load(name,hotx=4,hoty=28);@ids||={};@ids[name]||=(::UI.create_cursor(File.join(SRC,'assets',"cursor_#{name}.png"),hotx,hoty) rescue nil);end
      def knife;load('knife',3,3);end
      def trim;load('trim',16,16);end
      def align;load('align');end
    end
    class WallTrimExtendTool
      def initialize;@ip=Sketchup::InputPoint.new;@first=nil;@hover=nil;@hover_local=nil;@preview=nil;@mode='butt';@priority=0;end
      def status
        pri=@priority==0 ? 'first wall / دیوار اول' : 'second wall / دیوار دوم'
        Sketchup.set_status_text("Trim/Extend: click the piece of each wall to KEEP. Mode #{@mode}; priority #{pri}. Right-click for options. / بخش موردنظر برای حفظ را کلیک کنید.")
      end
      def activate;status;end
      def onSetCursor;id=ModifyCursor.trim;id ? (::UI.set_cursor(id);true) : false;end
      def onCancel(_r,v);if @first;@first=nil;@preview=nil;status;v.invalidate;else;Sketchup.active_model.select_tool(nil);end;end
      def local_point(wall);@ip.position.transform(Sketchup.active_model.edit_transform.inverse).transform(wall.transformation.inverse);end
      def onMouseMove(_f,x,y,v)
        @ip.pick(v,x,y);@hover=Picking.object_in(Picking.path(v,x,y));@hover=nil unless @hover&&Core::Metadata.read(@hover)['type']=='wall';@hover_local=@hover&&@ip.valid? ? local_point(@hover) : nil;@preview=nil
        if @first&&@hover&&@hover!=@first[0]&&@hover_local
          @preview=Core::WallJunctions.preview(@first[0],@first[1],@hover,@hover_local,@mode,@priority) rescue nil
        end;v.invalidate
      end
      def onLButtonDown(_f,_x,_y,v)
        raise 'Pick a Draupr wall.' unless @hover&&@ip.valid?
        local=local_point(@hover)
        if @first
          raise 'Choose a different second wall.' if @hover==@first[0]
          Core::WallJunctions.commit(@first[0],@first[1],@hover,local,@mode,@priority);@first=nil;@preview=nil;UI::Dialog.notify('Standalone walls joined. / دیوارهای مستقل متصل شدند.','success');status
        else
          @first=[@hover,local];multi=(Core::Objects.params(@hover)['path_points']||[]).length>2
          note=multi ? ' The selected path will be converted to standalone segments when committed. / مسیر انتخاب‌شده هنگام اعمال به قطعات مستقل تبدیل می‌شود.' : ''
          Sketchup.set_status_text('First kept piece set. Click the piece of the second wall to keep. / بخش حفظ‌شونده دیوار دوم را کلیک کنید.'+note)
        end;v.invalidate
      rescue StandardError=>e;UI::Dialog.notify(e.message,'error');end
      def getMenu(menu)
        {'butt'=>'Butt / لب‌به‌لب','miter'=>'Miter / فارسی‌بُر','square'=>'Square off / اتصال تخت'}.each do |value,label|
          item=menu.add_item("Draupr: #{label}") { @mode=value;status;Sketchup.active_model.active_view.invalidate };menu.set_validation_proc(item) { @mode==value ? MF_CHECKED : MF_UNCHECKED }
        end
        menu.add_separator;menu.add_item('Draupr: Swap wall priority / تعویض اولویت دیوار') { @priority=1-@priority;status;Sketchup.active_model.active_view.invalidate }
      end
      def draw(v)
        Picking.wire_bounds(v,[@hover].compact,@first ? [235,120,30] : [40,150,230]) if @hover
        return unless @preview
        tr=Sketchup.active_model.edit_transform
        v.line_width=4;v.line_stipple='';v.drawing_color=[35,180,90];v.draw(GL_LINES,@preview[:kept].flatten.map { |q| q.transform(tr) })
        unless @preview[:discard].empty?;v.line_stipple='-';v.drawing_color=[220,55,55];v.draw(GL_LINES,@preview[:discard].flatten.map { |q| q.transform(tr) });end
        v.line_stipple='';v.line_width=5;v.drawing_color=[240,140,25];v.draw(GL_LINES,@preview[:caps].flatten.map { |q| q.transform(tr) })
      end
    end

    class FaceAlignTool
      def initialize;@ref=nil;@path=[];end
      def activate;Sketchup.set_status_text('Align: click reference face, then target face to move. Esc exits.');end
      def onSetCursor;id=ModifyCursor.align;id ? (::UI.set_cursor(id);true) : false;end
      def onCancel(_r,v);@ref ? (@ref=nil;v.invalidate) : Sketchup.active_model.select_tool(nil);end
      def face_data(path)
        face=path.reverse.find { |e| e.is_a?(Sketchup::Face) };raise 'Pick a planar face.' unless face;i=path.index(face);tr=Sketchup.active_model.edit_transform;path[0...i].each { |e| tr=tr*e.transformation if e.respond_to?(:transformation) };[face.bounds.center.transform(tr),face.normal.transform(tr).normalize]
      end
      def onMouseMove(_f,x,y,v);@path=Picking.path(v,x,y);v.invalidate;end
      def onLButtonDown(_f,x,y,v);path=Picking.path(v,x,y);point,normal=face_data(path);if @ref;target=path.find { |e| e.is_a?(Sketchup::Group)||e.is_a?(Sketchup::ComponentInstance) };raise 'The target face must belong to a movable group or component.' unless target;Core::ModifyTools.align_faces(target,point,normal,@ref[0],@ref[1]);@ref=nil;UI::Dialog.notify('Faces aligned. Pick a new reference face.','success');else;@ref=[point,normal];Sketchup.set_status_text('Reference face set. Click the target face.');end;v.invalidate;rescue StandardError=>e;UI::Dialog.notify(e.message,'error');end
      def draw(v);Picking.wire_bounds(v,@path,@ref ? [235,120,30] : [40,150,230]);end
    end
    class RoofJoinTool
      def initialize;@first=nil;@hover=nil;@path=[];@ip=Sketchup::InputPoint.new;end
      def activate;Sketchup.set_status_text('Join Roof: click the source roof EDGE to extend/trim, then click the target roof FACE. Esc exits.');end
      def onSetCursor;id=ModifyCursor.trim;id ? (::UI.set_cursor(id);true) : false;end
      def onCancel(_r,v);if @first;@first=nil;Sketchup.set_status_text('Join Roof: click the source roof edge.');v.invalidate;else;Sketchup.active_model.select_tool(nil);end;end
      def roof_from(path);path.each { |e| roof=Core::RoofTools.owning_roof(e);return roof if roof };nil;end
      def onMouseMove(_f,x,y,v);@path=Picking.path(v,x,y);@hover=roof_from(@path);@ip.pick(v,x,y);v.invalidate;end
      def onLButtonDown(_f,x,y,v)
        path=Picking.path(v,x,y);roof=roof_from(path);@ip.pick(v,x,y);raise 'Click a Draupr roof edge or face.' unless roof&&@ip.valid?
        if @first
          raise 'Second click must be on a different roof.' if roof==@first[0]
          raise 'Second click must be on a roof face.' unless path.any? { |e| e.is_a?(Sketchup::Face) }
          face=path.reverse.find { |entity| entity.is_a?(Sketchup::Face) };index=path.index(face);transform=Sketchup.active_model.edit_transform;path[0...index].each { |entity| transform=transform*entity.transformation if entity.respond_to?(:transformation) };normal=face.normal.transform(transform);normal.normalize!
          Core::RoofTools.join_edge_to_face(@first[0],@first[1],roof,@ip.position,normal);UI::Dialog.notify('Complete roof end joined and target slope strips cut. / انتهای کامل سقف متصل و نوارهای شیب هدف بریده شد.','success');@first=nil;Sketchup.active_model.select_tool(nil)
        else
          raise 'First click must be on a visible roof boundary edge.' unless path.any? { |e| e.is_a?(Sketchup::Edge) }
          Core::RoofTools.picked_edge(roof,@ip.position);@first=[roof,@ip.position];Sketchup.set_status_text('Source edge set. Click the target roof face. Esc clears the source edge.')
        end
        v.invalidate
      rescue StandardError=>e;UI::Dialog.notify(e.message,'error');end
      def draw(v)
        Picking.wire_bounds(v,@path,@first ? [235,120,30] : [40,150,230]) if @hover
        if @first&&@first[0].valid?;v.drawing_color=[35,185,95];v.line_width=4;b=@first[0].bounds;pts=(0..7).map { |i| b.corner(i).transform(Sketchup.active_model.edit_transform) };edges=[[0,1],[1,3],[3,2],[2,0],[4,5],[5,7],[7,6],[6,4],[0,4],[1,5],[2,6],[3,7]];v.draw(GL_LINES,edges.flat_map { |i,j| [pts[i],pts[j]] });end
      end
    end
    module FaceCreation
      module_function
      def molding_profile(p)
        faces=Sketchup.active_model.selection.grep(Sketchup::Face);raise 'Select exactly one face to use as the molding profile.' unless faces.length==1
        face=faces.first;raise 'Faces with holes are not supported.' unless face.loops.length==1
        n=face.normal.transform(Sketchup.active_model.edit_transform)
        raise 'Use a vertical face for the profile cross-section, not a horizontal one.' if n.parallel?(Z_AXIS)
        x=Z_AXIS.cross(n);x.normalize!
        tr=Sketchup.active_model.edit_transform
        pts=face.outer_loop.vertices.map { |v| v.position.transform(tr) }
        origin=pts.first
        local=pts.map { |q| d=origin.vector_to(q);[d.dot(x),d.dot(Z_AXIS)] }
        xs=local.map(&:first);ys=local.map(&:last);minx=xs.min;miny=ys.min
        raise 'Profile face is too small.' if (xs.max-minx)<1.mm || (ys.max-miny)<1.mm
        p.merge('profile'=>'custom','profile_points'=>local.map { |px,py| [px-minx,py-miny] })
      end
      def create(kind,p)
        faces=Sketchup.active_model.selection.grep(Sketchup::Face);raise 'Select one horizontal face in the active editing context.' unless faces.length==1
        face=faces.first;raise 'Faces with holes are not supported.' unless face.loops.length==1
        raise 'Use a horizontal face.' unless face.normal.parallel?(Z_AXIS)
        pts=face.outer_loop.vertices.map(&:position);origin=pts.first;x=origin.vector_to(pts[1]);x.normalize!;y=Z_AXIS.cross(x);y.normalize!
        local=pts.map { |q| d=origin.vector_to(q);[d.dot(x),d.dot(y),0.0] };xs=local.map(&:first);ys=local.map { |q| q[1] };minx,maxx=xs.minmax;miny,maxy=ys.minmax
        p=p.merge('width'=>maxx-minx,'depth'=>maxy-miny,'placement_mode'=>'surface','z_offset'=>0.0,'rotation'=>0.0)
        rectangular=local.length==4 && local.all? { |q| [minx,maxx].any? { |v| (q[0]-v).abs<0.5.mm } && [miny,maxy].any? { |v| (q[1]-v).abs<0.5.mm } }
        if kind=='roof' && p['style']!='flat'
          raise 'Pitched roofs require a rectangular source face.' unless rectangular
        elsif !rectangular || kind=='slab'
          p['footprint']=local.map { |q| [q[0]-minx,q[1]-miny,0.0] }
        end
        origin=origin.offset(x,minx).offset(y,miny);tr=Geom::Transformation.axes(origin,x,y,Z_AXIS)
        Core::Transactions.run('Create Draupr from face') do
          g=Core::Objects.create(kind,p,tr);s=Sketchup.active_model.selection;s.clear;s.add(g)
        end
      end
    end
  end
end
