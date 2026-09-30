# frozen_string_literal: true
module Draupr
  module Core
    # One coordinate contract for all tools:
    # entity local -> active edit context -> model/world.
    module Transforms
      module_function
      def model; Sketchup.active_model; end
      def active_to_world; model.edit_transform; end
      def world_to_active; active_to_world.inverse; end
      def point_to_world(point); point.transform(active_to_world); end
      def point_to_active(point); point.transform(world_to_active); end
      def vector_to_world(vector)
        result=vector.transform(active_to_world);result.normalize! if result.length>1e-12;result
      end
      def vector_to_active(vector)
        result=vector.transform(world_to_active);result.normalize! if result.length>1e-12;result
      end
      def entity_to_world(entity)
        parent=Geometry.parent_entities(entity)
        parent.equal?(model.active_entities) ? active_to_world*entity.transformation : entity.transformation
      end
      def world_to_entity(entity);entity_to_world(entity).inverse;end
      def local_point_to_world(entity,point);point.transform(entity_to_world(entity));end
      def world_point_to_local(entity,point);point.transform(world_to_entity(entity));end
      def local_vector_to_world(entity,vector)
        result=vector.transform(entity_to_world(entity));result.normalize! if result.length>1e-12;result
      end
    end
  end
end
