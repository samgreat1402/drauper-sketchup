# frozen_string_literal: true
module Draupr
  module Core
    module Walls
      module_function
      def cross2(a,b);a[0]*b[1]-a[1]*b[0];end
      def hull(points)
        ps=points.map { |p| [p.x.to_f,p.y.to_f,p.z.to_f] }.uniq.sort_by { |p| [p[0],p[1]] };return ps if ps.length<3
        half=lambda do |list|
          out=[]
          list.each do |p|
            while out.length>=2
              a=out[-2];b=out[-1];turn=(b[0]-a[0])*(p[1]-b[1])-(b[1]-a[1])*(p[0]-b[0]);break if turn>1e-9;out.pop
            end;out<<p
          end;out
        end
        half.call(ps)[0...-1]+half.call(ps.reverse)[0...-1]
      end
      def inside2?(p,poly)
        inside=false
        poly.each_with_index do |a,i|
          b=poly[(i+1)%poly.length]
          if (a[1]>p.y)!=(b[1]>p.y)
            x=(b[0]-a[0])*(p.y-a[1])/(b[1]-a[1])+a[0];inside=!inside if p.x<x
          end
        end;inside
      end
      def with_end_trims(p,tr,entities)
        return p if p['closed'] || !p['path_points'] || p['path_points'].length<2
        paths=p['path_points'].map { |a| point(a) };trims=[]
        ends=[[paths[1],paths[0],0],[paths[-2],paths[-1],paths.length-2]]
        ends.each do |a,b,index|
          hits=[]
          entities.grep(Sketchup::Group).select { |g| Objects.valid?(g) && Metadata.read(g)['type']=='wall' }.each do |host|
            transform=tr.inverse*host.transformation
            next unless transform.zaxis.parallel?(Z_AXIS)
            segments(host).each do |s|
              poly=hull(s['layers'].flat_map { |l| l['quad'].map { |q| point(q).transform(transform) } })
              next if poly.length<3 || b.z<poly[0][2]-EPS || b.z>poly[0][2]+s['height']*transform.zaxis.length+EPS
              next unless inside2?(b,poly) && !inside2?(a,poly)
              r=[b.x-a.x,b.y-a.y]
              poly.each_with_index do |c,i|
                d=poly[(i+1)%poly.length];edge=[d[0]-c[0],d[1]-c[1]];den=cross2(r,edge);next if den.abs<1e-12
                v=[c[0]-a.x,c[1]-a.y];t=cross2(v,edge)/den;u=cross2(v,r)/den
                next unless t>0 && t<1 && u>=0 && u<=1
                normal=[-edge[1],edge[0],0.0];positive=(a.x-c[0])*normal[0]+(a.y-c[1])*normal[1]>=0
                hits<<[t,{'seg'=>index,'point'=>c,'normal'=>normal,'positive'=>positive}]
              end
            end
          end
          trims<<hits.min_by(&:first)[1] unless hits.empty?
        end
        p.merge('end_trims'=>trims)
      end
      def trim_segments(segs,trims)
        trims.each do |cut|
          s=segs[cut['seg']];next unless s
          plane=point(cut['point']);normal=Geom::Vector3d.new(cut['normal']);normal.normalize!
          s['layers'].each do |layer|
            q=clip(layer['quad'].map { |a| point(a) },plane,normal,cut['positive'])
            raise 'A wall endpoint is entirely inside another wall. Move the start/end outside that wall.' if q.length<3
            layer['quad']=q.map { |a| xyz(a) }
          end
        end;segs
      end
    end
  end
end
