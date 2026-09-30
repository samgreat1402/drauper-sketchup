# frozen_string_literal: true
module Draupr
  module Core
    # Shared, tolerance-aware path preparation for linear architectural objects.
    module PathFrames
      EPS=1.mm
      module_function
      def clean(points,closed=false)
        out=[]
        points.each { |point| out<<point if out.empty? || out[-1].distance(point)>=EPS }
        out.pop if out.length>1 && out.first.distance(out.last)<EPS
        raise 'A path needs at least two distinct points. / مسیر حداقل دو نقطه متفاوت می‌خواهد.' if out.length<2
        raise 'A closed path needs at least three points. / مسیر بسته حداقل سه نقطه می‌خواهد.' if closed && out.length<3
        out
      end
      def segments(points,closed=false)
        pts=clean(points,closed);result=pts.each_cons(2).to_a;result<<[pts[-1],pts[0]] if closed;result
      end
      def frame(a,b,up=Z_AXIS)
        tangent=a.vector_to(b);raise 'A path segment has zero length. / یک بخش مسیر طول صفر دارد.' if tangent.length<EPS
        tangent.normalize!;side=up.cross(tangent)
        if side.length<1e-8
          fallback=[X_AXIS,Y_AXIS,Z_AXIS].min_by { |axis| axis.dot(tangent).abs };side=fallback.cross(tangent)
        end
        side.normalize!;normal=tangent.cross(side);normal.normalize!
        {'origin'=>a,'tangent'=>tangent,'side'=>side,'up'=>normal,'length'=>a.distance(b),'transform'=>Geom::Transformation.axes(a,tangent,side,normal)}
      end
      def stations(a,b,maximum_spacing,include_ends=true)
        f=frame(a,b);count=[(f['length']/maximum_spacing).ceil,1].max
        range=include_ends ? (0..count) : (1...count)
        range.map { |index| a.offset(a.vector_to(b),f['length']*index.to_f/count) }
      end
    end
  end
end
