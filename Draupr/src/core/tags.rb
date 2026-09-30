# frozen_string_literal: true

module Draupr
  module Core
    module Tags
      NAMES = {
        walls: 'Draupr_Walls', curtain_frames: 'Draupr_CurtainFrames', glass: 'Draupr_Glass', panels: 'Draupr_Panels',
        openings: 'Draupr_Openings', stairs: 'Draupr_Stairs', roofs: 'Draupr_Roofs', framing: 'Draupr_Framing',
        columns: 'Draupr_Columns', beams: 'Draupr_Beams', foundations: 'Draupr_Foundations', slabs: 'Draupr_Slabs',
        documentation: 'Draupr_Documentation'
      }.freeze

      FOLDER = 'Draupr'
      @folder_by_model = {}

      def self.fetch(key)
        name = NAMES[key] || key.to_s
        layers = Sketchup.active_model.layers
        layer = layers[name] || layers.add(name)
        folderize(layer)
        layer
      end

      # Group all Draupr tags under one tag folder (SketchUp 2021+);
      # silently skipped on older versions.
      def self.folderize(layer)
        layers = Sketchup.active_model.layers
        return unless layers.respond_to?(:add_folder)
        key = Sketchup.active_model.guid
        folder = @folder_by_model[key]
        unless folder && folder.valid?
          folder = layers.add_folder(FOLDER)
          @folder_by_model[key] = folder
        end
        folder.add_layer(layer) if folder.respond_to?(:add_layer)
      rescue
        nil
      end

      def self.assign(entity, key)
        entity.layer = fetch(key) if entity.respond_to?(:layer=)
      end
    end
  end
end
