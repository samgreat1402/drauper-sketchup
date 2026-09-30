# frozen_string_literal: true
module Draupr
  module Core
    module RailingPresets
      DATA = {
        'modern_vertical_slim' => {'family' => 'vertical', 'count' => 14, 'gauge' => 0.65},
        'modern_vertical_bold' => {'family' => 'vertical', 'count' => 8, 'gauge' => 1.3},
        'modern_horizontal_5' => {'family' => 'horizontal', 'rails' => 5, 'gauge' => 1.0},
        'modern_horizontal_8' => {'family' => 'horizontal', 'rails' => 8, 'gauge' => 0.65},
        'modern_cable' => {'family' => 'horizontal', 'rails' => 10, 'gauge' => 0.35},
        'modern_glass_frameless' => {'family' => 'glass_frameless'},
        'modern_glass_posts' => {'family' => 'glass_posts', 'count' => 3},
        'modern_grid' => {'family' => 'grid', 'count' => 8, 'rails' => 4, 'gauge' => 0.65},
        'modern_cross' => {'family' => 'cross', 'count' => 3, 'gauge' => 1.0},
        'modern_diamond' => {'family' => 'diamond', 'count' => 5, 'gauge' => 0.65},
        'classic_square' => {'family' => 'vertical', 'count' => 9, 'gauge' => 1.25},
        'classic_turned' => {'family' => 'baluster', 'count' => 9, 'gauge' => 0.8},
        'classic_double' => {'family' => 'double', 'count' => 5, 'gauge' => 0.7},
        'classic_arch' => {'family' => 'arch', 'count' => 7, 'gauge' => 0.75},
        'classic_scroll' => {'family' => 'scroll', 'count' => 6, 'gauge' => 0.65},
        'classic_greek' => {'family' => 'greek', 'count' => 5, 'gauge' => 0.75},
        'classic_spear' => {'family' => 'spear', 'count' => 10, 'gauge' => 0.75},
        'classic_ring' => {'family' => 'ring', 'count' => 8, 'gauge' => 0.7},
        'classic_cross_circle' => {'family' => 'cross_circle', 'count' => 4, 'gauge' => 0.7},
        'classic_diamond' => {'family' => 'ornate', 'count' => 7, 'gauge' => 0.75},
      }.freeze
      module_function
      def fetch(id);DATA[id.to_s];end
    end
  end
end
