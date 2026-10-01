# frozen_string_literal: true
module Draupr
  module Core
    module WallLengthSolver
      MIN_LENGTH=10.mm
      module_function
      def deep_copy(value);Marshal.load(Marshal.dump(value));end
      def point(value);Geom::Point3d.new(value.map(&:to_f));end
      def validate_wall!(wall)
        raise 'Select exactly one Draupr wall.' unless Objects.valid?(wall) && Metadata.read(wall)['type']=='wall'
        raise 'The selected wall is locked.' if wall.locked?
        axes=[wall.transformation.xaxis,wall.transformation.yaxis,wall.transformation.zaxis]
        raise 'Scaled walls must be reset before using editable dimensions.' unless axes.all? { |axis| (axis.length-1.0).abs<1e-6 }
        p=Objects.params(wall)
        raise 'Legacy walls must be redrawn before using editable dimensions.' unless wall.get_attribute('Draupr','params_json')
        raise 'Editable dimensions currently support straight two-point walls.' unless p['path_points'].is_a?(Array) && p['path_points'].length==2 && p['closed']!=true && p['path_curve']!=true
        segments=Walls.segments(wall)
        raise 'Editable dimensions currently support one straight wall segment.' unless segments.length==1
        a=point(segments.first['cs']);b=point(segments.first['ce'])
        raise 'The wall centerline is too short.' if a.distance(b)<MIN_LENGTH
        [p,a,b]
      end
      def moving_ends(anchor)
        case anchor.to_sym
        when :start then ['end']
        when :end then ['start']
        when :center then %w[start end]
        else raise 'Anchor must be start, end, or center.'
        end
      end
      def validate_junctions!(p,anchor)
        joins=p['wall_joins'].is_a?(Hash) ? p['wall_joins'] : {}
        blocked=moving_ends(anchor).select { |key| joins[key].is_a?(Hash) }
        return if blocked.empty?
        raise "The #{blocked.join(' and ')} wall endpoint is joined. Choose the opposite anchor or detach the junction first."
      end
      def host_offset_shift(anchor,old_length,new_length)
        delta=new_length-old_length
        anchor.to_sym==:end ? delta : (anchor.to_sym==:center ? delta/2.0 : 0.0)
      end
      def hosted_objects(wall)
        uid=Objects.id(wall)
        Objects.all.select do |object|
          record=Hosts.records(object).first
          record && record['id'].to_s==uid.to_s && %w[door window].include?(Metadata.read(object)['type'])
        end
      end
      def host_updates(wall,shift,new_length)
        hosted_objects(wall).map do |object|
          p=Objects.params(object);offset=p['host_offset'].to_f+shift;width=p['width'].to_f
          if offset < -Walls::EPS || offset+width > new_length+Walls::EPS
            raise "#{Metadata.read(object)['type'].capitalize} #{object.name.inspect} would fall outside the resized wall."
          end
          [object,p.merge('host_offset'=>offset)]
        end
      end
      def update_host_params!(updates)
        updates.each do |object,p|
          object.set_attribute('Draupr','params_json',JSON.generate(p))
          object.set_attribute('Draupr','host_offset_mm',p['host_offset'].to_f*25.4)
        end
      end
      def resized_points(a,b,new_length,anchor)
        direction=a.vector_to(b);direction.normalize!
        case anchor.to_sym
        when :start then [a,a.offset(direction,new_length)]
        when :end then [b.offset(direction,-new_length),b]
        when :center
          center=Geom::Point3d.new((a.x+b.x)/2.0,(a.y+b.y)/2.0,(a.z+b.z)/2.0)
          [center.offset(direction,-new_length/2.0),center.offset(direction,new_length/2.0)]
        end
      end
      def shifted_openings(wall,shift)
        Walls.holes(wall).map do |opening|
          q=deep_copy(opening);q['t1']=q['t1'].to_f+shift;q['t2']=q['t2'].to_f+shift;q
        end
      end
      def resize(wall,new_length,anchor=:start)
        new_length=new_length.to_f
        raise "Wall length must be at least #{Sketchup.format_length(MIN_LENGTH)}." if new_length<MIN_LENGTH
        p,a,b=validate_wall!(wall);anchor=anchor.to_sym;validate_junctions!(p,anchor)
        old_length=a.distance(b);return wall if (new_length-old_length).abs<0.01.mm
        shift=host_offset_shift(anchor,old_length,new_length)
        updates=host_updates(wall,shift,new_length);openings=shifted_openings(wall,shift)
        na,nb=resized_points(a,b,new_length,anchor)
        q=deep_copy(p);q['path_points']=[Walls.xyz(na),Walls.xyz(nb)];q['length']=new_length;q['openings']=openings
        moving_ends(anchor).each do |key|
          (q['wall_end_overrides']||{}).delete(key)
          segment=key=='start' ? 0 : q['path_points'].length-2
          q['end_trims']=(q['end_trims']||[]).reject { |cut| cut['seg'].to_i==segment }
        end
        Walls.check_holes(Walls.geometry(q),openings)
        uid=Objects.id(wall);result=nil
        Transactions.run('Resize Draupr wall by dimension') do
          update_host_params!(updates)
          result=ModifyTools.rebuild_wall(wall,q)
          result.set_attribute('Draupr','openings',JSON.generate(openings))
          Hosts.reposition_for_wall(result)
          selection=Sketchup.active_model.selection;selection.clear;selection.add(result)
        end
        Objects.get(uid)
      end
      def translate(wall,world_vector)
        p,a,b=validate_wall!(wall);validate_junctions!(p,:center)
        transform=Sketchup.active_model.edit_transform*wall.transformation
        inverse=transform.inverse
        world_a=a.transform(transform).offset(world_vector)
        world_b=b.transform(transform).offset(world_vector)
        na=world_a.transform(inverse);nb=world_b.transform(inverse)
        q=deep_copy(p);q['path_points']=[Walls.xyz(na),Walls.xyz(nb)];q['length']=na.distance(nb).to_f
        q['openings']=Walls.holes(wall)
        %w[wall_end_overrides end_trims].each { |key| q.delete(key) }
        uid=Objects.id(wall);result=nil
        Transactions.run('Move Draupr wall by dimension') do
          result=ModifyTools.rebuild_wall(wall,q)
          result.set_attribute('Draupr','openings',JSON.generate(q['openings']))
          Hosts.reposition_for_wall(result)
          selection=Sketchup.active_model.selection;selection.clear;selection.add(result)
        end
        Objects.get(uid)
      end
    end
  end
end