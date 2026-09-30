# frozen_string_literal: true

module Draupr
  module Core
    module Geometry
      Z_AXIS = Geom::Vector3d.new(0, 0, 1)

      def self.parse_length(value, fallback)
        return fallback if value.nil? || value.to_s.strip.empty?
        value.is_a?(Numeric) ? value.to_l : value.to_s.to_l
      rescue
        fallback
      end

      # Parses user-typed text into a Length. Bare numbers without a unit
      # suffix are interpreted in the model's display unit (like SketchUp's
      # own measurements box) instead of raw inches.
      def self.parse_user_length(value, fallback = nil)
        return fallback if value.nil?
        return value.to_l if value.is_a?(Numeric)
        s = value.to_s.strip
        return fallback if s.empty?
        if s =~ /\A[-+]?[\d\.,]+\z/
          s = s.tr(',', '.')
          s = "#{s}#{model_unit_suffix}"
        end
        s.to_l
      rescue
        fallback
      end

      # Guesses the model's length display unit suffix (mm/cm/m/inch) by
      # formatting a probe length and reading its unit marker.
      def self.model_unit_suffix
        f = Sketchup.format_length(600.0).to_s.downcase
        return 'mm' if f.include?('mm')
        return 'cm' if f.include?('cm')
        return 'm' if f.end_with?('m')
        '"'
      rescue
        'mm'
      end

      # Offset range [off0, off1] of a wall cross-section relative to its
      # centerline, following the historical Draupr convention.
      def self.alignment_offsets(thickness, alignment)
        t = thickness.to_f
        case alignment.to_s
        when 'inside'  then [0.0, t]
        when 'outside' then [-t, 0.0]
        else [-t / 2.0, t / 2.0]
        end
      end

      # Builds one base polygon per wall segment with miter-joined ends, so
      # adjoining segments share exact corner edges instead of overlapping
      # or leaving wedges at corners.
      # points: array of Point3d (or arrays), off0/off1: offset distances
      # along the wall normal, closed: join last segment back to first.
      def self.wall_path_polygons(points, off0, off1, closed)
        pts = points.map { |p| p.is_a?(Geom::Point3d) ? p : Geom::Point3d.new(p) }
        seg_count = closed ? pts.length : pts.length - 1
        return [] if seg_count < 1
        segs = []
        (0...seg_count).each do |i|
          a = pts[i]
          b = pts[(i + 1) % pts.length]
          dir = a.vector_to(b)
          raise 'Wall length is zero' if dir.length <= 0.001
          dir.normalize!
          normal = dir.cross(Z_AXIS)
          raise 'Wall path must not be vertical' if normal.length <= 0.0001
          normal.length = 1
          segs << {
            a: a, b: b, n: normal,
            l0: [a.offset(normal, off0), dir],
            l1: [a.offset(normal, off1), dir]
          }
        end
        max_miter = (off1 - off0).abs * 10.0
        polys = []
        segs.each_with_index do |s, i|
          prev = i > 0 ? segs[i - 1] : (closed ? segs[seg_count - 1] : nil)
          nxt  = i < seg_count - 1 ? segs[i + 1] : (closed ? segs[0] : nil)
          if prev
            s0 = miter_point(prev[:l0], s[:l0], s[:a].offset(s[:n], off0), s[:a], max_miter)
            s1 = miter_point(prev[:l1], s[:l1], s[:a].offset(s[:n], off1), s[:a], max_miter)
          else
            s0 = s[:a].offset(s[:n], off0)
            s1 = s[:a].offset(s[:n], off1)
          end
          if nxt
            e0 = miter_point(s[:l0], nxt[:l0], s[:b].offset(s[:n], off0), s[:b], max_miter)
            e1 = miter_point(s[:l1], nxt[:l1], s[:b].offset(s[:n], off1), s[:b], max_miter)
          else
            e0 = s[:b].offset(s[:n], off0)
            e1 = s[:b].offset(s[:n], off1)
          end
          polys << [s0, e0, e1, s1]
        end
        polys
      end

      # Intersection of two offset lines; falls back to the plain offset
      # point when lines are parallel or the miter spike is extreme.
      def self.miter_point(line_a, line_b, fallback, vertex, max_dist)
        pt = Geom.intersect_line_line(line_a, line_b)
        return fallback unless pt
        return fallback if pt.distance(vertex) > max_dist
        pt
      end

      def self.midpoint(a, b)
        Geom::Point3d.new((a.x + b.x) / 2.0, (a.y + b.y) / 2.0, (a.z + b.z) / 2.0)
      end

      # Kept for API compatibility; now routed through the mitered builder.
      def self.wall_corners(p1, p2, thickness, alignment = 'center')
        off0, off1 = alignment_offsets(thickness, alignment)
        wall_path_polygons([p1, p2], off0, off1, false).first
      end

      def self.add_prism(parent_entities, base_points, height, material = nil)
        face = parent_entities.add_face(base_points)
        return nil unless face
        face.reverse! if face.normal.z < 0
        if material
          face.material = material
          face.back_material = material
        end
        face.pushpull(height)
        parent_entities.each { |e| e.layer = Sketchup.active_model.layers[0] if e.is_a?(Sketchup::Face) || e.is_a?(Sketchup::Edge) }
        face
      end

      def self.add_box(parent_entities, origin, width, depth, height, material = nil)
        pts = [origin,
               origin.offset(X_AXIS, width),
               origin.offset(X_AXIS, width).offset(Y_AXIS, depth),
               origin.offset(Y_AXIS, depth)]
        add_prism(parent_entities, pts, height, material)
      end

      def self.add_cylinder(parent_entities, origin, radius, height, sides = 32, material = nil)
        circle = parent_entities.add_circle(origin, Z_AXIS, radius, sides)
        face = parent_entities.add_face(circle)
        return nil unless face
        face.reverse! if face.normal.z < 0
        if material
          face.material = material
          face.back_material = material
        end
        face.pushpull(height)
        parent_entities.each { |e| e.layer = Sketchup.active_model.layers[0] if e.is_a?(Sketchup::Face) || e.is_a?(Sketchup::Edge) }
        face
      end

      def self.with_entities(entities)
        old = @build_entities
        @build_entities = entities
        yield
      ensure
        @build_entities = old
      end
      def self.parent_entities(entity)
        p = entity.parent
        p.is_a?(Sketchup::Entities) ? p : p.entities
      end
      def self.group(name, tag_key = nil)
        group = (@build_entities || Sketchup.active_model.active_entities).add_group
        group.name = name
        Tags.assign(group, tag_key) if tag_key
        group
      end
    end
  end
end
