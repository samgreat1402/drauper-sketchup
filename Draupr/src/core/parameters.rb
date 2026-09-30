# frozen_string_literal: true

module Draupr
  module Core
    module Parameters
      SCHEMA = JSON.parse(File.read(File.join(Draupr::SRC, 'config', 'schema.json'), encoding: 'UTF-8')).freeze
      TOOLS = SCHEMA['tools'].each_with_object({}) { |t, h| h[t['id']] = t }.freeze
      class ValidationError < StandardError
        attr_reader :fields
        def initialize(fields)
          @fields = fields
          super(fields.values.join("\n"))
        end
      end
      module_function

      def tool(kind)
        TOOLS.fetch(kind.to_s) { raise ArgumentError, "Unsupported object: #{kind}" }
      end

      def canonical(kind)
        kind.to_s == 'curtain' ? 'curtain_wall' : kind.to_s
      end

      def normalize_digits(value)
        value.to_s.tr('۰۱۲۳۴۵۶۷۸۹٠١٢٣٤٥٦٧٨٩', '01234567890123456789').tr('٫', '.').strip
      end

      def length(value)
        return value.to_f if !value.is_a?(String) && value.respond_to?(:to_f)
        s = normalize_digits(value)
        raise ArgumentError, 'A length is required' if s.empty?
        if s.match?(/\A[+-]?(?:\d+(?:[.,]\d*)?|[.,]\d+)(?:e[+-]?\d+)?\z/i)
          factor={'mm'=>1.0/25.4,'cm'=>1.0/2.54,'m'=>1.0/0.0254,'"'=>1.0,"'"=>12.0,'yd'=>36.0}.fetch(unit_suffix)
          value=Float(s.tr(',', '.'))*factor
          raise ArgumentError,'Invalid length' unless value.finite?
          return value
        end
        result = s.to_l.to_f
        raise ArgumentError, 'Invalid length' unless result.finite?
        result
      rescue StandardError
        raise ArgumentError, "Invalid length: #{value}. Use a value such as 1200 mm, 1.2 m or 4'."
      end

      def coord(value)
        # Serialized geometry is always inches. Legacy unit-marked strings
        # must retain their explicit units; bare numeric strings are inches.
        if value.is_a?(String)
          s = normalize_digits(value)
          return Float(s) if s.match?(/\A[+-]?(?:\d+\.?\d*|\.\d+)(?:e[+-]?\d+)?\z/i)
          return s.sub(/\A~\s*/, '').to_l.to_f
        end
        v = value.to_f
        raise ArgumentError, 'Non-finite coordinate' unless v.finite?
        v
      end

      UNIT_SUFFIXES={'mm'=>'mm','cm'=>'cm','m'=>'m','in'=>'"','ft'=>"'"}.freeze
      def unit_suffix(requested=nil)
        requested=(requested || Preferences.get('units','mm')).to_s
        return UNIT_SUFFIXES.fetch(requested) unless requested=='model'
        unit=Sketchup.active_model.options['UnitsOptions']['LengthUnit']
        {0=>'"',1=>"'",2=>'mm',3=>'cm',4=>'m',5=>'yd'}.fetch(unit,'mm')
      rescue StandardError
        'mm'
      end

      def display_length(v,requested=nil)
        suffix=unit_suffix(requested)
        scale={'mm'=>25.4,'cm'=>2.54,'m'=>0.0254,'"'=>1.0,"'"=>1.0/12.0,'yd'=>1.0/36.0}.fetch(suffix,25.4)
        "#{format('%.4f',v.to_f*scale).sub(/\.?0+$/,'')} #{suffix}"
      end

      def visible?(field, p)
        (field['show'] || {}).all? { |k,v| p[k] == v } && (field['showNot'] || {}).all? { |k,v| p[k] != v }
      end

      def defaults(kind)
        normalize(kind, {}, {}, false)
      end

      def normalize(kind, raw = {}, base = {}, validate = true)
        raw = raw.transform_keys(&:to_s)
        p = base.dup
        errors = {}
        tool(kind)['fields'].each do |f|
          k = f['key']
          val = raw.key?(k) ? raw[k] : (base.key?(k) ? base[k] : f['default'])
          begin
            p[k] = case f['type']
                   when 'length' then length(val)
                   when 'number' then Float(normalize_digits(val))
                   when 'integer'
                     n = Float(normalize_digits(val))
                     raise ArgumentError, 'Use a whole number' unless n == n.floor
                     n.to_i
                   when 'boolean' then val == true || val.to_s == 'true'
                   else val.to_s.strip
                   end
          rescue StandardError => e
            errors[k] = "#{f['label']}: #{e.message}"
          end
        end
        tool(kind)['fields'].each do |f|
          k = f['key']; v = p[k]
          next unless visible?(f, p)
          if %w[length number integer].include?(f['type']) && v.is_a?(Numeric)
            min = f.fetch('min', -1_000_000).to_f
            max = f.fetch('max', 1_000_000).to_f
            measured = f['type']=='length' ? v * 25.4 : v
            errors[k] = "#{f['label']}: value must be between #{min} and #{max}#{f['type']=='length' ? ' mm' : ''}." if !v.finite? || measured < min || measured > max
          elsif f['type']=='select' && !f['options'].any? { |o| o['value']==v }
            errors[k] = "#{f['label']}: choose a listed option."
          elsif v.is_a?(String) && v.length > 250
            errors[k] = "#{f['label']}: maximum 250 characters."
          end
        end
        if validate
          cross_validate(kind, p, errors)
          raise ValidationError, errors unless errors.empty?
        end
        p
      end

      def cross_validate(kind, p, errors)
        case kind.to_s
        when 'wall'
          if p['wall_type']=='cavity'
            errors['cavity_width']='Cavity must leave at least 2 mm of material in each leaf.' if p['thickness'].to_f-p['cavity_width'].to_f <= 4.mm
          elsif p['assembly']!='custom'
            errors['thickness']='Overall thickness must exceed both finishes by at least 2 mm.' if p['thickness'].to_f-p['inner_thickness'].to_f-p['outer_thickness'].to_f <= 2.mm
          end
        when 'door','window'
          errors['frame']='Frame is too large for this opening.' if p['frame'].to_f*2+1.mm >= [p['width'].to_f,p['height'].to_f].min
          if kind.to_s=='window'
            clear = p['width'].to_f-(p['mullions'].to_i+2)*p['frame'].to_f
            errors['mullions']='Mullions leave no clear glass area.' if clear <= (p['mullions'].to_i+1)*1.mm
            errors['glass_thickness']='Glass must fit inside frame depth.' if p['glass_thickness'].to_f>p['depth'].to_f
          else
            errors['leaf_thickness']='Leaf thickness must fit inside frame depth.' if p['leaf_thickness'].to_f>p['depth'].to_f
          end
        when 'curtain_wall'
          nx,ny=curtain_counts(p)
          errors['grid_x']='This grid is limited to 1600 panels.' if nx*ny>1600
          errors['mullion_width']='Frame members leave no clear panels.' if p['width'].to_f/nx <= p['mullion_width'].to_f*2 || p['height'].to_f/ny<=p['transom_width'].to_f*2
          errors['glass_thickness']='Glass thickness must fit inside the frame.' if p['glass_thickness'].to_f > p['mullion_depth'].to_f
        when 'foundation'
          case p['foundation_type'].to_s
          when 'raft'
            errors['height'] = 'Slab thickness must be at least 100 mm.' if p['height'].to_f < 100.mm
          when 'strip'
            errors['width'] = 'Strip width must be at least 200 mm.' if p['width'].to_f < 200.mm
            errors['height'] = 'Strip depth must be at least 150 mm.' if p['height'].to_f < 150.mm
          end
        when 'stair'
          if p['sizing_mode']=='floor'
            desired=(p['floor_height'].to_f/[p['riser'].to_f,1.mm].max).round
            errors['floor_height']='Floor height and target riser must produce 2–150 risers.' unless desired.between?(2,150)
          end
          errors['landing_depth']='Landing depth must be at least the flight width.' if p['turn']=='L' && p['landing_depth'].to_f<p['width'].to_f
          errors['tread_thickness']='Tread finish must be thinner than the actual riser.' if p['tread_thickness'].to_f >= stair_values(p)[1]
        when 'ramp'
          errors['rise'] = 'Ramp rise must not exceed the run length (45° max).' if p['rise'].to_f > p['length'].to_f
        when 'louver'
          errors['blade_thickness']='Blade thickness exceeds the array spacing.' if p['blade_thickness'].to_f>=p['height'].to_f/[p['count'].to_i,1].max
        end
      end

      def curtain_counts(p)
        if p['grid_mode']=='count'
          [[p['count_x'].to_i,1].max,[p['count_y'].to_i,1].max]
        else
          [[(p['width'].to_f/[p['grid_x'].to_f,1.mm].max).ceil,1].max,[(p['height'].to_f/[p['grid_y'].to_f,1.mm].max).ceil,1].max]
        end
      end

      def stair_values(p)
        n = p['steps'].to_i
        r = p['riser'].to_f
        if p['sizing_mode']=='floor'
          n = [[(p['floor_height'].to_f/[r,1.mm].max).round,2].max,150].min
          r = p['floor_height'].to_f/n
        end
        [n,r]
      end

      def derived(kind,p,requested_unit=nil)
        case kind.to_s
        when 'stair'
          n,r=stair_values(p); comfort=2*r*25.4+p['tread'].to_f*25.4
          { 'steps'=>n,'actualRiser'=>display_length(r,requested_unit),'totalRise'=>display_length(n*r,requested_unit),'comfort'=>comfort.round(1), 'warning'=>(comfort<580 || comfort>650 || r>190.mm) ? 'Check stair proportions and local regulations; this is not a compliance assessment.' : '' }
        when 'curtain_wall'
          nx,ny=curtain_counts(p);{'columns'=>nx,'rows'=>ny,'panels'=>nx*ny}
        when 'roof'
          span=(p['ridge_axis']=='x' ? p['depth'] : p['width']).to_f/2+p['overhang'].to_f
          span=[p['width'].to_f,p['depth'].to_f].min/2+p['overhang'].to_f if p['style']=='hip'
          rise=p['style']=='flat' ? 0.0 : (p['sizing_mode']=='pitch' ? span*Math.tan(p['pitch_deg'].to_f*Math::PI/180) : p['rise'].to_f)
          {'actualRise'=>display_length(rise,requested_unit),'pitch'=> (Math.atan2(rise,span)*180/Math::PI).round(2)}
        else {}
        end
      end

      def for_ui(kind,p,requested_unit=nil)
        out = p.dup
        tool(kind)['fields'].each { |f| out[f['key']]=display_length(p[f['key']],requested_unit) if f['type']=='length' && p.key?(f['key']) }
        out
      end
    end
  end
end
