# frozen_string_literal: true
module Draupr
  module Studio
    # User-authored temporary driving dimension:
    # fixed reference, driven target-wall endpoint, then dimension placement.
    class WallDimensionTool
      TEXT_HALF_HEIGHT=13
      ENDPOINT_HIT_RADIUS=26
      def initialize(wall=nil)
        @uid=Core::Objects.id(wall) if wall
        @ip=Sketchup::InputPoint.new;@stage=:reference
        @reference=nil;@target=nil;@target_index=nil;@axis=nil
        @hover_point=nil;@offset=36.0;@bounds=nil
      end
      def enableVCB?;@stage==:ready;end
      def wall;@uid ? Core::Objects.get(@uid) : nil;rescue RuntimeError;nil;end
      def wall_data
        object=wall;raise 'Select exactly one straight Draupr wall.' unless object
        p,a,b=Core::WallLengthSolver.validate_wall!(object)
        transform=Sketchup.active_model.edit_transform*object.transformation
        [object,p,a.transform(transform),b.transform(transform)]
      end
      def activate
        unless wall
          selected=Core::Objects.selected.select { |item| Core::Metadata.read(item)['type']=='wall' }
          raise 'Select exactly one Draupr wall.' unless selected.length==1
          @uid=Core::Objects.id(selected.first)
        end
        wall_data;status;Sketchup.active_model.active_view.invalidate
      rescue StandardError=>error
        ::UI.messagebox(error.message);Sketchup.active_model.select_tool(nil)
      end
      def deactivate(view);Sketchup.set_status_text('',SB_VCB_LABEL);Sketchup.set_status_text('',SB_VCB_VALUE);view.invalidate;end
      def resume(view);status;view.invalidate;end
      def suspend(view);view.invalidate;end
      def status
        text=case @stage
        when :reference then 'Driving dimension: click the fixed reference on this wall, another wall, or any model geometry.'
        when :target then 'Driving dimension: click an end cap, end edge, or endpoint of the selected target wall.'
        when :place then 'Driving dimension: move the cursor and click to place the dimension line.'
        else 'Type the required distance in Measurements and press Enter. Esc starts a new dimension.'
        end
        Sketchup.set_status_text(text);Sketchup.set_status_text('Distance',SB_VCB_LABEL)
        Sketchup.set_status_text(@stage==:ready ? Sketchup.format_length(measured_distance) : '',SB_VCB_VALUE)
      rescue StandardError;nil;end
      def endpoints;data=wall_data;[data[2],data[3]];end
      def endpoint_screen_hit(view,x,y)
        pairs=endpoints.each_with_index.map { |point,index| [view.screen_coords(point),point,index] }
        hit=pairs.min_by { |screen,_point,_index| Math.sqrt((screen.x-x)**2+(screen.y-y)**2) }
        return nil unless hit && hit[0].distance(Geom::Point3d.new(x,y,0))<=ENDPOINT_HIT_RADIUS
        [hit[1],hit[2]]
      end
      def wall_surface_endpoint_hit(view,x,y)
        object=wall
        path=Picking.paths(view,x,y,10).find { |candidate| Picking.object_in(candidate)==object }
        return nil unless path
        @ip.pick(view,x,y);return nil unless @ip.valid?
        a,b=endpoints;axis=a.vector_to(b);length=axis.length;return nil if length<1.mm
        axis.normalize!;station=a.vector_to(@ip.position).dot(axis)
        index=station<=length/2.0 ? 0 : 1
        # Clicking any visible end cap, end edge, or terminal quarter of a wall
        # resolves to the logical centerline endpoint. This is intentionally
        # larger than a pixel-only target because wall thickness separates the
        # visible corner from its parametric centerline in perspective views.
        distance=index==0 ? station.abs : (length-station).abs
        return nil if distance>length*0.25
        [index==0 ? a : b,index]
      end
      def target_endpoint_hit(view,x,y)
        endpoint_screen_hit(view,x,y)||wall_surface_endpoint_hit(view,x,y)
      end
      def picked_reference(view,x,y)
        endpoint=target_endpoint_hit(view,x,y);return endpoint[0] if endpoint
        @ip.pick(view,x,y);@ip.valid? ? @ip.position : nil
      end
      def onMouseMove(_flags,x,y,view)
        if @stage==:reference
          @hover_point=picked_reference(view,x,y)
        elsif @stage==:target
          hit=target_endpoint_hit(view,x,y);@hover_point=hit&&hit[0]
          view.tooltip=hit ? "Use target wall #{hit[1]==0 ? 'start' : 'end'}" : 'Click a target-wall endpoint'
        elsif @stage==:place
          update_offset(view,x,y)
        end
        view.invalidate
      end
      def onLButtonDown(_flags,x,y,view)
        case @stage
        when :reference
          point=picked_reference(view,x,y);raise 'Pick a valid fixed reference point.' unless point
          @reference=point;@stage=:target
        when :target
          hit=target_endpoint_hit(view,x,y);raise 'Click an end cap, end edge, or endpoint of the selected target wall.' unless hit
          @target,@target_index=hit;vector=@reference.vector_to(@target)
          raise 'The two dimension references must be different.' if vector.length<1.mm
          @axis=vector.normalize;@stage=:place
        when :place
          update_offset(view,x,y);@stage=:ready
        when :ready
          Sketchup.set_status_text('Type the required distance in Measurements and press Enter.') if in_bounds?(x,y)
        end
        status;view.invalidate
      rescue StandardError=>error
        Sketchup.set_status_text(error.message);::UI.beep;view.invalidate
      end
      def update_offset(view,x,y)
        return unless @reference&&@target
        a=view.screen_coords(@reference);b=view.screen_coords(@target);dx=b.x-a.x;dy=b.y-a.y;length=Math.sqrt(dx*dx+dy*dy);return if length<0.001
        nx=-dy/length;ny=dx/length;mid=Geom::Point3d.new((a.x+b.x)/2.0,(a.y+b.y)/2.0,0);raw=(x-mid.x)*nx+(y-mid.y)*ny
        @offset=raw.abs<18.0 ? (raw<0 ? -18.0 : 18.0) : [[raw,-180.0].max,180.0].min
      end
      def dimension_screen(view)
        a=view.screen_coords(@reference);b=view.screen_coords(@target);dx=b.x-a.x;dy=b.y-a.y;length=Math.sqrt(dx*dx+dy*dy)
        nx=length>0.001 ? -dy/length : 0.0;ny=length>0.001 ? dx/length : -1.0
        da=Geom::Point3d.new(a.x+nx*@offset,a.y+ny*@offset,0);db=Geom::Point3d.new(b.x+nx*@offset,b.y+ny*@offset,0);mid=Geom::Point3d.new((da.x+db.x)/2.0,(da.y+db.y)/2.0,0)
        text=Sketchup.format_length(measured_distance);width=[text.length*7.2+18.0,78.0].max;side=@offset<0 ? -1.0 : 1.0
        center=Geom::Point3d.new(mid.x+nx*17.0*side,mid.y+ny*17.0*side,0);@bounds=[center.x-width/2.0,center.y-TEXT_HALF_HEIGHT,center.x+width/2.0,center.y+TEXT_HALF_HEIGHT]
        [a,b,da,db,text]
      end
      def draw_marker(view,point,color,size=5.0)
        screen=view.screen_coords(point);view.drawing_color=color
        view.draw2d(GL_LINES,[screen.offset(X_AXIS,-size),screen.offset(X_AXIS,size),screen.offset(Y_AXIS,-size),screen.offset(Y_AXIS,size)])
      end
      def draw(view)
        blue=Sketchup::Color.new(35,112,220);orange=Sketchup::Color.new(240,145,20)
        draw_marker(view,@reference,orange,6.0) if @reference
        draw_marker(view,@hover_point,blue,5.0) if @hover_point && @stage!=:place
        return unless @reference&&@target
        a,b,da,db,text=dimension_screen(view);view.line_width=2;view.line_stipple='';view.drawing_color=blue;view.draw2d(GL_LINES,[a,da,b,db,da,db])
        direction=da.vector_to(db);direction.normalize! if direction.length>0.001;normal=Geom::Vector3d.new(-direction.y,direction.x,0);arrow=7.0
        view.draw2d(GL_LINES,[da,da.offset(direction,arrow).offset(normal,arrow/2.0),da,da.offset(direction,arrow).offset(normal,-arrow/2.0),db,db.offset(direction,-arrow).offset(normal,arrow/2.0),db,db.offset(direction,-arrow).offset(normal,-arrow/2.0)])
        left,top,right,bottom=@bounds;background=Sketchup::Color.new(250,252,255,235);border=Sketchup::Color.new(116,145,184)
        corners=[Geom::Point3d.new(left,top,0),Geom::Point3d.new(right,top,0),Geom::Point3d.new(right,bottom,0),Geom::Point3d.new(left,bottom,0)]
        view.drawing_color=background;view.draw2d(GL_QUADS,corners);view.line_width=1;view.drawing_color=border;view.draw2d(GL_LINE_LOOP,corners)
        view.draw_text([left+9,top+5],text,{color:blue,font:'Arial',size:12,bold:true})
        draw_marker(view,@reference,orange,6.0);draw_marker(view,@target,blue,6.0)
      rescue StandardError=>error;Core::Diag.log_error('Driving dimension overlay',error);end
      def measured_distance
        return 0.0 unless @reference&&@target
        @reference.vector_to(@target).dot(@axis||@reference.vector_to(@target).normalize).abs
      end
      def in_bounds?(x,y);@bounds && x>=@bounds[0] && x<=@bounds[2] && y>=@bounds[1] && y<=@bounds[3];end
      def onUserText(text,view)
        raise 'Create the dimension first: fixed reference, target endpoint, then placement.' unless @stage==:ready
        desired=Core::Parameters.length(text);raise 'Distance must be positive.' unless desired>1.mm
        object,_p,start_point,end_point=wall_data;target=@target_index==0 ? start_point : end_point
        wall_axis=start_point.vector_to(end_point);old_length=wall_axis.length;wall_axis.normalize!
        current=@reference.vector_to(target).dot(@axis);denominator=wall_axis.dot(@axis)
        if denominator.abs<0.1
          delta=desired-current.abs;direction=current<0 ? @axis.reverse : @axis
          direction=direction.reverse if delta<0;vector=direction.clone;vector.length=delta.abs
          object=Core::WallLengthSolver.translate(object,vector)
        else
          desired_signed=current<0 ? -desired : desired;movement=(desired_signed-current)/denominator
          new_length=@target_index==1 ? old_length+movement : old_length-movement;anchor=@target_index==1 ? :start : :end
          object=Core::WallLengthSolver.resize(object,new_length,anchor)
        end
        @uid=Core::Objects.id(object);data=wall_data;@target=@target_index==0 ? data[2] : data[3]
        status;view.invalidate
      rescue StandardError=>error
        Sketchup.set_status_text(error.message);::UI.beep;view.invalidate
      end
      def onCancel(_reason,view)
        if @stage==:reference;Sketchup.active_model.select_tool(nil)
        else
          @stage=:reference;@reference=nil;@target=nil;@target_index=nil;@axis=nil;@bounds=nil;status
        end
        view.invalidate
      end
    end
  end
end