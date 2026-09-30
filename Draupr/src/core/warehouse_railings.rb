# frozen_string_literal: true
module Draupr
  module Core
    # Loads user-owned SketchUp railing source models from a configurable local
    # folder. Source SKP files are never bundled with the public extension.
    module WarehouseRailings
      DATA={
        'local_metal_module'=>{'file'=>'Railing_Metal.skp','kind'=>'panel','label'=>'Local Metal Module'},
        'local_turned_baluster'=>{'file'=>'Balusters.skp','kind'=>'baluster','label'=>'Local Turned Baluster'},
        'local_classical_baluster'=>{'file'=>'Classical_Balusters.skp','kind'=>'baluster','label'=>'Local Classical Baluster','preferred'=>['Baluster#1','con tien lancan','Untitled']}
      }.freeze
      ALIASES={
        'warehouse_metal_module'=>'local_metal_module',
        'warehouse_turned_baluster'=>'local_turned_baluster',
        'warehouse_classical_baluster'=>'local_classical_baluster'
      }.freeze
      module_function
      def canonical_id(id);ALIASES.fetch(id.to_s,id.to_s);end
      def preset?(id);DATA.key?(canonical_id(id));end
      def default_folder
        File.join(Dir.home,'Draupr Railing Library')
      rescue StandardError
        File.join(Draupr::ROOT,'Railing Library')
      end
      def folder
        value=Preferences.get('railing_library_folder','').to_s
        value.empty? ? default_folder : value
      end
      def ensure_folder
        FileUtils.mkdir_p(folder) unless File.directory?(folder)
        folder
      end
      def set_folder(path)
        raise 'That railing source folder does not exist. / پوشه منبع نرده وجود ندارد.' unless File.directory?(path.to_s)
        Preferences.set('railing_library_folder',File.expand_path(path.to_s));folder
      end
      def asset_path(spec);File.join(folder,spec['file']);end
      def valid_skp?(path)
        return false unless File.file?(path)
        File.binread(path,80).include?('SketchUp Model'.encode('UTF-16LE').b)
      rescue StandardError
        false
      end
      def status
        sources=DATA.map do |id,spec|
          path=asset_path(spec);exists=File.file?(path)
          {'id'=>id,'label'=>spec['label'],'file'=>spec['file'],'path'=>path,'exists'=>exists,'valid'=>exists && valid_skp?(path),'size'=>exists ? File.size(path) : 0}
        end
        {'folder'=>folder,'sources'=>sources,'valid'=>sources.count { |s| s['valid'] },'missing'=>sources.reject { |s| s['valid'] }.map { |s| s['file'] }}
      end
      def diagnostics;status;end
      def open_folder
        ensure_folder;UI.openURL('file:///'+folder.gsub('\\','/'));true
      end
      def entity_definition(entity);entity.respond_to?(:definition) ? entity.definition : nil;end
      def transformed_bounds(bounds,tr)
        bb=Geom::BoundingBox.new;8.times { |i| bb.add(bounds.corner(i).transform(tr)) };bb
      end
      def scan(definition,tr=IDENTITY,depth=0,path=[])
        return [] if depth>5 || path.include?(definition.object_id)
        result=[]
        definition.entities.each do |entity|
          child=entity_definition(entity);next unless child
          ctr=tr*entity.transformation;bb=transformed_bounds(child.bounds,ctr)
          name=[entity.respond_to?(:name) ? entity.name : nil,child.name].map(&:to_s).reject(&:empty?).join(' / ')
          result << {definition:child,transform:ctr,bounds:bb,name:name,depth:depth}
          result.concat(scan(child,ctr,depth+1,path+[definition.object_id]))
        end
        result
      end
      def dimensions(bb);[bb.width.to_f,bb.depth.to_f,bb.height.to_f];end
      def choose_candidate(root,spec)
        candidates=scan(root)
        Array(spec['preferred']).each do |wanted|
          hit=candidates.find { |c| c[:name].downcase.include?(wanted.downcase) };return hit if hit
        end
        if spec['kind']=='baluster'
          usable=candidates.select { |c| x,y,z=dimensions(c[:bounds]);z>100.mm && [x,y].max>1.mm && z/[x,y].max>1.3 }
          return usable.max_by { |c| x,y,z=dimensions(c[:bounds]);z/[x,y,5.mm].max+Math.log([z.to_f,1.0].max) } unless usable.empty?
        else
          usable=candidates.select { |c| x,y,z=dimensions(c[:bounds]);long=[x,y].max;thin=[x,y].min;z>250.mm && long>500.mm && long>z*1.15 && thin<long*0.45 }
          return usable.max_by { |c| x,y,z=dimensions(c[:bounds]);[x,y].max/[[x,y].min,10.mm].max+z/[x,y].max } unless usable.empty?
        end
        {definition:root,transform:IDENTITY,bounds:root.bounds,name:root.name,depth:0}
      end
      def linear_transform(tr);Geom::Transformation.axes(ORIGIN,tr.xaxis,tr.yaxis,tr.zaxis);end
      def normalize_wrapper(wrapper,kind)
        entities=wrapper.entities.to_a;raise 'The local railing source component is empty. / کامپوننت منبع نرده خالی است.' if entities.empty?
        bb=wrapper.bounds
        if kind=='panel' && bb.depth>bb.width
          wrapper.entities.transform_entities(Geom::Transformation.rotation(ORIGIN,Z_AXIS,-Math::PI/2),entities);bb=wrapper.bounds;entities=wrapper.entities.to_a
        end
        move=if kind=='panel'
          Geom::Transformation.translation(Geom::Vector3d.new(-bb.min.x,-(bb.min.y+bb.max.y)/2.0,-bb.min.z))
        else
          Geom::Transformation.translation(Geom::Vector3d.new(-(bb.min.x+bb.max.x)/2.0,-(bb.min.y+bb.max.y)/2.0,-bb.min.z))
        end
        wrapper.entities.transform_entities(move,entities);bb=wrapper.bounds
        wrapper.set_attribute('draupr_local_railing','kind',kind);wrapper.set_attribute('draupr_local_railing','width',bb.width.to_f);wrapper.set_attribute('draupr_local_railing','height',bb.height.to_f);wrapper
      end
      def wrapper_for(raw_id)
        id=canonical_id(raw_id);model=Sketchup.active_model;spec=DATA.fetch(id);path=asset_path(spec)
        raise "Missing #{spec['file']}. Choose Local Railing Sources in Library. / فایل منبع نرده یافت نشد." unless File.file?(path)
        raise "#{spec['file']} is not a valid SketchUp model. / فایل اسکچاپ معتبر نیست." unless valid_skp?(path)
        signature=Digest::SHA256.file(path).hexdigest[0,12];name="Draupr Local Railing :: #{id} :: #{signature}"
        existing=model.definitions[name];return existing if existing && existing.get_attribute('draupr_local_railing','ready')
        root=model.definitions.load(path);candidate=choose_candidate(root,spec);wrapper=existing || model.definitions.add(name);wrapper.entities.clear! if wrapper.entities.length>0
        wrapper.entities.add_instance(candidate[:definition],linear_transform(candidate[:transform]));normalize_wrapper(wrapper,spec['kind'])
        wrapper.set_attribute('draupr_local_railing','source_name',candidate[:name]);wrapper.set_attribute('draupr_local_railing','source_file',spec['file']);wrapper.set_attribute('draupr_local_railing','source_digest',signature);wrapper.set_attribute('draupr_local_railing','ready',true)
        Diag.log("Local railing #{id}: #{candidate[:name]} #{wrapper.bounds.width.to_f.round(2)} x #{wrapper.bounds.depth.to_f.round(2)} x #{wrapper.bounds.height.to_f.round(2)}");wrapper
      end
      def horizontal_frame(vector)
        horizontal=Geom::Vector3d.new(vector.x,vector.y,0.0);raise 'Local railing segments cannot be vertical. / مسیر نرده نمی‌تواند عمودی باشد.' if horizontal.length<1.mm
        horizontal.normalize!;side=Z_AXIS.cross(horizontal);side.normalize!;[horizontal,side]
      end
      def place_balusters(group,p,pts,definition,post_material,rail_material,&bar)
        source_h=definition.get_attribute('draupr_local_railing','height').to_f;raise 'The selected baluster has no usable height.' if source_h<1.mm
        h=p['height'].to_f;target_h=[h*0.82,100.mm].max;scale=target_h/source_h;spacing=[p['infill_spacing'].to_f,20.mm].max;total=0.0
        pts.each_cons(2).with_index do |(a,b),si|
          vector=a.vector_to(b);length=vector.length;next if length<1.mm
          tangent,side=horizontal_frame(vector);count=[(length/spacing).ceil,2].max
          (1...count).each do |i|
            point=a.offset(vector,length*i/count.to_f).offset(Z_AXIS,h*0.1);axes=Geom::Transformation.axes(point,tangent,side,Z_AXIS);instance=group.entities.add_instance(definition,axes*Geom::Transformation.scaling(scale));instance.name="local_baluster_#{si}_#{i}";instance.set_attribute('draupr','role','infill')
          end
          (0..count).step(count).each do |i|
            next if si>0 && i==0
            point=a.offset(vector,length*i/count.to_f);Parts.cylinder(group.entities,'post',"local_post_#{si}_#{i}",point,p['post_diameter']/2,h,post_material,20)
          end
          bar.call("local_top_#{si}",a.offset(Z_AXIS,h),b.offset(Z_AXIS,h),p['rail_width'],p['rail_thickness'],rail_material)
          bar.call("local_bottom_#{si}",a.offset(Z_AXIS,h*0.08),b.offset(Z_AXIS,h*0.08),[p['rail_width']*0.65,20.mm].max,[p['rail_thickness']*0.65,20.mm].max,rail_material);total+=length
        end;total
      end
      def place_panels(group,p,pts,definition)
        source_w=definition.get_attribute('draupr_local_railing','width').to_f;source_h=definition.get_attribute('draupr_local_railing','height').to_f
        raise 'The selected local panel has invalid dimensions.' if source_w<1.mm || source_h<1.mm
        h=p['height'].to_f;height_scale=h/source_h;natural_width=source_w*height_scale;max_bay=[p['post_spacing'].to_f,100.mm].max;total=0.0
        pts.each_cons(2).with_index do |(a,b),si|
          vector=a.vector_to(b);length=vector.length;next if length<1.mm
          _horizontal,side=horizontal_frame(vector);horizontal_length=Math.sqrt(vector.x*vector.x+vector.y*vector.y);raise 'Local railing panel path is too steep.' if horizontal_length<1.mm
          bays=[(horizontal_length/[natural_width,max_bay].min).ceil,1].max
          bays.times do |i|
            start=a.offset(vector,i.to_f/bays);finish=a.offset(vector,(i+1).to_f/bays);run=start.vector_to(finish);hr=Math.sqrt(run.x*run.x+run.y*run.y);shear=Geom::Vector3d.new(run.x/hr,run.y/hr,run.z/hr)
            axes=Geom::Transformation.axes(start,shear,side,Z_AXIS);scale=Geom::Transformation.scaling(ORIGIN,hr/source_w,height_scale,height_scale);instance=group.entities.add_instance(definition,axes*scale);instance.name="local_panel_#{si}_#{i}";instance.set_attribute('draupr','role','infill')
          end;total+=length
        end;total
      end
      def build(group,p,pts,post_material,rail_material,&bar)
        id=canonical_id(p['preset']);spec=DATA.fetch(id);definition=wrapper_for(id)
        spec['kind']=='panel' ? place_panels(group,p,pts,definition) : place_balusters(group,p,pts,definition,post_material,rail_material,&bar)
      end
    end
  end
end
