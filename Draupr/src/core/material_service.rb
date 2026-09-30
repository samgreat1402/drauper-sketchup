# frozen_string_literal: true
module Draupr
  module Core
    module Materials
      class << self
        def find(name)
          mats=Sketchup.active_model.materials
          mats[name.to_s] || mats.find { |m| m.name==name.to_s || m.display_name==name.to_s }
        end
        def by_name_or_default(name,fallback)
          return fetch(fallback) if name.nil? || name.to_s.strip.empty?
          found=find(name);return found if found
          key=palette_key_for_name(name);return fetch(key) if key
          raise "Material '#{name}' is missing. Select an existing material."
        end
        def names
          (PALETTE.values.map(&:first)+Sketchup.active_model.materials.map(&:name)).uniq.sort
        end
        def category(name)
          n=name.downcase
          return 'glass' if n.include?('glass')
          return 'wood' if n.match?(/wood|timber|oak|walnut/)
          return 'metal' if n.match?(/steel|metal|mullion|alumin/)
          return 'masonry' if n.match?(/concrete|brick|stone|masonry/)
          return 'finish' if n.match?(/finish|plaster|paint/)
          'other'
        end
        def catalog(query='',source='all')
          favorites=Preferences.get('material_favorites',[]);recent=Preferences.get('material_recent',[])
          list=names.select { |name| name.downcase.include?(query.to_s.downcase) }
          list.select! { |name| find(name) } if source=='model'
          list.select! { |name| palette_key_for_name(name) } if source=='library'
          list.select! { |name| favorites.include?(name) } if source=='favorites'
          list=recent.select { |name| list.include?(name) } if source=='recent'
          rows=list.first(120).map do |name|
            m=find(name);rgba=m ? m.color.to_a : PALETTE.fetch(palette_key_for_name(name))[1]
            alpha=m ? m.alpha : rgba[3].to_f/255
            {'name'=>name,'color'=>format('#%02x%02x%02x',*rgba.first(3)),'opacity'=>(alpha*100).round,'category'=>category(name),'inModel'=>!!m,'favorite'=>favorites.include?(name),'texture'=>!!(m && m.texture),'thumbnail'=>m ? thumbnail(m) : nil,'size'=>m && m.texture ? [Parameters.display_length(m.texture.width),Parameters.display_length(m.texture.height)] : nil}
          end
          {'items'=>rows,'total'=>list.length,'names'=>names}
        end
        def thumbnail(m)
          return nil unless m.respond_to?(:write_thumbnail)
          @thumbs||={};signature=[m.name,m.color.to_a,m.alpha,m.texture && m.texture.filename,m.texture && m.texture.width].inspect
          return @thumbs[signature] if @thumbs.key?(signature)
          file=File.join(Dir.tmpdir,"draupr_thumb_#{SecureRandom.hex(8)}.png")
          return nil unless m.write_thumbnail(file)
          uri='data:image/png;base64,'+Base64.strict_encode64(File.binread(file));File.delete(file)
          @thumbs.clear if @thumbs.length>250;@thumbs[signature]=uri
        rescue StandardError
          nil
        end
        def recent(name)
          Preferences.set('material_recent',([name]+Preferences.get('material_recent',[])).uniq.first(24))
        end
        def favorite(name,value)
          a=Preferences.get('material_favorites',[]);a.delete(name);a<<name if value;Preferences.set('material_favorites',a)
        end
        def import_texture
          path=::UI.openpanel('Import a material texture',nil,'Images|*.png;*.jpg;*.jpeg;*.bmp;*.tif||');return nil unless path
          raise 'Texture exceeds 50 MB.' if File.size(path)>50_000_000
          m=nil
          Transactions.run('Import Draupr material') do
            m=Sketchup.active_model.materials.add(File.basename(path,File.extname(path)));m.texture=path;m.texture.size=[1000.mm,1000.mm] if m.texture
          end
          recent(m.name);m.name
        end
        def edit_material(data)
          original=by_name_or_default(data['name'],:wall_default);duplicate=data['duplicate']==true
          raise 'Confirm that every use of this shared material will change.' unless duplicate || data['confirmed']==true
          m=nil
          Transactions.run(duplicate ? 'Duplicate material' : 'Edit shared material') do
            if duplicate
              name=data['newName'].to_s.strip;raise 'Name the duplicate material.' if name.empty?
              m=Sketchup.active_model.materials.add(name)
              if original.texture
                file=original.texture.filename
                unless File.file?(file)
                  file=File.join(Dir.tmpdir,"draupr_texture_#{SecureRandom.hex(8)}.png");raise 'Could not copy the embedded texture.' unless original.texture.write(file)
                end
                m.texture=file;m.texture.size=[original.texture.width,original.texture.height]
              end
              m.color=original.color;m.alpha=original.alpha
            else;m=original;end
            color=data['color'].to_s;raise 'Use a six-digit hexadecimal color.' unless color.match?(/\A#[a-f0-9]{6}\z/i)
            m.color=Sketchup::Color.new(color)
            opacity=Float(data['opacity']);raise 'Opacity must be between 0 and 100.' unless opacity.finite? && opacity.between?(0,100);m.alpha=opacity/100
            if m.texture && data['textureWidth'] && !data['textureWidth'].to_s.empty?
              w=Parameters.length(data['textureWidth']);h=Parameters.length(data['textureHeight']);raise 'Texture dimensions must be positive.' unless w>0 && h>0;m.texture.size=[w,h]
            end
          end
          @thumbs={};recent(m.name);m.name
        end
        def assign(data)
          m=by_name_or_default(data['material'],:wall_default);scope=data['scope'];role=data['role'];part_key=data['part'];angle=Float(data.fetch('angle',0));raise 'Invalid texture angle.' unless angle.finite?
          if scope=='defaults'
            kind=data['kind'];p=Parameters.normalize(kind,{},Preferences.defaults_for(kind));roles=Parameters.tool(kind)['roles'].select { |r| role.to_s.empty? || r['id']==role }
            raise 'Choose a material role.' if roles.empty?;roles.each { |r| p[r['key']]=m.name };Preferences.set("defaults_#{kind}",p);recent(m.name);return
          end
          ids=data.fetch('ids',[]);raise 'Select a Draupr object.' if ids.empty?
          Transactions.run('Assign Draupr material') do
            ids.each do |uid|
              g=Objects.get(uid);raise 'Object is locked.' if g.locked?;Parts.independent_tree(g);p=Objects.params(g);parts=[]
              Parts.each(g.entities) { |e| parts<<e if scope=='whole' || (scope=='role' && e.get_attribute(Parts::DICT,'role')==role) || (scope=='part' && e.get_attribute(Parts::DICT,'key')==part_key) }
              if parts.empty?
                raise 'No matching parts. For legacy objects, apply a reviewed Edit first.' unless scope=='whole'
                Parts.assign(g,m,angle)
              end
              p['part_overrides']||={}
              if scope=='whole'
                p['part_overrides']={}
                p.fetch('panel_overrides',{}).each_value { |o| o.delete('material') }
              end
              parts.each { |e| Parts.assign(e,m,angle);p['part_overrides'][e.get_attribute(Parts::DICT,'key')]={'material'=>m.name,'angle'=>angle} }
              Parameters.tool(Metadata.read(g)['type'])['roles'].each { |r| p[r['key']]=m.name if scope=='whole' || (scope=='role' && r['id']==role) }
              if g.get_attribute('Draupr','params_json')
                g.set_attribute('Draupr','params_json',JSON.generate(p))
              else
                Parameters.tool(Metadata.read(g)['type'])['roles'].each { |r| g.set_attribute('Draupr',r['key'],m.name) }
              end
              summary=Parameters.tool(Metadata.read(g)['type'])['roles'].map { |r| p[r['key']] }.compact.uniq.join(' / ')
              g.set_attribute('Draupr','material',summary)
            end
          end;recent(m.name)
        end
      end
    end
  end
end
