# frozen_string_literal: true
module Draupr
  module Studio
    class DrawTool
      def initialize(kind,params,mode=nil)
        @kind=kind;@p=params;@mode=mode||Core::Parameters.tool(kind)['mode'];@points=[];@ip=Sketchup::InputPoint.new;@lock=nil;@cursor=nil;@arc=false;@arc_pending=nil;@preview_pts=nil;@plane_world=nil;@plane_normal=Z_AXIS.clone;@plane_x=X_AXIS.clone;@plane_y=Y_AXIS.clone;@arc_generated=false
      end
      def enableVCB?;@mode!='point';end
      def activate;status;end
      def deactivate(view)
        # Deactivation means any tool switch, not user confirmation. Never commit here.
        @finish_pending=false;Sketchup.set_status_text('',SB_VCB_VALUE);view.invalidate
      end
      def suspend(view);view.invalidate;end
      def resume(view);status;view.invalidate;end
      def status
        text=case @mode;when 'point' then 'Click to place';when 'path' then (@arc ? (@arc_pending ? 'Click the arc bulge point' : 'Arc mode: click the arc end point') : 'Click path points; Space, Enter or double-click to finish');when 'rotated' then 'Click origin, width direction, then depth';when 'rectangle' then 'Click opposite footprint corners';when 'direction' then 'Click position, then ascent direction';else 'Click start, then end';end
        text+='. Up arrow or right-click toggles arc' if @mode=='path'
        text+='. Right-click for profile side and rotation' if @kind=='molding'
        Sketchup.set_status_text("Draupr #{@kind}: #{text}. Arrows lock X/Y. Esc steps back.")
        Sketchup.set_status_text(%w[rectangle rotated].include?(@mode) ? 'Width x Depth' : 'Length',SB_VCB_LABEL)
      end
      def visible_face_hit(view,x,y)
        path=Picking.path(view,x,y);face=path.reverse.find { |entity| entity.is_a?(Sketchup::Face) };return nil unless face
        index=path.index(face);transform=Sketchup.active_model.edit_transform
        path[0...index].each { |entity| transform=transform*entity.transformation if entity.respond_to?(:transformation) }
        points=face.vertices.first(3).map { |vertex| vertex.position.transform(transform) };return nil if points.length<3
        normal=face.normal.transform(transform);return nil if normal.length<1e-9;normal.normalize!
        hit=Geom.intersect_line_plane(view.pickray(x,y),Geom.fit_plane_to_points(*points));hit ? [hit,normal] : nil
      end
      def snapped_world(view,raw,plane)
        return raw unless raw&&plane&&@ip.valid?
        normal=plane[1].clone;return raw if normal.length<1e-9;normal.normalize!
        candidate=@ip.position;signed=plane[0].vector_to(candidate).dot(normal);projected=candidate.offset(normal,-signed)
        tolerance=view.pixels_to_model(12,raw)
        if signed.abs<=tolerance && projected.distance(raw)<=tolerance;@snap_visible=true;projected else raw end
      end
      def picked(view,x,y)
        @ip.pick(view,x,y);@snap_visible=false
        if @plane_world && !@points.empty?
          world=Geom.intersect_line_plane(view.pickray(x,y),@plane_world);world=snapped_world(view,world,@plane_world)
        elsif @p['placement_mode']=='level'
          elevation=Core::Project.level_z(@p['level_id'])+@p['z_offset'].to_f
          level_plane=[Geom::Point3d.new(0,0,elevation),Z_AXIS];world=Geom.intersect_line_plane(view.pickray(x,y),level_plane);world=snapped_world(view,world,level_plane)
        else
          surface=visible_face_hit(view,x,y) if @points.empty? && @p['placement_mode']=='surface'
          world=surface ? snapped_world(view,surface[0],[surface[0],surface[1]]) : (@ip.valid? ? @ip.position : nil)
          @snap_visible=true if !surface&&@ip.valid?
        end
        return nil unless world
        if @points.empty? && @p['placement_mode']=='surface' && surface && @kind=='roof'
          n=Z_AXIS.clone;@plane_normal=Z_AXIS.clone;@plane_x=X_AXIS.clone;@plane_y=Y_AXIS.clone
          world=world.offset(Z_AXIS,@p['z_offset']);@plane_world=[world,n]
        elsif @points.empty? && @p['placement_mode']=='surface' && surface
          n=surface[1];n.reverse! if n.z<0
          @plane_normal=n.transform(Sketchup.active_model.edit_transform.inverse);@plane_normal.normalize!
          dot=X_AXIS.dot(@plane_normal);@plane_x=Geom::Vector3d.new(1-@plane_normal.x*dot,-@plane_normal.y*dot,-@plane_normal.z*dot)
          if @plane_x.length<0.001
            dot=Y_AXIS.dot(@plane_normal);@plane_x=Geom::Vector3d.new(-@plane_normal.x*dot,1-@plane_normal.y*dot,-@plane_normal.z*dot)
          end
          @plane_x.normalize!;@plane_y=@plane_normal.cross(@plane_x);@plane_y.normalize!
          world=world.offset(n,@p['z_offset']);@plane_world=[world,n]
        elsif !@plane_world
          world=world.offset(Z_AXIS,@p['z_offset'])
        end
        local=world.transform(Sketchup.active_model.edit_transform.inverse)
        return local if @points.empty?
        local=@points.last.offset(@held,@points.last.vector_to(local).dot(@held)) if @held
        if !%w[rectangle rotated].include?(@mode) || (@mode=='rotated' && @points.length==1)
          a=@points.last;v=a.vector_to(local)
          axis=@lock==:x ? @plane_x : (@lock==:y ? @plane_y : nil)
          if !axis && v.length>0.001
            unit=v.normalize;axis=@plane_x if unit.dot(@plane_x).abs>0.9903;axis=@plane_y if unit.dot(@plane_y).abs>0.9903
          end
          local=a.offset(axis,v.dot(axis)) if axis
        end
        local
      end
      def onMouseMove(_flags,x,y,view)
        @cursor=picked(view,x,y);@screen=[x,y]
        if @cursor && !@points.empty?
          a=@points.last;@direction=a.vector_to(@cursor)
          text= @mode=='rectangle' ? "#{Sketchup.format_length(a.vector_to(@cursor).dot(@plane_x).abs)} x #{Sketchup.format_length(a.vector_to(@cursor).dot(@plane_y).abs)}" : Sketchup.format_length(a.distance(@cursor))
          @dimension_text=text;Sketchup.set_status_text(text,SB_VCB_VALUE)
        end;view.invalidate
      end
      def onLButtonDown(_flags,x,y,view)
        q=picked(view,x,y);return unless q
        if @mode=='path' && @arc_pending
          generated=arc_points(@points.last,@arc_pending,q);@points.concat(generated);@arc_generated=true if generated.length>1;@arc_pending=nil
          status;view.invalidate;return
        end
        if @mode=='path' && @points.length>=3 && q.distance(@points.first)<view.pixels_to_model(10,q)
          @closed=true;finish;return
        end
        return if !@points.empty? && q.distance(@points.last)<1.mm
        if @mode=='path' && @arc && !@points.empty?
          @arc_pending=q;status;view.invalidate;return
        end
        @points<<q
        needed={'point'=>1,'line'=>2,'direction'=>2,'rectangle'=>2,'rotated'=>3}[@mode]
        finish if needed && @points.length==needed
        status;view.invalidate
      rescue StandardError => e
        fail_message(e)
      end
      def onLButtonDoubleClick(_flags,_x,_y,_view);finish if @mode=='path' && @points.length>1;end
      def onKeyDown(key,_repeat,_flags,view)
        if key==VK_SPACE
          # Reached when Space is delivered to the active Tool. A SketchUp shortcut
          # that replaces the Tool cancels safely rather than committing partial geometry.
          finish;view.invalidate;return true
        elsif key==VK_RETURN
          # Defer so onUserText can apply a typed VCB length first instead of finishing early.
          @finish_pending=true
          ::UI.start_timer(0,false) { begin;finish_deferred;rescue StandardError;end }
        elsif (key==VK_UP || key==9) && @mode=='path';toggle_arc
        elsif key==VK_RIGHT;@lock=@lock==:x ? nil : :x
        elsif key==VK_LEFT;@lock=@lock==:y ? nil : :y
        elsif key==16 && @direction && @direction.length>0.001;@held=@direction.normalize;end
        view.invalidate
      end
      def onKeyUp(key,_repeat,_flags,view);@held=nil if key==16;view.invalidate;end
      def onSetCursor
        id=DrawTool.draw_cursor
        if id;::UI.set_cursor(id);true;else false;end
      end
      def self.draw_cursor
        return @draw_cursor_id if defined?(@draw_cursor_id)
        path=File.join(SRC,'assets','cursor_draw.png')
        @draw_cursor_id=(File.exist?(path) ? ::UI.create_cursor(path,16,16) : nil)
      rescue StandardError
        @draw_cursor_id=nil
      end
      def toggle_arc
        @arc=!@arc;@arc_pending=nil;status
        v=Sketchup.active_model.active_view;v.invalidate if v
      end
      def getMenu(menu)
        return unless @mode=='path'
        item=menu.add_item('Draupr: Arc Mode') { toggle_arc };menu.set_validation_proc(item) { @arc ? MF_CHECKED : MF_UNCHECKED }
        if @kind=='molding'
          menu.add_separator
          menu.add_item('Draupr: Flip Molding Profile') { @p['flip_profile']=!@p['flip_profile'];Sketchup.active_model.active_view.invalidate }
          menu.add_item('Draupr: Rotate Profile +15°') { @p['profile_rotation']=@p['profile_rotation'].to_f+15.0;Sketchup.active_model.active_view.invalidate }
          menu.add_item('Draupr: Rotate Profile -15°') { @p['profile_rotation']=@p['profile_rotation'].to_f-15.0;Sketchup.active_model.active_view.invalidate }
          menu.add_item('Draupr: Reset Profile Rotation') { @p['profile_rotation']=0.0;Sketchup.active_model.active_view.invalidate }
        end
      end
      def onReturn(view)
        @finish_pending=true
        ::UI.start_timer(0,false) { begin;finish_deferred;rescue StandardError;end }
        view.invalidate
        nil
      end
      def finish_deferred
        return unless @finish_pending
        @finish_pending=false
        finish
        Sketchup.active_model.active_view.invalidate
      end
      def onCancel(_reason,view)
        if @arc_pending;@arc_pending=nil;status
        elsif @points.empty?;Sketchup.active_model.select_tool(nil)
        else;@points.pop;@closed=false;status;end;view.invalidate
      end
      def onUserText(text,view)
        return if @points.empty?
        @finish_pending=false
        if text.to_s.strip.empty?
          finish;view.invalidate;return
        end
        if %w[rectangle rotated].include?(@mode)
          v=text.to_s.split(/\s*[x×;]\s*/i);raise 'Use width x depth, for example 5m x 3m.' unless v.length==2
          w=Core::Parameters.length(v[0]);d=Core::Parameters.length(v[1]);raise 'Dimensions must be positive.' unless w>1.mm && d>1.mm
          a=@points.first
          if @mode=='rotated'
            x=(@points[1] ? a.vector_to(@points[1]) : (@direction||X_AXIS)).normalize;y=Z_AXIS.cross(x);y.normalize!;@points=[a,a.offset(x,w),a.offset(x,w).offset(y,d)]
          else;@points=[a,Geom::Point3d.new(a.x+w,a.y+d,a.z)];end
        else
          n=Core::Parameters.length(text);raise 'Length must be positive.' unless n>1.mm
          v=@held||@direction||X_AXIS;raise 'Choose a direction first.' if v.length<0.001
          @points<<@points.last.offset(v,n)
        end
        finish unless @mode=='path';view.invalidate
      rescue StandardError => e;fail_message(e);end
      def arc_points(a,b,through)
        chord=a.vector_to(b);len=chord.length
        return [b] if len<0.001
        perp=@plane_normal.cross(chord)
        return [b] if perp.length<0.001
        perp.normalize!
        mid=Geom::Point3d.new((a.x+b.x)/2.0,(a.y+b.y)/2.0,(a.z+b.z)/2.0)
        bulge=(Geom::Point3d.new(through.x,through.y,through.z)-mid).dot(perp)
        return [b] if bulge.abs<1.mm
        r=(bulge*bulge+(len/2.0)**2)/(2.0*bulge.abs)
        side=bulge>0 ? 1.0 : -1.0
        center=mid.offset(perp,-side*(r-bulge.abs))
        va=a-center;vb=b-center
        sweep=Math.atan2(va.cross(vb).dot(@plane_normal),va.dot(vb))
        sweep+=sweep>0 ? -2.0*Math::PI : 2.0*Math::PI if bulge.abs>len/2.0
        n=[[3,(sweep.abs*180.0/Math::PI/10.0).ceil].max,48].min
        (1..n).map { |i| a.transform(Geom::Transformation.rotation(center,@plane_normal,sweep*i/n)) }
      rescue StandardError
        [b]
      end
      def configuration(points=@points)
        p=Marshal.load(Marshal.dump(@p));a=points.first;return nil unless a
        tr=Geom::Transformation.new(a)
        if @mode=='rectangle'
          b=points[1];return nil unless b;v=a.vector_to(b);dx=v.dot(@plane_x);dy=v.dot(@plane_y);p['width']=dx.abs;p['depth']=dy.abs;origin=a;origin=origin.offset(@plane_x,dx) if dx<0;origin=origin.offset(@plane_y,dy) if dy<0;tr=Geom::Transformation.axes(origin,@plane_x,@plane_y,@plane_normal)
        elsif @mode=='rotated'
          b=points[1];c=points[2];return nil unless b && c;x=a.vector_to(b);p['width']=x.length;return nil if x.length<0.001;x.normalize!;y=@plane_normal.cross(x);y.normalize!;depth=a.vector_to(c).dot(y);p['depth']=depth.abs;a=a.offset(y,depth) if depth<0;tr=Geom::Transformation.axes(a,x,y,@plane_normal)
        elsif @mode=='path'
          return nil if points.length<2
          if %w[railing molding wall curtain_wall beam].include?(@kind) || (@kind=='foundation' && p['foundation_type']=='strip')
            p['path_points']=points.map { |q| d=a.vector_to(q);[d.x,d.y,d.z] };tr=Geom::Transformation.new(a)
          else
            p['path_points']=points.map { |q| d=a.vector_to(q);[d.dot(@plane_x),d.dot(@plane_y),d.dot(@plane_normal)] };tr=Geom::Transformation.axes(a,@plane_x,@plane_y,@plane_normal)
          end
          p['path_surface_normal']=[@plane_normal.x,@plane_normal.y,@plane_normal.z] if @kind=='molding' && @p['placement_mode']=='surface'
          p['closed']=@closed==true;p['path_curve']=true if @arc_generated;p['length']=points.each_cons(2).sum { |x,y| x.distance(y).to_f };p['length']+=points.last.distance(a) if p['closed']
        elsif @mode!='point'
          b=points[1];return nil unless b;v=a.vector_to(b);len=v.length;return nil if len<0.001
          if %w[railing molding wall curtain_wall beam].include?(@kind) || (@kind=='foundation' && p['foundation_type']=='strip')
            p['path_points']=[[0.0,0.0,0.0],[v.x,v.y,v.z]];tr=Geom::Transformation.new(a)
          else
            x=v.normalize;y=@plane_normal.cross(x);y.normalize!;tr=Geom::Transformation.axes(a,x,y,@plane_normal)
          end
          if %w[curtain_wall louver].include?(@kind);p['width']=len
          elsif %w[beam railing ramp].include?(@kind);p['length']=len;end
        end
        tr=Geom::Transformation.axes(a,@plane_x,@plane_y,@plane_normal) if @mode=='point'
        tr=tr*Geom::Transformation.rotation(ORIGIN,Z_AXIS,p['rotation']*Math::PI/180)
        [p,tr]
      end
      def finish(commit_only=false)
        @finish_pending=false
        conf=configuration;return unless conf;p,tr=conf
        split_wall=@kind=='wall' && p['path_points'].is_a?(Array) && p['path_points'].length>2 && p['closed']!=true && p['path_curve']!=true
        p=Core::Walls.with_end_trims(p,tr,Sketchup.active_model.active_entities) if @kind=='wall' && !split_wall
        Core::Parameters.normalize(@kind,{},p)
        created=[]
        Core::Transactions.run("Draw Draupr #{@kind}") do
          created=split_wall ? Core::WallJunctions.create_path_segments(p,tr) : [Core::Objects.create(@kind,p,tr)]
          sel=Sketchup.active_model.selection;sel.clear;created.each { |g| sel.add(g) }
        end
        message=if split_wall
          'Wall path created as standalone segments. / مسیر دیوار به‌صورت قطعات مستقل ساخته شد.'
        elsif @kind=='molding'
          count=[p['path_points'].to_a.length-1,1].max
          "Molding created along #{count} path segment#{count==1 ? '' : 's'}. / نوار تزئینی در #{count} قطعه مسیر ساخته شد."
        else
          'Object created. / آبجکت ساخته شد.'
        end
        UI::Dialog.notify(message,'success');@points=[];@closed=false;@arc_pending=nil;@preview_pts=nil;@arc_generated=false
        Sketchup.active_model.select_tool(nil) unless commit_only || Core::Preferences.get('keep_drawing',true)
      rescue StandardError => e;fail_message(e);end
      def fail_message(e)
        Core::Diag.log_error('Drawing',e);UI::Dialog.notify(e.message,'error');Sketchup.set_status_text("Draupr: #{e.message}");::UI.beep
      end
      def getExtents
        b=Geom::BoundingBox.new;((@preview_pts||@points)+[@cursor]).compact.each { |q| b.add(q.transform(Sketchup.active_model.edit_transform)) };b
      end
      def draw_molding_profile_preview(view,pts)
        return if pts.length<2
        data=Core::MoldingProfiles.fetch(@p['profile']);profile=data ? data['points'] : [[0,0],[1,0],[1,1],[0,1]]
        tangent=pts[-2].vector_to(pts[-1]);return if tangent.length<1e-8;tangent.normalize!
        side=nil
        if @p['placement_mode']=='surface'
          candidate=@plane_normal.clone;dot=candidate.dot(tangent);candidate=Geom::Vector3d.new(candidate.x-tangent.x*dot,candidate.y-tangent.y*dot,candidate.z-tangent.z*dot);side=candidate if candidate.length>1e-8
        end
        side||=Z_AXIS.cross(tangent);side=X_AXIS.cross(tangent) if side.length<1e-8;return if side.length<1e-8;side.normalize!;side.reverse! if @p['flip_profile']==true
        angle=@p['profile_rotation'].to_f*Math::PI/180.0;side.transform!(Geom::Transformation.rotation(ORIGIN,tangent,angle)) if angle.abs>1e-8;up=tangent.cross(side);return if up.length<1e-8;up.normalize!
        height=@p['height'].to_f;projection=data && @p['preserve_profile_ratio']!=false ? height*data['aspect'].to_f : @p['projection'].to_f
        origin=pts.last;anchor=Core::MoldingProfiles.anchor(profile,@p['profile_anchor']);outline=profile.map { |q| origin.offset(side,(q[0].to_f-anchor[0])*projection).offset(up,(q[1].to_f-anchor[1])*height).transform(Sketchup.active_model.edit_transform) };outline<<outline.first
        view.drawing_color=[225,116,35];view.line_width=3;view.draw(GL_LINE_STRIP,outline)
        tip=origin.offset(side,projection).transform(Sketchup.active_model.edit_transform);view.draw(GL_LINES,[origin.transform(Sketchup.active_model.edit_transform),tip])
      rescue StandardError
        nil
      end
      def draw(view)
        @ip.draw(view) if @snap_visible&&@ip.valid?
        view.draw_text(Geom::Point3d.new(@screen[0]+16,@screen[1]-24,0),@dimension_text,{size:12,color:'DodgerBlue'}) if @screen && @dimension_text && !@points.empty?
        pts=@points.dup
        if @arc_pending && @cursor
          pts+=arc_points(@points.last,@arc_pending,@cursor)
        elsif @cursor && (pts.empty? || pts.last.distance(@cursor)>0.001)
          pts<<@cursor
        end
        @preview_pts=pts
        if @kind=='railing' && pts.length>1
          worldpts=pts.map { |q| q.transform(Sketchup.active_model.edit_transform) };h=@p['height']||1000.mm;top=worldpts.map { |q| q.offset(Z_AXIS,h) };view.drawing_color=[36,114,184];view.line_width=3;view.draw(GL_LINE_STRIP,top);view.draw(GL_LINES,worldpts.zip(top).flatten);return
        end
        if (%w[molding curtain_wall beam louver].include?(@kind) || (@kind=='foundation' && @p['foundation_type']=='strip')) && pts.length>1
          view.drawing_color=[36,114,184];view.line_width=2;view.draw(GL_LINE_STRIP,pts.map { |q| q.transform(Sketchup.active_model.edit_transform) });draw_molding_profile_preview(view,pts) if @kind=='molding'
          return
        end
        conf=configuration(pts)
        unless conf
          if pts.length>1
            view.drawing_color=[36,114,184];view.line_width=2;view.draw(GL_LINE_STRIP,pts.map { |q| q.transform(Sketchup.active_model.edit_transform) })
          end
          return
        end
        p,tr=conf
        view.line_width=2
        dir=@direction && @direction.length>0.001 ? @direction.normalize : nil
        view.drawing_color=(@lock==:x || (dir && dir.x.abs>0.9903)) ? [220,65,65] : ((@lock==:y || (dir && dir.y.abs>0.9903)) ? [40,160,90] : [36,114,184])
        world=Sketchup.active_model.edit_transform*tr
        if @kind=='wall'
          Core::Walls.geometry(p).each { |s| s['layers'].each { |l| q=l['quad'].map { |a| Core::Walls.point(a) };wire_prism(view,q,p['height'],world) } }
        else
          w=%w[beam railing ramp].include?(@kind) ? p['length'] : (p['width']||p['spacing_x']||400.mm);d=p['depth']||p['mullion_depth']||p['blade_depth']||p['width']||100.mm;h=p['height']||p['thickness']||900.mm
          if @kind=='column' && p['shape']=='round';w=p['radius']*2;d=w;end
          if @kind=='stair';n,r=Core::Parameters.stair_values(p);w=n*p['tread'];d=p['width'];h=n*r;end
          if @kind=='roof';h=Core::Parameters.length(Core::Parameters.derived(@kind,p)['actualRise'])+p['thickness'];end
          x0=%w[column foundation].include?(@kind) ? -w/2 : 0;y0=%w[column foundation].include?(@kind) ? -d/2 : 0
          if @kind=='beam';d=p['width'];y0=p['alignment']=='center' ? -d/2 : (p['alignment']=='outside' ? -d : 0);end
          q=[[x0,y0,0],[x0+w,y0,0],[x0+w,y0+d,0],[x0,y0+d,0]].map { |a| Geom::Point3d.new(a) };wire_prism(view,q,h,world)
          if @kind=='curtain_wall'
            xs,zs=Core::Builders.curtain_grid(p)
            lines=xs.first(50).flat_map { |x| [Geom::Point3d.new(x,0,0).transform(world),Geom::Point3d.new(x,0,h).transform(world)] }+zs.first(50).flat_map { |z| [Geom::Point3d.new(0,0,z).transform(world),Geom::Point3d.new(w,0,z).transform(world)] };view.draw(GL_LINES,lines)
          end
        end
      rescue StandardError
        # A transient zero-size preview must not interrupt picking.
        nil
      end
      def wire_prism(view,q,h,tr)
        bottom=q.map { |a| a.transform(tr) };top=q.map { |a| a.offset(Z_AXIS,h).transform(tr) };view.draw(GL_LINE_LOOP,bottom);view.draw(GL_LINE_LOOP,top);view.draw(GL_LINES,bottom.zip(top).flatten)
      end
    end
  end
end
