# frozen_string_literal: true

module Draupr
  module Core
    module Materials
      # name, fallback RGBA, optional texture file + real-world size
      PALETTE = {
        wall_default: ['Draupr Wall - Warm Concrete', [190, 185, 176, 255]],
        wall_finish: ['Draupr Finish - Soft Plaster', [235, 232, 226, 255]],
        roof_shingle: ['Draupr Roofing - Charcoal Shingle', [72, 68, 62, 255]],
        door_leaf: ['Draupr Door - Walnut', [150, 100, 62, 255]],
        glass_clear: ['Draupr Glass - Clear Blue', [130, 190, 230, 70]],
        glass_tinted: ['Draupr Glass - Tinted Grey', [70, 90, 105, 85]],
        mullion_dark: ['Draupr Mullion - Graphite', [45, 48, 52, 255]],
        trim_light: ['Draupr Trim - Warm White', [224, 222, 214, 255]],
        siding_light: ['Draupr Siding - Warm White', [226, 225, 219, 255]],
        steel: ['Draupr Steel - Satin', [100, 105, 110, 255]],
        timber: ['Draupr Timber - Oak', [184, 126, 70, 255]],
        concrete: ['Draupr Concrete - Structural', [155, 153, 148, 255]],
        foundation: ['Draupr Foundation - Concrete', [132, 130, 126, 255]],
        opening: ['Draupr Opening Marker', [230, 150, 80, 120]],
        brick: ['Draupr Masonry - Brick', [166, 94, 80, 255]],
        insulation: ['Draupr Insulation - Mineral Wool', [240, 220, 130, 255]]
      }.freeze

      # texture file name + physical size the image spans
      TEXTURES = {
        brick: ['draupr_brick.png', 400.mm],
        concrete: ['draupr_concrete.png', 500.mm],
        timber: ['draupr_timber.png', 300.mm],
        wall_finish: ['draupr_plaster.png', 400.mm],
        siding_light: ['draupr_siding_white.png', 600.mm],
        roof_shingle: ['draupr_roof_shingle.png', 600.mm]
      }.freeze

      def self.fetch(key)
        name, rgba = PALETTE[key] || PALETTE[:wall_default]
        mats = Sketchup.active_model.materials
        mat = mats[name] || mats.add(name)
        # Only style the material on first creation, so user edits survive.
        if mat.get_attribute('Draupr', 'palette_initialized') != true
          unless apply_texture(mat, key)
            mat.color = Sketchup::Color.new(*rgba)
            mat.alpha = rgba[3].to_f / 255.0
          end
          mat.set_attribute('Draupr', 'palette_initialized', true)
        end
        mat
      end

      def self.apply_texture(mat, key)
        entry = TEXTURES[key]
        return false unless entry
        path = File.join(Draupr::SRC, 'assets', 'textures', entry[0])
        return false unless File.exist?(path)
        mat.texture = path
        mat.texture.size = [entry[1], entry[1]] if mat.texture
        true
      rescue
        false
      end

      # Resolve a display name back to its palette entry so selecting e.g.
      # "Draupr Glass - Tinted Grey" actually creates the tinted material
      # instead of silently falling back to the default.
      def self.by_name_or_default(name, fallback_key)
        return fetch(fallback_key) if name.nil? || name.to_s.strip.empty?
        key = palette_key_for_name(name)
        return fetch(key) if key
        mats = Sketchup.active_model.materials
        mats[name] || fetch(fallback_key)
      end

      def self.palette_key_for_name(name)
        PALETTE.each do |key, (mat_name, _rgba)|
          return key if mat_name == name.to_s
        end
        nil
      end

      # All palette display names, for the UI.
      def self.names
        PALETTE.values.map(&:first)
      end
    end
  end
end
