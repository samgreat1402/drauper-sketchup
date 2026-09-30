# frozen_string_literal: true

module Draupr
  module Tools
    module Walls
      # Analytical wall carving v2 — segment-aware and crash-hardened.
      #
      # A wall group carries one or more SEGMENTS (a single straight run, or
      # several for walls merged by older versions). Each segment has its own
      # centerline, height, and base quads (layers). Openings carry an
      # optional 'seg' index selecting the segment they belong to (default 0).
      #
      # NO SketchUp boolean operations are used anywhere: pieces are fresh
      # faces + pushpull, with every dimension guarded well above SketchUp's
      # ~0.001" geometry tolerance so the kernel never receives slivers.
      module Carve
        MIN_DIM = 0.5.mm   # minimum piece edge / height
        MIN_AREA = 0.0008  # square inches (~0.5 mm2)

        module_function

        def apply(wall, openings)
          data = Core::Metadata.read(wall)
          segs = segments_from(data)
          if segs.empty?
            Core::Diag.log("carve.apply FAILED: no segments. keys=#{data.keys.sort.join(',')} merged=#{data['merged'].inspect} x1=#{data['x1'].inspect} layers_bytes=#{data['layers'].to_s.length} corners=#{data['corners'].inspect[0, 80]}")
            return nil
          end

          ents = wall.parent.entities
          new_group = ents.add_group
          net_vol = 0.0
          total_len = 0.0
          open_area = 0.0
          segs.each_with_index do |seg, si|
            seg_ops = openings.select { |o| (o['seg'] || 0) == si }
            total_len += seg[:len]
            open_area += seg_ops.inject(0.0) { |s, o| s + ([o['t2'] - o['t1'], 0].max * [o['z1'] - o['z0'], 0].max) }
            seg[:layers].each do |layer|
              mat = Core::Materials.by_name_or_default(layer['m'], :wall_default)
              net_vol += build_pieces(new_group.entities, layer['quad'], seg[:cs], seg[:dir],
                                      seg[:base_z], seg[:height], seg_ops, mat)
            end
          end
          Core::Diag.log("carve.apply: segs=#{segs.length} openings=#{openings.length} net_vol_in3=#{net_vol.round(1)}")

          name = wall.name
          tag = wall.layer
          new_group.name = name.to_s.empty? ? 'Draupr Wall' : name
          new_group.layer = tag if tag

          attrs = {}
          data.each { |k, v| attrs[k] = v }
          attrs['openings'] = JSON.generate(openings.map do |o|
            { 't1' => o['t1'].to_f, 't2' => o['t2'].to_f, 'z0' => o['z0'].to_f,
              'z1' => o['z1'].to_f, 'seg' => (o['seg'] || 0).to_i }
          end)
          attrs['volume_m3'] = (net_vol * 0.000016387064).round(3)
          height_in = (data['height_mm'] || 3000).to_f.mm
          attrs['area_m2'] = (((total_len * height_in) - open_area) * 0.00064516).round(3)
          attrs['carved'] = !openings.empty?
          first = segs.first
          attrs['x1'] = first[:cs].x
          attrs['y1'] = first[:cs].y
          attrs['z1'] = first[:cs].z
          attrs['x2'] = first[:ce].x
          attrs['y2'] = first[:ce].y
          attrs['z2'] = first[:ce].z
          attrs['length_mm'] = total_len.to_mm.round(2)
          wall.erase!
          Core::Metadata.write(new_group, attrs)
          new_group
        rescue => e
          Core::Diag.log_error('carve.apply', e)
          puts("Draupr carve failed: #{e.message}")
          new_group.erase! if new_group && new_group.valid?
          nil
        end

        # Returns the wall to its pristine state (closes all openings).
        def heal(wall)
          apply(wall, [])
        end

        # ---- segments ------------------------------------------------------

        def segments_from(data)
          raw = data['segments']
          if data['merged'] && raw.is_a?(String) && !raw.empty?
            parsed = JSON.parse(raw) rescue []
            segs = parsed.map { |s| segment_from_hash(s, data['material']) }.compact
            return segs unless segs.empty?
          end
          layers = layers_from(data)
          return [] if layers.empty? || !data['x1'] || !data['x2']
          cs = Geom::Point3d.new(data['x1'], data['y1'], data['z1'])
          ce = Geom::Point3d.new(data['x2'], data['y2'], data['z2'])
          seg = segment_from_points(cs, ce, (data['height_mm'] || 3000).to_f, layers)
          seg ? [seg] : []
        end

        def segment_from_hash(s, material)
          return nil unless s['x1'] && s['x2']
          coords = [s['x1'], s['y1'], s['z1'], s['x2'], s['y2'], s['z2']].map { |v| coord_num(v) }
          return nil if coords.any?(&:nil?)
          cs = Geom::Point3d.new(coords[0], coords[1], coords[2])
          ce = Geom::Point3d.new(coords[3], coords[4], coords[5])
          dir = cs.vector_to(ce)
          return nil if dir.length <= 0.001
          dir.normalize!
          n = dir.cross(Geom::Vector3d.new(0, 0, 1))
          n.length = 1
          half = (s['t'] || 200).to_f.mm / 2.0
          quad = [cs.offset(n, -half), ce.offset(n, -half), ce.offset(n, half), cs.offset(n, half)]
          { cs: cs, ce: ce, dir: dir, len: cs.distance(ce), base_z: cs.z,
            height: (s['h'] || 3000).to_f.mm, layers: [{ 'quad' => quad, 'm' => material }] }
        end

        def segment_from_points(cs, ce, height_mm, layers)
          dir = cs.vector_to(ce)
          len = dir.length
          return nil if len <= 0.001
          dir.normalize!
          { cs: cs, ce: ce, dir: dir, len: len, base_z: cs.z, height: height_mm.mm, layers: layers }
        end

        # Coordinates may arrive as Strings from metadata written by older
        # builds (JSON serialized SketchUp Lengths as unit text like "250mm").
        # String#to_l parses them back WITH their unit, so scale survives.
        def coord_num(v)
          return v.to_f if v.is_a?(Numeric)
          return nil unless v.is_a?(String)
          v.to_l.to_f
        rescue
          nil
        end

        def layers_from(data)
          raw = data['layers']
          if raw.is_a?(String) && !raw.empty?
            parsed = JSON.parse(raw) rescue []
            layers = parsed.map do |l|
              nums = (l['c'] || []).map { |v| coord_num(v) }
              next nil if nums.any?(&:nil?)
              quad = nums.each_slice(3).map { |x, y, z| Geom::Point3d.new(x, y, z) }
              quad.length >= 3 ? { 'quad' => quad, 'm' => l['m'] } : nil
            end.compact
            return layers unless layers.empty?
          end
          fallback_layer(data)
        end

        # Walls from older builds have no stored corners: synthesize the
        # rectangle from centerline + thickness (mitered ends become square).
        def fallback_layer(data)
          return [] unless data['x1'] && data['x2']
          cs = Geom::Point3d.new(data['x1'], data['y1'], data['z1'])
          ce = Geom::Point3d.new(data['x2'], data['y2'], data['z2'])
          dir = cs.vector_to(ce)
          return [] if dir.length <= 0.001
          dir.normalize!
          n = dir.cross(Geom::Vector3d.new(0, 0, 1))
          n.length = 1
          half = (data['thickness_mm'] || 200).to_f.mm / 2.0
          quad = [cs.offset(n, -half), ce.offset(n, -half), ce.offset(n, half), cs.offset(n, half)]
          [{ 'quad' => quad, 'm' => data['material'] }]
        end

        # ---- piece building ------------------------------------------------

        def build_pieces(ents, quad, cs, dir, base_z, height, openings, mat)
          ts = quad.map { |p| cs.vector_to(p).dot(dir) }
          t_min = ts.min
          t_max = ts.max
          vol = 0.0
          solid_intervals(openings, t_min, t_max).each do |a, b|
            vol += extrude(ents, clip_range(quad, cs, dir, a, b), base_z, height, mat)
          end
          openings.each do |o|
            next if o['t2'] - o['t1'] <= MIN_DIM
            if o['z0'] > MIN_DIM
              vol += extrude(ents, clip_range(quad, cs, dir, o['t1'], o['t2']), base_z, o['z0'], mat)
            end
            if o['z1'] < height - MIN_DIM
              vol += extrude(ents, clip_range(quad, cs, dir, o['t1'], o['t2']), base_z + o['z1'], height - o['z1'], mat)
            end
          end
          vol
        end

        def solid_intervals(openings, t_min, t_max)
          cuts = openings.select { |o| o['t2'] - o['t1'] > MIN_DIM }.sort_by { |o| o['t1'] }
          intervals = []
          cur = t_min
          cuts.each do |o|
            a = clamp(o['t1'], t_min, t_max)
            b = clamp(o['t2'], t_min, t_max)
            next if b <= a
            intervals << [cur, a] if a - cur > MIN_DIM
            cur = [cur, b].max
          end
          intervals << [cur, t_max] if t_max - cur > MIN_DIM
          intervals
        end

        def clamp(v, lo, hi)
          [[v, lo].max, hi].min
        end

        def clip_range(quad, cs, dir, a, b)
          left = clip_halfplane(quad, cs.offset(dir, a), dir, true)
          clip_halfplane(left, cs.offset(dir, b), dir, false)
        end

        def clip_halfplane(points, cut_point, dir, keep_positive)
          out = []
          points.each_with_index do |a, i|
            bpt = points[(i + 1) % points.length]
            da = cut_point.vector_to(a).dot(dir)
            db = cut_point.vector_to(bpt).dot(dir)
            ina = keep_positive ? da >= 0 : da <= 0
            inb = keep_positive ? db >= 0 : db <= 0
            out << a if ina
            if ina != inb
              den = da - db
              next if den.abs < 1e-12
              t = da / den
              out << Geom::Point3d.new(a.x + (bpt.x - a.x) * t,
                                       a.y + (bpt.y - a.y) * t,
                                       a.z + (bpt.z - a.z) * t)
            end
          end
          out
        end

        def extrude(ents, quad, z_base, height, mat)
          return 0.0 if quad.nil? || quad.length < 3 || height <= MIN_DIM
          unless valid_quad?(quad)
            Core::Diag.log("carve: sliver piece skipped (#{quad.length} pts, area=#{polygon_area(quad).round(5)})")
            return 0.0
          end
          pts = quad.map { |p| Geom::Point3d.new(p.x, p.y, z_base) }
          Core::Geometry.add_prism(ents, pts, height, mat)
          polygon_area(quad) * height
        rescue => e
          Core::Diag.log_error('carve piece', e)
          puts("Draupr: carve piece skipped (#{e.message})")
          0.0
        end

        # Sliver guard: any edge under MIN_DIM or area under MIN_AREA would
        # risk SketchUp's geometry tolerance — skip such pieces instead of
        # handing the kernel geometry it can crash on.
        def valid_quad?(quad)
          return false if quad.any? { |p| !p.x.finite? || !p.y.finite? || !p.z.finite? }
          quad.each_with_index do |p, i|
            q = quad[(i + 1) % quad.length]
            return false if p.distance(q) < MIN_DIM
          end
          polygon_area(quad) > MIN_AREA
        end

        def polygon_area(quad)
          s = 0.0
          quad.each_with_index do |p, i|
            q = quad[(i + 1) % quad.length]
            s += (p.x * q.y) - (q.x * p.y)
          end
          s.abs / 2.0
        end
      end
    end
  end
end
