# frozen_string_literal: true

module Draupr
  module Core
    module Project
      DICT='Draupr_Project'
      module_function
      def model; Sketchup.active_model; end
      def levels
        JSON.parse(model.get_attribute(DICT,'levels','[{"id":"ground","name":"Ground","elevation":0.0}]'))
      rescue StandardError
        [{'id'=>'ground','name'=>'Ground','elevation'=>0.0}]
      end
      def active_level;model.get_attribute(DICT,'active_level','ground');end
      def level_z(id=nil)
        l=levels.find { |v| v['id']==(id || active_level) }
        l ? l['elevation'].to_f : 0.0
      end
      def save_levels(rows,active)
        raise 'At least one level is required' unless rows.is_a?(Array) && !rows.empty? && rows.length<=100
        clean=rows.map { |r| {'id'=>r['id'].to_s.empty? ? SecureRandom.uuid : r['id'].to_s,'name'=>r['name'].to_s.strip[0,100],'elevation'=>Parameters.length(r['elevation'])} }
        raise 'Every level needs a name' if clean.any? { |r| r['name'].empty? }
        raise 'Duplicate level identifiers' unless clean.map { |r| r['id'] }.uniq.length==clean.length
        removed=levels.map { |r| r['id'] }-clean.map { |r| r['id'] }
        used=Objects.all.select { |g| removed.include?(Objects.params(g)['level_id']) }
        raise 'A deleted level is still used by objects. Reassign those objects first.' unless used.empty?
        raise 'Select a valid active level' unless clean.any? { |r| r['id']==active }
        Transactions.run('Draupr levels') do
          model.set_attribute(DICT,'levels',JSON.generate(clean))
          model.set_attribute(DICT,'active_level',active)
        end
        snapshot
      end
      def snapshot(requested_unit=nil)
        { 'levels'=>levels.map { |l| l.merge('elevation'=>Parameters.display_length(l['elevation'],requested_unit)) },'activeLevel'=>active_level }
      end
      def audit
        items=Objects.all
        uids=items.group_by { |g| g.get_attribute('Draupr','uid') }
        warnings=[]
        items.each do |g|
          begin
            d=Metadata.read(g);p=Objects.params(g)
            Parameters.normalize(d['type'],{},p)
            unless d['params_json'];inf=Objects.legacy_level_inference(g);warnings << (inf['safe'] ? "#{g.name}: legacy object; inferred level #{inf['level_id']} should be reviewed." : "#{g.name}: legacy object has unresolved level; review before editing.");end
            warnings << "#{g.name}: duplicate object identity; use Duplicate in Draupr to create independent copies." if d['uid'] && uids[d['uid']].length>1
            p.each { |k,v| warnings << "#{g.name}: missing material #{v}" if k.end_with?('material') && !v.to_s.empty? && !Materials.find(v) }
            warnings << "#{g.name}: linked host is missing." if d['hosts_json'] && Hosts.hosts_for(g).empty?
          rescue StandardError => e
            warnings << "#{g.name}: #{e.message}"
          end
        end
        {'objects'=>items.length,'warnings'=>warnings.uniq,'byType'=>items.group_by { |g| Metadata.read(g)['type'] }.transform_values(&:length)}
      end
    end
    module Library
      module_function
      def portable(kind,raw)
        raise 'Invalid parameter data.' unless raw.is_a?(Hash)
        p=Parameters.normalize(kind,raw)
        %w[path_points footprint].each do |key|
          next unless raw[key]
          limit=key=='path_points' ? 500 : 1000
          raise 'Invalid or oversized saved geometry.' unless raw[key].is_a?(Array) && raw[key].length<=limit
          p[key]=raw[key].map do |pt|
            raise 'Invalid saved coordinate.' unless pt.is_a?(Array) && pt.length==3
            pt.map { |v| n=Parameters.coord(v);raise 'Invalid saved coordinate.' unless n.finite?;n }
          end
        end
        p['closed']=raw['closed']==true if raw.key?('closed')
        if raw['panel_overrides']
          raise 'Invalid panel overrides.' unless raw['panel_overrides'].is_a?(Hash) && raw['panel_overrides'].length<=1600
          p['panel_overrides']=raw['panel_overrides'].each_with_object({}) do |(k,v),h|
            next unless k.match?(/\Apanel_\d+_\d+\z/) && v.is_a?(Hash) && %w[vision spandrel open].include?(v['type'])
            h[k]={'type'=>v['type'],'material'=>v['material'].to_s[0,250]}
          end
        end
        if raw['part_overrides']
          raise 'Invalid part overrides.' unless raw['part_overrides'].is_a?(Hash) && raw['part_overrides'].length<=10000
          p['part_overrides']=raw['part_overrides'].each_with_object({}) do |(k,v),h|
            next unless v.is_a?(Hash);angle=Float(v.fetch('angle',0));raise 'Invalid texture rotation.' unless angle.finite?
            h[k.to_s[0,150]]={'material'=>v['material'].to_s[0,250],'angle'=>angle}
          end
        end
        p
      end
      def all;Preferences.get('presets',[]);end
      def save(item)
        kind=item['kind'].to_s
        p=portable(kind,item.fetch('params',{}))
        name=item['name'].to_s.strip[0,100]
        raise 'Give the preset a name' if name.empty?
        rows=all
        id=item['id'].to_s.empty? ? SecureRandom.uuid : item['id']
        rows.reject! { |r| r['id']==id }
        rows << {'id'=>id,'kind'=>kind,'name'=>name,'favorite'=>item['favorite']==true,'params'=>p,'schema'=>DataSchema::VERSION}
        Preferences.set('presets',rows.last(500))
      end
      def remove(id);Preferences.set('presets',all.reject { |r| r['id']==id });end
      def favorite(id,value)
        rows=all;rows.each { |r| r['favorite']=value==true if r['id']==id };Preferences.set('presets',rows)
      end
      def export_file
        path=::UI.savepanel('Export Draupr presets',nil,'draupr_presets.json');return false unless path
        File.write(path,JSON.pretty_generate({'format'=>'draupr-presets','version'=>1,'presets'=>all}),encoding:'UTF-8');true
      end
      def import_file
        path=::UI.openpanel('Import Draupr presets',nil,'JSON|*.json||');return false unless path
        raise 'Preset file is too large' if File.size(path)>2_000_000
        doc=JSON.parse(File.read(path,encoding:'UTF-8'))
        raise 'Not a supported Draupr preset file' unless doc['format']=='draupr-presets' && doc['version']==1 && doc['presets'].is_a?(Array)
        clean=doc['presets'].first(500).map do |r|
          {'id'=>SecureRandom.uuid,'name'=>r['name'].to_s[0,100],'kind'=>r['kind'],'favorite'=>false,'schema'=>DataSchema::VERSION,'params'=>portable(r['kind'],r['params'])}
        end
        Preferences.set('presets',(all+clean).last(500));true
      end
      def for_ui;all.map { |r| r.merge('params'=>Parameters.for_ui(r['kind'],r['params'])) };end
    end
  end
end
