# frozen_string_literal: true

module Draupr
  module Core
    module Parts
      DICT='Draupr_Part'
      module_function
      def make(entities,role,key,material=nil)
        g=entities.add_group
        g.name=key.to_s.tr('_',' '); g.layer=Sketchup.active_model.layers[0]
        g.set_attribute(DICT,'role',role.to_s)
        g.set_attribute(DICT,'key',key.to_s)
        g.material=material if material
        g
      end
      def material_for(p,key,fallback)
        Materials.by_name_or_default(p[key],fallback)
      end
      def box(entities,role,key,origin,w,d,h,material)
        raise ArgumentError,'Invalid part dimensions' unless [w,d,h].all? { |v| v.to_f.finite? && v.to_f>0 }
        g=make(entities,role,key,material)
        face=Geometry.add_box(g.entities,origin,w,d,h,nil)
        raise 'SketchUp could not create the part' unless face
        g
      end
      def cylinder(entities,role,key,origin,r,h,material,sides=24)
        g=make(entities,role,key,material)
        face=Geometry.add_cylinder(g.entities,origin,r,h,sides,nil)
        raise 'SketchUp could not create the cylinder' unless face
        g
      end
      def each(entities,&block)
        entities.each do |e|
          yield e if e.respond_to?(:get_attribute) && e.get_attribute(DICT,'role')
          each(e.entities,&block) if e.is_a?(Sketchup::Group)
        end
      end
      def independent_tree(group)
        group.make_unique if group.definition.instances.length>1
        group.entities.grep(Sketchup::Group).each { |child| independent_tree(child) }
      end
      def clear_faces(entities)
        entities.each do |e|
          if e.is_a?(Sketchup::Face)
            e.material=nil;e.back_material=nil
          elsif e.is_a?(Sketchup::Group)
            e.material=nil;clear_faces(e.entities)
          end
        end
      end
      def assign(entity,material,texture_angle=nil)
        if entity.is_a?(Sketchup::Face)
          entity.material=material;entity.back_material=material
          map_texture(entity,material,texture_angle.to_f) if material && material.texture
        elsif entity.is_a?(Sketchup::Group)
          clear_faces(entity.entities)
          entity.material=material
          map_all_faces(entity.entities,material,texture_angle.to_f) if material && material.texture && !texture_angle.nil?
        end
      end
      def map_all_faces(entities,material,angle)
        entities.each do |e|
          if e.is_a?(Sketchup::Face)
            map_texture(e,material,angle)
          elsif e.is_a?(Sketchup::Group)
            map_all_faces(e.entities,material,angle)
          end
        end
      end
      def map_texture(face,material,angle=0)
        return unless material.texture
        normal=face.normal
        axis=normal.parallel?(Z_AXIS) ? X_AXIS : Z_AXIS.cross(normal)
        axis.normalize!
        v=normal.cross(axis);v.normalize!
        a=angle*Math::PI/180
        u=Geom::Vector3d.new(axis.x*Math.cos(a)+v.x*Math.sin(a),axis.y*Math.cos(a)+v.y*Math.sin(a),axis.z*Math.cos(a)+v.z*Math.sin(a))
        v2=normal.cross(u);v2.normalize!
        origin=face.vertices.first.position
        w=material.texture.width.to_f;h=material.texture.height.to_f
        return if w<=0 || h<=0
        mapping=[origin,Geom::Point3d.new(0,0,0),origin.offset(u,w),Geom::Point3d.new(1,0,0),origin.offset(v2,h),Geom::Point3d.new(0,1,0)]
        face.position_material(material,mapping,true)
        face.position_material(material,mapping,false)
      rescue StandardError => e
        Diag.log_error('Texture mapping',e)
      end
      def snapshot(group)
        result={}
        each(group.entities) do |part|
          k=part.get_attribute(DICT,'key')
          mat=part.material if part.respond_to?(:material)
          result[k]={'material'=>mat.name} if mat
        end
        result
      end
      def apply_overrides(group,overrides)
        each(group.entities) do |part|
          o=overrides[part.get_attribute(DICT,'key')]
          next unless o && o['material']
          mat=Materials.find(o['material'])
          raise "Missing material: #{o['material']}" unless mat
          assign(part,mat,o['angle'])
        end
      end
      def list(group)
        seen={}
        each(group.entities) do |part|
          key=part.get_attribute(DICT,'key');role=part.get_attribute(DICT,'role')
          next if seen[key]
          seen[key]={'key'=>key,'role'=>role,'name'=>part.respond_to?(:name) ? part.name : key,'material'=>part.material ? part.material.name : ''}
        end
        seen.values
      end
      def tag_face(face,role,key)
        face.layer=Sketchup.active_model.layers[0]
        face.edges.each { |e| e.layer=Sketchup.active_model.layers[0] }
        face.set_attribute(DICT,'role',role);face.set_attribute(DICT,'key',key)
      end
    end
  end
end
