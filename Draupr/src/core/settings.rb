# frozen_string_literal: true

module Draupr
  module Core
    module Settings
      DEFAULTS = {
        wall_height: 3000.mm,
        wall_thickness: 200.mm,
        wall_alignment: 'center',
        wall_assembly: 'custom',
        cavity_width: 60.mm,
        mullion_width: 80.mm,
        mullion_depth: 120.mm,
        curtain_grid_x: 1200.mm,
        curtain_grid_y: 1000.mm,
        glass_thickness: 12.mm,
        column_width: 400.mm,
        foundation_height: 400.mm
      }.freeze

      def self.get(key)
        Sketchup.active_model.get_attribute('Draupr_Settings', key.to_s, DEFAULTS[key])
      end

      def self.set(key, value)
        Sketchup.active_model.set_attribute('Draupr_Settings', key.to_s, value)
      end
    end
  end
end
