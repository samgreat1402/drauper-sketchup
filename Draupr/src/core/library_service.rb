# frozen_string_literal: true
require 'fileutils'
require 'digest'

module Draupr
  module Core
    # Folder-based object library: save the current selection as a portable
    # JSON + PNG pair, list the folder, and place items back into any model.
    module LibraryService
      module_function

      FORMAT = 4
      MIN_FORMAT = 1
      MAX_FILE_BYTES = 25_000_000
      MAX_FACES = 100_000
      MAX_VERTICES_PER_FACE = 5_000
      MAX_HOLES_PER_FACE = 256
      MAX_MATERIALS = 1_000

      def default_folder
        File.join(Dir.home, 'Documents', 'Draupr Library')
      end

      def folder
        f = Preferences.get('library_folder', '').to_s
        f.empty? ? default_folder : f
      end

      def ensure_folder
        f = folder
        FileUtils.mkdir_p(f) unless File.directory?(f)
        f
      end

      def set_folder(path)
        raise 'That folder does not exist.' unless File.directory?(path.to_s)
        Preferences.set('library_folder', path.to_s)
        folder
      end

      def sanitize(name)
        name.gsub(/[\/\\:*?"<>|]/, '').strip
      end

      def selectable?(e)
        e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Face)
      end

      def collect_entity(e, tr, faces, points, inherited_material=nil)
        if e.is_a?(Sketchup::Group)
          effective=e.material || inherited_material
          collect_faces(e.entities, tr * e.transformation, faces, points, effective)
        elsif e.is_a?(Sketchup::ComponentInstance)
          effective=e.material || inherited_material
          collect_faces(e.definition.entities, tr * e.transformation, faces, points, effective)
        elsif e.is_a?(Sketchup::Face)
          front=e.material || inherited_material
          back=e.back_material || inherited_material
          normal=e.normal.transform(tr);normal.normalize! if normal.length>1e-12
          rec = {
            'm' => (front.name rescue nil), 'back_m' => (back.name rescue nil),
            'persistent_id' => (e.persistent_id rescue e.entityID),
            'normal' => [normal.x.round(8),normal.y.round(8),normal.z.round(8)],
            'role' => (e.get_attribute('Draupr','role') rescue nil)
          }
          rec['loop'] = e.outer_loop.vertices.map do |v|
            pt = v.position.transform(tr)
            c = [(pt.x * 25.4).round(3), (pt.y * 25.4).round(3), (pt.z * 25.4).round(3)]
            points << c
            c
          end
          inner = e.loops.reject(&:outer?)
          unless inner.empty?
            rec['holes'] = inner.map do |lp|
              lp.vertices.map do |v|
                pt=v.position.transform(tr)
                [(pt.x*25.4).round(3),(pt.y*25.4).round(3),(pt.z*25.4).round(3)]
              end
            end
          end
          faces << rec
        end
      end

      def collect_faces(ents, tr, faces, points, inherited_material=nil)
        ents.each { |e| collect_entity(e, tr, faces, points, inherited_material) }
      end

      def write_thumbnail(sel, path)
        view=Sketchup.active_model.active_view;cam=view.camera;saved=[cam.eye,cam.target,cam.up,cam.perspective?]
        begin
          view.zoom(sel);view.write_image(path,320,240,true,0.0);true
        rescue StandardError=>error
          Diag.log_error('Library thumbnail',error) if defined?(Diag);false
        ensure
          begin;cam.set(saved[0],saved[1],saved[2]);cam.perspective=saved[3];view.refresh;rescue StandardError;end
        end
      end

      def export_material_records(names, folder_path)
        names.map { |value| value.to_s }.reject(&:empty?).uniq.filter_map do |name|
          material=Sketchup.active_model.materials[name]
          next unless material
          color=material.color
          record={
            'name'=>material.name.to_s,
            'display_name'=>(material.display_name rescue material.name.to_s),
            'color'=>[color.red,color.green,color.blue],
            'alpha'=>material.alpha.to_f
          }
          texture=material.texture
          if texture
            ext=File.extname(texture.filename.to_s).downcase
            ext='.png' unless %w[.png .jpg .jpeg .bmp .tif .tiff].include?(ext)
            texture_file=Digest::SHA256.hexdigest(material.name.to_s)[0,20]+ext
            relative=['_textures',texture_file].join('/')
            absolute=File.join(folder_path,relative)
            FileUtils.mkdir_p(File.dirname(absolute))
            begin
              texture.write(absolute)
            rescue StandardError
              source=texture.filename.to_s
              FileUtils.cp(source,absolute) if File.file?(source)
            end
            if File.file?(absolute)
              record['texture']={
                'file'=>relative,
                'width_mm'=>(texture.width.to_f*25.4).round(4),
                'height_mm'=>(texture.height.to_f*25.4).round(4),
                'sha256'=>Digest::SHA256.file(absolute).hexdigest
              }
            end
          end
          record
        end
      end

      def material_record_map(data)
        (data['materials'] || []).each_with_object({}) do |record,map|
          map[record['name'].to_s]=record if record.is_a?(Hash) && record['name']
        end
      end

      def material_matches?(material,record)
        return true unless record
        rgb=record['color'];same_color=!rgb.is_a?(Array) || rgb.length<3 || material.color.to_a.first(3)==rgb.first(3).map(&:to_i)
        same_alpha=!record.key?('alpha') || (material.alpha.to_f-record['alpha'].to_f).abs<0.001
        same_color && same_alpha
      end

      def restore_material(data,name,cache)
        key=name.to_s;return nil if key.empty?;return cache[key] if cache.key?(key)
        model=Sketchup.active_model;record=material_record_map(data)[key];material=model.materials[key]
        if material && record && !material_matches?(material,record)
          digest=Digest::SHA256.hexdigest(JSON.generate(record))[0,8];safe_name="#{key} [Draupr #{digest}]";material=model.materials[safe_name] || model.materials.add(safe_name)
        end
        material ||= model.materials.add(key)
        if record
          rgb=record['color'];material.color=rgb if rgb.is_a?(Array) && rgb.length>=3;material.alpha=record['alpha'].to_f if record.key?('alpha')
          texture=record['texture']
          if texture.is_a?(Hash) && texture['file']
            candidate=File.expand_path(texture['file'].to_s,folder);library_root=File.expand_path(folder)+File::SEPARATOR
            valid=candidate.start_with?(library_root) && File.file?(candidate)
            valid&&=Digest::SHA256.file(candidate).hexdigest==texture['sha256'].to_s if valid && texture['sha256']
            if valid
              begin
                material.texture=candidate
                material.texture.size=[texture['width_mm'].to_f.mm,texture['height_mm'].to_f.mm] if material.texture && texture['width_mm'].to_f>0 && texture['height_mm'].to_f>0
              rescue StandardError=>error;Diag.log_error('Library texture restore',error) if defined?(Diag);end
            end
          end
        end
        cache[key]=material
      end

      def restore_all_materials(data)
        cache={};raise 'Library material limit exceeded. / تعداد متریال‌های کتابخانه بیش از حد مجاز است.' if (data['materials']||[]).length>MAX_MATERIALS
        (data['materials']||[]).each { |record| restore_material(data,record['name'],cache) if record.is_a?(Hash) }
        cache
      end

      def save_selection(name,meta={})
        name = sanitize(name.to_s)
        raise 'Enter a name for the object.' if name.empty?
        model = Sketchup.active_model
        sel = model.selection.to_a.select { |e| selectable?(e) }
        raise 'Select at least one group, component or face first.' if sel.empty?
        base_tr = model.edit_transform
        bodies = []
        items = []
        points = []
        sel.each do |e|
          if Objects.valid?(e) && Metadata.read(e)['params_json'] && !e.get_attribute('Draupr', 'hosts_json')
            d = Metadata.read(e)
            items << { 'kind' => d['type'], 'uid' => Objects.id(e), 'params' => Objects.params(e), 'transform' => (base_tr * e.transformation).to_a, 'semantic_roles' => (d['roles'] || []), 'metrics' => (d['metrics'] || {}), 'source_template' => d['template_source'], 'source_checksum' => d['template_sha256'] }
            bb = e.bounds
            8.times { |i| c = bb.corner(i).transform(base_tr * e.transformation); points << [(c.x * 25.4).round(3), (c.y * 25.4).round(3), (c.z * 25.4).round(3)] }
          else
            faces = []
            collect_entity(e, base_tr, faces, points)
            bodies << { 'id' => (e.persistent_id rescue e.entityID), 'entity_kind' => (e.is_a?(Sketchup::Group) ? 'group' : e.is_a?(Sketchup::ComponentInstance) ? 'component' : 'faces'), 'name' => (e.name rescue ''), 'definition_name' => (e.is_a?(Sketchup::ComponentInstance) ? e.definition.name.to_s : ''), 'tag' => (e.layer.name rescue ''), 'material' => (e.material.name rescue nil), 'source_transform' => (e.respond_to?(:transformation) ? (base_tr * e.transformation).to_a : base_tr.to_a), 'faces' => faces } unless faces.empty?
          end
        end
        raise 'Nothing saveable in the selection.' if bodies.empty? && items.empty?
        raise 'Face limit for a library item is 100000. / حداکثر تعداد سطح برای هر آیتم ۱۰۰۰۰۰ است.' if bodies.sum { |b| b['faces'].length }>MAX_FACES
        xs = points.map { |c| c[0] }; ys = points.map { |c| c[1] }; zs = points.map { |c| c[2] }
        cx = (xs.min + xs.max) / 2.0; cy = (ys.min + ys.max) / 2.0; z0 = zs.min
        shift = Geom::Transformation.new(Geom::Vector3d.new((-cx).mm, (-cy).mm, (-z0).mm))
        bodies.each do |b|
          b['faces'].each do |f|
            f['loop'] = f['loop'].map { |c| [c[0] - cx, c[1] - cy, c[2] - z0] }
            (f['holes'] || []).each { |hl| hl.map! { |c| [c[0] - cx, c[1] - cy, c[2] - z0] } }
          end
        end
        items.each { |di| di['transform'] = (shift * Geom::Transformation.new(di['transform'])).to_a }
        geometry_payload={'bodies'=>bodies,'draupr_items'=>items}
        checksum=Digest::SHA256.hexdigest(JSON.generate(geometry_payload))
        folder_path=ensure_folder
        material_names=bodies.flat_map { |body| [body['material']]+body['faces'].flat_map { |face| [face['m'],face['back_m']] } }
        items.each do |record|
          (record['params'] || {}).each { |key,value| material_names << value if key.to_s.end_with?('_material') }
        end
        material_records=export_material_records(material_names.compact,folder_path)
        item = {
          'library_format' => FORMAT,
          'schema' => {'name'=>'draupr-object-library','version'=>FORMAT,'compatible_min'=>MIN_FORMAT},
          'name' => name, 'units' => 'mm', 'saved_at' => Time.now.strftime('%Y-%m-%d %H:%M'),
          'category' => meta['category'].to_s.strip,
          'tags' => meta['tags'].to_s.split(',').map(&:strip).reject(&:empty?).uniq,
          'description' => meta['description'].to_s.strip,
          'source' => {'kind'=>'selection','model_name'=>model.title.to_s,'model_path'=>model.path.to_s,'sketchup_version'=>Sketchup.version.to_s},
          'origin' => {'strategy'=>'bounds_center_floor','source_point_mm'=>[cx.round(3),cy.round(3),z0.round(3)]},
          'bounds' => [[(xs.min - cx).round(1), (ys.min - cy).round(1), 0.0], [(xs.max - cx).round(1), (ys.max - cy).round(1), (zs.max - z0).round(1)]],
          'geometry' => {'coordinate_space'=>'item_local_mm','body_count'=>bodies.length,'face_count'=>bodies.sum { |body| body['faces'].length },'checksum_sha256'=>checksum},
          'parametric' => {'item_count'=>items.length,'editable'=>!items.empty?,'items'=>items.map { |record| {'kind'=>record['kind'],'params'=>record['params'],'semantic_roles'=>record['semantic_roles'],'source_template'=>record['source_template'],'source_checksum'=>record['source_checksum']} }},
          'materials' => material_records,
          'thumbnail' => {'file'=>name+'.png','width'=>320,'height'=>240},
          'host_behavior' => {'hosted_items_excluded'=>true,'placement'=>'free'},
          'bodies' => bodies, 'draupr_items' => items
        }
        target=File.join(folder_path,name+'.json');temporary=target+'.tmp';File.write(temporary,JSON.generate(item));File.rename(temporary,target)
        write_thumbnail(sel, File.join(folder_path, name + '.png'))
        true
      end

      def item_path(file)
        f = File.join(folder, File.basename(file.to_s))
        raise 'Library item not found.' unless File.exist?(f)
        f
      end

      def validate_item!(data,path=nil)
        raise 'Invalid Object Library document. / سند کتابخانه آبجکت نامعتبر است.' unless data.is_a?(Hash)
        bodies=data['bodies']||[];items=data['draupr_items']||[];faces=bodies.sum { |body| (body['faces']||[]).length }
        raise 'Object Library face limit exceeded. / تعداد سطوح کتابخانه بیش از حد مجاز است.' if faces>MAX_FACES
        bodies.each do |body|
          (body['faces']||[]).each do |face|
            loop_points=face['loop'];raise 'Invalid library face loop. / حلقه سطح کتابخانه نامعتبر است.' unless loop_points.is_a?(Array) && loop_points.length.between?(3,MAX_VERTICES_PER_FACE)
            holes=face['holes']||[];raise 'Library hole limit exceeded. / تعداد بازشوهای سطح بیش از حد مجاز است.' if holes.length>MAX_HOLES_PER_FACE
            (holes+[loop_points]).each { |loop| raise 'Invalid library coordinates. / مختصات کتابخانه نامعتبر است.' unless loop.all? { |point| point.is_a?(Array) && point.length==3 && point.all? { |value| value.is_a?(Numeric) && value.finite? } } }
          end
        end
        expected=data.dig('geometry','checksum_sha256')
        actual=Digest::SHA256.hexdigest(JSON.generate({'bodies'=>bodies,'draupr_items'=>items}))
        raise 'Object Library geometry checksum failed. / کنترل صحت هندسه کتابخانه ناموفق بود.' if expected && expected!=actual
        true
      end
      def load_item(file)
        path=item_path(file);raise 'Object Library file is too large. / فایل کتابخانه آبجکت بیش از حد بزرگ است.' if File.size(path)>MAX_FILE_BYTES
        data=JSON.parse(File.read(path));version=data['library_format'].to_i
        raise 'Not a supported Draupr library item. / فایل کتابخانه Draupr پشتیبانی نمی‌شود.' unless version.between?(MIN_FORMAT,FORMAT)
        validate_item!(data,path)
        data['category']||=''
        data['tags']||=[]
        data['description']||=''
        data['schema']||={'name'=>'draupr-object-library','version'=>version,'compatible_min'=>MIN_FORMAT}
        data['geometry']||={'coordinate_space'=>'item_local_mm','body_count'=>(data['bodies']||[]).length,'face_count'=>(data['bodies']||[]).sum { |body| (body['faces']||[]).length }}
        data['parametric']||={'item_count'=>(data['draupr_items']||[]).length,'editable'=>!(data['draupr_items']||[]).empty?}
        data['materials']||=[]
        data['host_behavior']||={'hosted_items_excluded'=>true,'placement'=>'free'}
        data
      end

      def list_payload
        f = folder
        items = []
        if File.directory?(f)
          Dir.glob(File.join(f, '*.json')).sort.each do |path|
            begin
              d = JSON.parse(File.read(path))
              version=d['library_format'].to_i
              next unless version.between?(MIN_FORMAT,FORMAT)
              name = File.basename(path, '.json')
              png = File.join(f, name + '.png')
              items << {
                'name' => d['name'].to_s, 'file' => File.basename(path),
                'saved_at' => d['saved_at'].to_s,
                'faces' => (d['bodies'] || []).sum { |b| (b['faces'] || []).length },
                'draupr' => (d['draupr_items'] || []).length,
                'category' => d['category'].to_s, 'tags' => d['tags'] || [],
                'description' => d['description'].to_s, 'format' => version, 'schema' => d['schema'], 'checksum' => d.dig('geometry','checksum_sha256'), 'parametric' => d.dig('parametric','editable'),
                'size' => File.size(path),
                'thumb' => File.exist?(png) ? 'data:image/png;base64,' + Base64.encode64(File.binread(png)).delete("\n") : nil
              }
            rescue StandardError
              next
            end
          end
        end
        { 'folder' => f, 'items' => items }
      end

      def delete_item(file)
        path = item_path(file)
        base = path.sub(/\.json\z/i, '')
        File.delete(path)
        File.delete(base + '.png') if File.exist?(base + '.png')
        true
      end

      def rename_item(file,name)
        path=item_path(file);name=sanitize(name.to_s);raise 'Enter a name.' if name.empty?
        data=load_item(file);data['name']=name
        target=File.join(folder,name+'.json');raise 'An item with that name already exists.' if target!=path && File.exist?(target)
        temporary=target+'.tmp';File.write(temporary,JSON.generate(data));File.rename(temporary,target)
        old_png=path.sub(/\.json\z/i,'.png');new_png=target.sub(/\.json\z/i,'.png')
        File.rename(old_png,new_png) if old_png!=new_png && File.exist?(old_png)
        File.delete(path) if target!=path
        true
      end

      def update_metadata(file,meta)
        path=item_path(file);data=load_item(file)
        data['category']=meta['category'].to_s.strip
        data['tags']=meta['tags'].to_s.split(',').map(&:strip).reject(&:empty?).uniq
        data['description']=meta['description'].to_s.strip
        temporary=path+'.tmp';File.write(temporary,JSON.generate(data));File.rename(temporary,path);true
      end

      def open_folder
        ensure_folder
        UI.openURL('file:///'+folder.gsub('\\','/'))
        true
      end

      def diagnostics
        good=[];broken=[]
        Dir.glob(File.join(folder,'*.json')).sort.each do |path|
          begin
            raise 'file too large' if File.size(path)>MAX_FILE_BYTES
            d=JSON.parse(File.read(path));v=d['library_format'].to_i
            raise "unsupported format #{v}" unless v.between?(MIN_FORMAT,FORMAT)
            validate_item!(d,path);good<<File.basename(path)
          rescue StandardError=>e
            broken<<{'file'=>File.basename(path),'error'=>e.message}
          end
        end
        {'folder'=>folder,'valid'=>good.length,'broken'=>broken}
      end

      def replace_selected(data)
        sel=Sketchup.active_model.selection.to_a.select { |e| e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance) }
        raise 'Select exactly one group or component to replace.' unless sel.length==1
        old=sel.first
        raise 'Hosted Draupr objects must be replaced through their host.' if old.respond_to?(:get_attribute) && old.get_attribute('Draupr','hosts_json')
        parent=Geometry.parent_entities(old)
        place(data,old.transformation.origin,parent,{'base_transform'=>old.transformation,'replace'=>old})
      end

      def p3(c); Geom::Point3d.new(c[0].mm, c[1].mm, c[2].mm); end

      def clean_loop(loop)
        pts = []
        loop.each do |c|
          if pts.empty? || (c[0] - pts[-1][0]).abs > 0.001 || (c[1] - pts[-1][1]).abs > 0.001 || (c[2] - pts[-1][2]).abs > 0.001
            pts << c
          end
        end
        while pts.length > 2 && (pts[0][0] - pts[-1][0]).abs <= 0.001 && (pts[0][1] - pts[-1][1]).abs <= 0.001 && (pts[0][2] - pts[-1][2]).abs <= 0.001
          pts.pop
        end
        pts
      end

      def soften(group)
        group.entities.grep(Sketchup::Edge).each do |e|
          next unless e.faces.length == 2
          next if e.faces[0].normal.angle_between(e.faces[1].normal) > 60.0.degrees
          e.soft = true
          e.smooth = true
        end
      end

      def place(data, point, parent = nil, options={})
        parent ||= Sketchup.active_model.active_entities
        created = []
        Transactions.run("Place library item #{data['name']}") do
          angle=options.fetch('rotation',0).to_f*Math::PI/180.0
          scale=options.fetch('scale',1).to_f
          raise 'Scale must be greater than zero.' unless scale>0
          tr=options['base_transform'] || (Geom::Transformation.new(point)*Geom::Transformation.rotation(ORIGIN,Z_AXIS,angle)*Geom::Transformation.scaling(scale))
          bodies = data['bodies'] || []
          unless bodies.empty?
            root = parent.add_group
            root.name = data['name'].to_s
            mats=restore_all_materials(data)
            bodies.each do |b|
              g = root.entities.add_group
              g.name=b['name'].to_s;tag=b['tag'].to_s;g.layer=Sketchup.active_model.layers[tag] || Sketchup.active_model.layers.add(tag) unless tag.empty?
              (b['faces'] || []).each do |record|
                points=clean_loop(record['loop']).map { |coordinate| p3(coordinate) }
                next if points.length<3
                face=g.entities.add_face(points)
                next unless face
                (record['holes'] || []).each do |hole|
                  cutter=g.entities.add_face(clean_loop(hole).map { |coordinate| p3(coordinate) })
                  cutter.erase! if cutter
                end
                saved_normal=record['normal'];if saved_normal.is_a?(Array) && saved_normal.length==3;normal=Geom::Vector3d.new(*saved_normal);face.reverse! if normal.length>1e-9 && face.normal.dot(normal)<0;end
                front_material=restore_material(data,record['m'],mats)
                back_material=restore_material(data,record['back_m'],mats)
                face.material=front_material if front_material
                face.back_material=back_material if back_material
              end
              soften(g)
              body_material=restore_material(data,b['material'],mats)
              g.material=body_material if body_material
            end
            root.transformation = tr
            created << root
          end
          material_cache=restore_all_materials(data)
          (data['draupr_items'] || []).each do |di|
            lt=Geom::Transformation.new(di['transform']);params=Marshal.load(Marshal.dump(di['params']||{}))
            params.each { |key,value| params[key]=material_cache[value].name if key.to_s.end_with?('_material') && material_cache[value] }
            created << Objects.create(di['kind'],params,tr*lt,parent)
          end
          sel = Sketchup.active_model.selection
          sel.clear
          created.each { |g| sel.add(g) }
          old=options['replace'];old.erase! if old && old.valid?
        end
        created
      end
    end
  end
end
