# frozen_string_literal: true
module Draupr
  module Studio
    module ModifierPicking
      module_function
      def object_at(view,x,y);Picking.object_in(Picking.path(view,x,y));end
      def local_point(object,input_point)
        input_point.position.transform(Sketchup.active_model.edit_transform.inverse).transform(object.transformation.inverse)
      end
      def world_face_hit(view,x,y)
        world_face_hit_on_path(Picking.path(view,x,y),view,x,y)
      end
      def world_face_hit_on_path(path,view,x,y)
        face=path.reverse.find { |entity| entity.is_a?(Sketchup::Face) };return nil unless face
        index=path.index(face);transform=Sketchup.active_model.edit_transform
        path[0...index].each { |entity| transform=transform*entity.transformation if entity.respond_to?(:transformation) }
        points=face.vertices.first(3).map { |vertex| vertex.position.transform(transform) };return nil if points.length<3
        hit=Geom.intersect_line_plane(view.pickray(x,y),Geom.fit_plane_to_points(*points));hit ? [hit,path,face,transform] : nil
      end
      def wall_opening_near(view,x,y)
        model=Sketchup.active_model;walls=(Core::Objects.all+Core::Objects.all(model.active_entities)+Core::Objects.selected).uniq
        candidates=walls.filter_map do |wall|
          next unless Core::Metadata.read(wall)['type']=='wall'
          segments=Core::Walls.segments(wall)
          Core::Walls.holes(wall).filter_map do |opening|
            segment=segments[opening['seg'].to_i];next unless segment
            a=Core::Walls.point(segment['cs']);b=Core::Walls.point(segment['ce']);direction=a.vector_to(b);next if direction.length<1.mm;direction.normalize!
            local=a.offset(direction,(opening['t1']+opening['t2'])/2.0);local.z=a.z+(opening['z0']+opening['z1'])/2.0
            world=Core::Transforms.local_point_to_world(wall,local);screen=view.screen_coords(world);distance=Math.sqrt((screen.x-x)**2+(screen.y-y)**2)
            [distance,wall,world]
          end.min_by(&:first)
        end.compact.min_by(&:first)
        candidates && candidates[0]<=500 ? [candidates[1],candidates[2]] : nil
      end
      def screen_path_solution(object,points,view,x,y)
        transform=Core::Transforms.entity_to_world(object)
        points.each_cons(2).with_index.filter_map do |(a,b),index|
          sa=view.screen_coords(a.transform(transform));sb=view.screen_coords(b.transform(transform));dx=sb.x-sa.x;dy=sb.y-sa.y;length2=dx*dx+dy*dy;next if length2<1e-9
          ratio=[[(x-sa.x)*dx+(y-sa.y)*dy,0.0].max,length2].min/length2;sx=sa.x+dx*ratio;sy=sa.y+dy*ratio
          point=Geom::Point3d.new(a.x+(b.x-a.x)*ratio,a.y+(b.y-a.y)*ratio,a.z+(b.z-a.z)*ratio)
          [(x-sx)**2+(y-sy)**2,index,point]
        end.min_by(&:first)
      end
      def knife_pick(view,x,y)
        seen={};ranked=[];paths=Picking.paths(view,x,y,12)
        evaluate=lambda do |object,path,pick_rank|
          return unless object;uid=Core::Objects.id(object).to_s;return if seen[uid];seen[uid]=true
          begin
            _kind,params,points=Core::ModifyTools.path_points!(object,true);points=points+[points.first] if params['closed']==true;surface=path ? world_face_hit_on_path(path,view,x,y) : nil
            if surface
              local=Core::Transforms.world_point_to_local(object,surface[0])
              solution=points.each_cons(2).with_index.filter_map do |(a,b),segment_index|
                vector=a.vector_to(b);length=vector.length;next if length<1.mm
                vector.normalize!;station=[[a.vector_to(local).dot(vector),0.0].max,length].min;point=a.offset(vector,station)
                [point.distance(local),segment_index,point]
              end.min_by(&:first)
            else
              solution=screen_path_solution(object,points,view,x,y)
            end
            return unless solution;return if !path&&solution[0]>24.0**2
            endpoint_margin=params['closed']==true ? Core::Walls::EPS*2.0 : [solution[2].distance(points.first),solution[2].distance(points.last)].min
            if surface;display=surface[0]
            else
              segment_a=Core::Transforms.local_point_to_world(object,points[solution[1]]);segment_b=Core::Transforms.local_point_to_world(object,points[solution[1]+1]);normal=segment_a.vector_to(segment_b)
              display=normal.length>1e-9 ? (Geom.intersect_line_plane(view.pickray(x,y),[Core::Transforms.local_point_to_world(object,solution[2]),normal]) || Core::Transforms.local_point_to_world(object,solution[2])) : Core::Transforms.local_point_to_world(object,solution[2])
            end
            ranked<<[path ? 0 : 1,endpoint_margin<=Core::Walls::EPS ? 1 : 0,solution[0],pick_rank,object,solution[2],display]
          rescue StandardError
            nil
          end
        end
        paths.each_with_index { |path,index| evaluate.call(Picking.object_in(path),path,index) }
        model=Sketchup.active_model;nearby=(Core::Objects.all+Core::Objects.all(model.active_entities)+Core::Objects.selected).uniq
        nearby.each { |object| evaluate.call(object,nil,paths.length+1) }
        best=ranked.min_by { |entry| [entry[0],entry[1],entry[2],entry[3]] };best ? [best[4],best[5],best[6]] : nil
      end
      def local_path_point(object,view,x,y)
        params=Core::Objects.params(object);points=Array(params['path_points']).map { |value| Core::ModifyTools.numeric_point(value) }
        raise Core::I18n.message('This object has no editable path.','این آبجکت مسیر قابل ویرایش ندارد.') if points.length<2
        screen=screen_path_solution(object,points,view,x,y);surface=world_face_hit(view,x,y);best=nil
        if surface
          local=Core::Transforms.world_point_to_local(object,surface[0])
          best=points.each_cons(2).with_index.filter_map do |(a,b),segment_index|
            vector=a.vector_to(b);length=vector.length;next if length<1.mm
            vector.normalize!;station=[[a.vector_to(local).dot(vector),0.0].max,length].min;point=a.offset(vector,station)
            [point.distance(local),segment_index,point]
          end.min_by(&:first)
        end
        if screen
          endpoint=best && ([best[2].distance(points.first),best[2].distance(points.last)].min<=Core::Walls::EPS)
          screen_internal=[screen[2].distance(points.first),screen[2].distance(points.last)].min>Core::Walls::EPS
          best=screen if !best || (endpoint&&screen_internal)
        end
        raise Core::I18n.message('No valid path segment was found.','هیچ بخش معتبر مسیر پیدا نشد.') unless best
        best[2]
      end
      def face_plane(view,x,y)
        path=Picking.path(view,x,y);face=path.reverse.find { |entity| entity.is_a?(Sketchup::Face) };raise Core::I18n.message('Pick a planar target face.','یک سطح تخت هدف انتخاب کنید.') unless face
        index=path.index(face);transform=Sketchup.active_model.edit_transform;path[0...index].each { |entity| transform=transform*entity.transformation if entity.respond_to?(:transformation) }
        points=face.vertices.first(3).map { |vertex| vertex.position.transform(transform) };raise Core::I18n.message('Target face is degenerate.','سطح هدف نامعتبر است.') if points.length<3
        [Geom.fit_plane_to_points(*points),path,face,transform]
      end
      def local_plane(object,world_plane)
        world_to_object=(Sketchup.active_model.edit_transform*object.transformation).inverse
        origin=Geom::Point3d.new(0,0,0);normal=Geom::Vector3d.new(world_plane[0],world_plane[1],world_plane[2]);point=Geom.intersect_line_plane([origin,normal],world_plane) || origin
        x=normal.cross(Z_AXIS);x=normal.cross(X_AXIS) if x.length<1e-8;x.normalize!;y=normal.cross(x);y.normalize!
        Geom.fit_plane_to_points(point.transform(world_to_object),point.offset(x,1000.mm).transform(world_to_object),point.offset(y,1000.mm).transform(world_to_object))
      end
      def target_reference(path,face)
        {'persistent_id'=>face.persistent_id,'instance_path'=>path[0...path.index(face)].filter_map { |entity| entity.respond_to?(:persistent_id) ? entity.persistent_id : nil },'model_guid'=>(Sketchup.active_model.guid rescue nil)}
      end
    end

    class AssemblySplitTool
      def initialize;@object=nil;@local=nil;@display_world=nil;@guide=nil;@error=nil;end
      def activate;Sketchup.set_status_text('Knife: move across the assembly path. The solid red line is the exact cut station. / چاقو: روی مسیر مونتاژ حرکت کنید؛ خط قرمز محل دقیق برش است.');end
      def onSetCursor;id=ModifyCursor.knife;id ? (::UI.set_cursor(id);true) : false;end
      def onCancel(_reason,view);Sketchup.active_model.select_tool(nil);view.invalidate;end
      def deactivate(view);view.invalidate;end
      def onMouseMove(_flags,x,y,view)
        pick=ModifierPicking.knife_pick(view,x,y);@object=pick&&pick[0];@local=pick&&pick[1];@display_world=pick&&pick[2];@guide=nil;@error=nil
        if @object&&@local
          @guide=Core::ModifyTools.split_preview_path(@object,@local).map { |point| point.transform(@object.transformation).transform(Sketchup.active_model.edit_transform) }
          Sketchup.set_status_text('Knife ready: click to create two independent parametric objects. / چاقو آماده است؛ برای ساخت دو آبجکت پارامتریک مستقل کلیک کنید.')
        end;view.invalidate
      rescue StandardError=>error
        @guide=nil;@error=error.message;Sketchup.set_status_text("Draupr Knife: #{@error}");view.invalidate
      end
      def onLButtonDown(_flags,x,y,view)
        pick=ModifierPicking.knife_pick(view,x,y);object=pick ? pick[0] : @object;local=pick ? pick[1] : @local;raise Core::I18n.message('Hover a supported Draupr path first.','ابتدا روی یک مسیر پشتیبانی‌شده Draupr بروید.') unless object&&local
        Core::ModifyTools.split_preview_path(object,local)
        Core::ModifyTools.split_path(object,local);@object=nil;@local=nil;@display_world=nil;@guide=nil;@error=nil;UI::Dialog.notify(Core::I18n.message('Assembly split into two parametric objects.','مونتاژ به دو آبجکت پارامتریک تقسیم شد.'),'success');view.invalidate
      rescue StandardError=>error;@error=error.message;UI::Dialog.notify(error.message,'error');view.invalidate;end
      def draw(view)
        return unless @guide
        bottom=Geom::Point3d.new((@guide[0].x+@guide[1].x)/2.0,(@guide[0].y+@guide[1].y)/2.0,(@guide[0].z+@guide[1].z)/2.0)
        top=Geom::Point3d.new((@guide[2].x+@guide[3].x)/2.0,(@guide[2].y+@guide[3].y)/2.0,(@guide[2].z+@guide[3].z)/2.0)
        view.line_stipple='';view.drawing_color=[235,45,45];view.line_width=6;view.draw(GL_LINES,[bottom,top])
      end
    end

    class PathTrimBoundaryTool
      def initialize;@ip=Sketchup::InputPoint.new;@source=nil;@source_local=nil;@path=[];end
      def activate;Sketchup.set_status_text('Trim/Extend: click a path endpoint, then a target face. Esc clears. / انتهای مسیر و سپس سطح هدف را کلیک کنید.');end
      def onSetCursor;id=ModifyCursor.trim;id ? (::UI.set_cursor(id);true) : false;end
      def onCancel(_reason,view);if @source;@source=nil;@source_local=nil;else;Sketchup.active_model.select_tool(nil);end;view.invalidate;end
      def onMouseMove(_flags,x,y,view);@ip.pick(view,x,y);@path=Picking.path(view,x,y);view.invalidate;end
      def onLButtonDown(_flags,x,y,view)
        @ip.pick(view,x,y)
        if @source
          plane,_path,_face,_transform=ModifierPicking.face_plane(view,x,y);Core::ModifyTools.trim_path_to_plane(@source,@source_local,plane);@source=nil;@source_local=nil;UI::Dialog.notify(Core::I18n.message('Path trimmed or extended.','مسیر برش یا امتداد یافت.'),'success')
        else
          object=ModifierPicking.object_at(view,x,y);raise Core::I18n.message('Click a supported Draupr path endpoint.','روی انتهای یک مسیر پشتیبانی‌شده Draupr کلیک کنید.') unless object&&@ip.valid?;@source=object;@source_local=ModifierPicking.local_point(object,@ip);Core::ModifyTools.path_points!(object);Sketchup.set_status_text('Source endpoint set. Click the target face. / انتهای مبدا تنظیم شد؛ سطح هدف را کلیک کنید.')
        end;view.invalidate
      rescue StandardError=>error;UI::Dialog.notify(error.message,'error');end
      def draw(view);Picking.wire_bounds(view,@path,@source ? [235,120,30] : [40,150,230]);end
    end

    class BaselineAlignTool
      def initialize;@reference=nil;@path=[];end
      def activate;Sketchup.set_status_text('Align Baseline: click reference path, then path to move. / ابتدا مسیر مرجع و سپس مسیر قابل‌حرکت را کلیک کنید.');end
      def onSetCursor;id=ModifyCursor.align;id ? (::UI.set_cursor(id);true) : false;end
      def onCancel(_reason,view);if @reference;@reference=nil;else;Sketchup.active_model.select_tool(nil);end;view.invalidate;end
      def onMouseMove(_flags,x,y,view);@path=Picking.path(view,x,y);view.invalidate;end
      def onLButtonDown(_flags,x,y,view)
        object=ModifierPicking.object_at(view,x,y);raise Core::I18n.message('Pick a supported Draupr path.','یک مسیر پشتیبانی‌شده Draupr انتخاب کنید.') unless object;Core::ModifyTools.path_points!(object)
        if @reference;Core::ModifyTools.align_baselines(@reference,object);@reference=nil;UI::Dialog.notify(Core::I18n.message('Baselines aligned.','خطوط مبنا هم‌راستا شدند.'),'success')
        else;@reference=object;Sketchup.set_status_text('Reference baseline set. Click the path to move. / خط مبنا تنظیم شد؛ مسیر قابل‌حرکت را کلیک کنید.');end;view.invalidate
      rescue StandardError=>error;UI::Dialog.notify(error.message,'error');end
      def draw(view);Picking.wire_bounds(view,@path,@reference ? [235,120,30] : [40,150,230]);end
    end

    class BoundaryAttachTool
      def initialize(boundary);@boundary=boundary.to_s;@wall=nil;@path=[];end
      def activate
        walls=Core::Objects.selected.select { |object| Core::Metadata.read(object)['type']=='wall' };@wall=walls.length==1 ? walls.first : nil;status
      end
      def status
        text=@wall ? "Attach #{@boundary.capitalize}: wall set; click the target roof, slab, or planar face. / دیوار تنظیم شد؛ سطح هدف را کلیک کنید." : "Attach #{@boundary.capitalize}: click the Draupr wall first, then the target face. / ابتدا دیوار Draupr و سپس سطح هدف را کلیک کنید."
        Sketchup.set_status_text(text)
      end
      def onCancel(_reason,view);if @wall;@wall=nil;status;else;Sketchup.active_model.select_tool(nil);end;view.invalidate;end
      def onMouseMove(_flags,x,y,view);@path=Picking.path(view,x,y);view.invalidate;end
      def onLButtonDown(_flags,x,y,view)
        unless @wall
          candidate=ModifierPicking.object_at(view,x,y);raise Core::I18n.message('First click a Draupr wall.','ابتدا روی یک دیوار Draupr کلیک کنید.') unless candidate&&Core::Metadata.read(candidate)['type']=='wall'
          @wall=candidate;status;view.invalidate;return
        end
        plane,path,face,_transform=ModifierPicking.face_plane(view,x,y);target=ModifierPicking.object_at(view,x,y)
        if target&&Core::Objects.valid?(target)&&Core::Metadata.read(target)['type']=='roof'
          Core::ModifyTools.attach_roof_boundary(@wall,@boundary,target)
        else
          local=ModifierPicking.local_plane(@wall,plane);reference=ModifierPicking.target_reference(path,face)
          reference=reference.merge('object_uid'=>Core::Objects.id(target),'type'=>Core::Metadata.read(target)['type']) if target&&Core::Objects.valid?(target)
          Core::ModifyTools.attach_boundary(@wall,@boundary,local,reference)
        end
        UI::Dialog.notify(Core::I18n.message("Wall #{@boundary} attached.","مرز #{@boundary} دیوار متصل شد."),'success');Sketchup.active_model.select_tool(nil);view.invalidate
      rescue StandardError=>error;UI::Dialog.notify(error.message,'error');end
      def draw(view);Picking.wire_bounds(view,@path,@wall ? [35,180,90] : [40,150,230]);end
    end

    class StepPathTool
      def initialize(delta);@delta=delta.to_f;@ip=Sketchup::InputPoint.new;@object=nil;@guide=nil;end
      def activate;Sketchup.set_status_text('Step Height: hover a wall or strip foundation and click the step station. / روی دیوار یا فونداسیون نواری کلیک کنید.');end
      def onSetCursor;id=ModifyCursor.knife;id ? (::UI.set_cursor(id);true) : false;end
      def onCancel(_reason,view);Sketchup.active_model.select_tool(nil);view.invalidate;end
      def onMouseMove(_flags,x,y,view);@ip.pick(view,x,y);@object=ModifierPicking.object_at(view,x,y);@guide=nil;if @object&&@ip.valid?;local=ModifierPicking.local_point(@object,@ip);@guide=Core::ModifyTools.split_preview_path(@object,local).map { |point| point.transform(@object.transformation).transform(Sketchup.active_model.edit_transform) };end;view.invalidate;rescue StandardError;@object=nil;@guide=nil;view.invalidate;end
      def onLButtonDown(_flags,_x,_y,view);raise Core::I18n.message('Hover a wall or strip foundation first.','ابتدا روی دیوار یا فونداسیون نواری بروید.') unless @object&&@ip.valid?;Core::ModifyTools.step_at(@object,ModifierPicking.local_point(@object,@ip),@delta);UI::Dialog.notify(Core::I18n.message('Step applied.','پله اعمال شد.'),'success');view.invalidate;rescue StandardError=>error;UI::Dialog.notify(error.message,'error');end
      def draw(view);return unless @guide;view.drawing_color=[235,120,30];view.line_width=4;view.draw(GL_LINES,[@guide[0],@guide[1],@guide[0],@guide[2]]);end
    end

    class JunctionModifierTool
      def initialize(mode,radius);@mode=mode;@radius=radius.to_f;@ip=Sketchup::InputPoint.new;@wall=nil;@path=[];end
      def activate;Sketchup.set_status_text("Junction #{@mode}: click a joined wall endpoint. / روی انتهای متصل دیوار کلیک کنید.");end
      def onCancel(_reason,view);Sketchup.active_model.select_tool(nil);view.invalidate;end
      def onMouseMove(_flags,x,y,view);@ip.pick(view,x,y);@path=Picking.path(view,x,y);@wall=Picking.object_in(@path);@wall=nil unless @wall&&Core::Metadata.read(@wall)['type']=='wall';view.invalidate;end
      def onLButtonDown(_flags,_x,_y,view);raise Core::I18n.message('Pick a joined Draupr wall endpoint.','انتهای یک دیوار متصل Draupr را انتخاب کنید.') unless @wall&&@ip.valid?;Core::ModifyTools.set_junction(@wall,ModifierPicking.local_point(@wall,@ip),@mode,@radius);UI::Dialog.notify(Core::I18n.message('Junction updated.','اتصال به‌روزرسانی شد.'),'success');view.invalidate;rescue StandardError=>error;UI::Dialog.notify(error.message,'error');end
      def draw(view);Picking.wire_bounds(view,@path,[195,80,220]);end
    end

    class OpeningModifierTool
      def initialize(action,options={});@action=action.to_s;@options=options;@path=[];end
      def activate;Sketchup.set_status_text(@action=='heal' ? 'Heal Opening: click the opening object, jamb, or empty opening. / روی آبجکت، چهارچوب یا فضای خالی بازشو کلیک کنید.' : 'Splay Opening: click a hosted door or window. / روی در یا پنجره متصل کلیک کنید.');end
      def onCancel(_reason,view);Sketchup.active_model.select_tool(nil);view.invalidate;end
      def onMouseMove(_flags,x,y,view);@path=Picking.path(view,x,y);view.invalidate;end
      def onLButtonDown(_flags,x,y,view)
        object=ModifierPicking.object_at(view,x,y)
        if @action=='heal'
          kind=object ? Core::Metadata.read(object)['type'].to_s : ''
          if %w[door window skylight dormer].include?(kind);Core::ModifyTools.heal_opening(object)
          else
            hit=ModifierPicking.world_face_hit(view,x,y);near=ModifierPicking.wall_opening_near(view,x,y)
            if kind=='wall';host=object;point=hit ? hit[0] : (near&&near[1])
            else;host=near&&near[0];point=near&&near[1];end
            raise Core::I18n.message('Click an opening object, jamb, or opening void.','روی آبجکت بازشو، چهارچوب یا فضای بازشو کلیک کنید.') unless host&&point
            Core::ModifyTools.heal_opening(host,point)
          end
        else
          raise Core::I18n.message('Pick a hosted opening.','یک بازشوی متصل انتخاب کنید.') unless object
          Core::ModifyTools.splay_opening(object,@options['angle'],@options['sillSlope'],@options['setback'])
        end
        UI::Dialog.notify(Core::I18n.message('Opening updated.','بازشو به‌روزرسانی شد.'),'success');view.invalidate
      rescue StandardError=>error;UI::Dialog.notify(error.message,'error');end
      def draw(view);Picking.wire_bounds(view,@path,[220,65,65]);end
    end

    class SweepModifierTool
      def initialize(options);@options=options;@path=[];end
      def activate;Sketchup.set_status_text('Sweep Modifier: click a molding or railing. / روی ابزار پروفیلی یا نرده کلیک کنید.');end
      def onCancel(_reason,view);Sketchup.active_model.select_tool(nil);view.invalidate;end
      def onMouseMove(_flags,x,y,view);@path=Picking.path(view,x,y);view.invalidate;end
      def onLButtonDown(_flags,x,y,view)
        object=ModifierPicking.object_at(view,x,y);raise Core::I18n.message('Pick a molding or railing.','یک ابزار پروفیلی یا نرده انتخاب کنید.') unless object
        Core::ModifyTools.modify_sweep(object,@options['anchor'],@options['flip']==true,@options['startReturn']==true,@options['endReturn']==true,@options['returnLength']);UI::Dialog.notify(Core::I18n.message('Sweep updated.','مسیر پروفیل به‌روزرسانی شد.'),'success');view.invalidate
      rescue StandardError=>error;UI::Dialog.notify(error.message,'error');end
      def draw(view);Picking.wire_bounds(view,@path,[35,150,215]);end
    end
  end
end
