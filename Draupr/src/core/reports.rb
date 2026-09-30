# frozen_string_literal: true
module Draupr
  module Core
    module Reports
      module_function
      def rows(requested_unit=nil)
        levels=Project.levels.each_with_object({}) { |l,h| h[l['id']]=l['name'] }
        Objects.all.map do |g|
          d=Metadata.read(g);p=Objects.params(g);tr=g.transformation
          length_mm=rounded(d['length_mm'])
          {'name'=>g.name,'type'=>d['type'],'mark'=>p['mark'],'level'=>levels.fetch(p['level_id'],p['level_id'].to_s),'length_mm'=>length_mm,'length_display'=>length_mm.nil? ? nil : Parameters.display_length(length_mm.to_f.mm,requested_unit),'area_m2'=>rounded(d['area_m2']),'volume_m3'=>rounded(d['volume_m3']),'width_mm'=>rounded(d['width_mm']),'height_mm'=>rounded(d['height_mm']),'sill_mm'=>rounded(d['sill_mm']),'material'=>d['material'],'scaled'=>[tr.xaxis,tr.yaxis,tr.zaxis].any? { |a| (a.length-1).abs>0.00001 }}
        end
      end
      def rounded(v);v.nil? ? nil : v.to_f.round(3);end
      def safe(v)
        return v unless v.is_a?(String)
        v.match?(/\A[=+@\-]/) ? "'#{v}" : v
      end
      def export(kind)
        path=::UI.savepanel('Export Draupr report',nil,"draupr_#{kind}.csv");return false unless path
        data=rows('mm')
        if kind=='openings'
          data.select! { |r| %w[door window skylight dormer].include?(r['type']) }
          keys=%w[mark name type level width_mm height_mm sill_mm material scaled]
        elsif kind=='materials'
          grouped={}
          data.each do |r|
            key=r['material'].to_s.empty? ? '(unassigned)' : r['material'].to_s
            q=(grouped[key]||={'material'=>key,'objects'=>0,'length_mm'=>0.0,'area_m2'=>0.0,'volume_m3'=>0.0})
            q['objects']+=1;q['length_mm']+=r['length_mm'].to_f;q['area_m2']+=r['area_m2'].to_f;q['volume_m3']+=r['volume_m3'].to_f
          end
          data=grouped.values;keys=%w[material objects length_mm area_m2 volume_m3]
        elsif kind=='levels'
          grouped={}
          data.each do |r|
            q=(grouped[r['level']]||={'level'=>r['level'],'objects'=>0,'length_mm'=>0.0,'area_m2'=>0.0,'volume_m3'=>0.0})
            q['objects']+=1;q['length_mm']+=r['length_mm'].to_f;q['area_m2']+=r['area_m2'].to_f;q['volume_m3']+=r['volume_m3'].to_f
          end
          data=grouped.values;keys=%w[level objects length_mm area_m2 volume_m3]
        else
          keys=%w[name type mark level length_mm area_m2 volume_m3 material scaled]
        end
        File.open(path,'w:UTF-8') do |f|
          f.write("\uFEFF");csv=CSV.new(f);csv<<keys
          data.each { |r| csv<<keys.map { |k| safe(r[k]) } }
        end;true
      end
    end
    module NativeTest
      class Rollback < StandardError;end
      module_function
      def run
        model=Sketchup.active_model
        raise 'Run this test in a NEW EMPTY model with no active editing context.' unless model.entities.to_a.empty? && model.active_path.nil?
        answer=::UI.messagebox('Run the Draupr native smoke test? Temporary objects are built and then rolled back. Use an empty test model only.',MB_YESNO)
        return false unless answer==IDYES
        results=[]
        expected_tools=Draupr::RELEASE.fetch('tool_count').to_i;actual_tools=Parameters::TOOLS.length
        raise "Release metadata expects #{expected_tools} tools; schema loaded #{actual_tools}." unless expected_tools==actual_tools
        results<<{'test'=>"Release/schema tool count = #{actual_tools}",'pass'=>true}
        expected_fields=Draupr::RELEASE.fetch('field_count').to_i;actual_fields=Parameters::TOOLS.values.sum { |tool| tool['fields'].length }
        raise "Release metadata expects #{expected_fields} fields; schema loaded #{actual_fields}." unless expected_fields==actual_fields
        results<<{'test'=>"Release/schema field count = #{actual_fields}",'pass'=>true}
        original_unit=Preferences.get('units','mm')
        begin
          probe_unit=original_unit.to_s=='ft' ? 'cm' : 'ft';Preferences.set('units',probe_unit);Preferences.reload!(true)
          raise 'Input/display unit did not survive durable preference reload' unless Preferences.get('units','mm').to_s==probe_unit
          results<<{'test'=>'Input/display unit persists after clearing session preference memory','pass'=>true}
          Preferences.set('units',original_unit);Preferences.reload!(true)
          units={'mm'=>['mm',0.001],'cm'=>['cm',0.01],'m'=>['m',0.1],'in'=>['"',0.01],'ft'=>["'",0.02]}
          units.each do |unit,(suffix,tolerance_mm)|
            Preferences.set('units',unit);shown=Parameters.display_length(1000.mm,unit)
            raise "#{unit}: display suffix did not update (#{shown})" unless shown.end_with?(" #{suffix}")
            parsed=Parameters.length(shown);delta_mm=(parsed-1000.mm).abs*25.4
            raise "#{unit}: display/input round trip exceeded #{tolerance_mm} mm (#{delta_mm.round(6)} mm)" if delta_mm>tolerance_mm
          end
          results<<{'test'=>'Input/display units: mm → cm → m → in → ft round trip','pass'=>true}
        ensure
          Preferences.set('units',original_unit);Preferences.reload!(true)
        end
        begin
          Transactions.run('Draupr native smoke test — rolled back') do
            Parameters::TOOLS.each_key do |kind|
              p=Parameters.defaults(kind);p['level_id']=Project.active_level
              p['turn']='L' if kind=='stair';p['railing']=true if kind=='stair'
              p['path_points']=[[0.0,0.0,0.0],[3000.mm.to_f,0.0,0.0]] if kind=='molding'
              # A standalone Dormer builder needs the slope normally derived from its picked host face.
              # Keep this synthetic fixture pitched; flat-host rejection is tested separately below.
              if kind=='dormer'
                p['host_slope']=0.5;p['host_slope_rise']=p['depth'].to_f*0.5;p['host_surface_factor']=1.0/Math.sqrt(1.0+0.5**2)
              end
              tr=Geom::Transformation.new([10000.mm,20000.mm,500.mm])*Geom::Transformation.rotation(ORIGIN,Z_AXIS,37*Math::PI/180)
              g=Objects.create(kind,p,tr)
              raise "#{kind}: missing geometry" if g.entities.to_a.empty?
              before=g.transformation.to_a
              field=Parameters.tool(kind)['fields'].find { |f| f['key']=='height' }
              patch=field ? {'height'=>p['height']+10.mm} : {'mark'=>'QA'}
              expected=Parameters.normalize(kind,patch,p)
              g=Objects.edit(g,patch)
              raise "#{kind}: transform changed" unless before==g.transformation.to_a
              actual=Objects.params(g)
              Parameters.tool(kind)['fields'].each { |f| k=f['key'];raise "#{kind}: parameter #{k} lost" unless actual[k]==expected[k] }
              results<<{'test'=>"#{kind}: create → edit → preserve parameters and transform",'pass'=>true}
            end
            molding=Parameters.defaults('molding');molding['path_points']=[[0,0,0],[3000.mm.to_f,0,0],[3000.mm.to_f,2000.mm.to_f,0]]
            molding_group=Objects.create('molding',molding,Geom::Transformation.translation([20000.mm,30000.mm,0]))
            molding_sweeps=Parts.list(molding_group).select { |part| part['role']=='molding' }
            stored_molding=Objects.params(molding_group)
            raise 'Three-point molding did not preserve all path points' unless stored_molding['path_points'].length==3
            raise 'Three-point molding did not create one continuous mitered sweep' unless molding_sweeps.length==1
            results<<{'test'=>'Molding path: three clicks create one continuous mitered Follow Me sweep','pass'=>true}
            source_edges=model.active_entities.add_edges(Geom::Point3d.new(0,40000.mm,0),Geom::Point3d.new(2500.mm,40000.mm,0),Geom::Point3d.new(2500.mm,42000.mm,0))
            ordered,closed=Studio::PathCreation.order_edges(source_edges)
            raise 'Selected-edge path ordering failed' unless ordered.length==3 && closed==false
            source_edges.each { |edge| edge.erase! if edge.valid? }
            results<<{'test'=>'Linear input: selected edges order into one copied parametric path','pass'=>true}
            pa=Parameters.defaults('wall');pa['path_points']=[[0,0,0],[4000.mm.to_f,0,0]]
            pb=Parameters.defaults('wall');pb['path_points']=[[4000.mm.to_f,-2000.mm.to_f,0],[4000.mm.to_f,2000.mm.to_f,0]]
            ta=Geom::Transformation.translation([30000.mm,0,0]);wa=Objects.create('wall',pa,ta);wb=Objects.create('wall',pb,ta);ua=Objects.id(wa);ub=Objects.id(wb)
            WallJunctions.commit(wa,Geom::Point3d.new(1000.mm,0,0),wb,Geom::Point3d.new(4000.mm,-1000.mm,0),'butt',0)
            ja=Objects.params(Objects.get(ua))['wall_joins']||{};jb=Objects.params(Objects.get(ub))['wall_joins']||{}
            raise 'Persistent wall butt join metadata missing' if ja.empty? || jb.empty?
            results<<{'test'=>'Wall junction: piece-to-keep butt join persists on both standalone walls','pass'=>true}
            chain=Parameters.defaults('wall');chain['path_points']=[[0,0,0],[2500.mm.to_f,0,0],[2500.mm.to_f,1800.mm.to_f,0]]
            segments=WallJunctions.create_path_segments(chain,Geom::Transformation.translation([40000.mm,0,0]))
            raise 'Wall path was not split into two standalone objects' unless segments.length==2 && segments.all? { |g| Objects.params(g)['path_points'].length==2 }
            joins=segments.map { |g| Objects.params(g)['wall_joins']||{} };raise 'Internal wall-path corner cleanup is not persistent' unless joins.all? { |j| !j.empty? }
            results<<{'test'=>'Wall path: create standalone segments with persistent internal miter','pass'=>true}
            p=Parameters.defaults('wall');p['length']=6000.mm.to_f;p['height']=3000.mm.to_f
            wall=Objects.create('wall',p);uid=wall.get_attribute('Draupr','uid')
            win=Hosts.place('window',Parameters.defaults('window'),wall,0,1000.mm)
            wall=Objects.get(uid);raise 'Opening record missing' unless Walls.holes(wall).length==1
            win=Objects.edit(win,{'width'=>1500.mm.to_f,'sill'=>1100.mm.to_f});wall=Objects.get(uid)
            hole=Walls.holes(wall).first;raise 'Opening resize not synchronized' unless ((hole['t2']-hole['t1'])-1500.mm).abs<0.001
            Hosts.remove(win);wall=Objects.get(uid);raise 'Opening did not heal' unless Walls.holes(wall).empty?
            results<<{'test'=>'Hosted window place → resize → remove → heal','pass'=>true}
            dormer_types=%w[gabled hipped shed eyebrow segmental barrel flat pointed trapezoidal]
            dormer_types.each_with_index do |dormer_type,index|
              fixture_params=Parameters.defaults('dormer');fixture_params['dormer_type']=dormer_type;fixture_params['depth']=3500.mm.to_f;fixture_params['height']=700.mm.to_f;fixture_params['rise']=300.mm.to_f;fixture_params['host_slope']=1800.0/3500.0;fixture_params['host_slope_rise']=1800.mm.to_f;fixture_params['host_surface_factor']=1.0/Math.sqrt(1.0+fixture_params['host_slope']**2)
              solution=Builders.dormer_solution(fixture_params);raise "#{dormer_type} Dormer escaped its drawn footprint" if solution['actual_depth']>fixture_params['depth']*2.02+1.mm;raise "#{dormer_type} Dormer did not penetrate the host roof correctly" unless solution['front_base']<solution['eave'] && solution['opening'].length>=4
              fixture=Objects.create('dormer',fixture_params,Geom::Transformation.translation([45000.mm,index*2500.mm,0]));raise "#{dormer_type} Dormer fixture was not created" unless fixture&&fixture.valid?;fixture.erase!
            end
            results<<{'test'=>'Dormer catalog: all nine roof types build with planar panels','pass'=>true}
            begin
              invalid=Parameters.defaults('dormer');invalid['host_slope']=0.0;Builders.dormer_solution(invalid)
              raise 'Flat-host Dormer validation did not reject zero slope'
            rescue StandardError=>error
              raise unless error.message.include?('too flat')
            end
            results<<{'test'=>'Dormer validation: flat host is rejected without weakening production guard','pass'=>true}
            rp=Parameters.defaults('roof');rp['style']='gable';rp['width']=8000.mm.to_f;rp['depth']=6000.mm.to_f;rp['rise']=1800.mm.to_f
            host_roof=Objects.create('roof',rp,Geom::Transformation.translation([50000.mm,0,0]));roof_uid=Objects.id(host_roof);quad=Builders.roof_faces(rp).first
            normal=quad[0].vector_to(quad[1]).cross(quad[1].vector_to(quad[2]));normal.normalize!;axis_x=Z_AXIS.cross(normal);axis_x.normalize!;axis_y=normal.cross(axis_x);axis_y.normalize!
            center=Geom::Point3d.new(quad.sum(&:x)/quad.length,quad.sum(&:y)/quad.length,quad.sum(&:z)/quad.length);origin=center.offset(axis_x,-600.mm).offset(axis_y,-450.mm)
            rec={'o'=>origin.to_a,'x'=>axis_x.to_a,'y'=>axis_y.to_a,'w'=>1200.mm.to_f,'d'=>2200.mm.to_f};frame={'record'=>rec,'transform'=>host_roof.transformation*Geom::Transformation.axes(origin,axis_x,axis_y,normal)}
            dp=Parameters.defaults('dormer');dp['dormer_type']='gabled';dp['height']=600.mm.to_f;dp['rise']=250.mm.to_f;dormer=Hosts.place_on_roof('dormer',dp,host_roof,frame);host_roof=Objects.get(roof_uid)
            raise 'Hosted dormer relationship missing' if Hosts.records(dormer).empty?
            raise 'Dormer did not cut one roof opening' unless Hosts.roof_holes(host_roof).length==1
            raise 'Dormer did not keep a vertical local axis' unless dormer.transformation.zaxis.parallel?(host_roof.transformation.zaxis)
            origin2=center.offset(axis_x,1100.mm).offset(axis_y,-1000.mm);rec2={'o'=>origin2.to_a,'x'=>axis_x.to_a,'y'=>axis_y.to_a,'w'=>800.mm.to_f,'d'=>2200.mm.to_f};frame2={'record'=>rec2,'transform'=>host_roof.transformation*Geom::Transformation.axes(origin2,axis_x,axis_y,normal)}
            dp2=dp.merge('dormer_type'=>'hipped');dormer2=Hosts.place_on_roof('dormer',dp2,host_roof,frame2);host_roof=Objects.get(roof_uid)
            raise 'Second dormer did not preserve two independent roof openings' unless Hosts.roof_holes(host_roof).length==2
            raise 'Roof opening records were not bound to a canonical slope' unless Hosts.roof_holes(host_roof).all? { |opening| opening.key?('face') }
            dormer=Objects.edit(dormer,{'dormer_type'=>'trapezoidal','width'=>1100.mm.to_f});host_roof=Objects.get(roof_uid);raise 'Edited Dormer lost its host or sibling opening' unless dormer.valid? && Hosts.roof_holes(host_roof).length==2 && Hosts.records(dormer).first['id']==roof_uid
            Hosts.remove(dormer);host_roof=Objects.get(roof_uid);raise 'Removing one dormer damaged the other opening' unless Hosts.roof_holes(host_roof).length==1
            Hosts.remove(dormer2);host_roof=Objects.get(roof_uid);raise 'Removing both dormers did not heal roof' unless Hosts.roof_holes(host_roof).empty?
            results<<{'test'=>'Hosted dormers: exact valley cuts → edit identity → second Dormer → independent heal','pass'=>true}
            raise Rollback
          end
        rescue Rollback
          results<<{'test'=>'Temporary model changes rolled back','pass'=>model.entities.to_a.empty?}
        rescue StandardError => e
          results<<{'test'=>e.message,'pass'=>false};Diag.log_error('Native smoke test',e)
        end
        {'version'=>Draupr::EXTENSION_VERSION,'passed'=>results.count { |r| r['pass'] },'failed'=>results.count { |r| !r['pass'] },'checks'=>results,'note'=>'This smoke test does not replace interactive Undo/Redo, saving/reopening, host movement and cross-version visual QA.'}
      end
    end
  end
end
