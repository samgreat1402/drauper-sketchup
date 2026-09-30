# frozen_string_literal: true
module Draupr
  module Core
    module ModifyTools
      module_function
      def numeric_point(a);Geom::Point3d.new(a[0].to_f,a[1].to_f,a[2].to_f);end
      def editable_wall!(g)
        raise 'Select Draupr walls only.' unless Objects.valid?(g) && Metadata.read(g)['type']=='wall'
        p=Objects.params(g)
        raise 'Hosted openings must be removed before splitting or trimming this wall.' unless Walls.holes(g).empty?
        raise 'Legacy or closed walls must be redrawn before this operation.' unless p['path_points'].is_a?(Array) && p['path_points'].length>=2 && !p['closed']
        p
      end
      def rebuild_wall(old,p)
        uid=old.get_attribute('Draupr','uid')||SecureRandom.uuid;tr=old.transformation;parent=Geometry.parent_entities(old)
        ng=Objects.create('wall',p,tr,parent,uid);Objects.copy_identity(old,ng);ng.transformation=tr;Objects.capture(ng,'wall',p,uid);old.erase!;ng
      end
      def align(axis)
        items=Sketchup.active_model.selection.to_a.select { |e| e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance) }
        raise 'Select at least two groups or components. The first selected item is the reference.' if items.length<2
        ref=items.first.transformation.origin;i={'x'=>0,'y'=>1,'z'=>2}.fetch(axis.to_s)
        Transactions.run("Align selected #{axis.upcase}") do
          items.drop(1).each do |g|
            o=g.transformation.origin;delta=[0.0,0.0,0.0];delta[i]=ref.to_a[i]-o.to_a[i]
            g.transformation=Geom::Transformation.new(Geom::Vector3d.new(*delta))*g.transformation
          end
        end;true
      end
      def trim_walls
        walls=Objects.selected.select { |g| Metadata.read(g)['type']=='wall' };raise 'Select exactly two editable Draupr walls.' unless walls.length==2
        ps=walls.map { |g| editable_wall!(g) }
        world=walls.each_with_index.map do |g,i|
          pts=ps[i]['path_points'].map { |a| numeric_point(a).transform(g.transformation) }
          [pts,pts[-2],pts[-1]]
        end
        hit=Geom.intersect_line_line([world[0][1],world[0][1].vector_to(world[0][2])],[world[1][1],world[1][1].vector_to(world[1][2])])
        raise 'The last segments are parallel and cannot be trimmed.' unless hit
        Transactions.run('Trim Draupr walls') do
          walls.each_with_index do |g,i|
            local=hit.transform(g.transformation.inverse);arr=ps[i]['path_points'].map(&:dup)
            first=numeric_point(arr.first);last=numeric_point(arr.last)
            target=last.distance(local)<=first.distance(local) ? -1 : 0
            arr[target]=[local.x,local.y,local.z];ps[i]['path_points']=arr;rebuild_wall(g,ps[i])
          end
        end;true
      end
      def split_wall(wall,local)
        p=editable_wall!(wall);pts=p['path_points'].map { |a| numeric_point(a) }
        candidates=pts.each_cons(2).with_index.map do |(a,b),i|
          v=a.vector_to(b);len=v.length;v.normalize!;t=[[a.vector_to(local).dot(v),0].max,len].min;q=a.offset(v,t);[q.distance(local),i,q]
        end
        _,i,q=candidates.min_by(&:first);raise 'Split point is too close to an end.' if q.distance(pts[i])<10.mm || q.distance(pts[i+1])<10.mm
        a=pts[0..i]+[q];b=[q]+pts[(i+1)..]
        parent=Geometry.parent_entities(wall);tr=wall.transformation
        Transactions.run('Split Draupr wall') do
          p1=p.merge('path_points'=>a.map(&:to_a),'name'=>p['name'].to_s+' A');p2=p.merge('path_points'=>b.map(&:to_a),'name'=>p['name'].to_s+' B')
          g1=Objects.create('wall',p1,tr,parent);g2=Objects.create('wall',p2,tr,parent);wall.erase!
          s=Sketchup.active_model.selection;s.clear;s.add(g1);s.add(g2)
        end;true
      end
      def nearest_segment(wall,local)
        p=editable_wall!(wall);pts=p['path_points'].map { |a| numeric_point(a) }
        best=pts.each_cons(2).with_index.map { |(a,b),i| v=a.vector_to(b);l=v.length;v.normalize!;t=[[a.vector_to(local).dot(v),0].max,l].min;q=a.offset(v,t);[q.distance(local),i,a,b,q] }.min_by(&:first)
        [p,pts,best[1],best[2],best[3],best[4]]
      end
      def split_preview(wall,local)
        p,pts,i,a,b,q=nearest_segment(wall,local);v=a.vector_to(b);v.normalize!;n=Z_AXIS.cross(v);n.normalize!;half=Parameters.length(p['thickness'])/2+150.mm
        [q.offset(n,-half),q.offset(n,half),q.offset(Z_AXIS,Parameters.length(p['height']))]
      end
      def trim_endpoint_data(wall,p,pts,seg_index,click,hit_world)
        hit=hit_world.transform(wall.transformation.inverse)
        if pts.length==2
          replace=click.distance(pts[0])<=click.distance(pts[-1]) ? -1 : 0
        elsif seg_index==0
          replace=0
        elsif seg_index==pts.length-2
          replace=-1
        else
          raise 'For a multi-segment wall, select its first or last segment.'
        end
        arr=p['path_points'].map { |a| [a[0].to_f,a[1].to_f,a[2].to_f] };arr[replace]=[hit.x,hit.y,hit.z]
        kept=numeric_point(arr[replace==0 ? 1 : -2]);toward=kept.vector_to(hit);toward.normalize!
        [arr,replace,toward,hit,kept]
      end
      def trim_extend(ref,ref_local,target,target_local)
        WallJunctions.commit(ref,ref_local,target,target_local,'butt',0)
      end
      def align_faces(target,target_point,target_normal,ref_point,ref_normal)
        desired=target_normal.dot(ref_normal)>=0 ? ref_normal : ref_normal.reverse
        axis=target_normal.cross(desired);angle=target_normal.angle_between(desired);rot=angle<1e-8 ? Geom::Transformation.new : Geom::Transformation.rotation(target_point,axis,angle)
        moved=target_point.transform(rot);delta=ref_normal.dot(moved.vector_to(ref_point));tr=Geom::Transformation.translation(ref_normal.clone.tap { |v| v.length=delta })*rot
        Transactions.run('Align face to face') { target.transformation=tr*target.transformation };true
      end
    end
  end
end
