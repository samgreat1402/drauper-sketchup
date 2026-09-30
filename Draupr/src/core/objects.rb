# frozen_string_literal: true
module Draupr
  module Core
    module Objects
      module_function
      def valid?(e);e.is_a?(Sketchup::Group) && e.valid? && Parameters::TOOLS.key?(e.get_attribute('Draupr','type').to_s);end
      def all(entities=Sketchup.active_model.entities)
        return ObjectIndex.all if entities.equal?(Sketchup.active_model.entities)
        entities.grep(Sketchup::Group).flat_map { |g| valid?(g) ? [g] : all(g.entities) }.uniq
      end
      def selected;Sketchup.active_model.selection.to_a.select { |e| valid?(e) };end
      def id(g);g.get_attribute('Draupr','uid') || "pid:#{g.persistent_id}";end
      def get(uid)
        list=(ObjectIndex.find(uid)+selected).uniq.select { |g| valid?(g) && id(g)==uid.to_s }
        raise 'Object no longer exists. Refresh selection.' if list.empty?
        raise 'Copied identity. Select one copy and use Adopt copy first.' if list.length>1
        list.first
      end
      def resolve_for_edit(uid)
        get(uid)
      rescue RuntimeError => error
        raise unless error.message=='Object no longer exists. Refresh selection.'
        live=selected
        raise error unless live.length==1
        live.first
      end
      def legacy_level_inference(g)
        rows=Project.levels
        base=g.bounds.min.z.to_f
        ranked=rows.map { |l| [((l['elevation'].to_f-base).abs),l] }.sort_by(&:first)
        nearest=ranked.first
        return {'safe'=>false,'level_id'=>Project.active_level,'base_elevation'=>base,'delta'=>nil} unless nearest
        tolerance=50.mm.to_f;second=ranked[1];safe=nearest[0]<=tolerance && (!second || second[0]-nearest[0]>tolerance)
        {'safe'=>safe,'level_id'=>nearest[1]['id'],'base_elevation'=>base,'delta'=>nearest[0]}
      rescue StandardError
        {'safe'=>false,'level_id'=>Project.active_level,'base_elevation'=>nil,'delta'=>nil}
      end
      def params(g)
        d=Metadata.read(g);kind=d['type'];return Parameters.normalize(kind,{},JSON.parse(d['params_json']),false) if d['params_json']
        p=Parameters.defaults(kind)
        Parameters.tool(kind)['fields'].each do |f|
          k=f['key'];v=d[k]
          if f['type']=='length' && d["#{k}_mm"];p[k]=d["#{k}_mm"].to_f.mm.to_f
          elsif %w[integer number boolean select text].include?(f['type']) && !v.nil?;p[k]=v
          elsif f['type']=='material' && v && !v.to_s.empty? && !v.to_s.include?(' + ');p[k]=v;end
        end
        p['name']=g.name;p['tag']=g.layer.name;inf=legacy_level_inference(g);p['level_id']=inf['level_id'];p['placement_mode']=inf['safe'] ? 'level' : 'surface';p['z_offset']=0.0
        case kind
        when 'column'
          p['radius']=[g.definition.bounds.width,g.definition.bounds.depth].min.to_f/2 if p['shape']=='round' && !d['radius_mm']
        when 'door','window';p['frame_material']=d['material'] if d['material'];p['mullions']=d.fetch('mullions',0).to_i
        when 'wall'
          segs=Walls.segments(g);p['openings']=Walls.holes(g)
          if segs.length==1
            a=Walls.point(segs[0]['cs']);b=Walls.point(segs[0]['ce']);dir=a.vector_to(b);dir.normalize!;n=dir.cross(Z_AXIS);n.normalize!;off=Geometry.alignment_offsets(p['thickness'],p['alignment']).sum/2
            p['path_points']=[Walls.xyz(a.offset(n,-off)),Walls.xyz(b.offset(n,-off))]
          else;p['legacy_segments']=segs;end
          if d['wall_type'].to_s.start_with?('cavity-')
            p['wall_type']='single';p['legacy_cavity_type']=d['wall_type'];p['legacy_cavity_width']=d.fetch('cavity_width_mm',60).to_f.mm.to_f
          end
          p['core_material']=d['material'] if d['material'] && !d['material'].include?(' + ')
        when 'roof'
          p['width']-=2*p['overhang'];p['depth']-=2*p['overhang'];p['top_material']=d['material'] if d['material']
        when 'beam';p['alignment']='inside'
        when 'slab';%w[top_material underside_material edge_material].each { |k| p[k]=d['material'] if d['material'] }
        when 'railing';%w[post_material rail_material].each { |k| p[k]=d['material'] if d['material'] }
        end
        Parameters.normalize(kind,{},p,false)
      end
      def legacy_anchor(g)
        d=Metadata.read(g);return Geom::Transformation.new if d['params_json'] || d['type']=='wall'
        if d.key?('ox')
          a=Geom::Point3d.new(d['ox'].to_f,d['oy'].to_f,d['oz'].to_f)
          a=a.offset(X_AXIS,d['overhang_mm'].to_f.mm).offset(Y_AXIS,d['overhang_mm'].to_f.mm) if d['type']=='roof'
        else
          b=g.definition.bounds;a=%w[column foundation].include?(d['type']) ? Geom::Point3d.new(b.center.x,b.center.y,b.min.z) : b.min
          a=a.offset(Z_AXIS,-d['sill_mm'].to_f.mm) if d['type']=='window'
        end
        Geom::Transformation.new(a)
      end
      def capture(g,kind,p,uid=nil)
        v={'type'=>kind,'uid'=>uid||SecureRandom.uuid,'schema'=>DataSchema::VERSION,'entity_pid'=>g.persistent_id,'params_json'=>JSON.generate(p),'last_transform'=>JSON.generate(g.transformation.to_a),'mark'=>p['mark'],'ox'=>0.0,'oy'=>0.0,'oz'=>0.0}
        Parameters.tool(kind)['fields'].each { |f| v["#{f['key']}_mm"]=p[f['key']]*25.4 if f['type']=='length' }
        v['material']=Parameters.tool(kind)['fields'].select { |f| f['type']=='material' }.map { |f| p[f['key']] }.reject { |m| m.to_s.empty? }.uniq.join(' / ')
        Metadata.write(g,v);ObjectIndex.invalidate;g.name=p['name'].to_s.empty? ? "Draupr #{Parameters.tool(kind)['label']}" : p['name']
        g.layer=Sketchup.active_model.layers[p['tag']] || Sketchup.active_model.layers.add(p['tag']) unless p['tag'].to_s.empty?;g
      end
      def create(kind,p={},tr=nil,parent=nil,uid=nil)
        kind=Parameters.canonical(kind);p=Parameters.normalize(kind,{},p)
        raise 'Path limit: 500 vertices.' if p['path_points'].is_a?(Array) && p['path_points'].length>500
        raise 'Footprint limit: 1000 vertices.' if p['footprint'].is_a?(Array) && p['footprint'].length>1000
        parent||=Sketchup.active_model.active_entities
        g=Geometry.with_entities(parent) { Builders.build(kind,p) };g.transformation=tr||Geom::Transformation.new
        capture(g,kind,p,uid);Parts.apply_overrides(g,p.fetch('part_overrides',{}));g
      rescue StandardError
        g.erase! if g && g.valid?;raise
      end
      def copy_identity(old,g)
        d=Metadata.read(old)
        %w[uid schema params_json hosts_json mark last_transform].each { |k| g.set_attribute('Draupr',k,d[k]) if d.key?(k) }
        if old.attribute_dictionaries
          old.attribute_dictionaries.each { |dict| next if dict.name=='Draupr';dict.each_pair { |k,v| g.set_attribute(dict.name,k,v) } }
        end
        g.name=old.name;g.layer=old.layer;g.material=old.material;g.hidden=old.hidden?;g.transformation=old.transformation;g
      end
      def next_transform(g,oldp,p,changes)
        tr=g.transformation*legacy_anchor(g);delta=p['rotation'].to_f-oldp['rotation'].to_f
        tr=tr*Geom::Transformation.rotation(ORIGIN,Z_AXIS,delta*Math::PI/180) unless delta.abs<1e-9
        if (changes.keys & %w[z_offset level_id placement_mode]).any?
          model=Sketchup.active_model;global=model.edit_transform*tr;v=global.origin
          z=p['placement_mode']=='level' ? Project.level_z(p['level_id'])+p['z_offset'] : v.z+p['z_offset']-oldp['z_offset']
          target=Geom::Point3d.new(v.x,v.y,z).transform(model.edit_transform.inverse);tr=Geom::Transformation.new(tr.origin.vector_to(target))*tr
        end
        tr
      end
      def edited_params(g,changes)
        d=Metadata.read(g);oldp=params(g);p=Parameters.normalize(d['type'],changes,oldp)
        overrides=oldp.fetch('part_overrides',{}).merge(Parts.snapshot(g)) { |_key,old,current| old.merge(current) };roles=Parameters.tool(d['type'])['roles'].select { |r| changes.key?(r['key']) }.map { |r| r['id'] }
        Parts.list(g).each { |part| overrides.delete(part['key']) if roles.include?(part['role']) };p['part_overrides']=overrides
        if p['path_points'] && changes.key?('length') && oldp['length'].to_f>0
          ratio=p['length']/oldp['length'];a=p['path_points'].first;p['path_points']=p['path_points'].map { |v| [a[0]+(v[0]-a[0])*ratio,a[1]+(v[1]-a[1])*ratio,v[2]] }
        end
        if p['footprint'] && (changes.keys & %w[width depth]).any?
          rx=p['width']/oldp['width'];ry=p['depth']/oldp['depth'];p['footprint']=p['footprint'].map { |v| [v[0]*rx,v[1]*ry,v[2]] }
        end
        if p['legacy_segments'] && (changes.keys-%w[name mark tag z_offset level_id placement_mode rotation]).any?
          raise 'Legacy merged walls are preserved, but geometry edits require redrawing with the new wall tool.'
        end
        [oldp,p]
      end
      def edit(g,changes)
        raise 'Object is locked.' if g.locked?
        d=Metadata.read(g);kind=d['type'];oldp,p=edited_params(g,changes)
        if (changes.keys-%w[name mark tag]).empty?
          g.set_attribute('Draupr','params_json',JSON.generate(p)) if d['params_json']
          g.set_attribute('Draupr','mark',p['mark']);g.name=p['name'].to_s.empty? ? "Draupr #{Parameters.tool(kind)['label']}" : p['name']
          g.layer=Sketchup.active_model.layers[p['tag']] || Sketchup.active_model.layers.add(p['tag']) unless p['tag'].to_s.empty?
          return g
        end
        return Hosts.edit_opening(g,oldp,p,changes) if d['hosts_json'] && %w[door window skylight dormer].include?(kind)
        tr=next_transform(g,oldp,p,changes);p['openings']=Walls.holes(g) if kind=='wall'
        # Joined walls are rebuilt once without stale cap coordinates, then the shared solver refreshes both endpoints in edit_many.
        p.delete('wall_end_overrides') if kind=='wall' && p['wall_joins']
        uid=d['uid']||SecureRandom.uuid;ng=create(kind,p,tr,Geometry.parent_entities(g),uid);copy_identity(g,ng);ng.transformation=tr;capture(ng,kind,p,uid);g.erase!
        Hosts.reposition_for_wall(ng) if kind=='wall';ng
      end
      def edit_many(ids,changes)
        raise 'No objects selected.' if ids.empty?
        ids=[id(resolve_for_edit(ids.first))] if ids.length==1
        results=[];result_ids=[]
        Transactions.run('Edit Draupr selection') do
          ids.each do |uid|
            g=get(uid);allowed=Parameters.tool(Metadata.read(g)['type'])['fields'].map { |f| f['key'] };patch=changes.select { |k,_| allowed.include?(k) };updated=patch.empty? ? g : edit(g,patch);results<<updated;result_ids<<id(updated)
          end
          ids_after=result_ids;WallJunctions.refresh_for_ids(ids_after) if defined?(WallJunctions)
          results=ids_after.map { |uid| get(uid) };sel=Sketchup.active_model.selection;sel.clear;ids_after.each { |uid| sel.add(get(uid)) }
        end;results
      end
      def to_ui(g,requested_unit=nil)
        d=Metadata.read(g);p=params(g)
        legacy=!d['params_json'];inf=legacy ? legacy_level_inference(g) : nil;{'id'=>id(g),'kind'=>d['type'],'name'=>g.name,'legacy'=>legacy,'legacyUnresolved'=>legacy && !inf['safe'],'legacyInference'=>inf,'locked'=>g.locked?,'params'=>Parameters.for_ui(d['type'],p,requested_unit),'derived'=>Parameters.derived(d['type'],p,requested_unit),'parts'=>Parts.list(g),'hosted'=>!!d['hosts_json'],'position'=>g.transformation.origin.to_a.map { |v| Parameters.display_length(v,requested_unit) }}
      end
      def adopt_selected
        Transactions.run('Adopt Draupr copies') do
          raise 'Select exactly one copied object.' unless selected.length==1
          selected.each do |g|
            uid=g.get_attribute('Draupr','uid')
            raise 'This object does not have a copied identity.' unless uid && all.count { |o| o.get_attribute('Draupr','uid')==uid }>1
            raise 'Select the copy, not the original object.' if g.get_attribute('Draupr','entity_pid')==g.persistent_id
            Parts.independent_tree(g);g.set_attribute('Draupr','uid',SecureRandom.uuid);g.delete_attribute('Draupr','hosts_json');g.set_attribute('Draupr','entity_pid',g.persistent_id)
            if Metadata.read(g)['type']=='wall'
              ops=Walls.holes(g).map { |o| o.reject { |k,_| k=='oid' } };g.set_attribute('Draupr','openings',JSON.generate(ops))
            end
          end
        end
      end
    end
  end
end
