# frozen_string_literal: true
module Draupr
  module UI
    class SelectionWatcher < Sketchup::SelectionObserver
      def onSelectionBulkChange(_s);Dialog.selection_changed;end
      def onSelectionAdded(_s,_e);Dialog.selection_changed;end
      def onSelectionRemoved(_s,_e);Dialog.selection_changed;end
      def onSelectionCleared(_s);Dialog.selection_changed;end
    end
    class ModelWatcher < Sketchup::ModelObserver
      def refresh;Core::ObjectIndex.invalidate;Dialog.selection_changed;end
      def onTransactionCommit(_m);refresh;end
      def onTransactionUndo(_m);refresh;end
      def onTransactionRedo(_m);refresh;end
      def onTransactionAbort(_m);refresh;end
    end
    class AppWatcher < Sketchup::AppObserver
      def onActivateModel(_m);Dialog.model_changed;end
      def onOpenModel(_m);Dialog.model_changed;end
      def onNewModel(_m);Dialog.model_changed;end
    end
    class EditPreview < Studio::DrawTool
      def initialize(kind,p,tr)
        super(kind,p,'point');@preview_transform=tr
      end
      def configuration(_points=nil);[@p,@preview_transform];end
      def activate;Sketchup.set_status_text('Draupr wireframe preview only. Esc or click exits; Apply in Studio commits the edit.');end
      def enableVCB?;false;end
      def onMouseMove(_f,_x,_y,v);v.invalidate;end
      def onLButtonDown(_f,_x,_y,v);Sketchup.active_model.select_tool(nil);v.invalidate;end
      def onUserText(_text,_v);end
      def onCancel(_r,v);Sketchup.active_model.select_tool(nil);v.invalidate;end
    end
    module Dialog
      module_function
      def visible?;@dialog && @dialog.visible?;end
      def show(workspace=nil)
        if visible?
          @dialog.bring_to_front;event('workspace',{'workspace'=>workspace}) if workspace;return
        end
        @ready=false;@initial_workspace=workspace
        dlg=::UI::HtmlDialog.new(dialog_title:'Draupr Studio',preferences_key:'com.draupr.studio',scrollable:false,resizable:true,width:610,height:820,min_width:420,min_height:560,style: ::UI::HtmlDialog::STYLE_DIALOG)
        @dialog=dlg
        dlg.add_action_callback('studioCommand') { |_context,raw| command(raw) }
        dlg.set_on_closed do
          if @dialog.equal?(dlg)
            detach;@dialog=nil;@ready=false
          end
        end
        attach
        unless @app_watcher
          @app_watcher=AppWatcher.new;Sketchup.add_observer(@app_watcher)
        end
        dlg.set_file(File.join(Draupr::SRC,'ui','panel.html'));dlg.show
      end
      def attach
        detach;@model=Sketchup.active_model;@selection_watcher=SelectionWatcher.new;@model_watcher=ModelWatcher.new
        @model.selection.add_observer(@selection_watcher);@model.add_observer(@model_watcher)
      end
      def detach
        ::UI.stop_timer(@timer) if @timer;@timer=nil
        if @model
          @model.selection.remove_observer(@selection_watcher) if @selection_watcher
          @model.remove_observer(@model_watcher) if @model_watcher
        end
      rescue StandardError
        nil
      ensure
        @model=nil;@selection_watcher=nil;@model_watcher=nil
      end
      def model_changed
        return unless visible?
        attach;event('selection',{'selection'=>selection});notify('Active model changed. Refresh Studio to load its project levels.','info')
      end
      def selection_changed
        return unless @ready && visible?
        ::UI.stop_timer(@timer) if @timer
        @timer=::UI.start_timer(0.15,false) { @timer=nil;event('selection',{'selection'=>selection}) if @ready && visible? }
      end
      def selection(requested_unit=nil)
        Core::Objects.selected.map { |g| Core::Objects.to_ui(g,requested_unit) }
      rescue StandardError => e
        Core::Diag.log_error('Selection inspector',e);notify(e.message,'error');[]
      end
      def event(type,payload={})
        return unless @ready && visible?
        json=JSON.generate({'type'=>type,'payload'=>payload}).gsub("\u2028",'\\u2028').gsub("\u2029",'\\u2029')
        @dialog.execute_script("window.Draupr && window.Draupr.receive(#{json})")
      rescue StandardError => e
        Core::Diag.log_error('Studio response',e)
      end
      def notify(message,kind='info');event('notice',{'message'=>message.to_s,'kind'=>kind});end
      def bootstrap(unit_override=nil)
        prefs=Core::Preferences.snapshot;prefs['workspace']=@initial_workspace if @initial_workspace;@initial_workspace=nil
        unit=(unit_override || prefs['units'] || 'mm').to_s;prefs['units']=unit
        defs=Core::Parameters::TOOLS.keys.each_with_object({}) do |kind,h|
          h[kind]=Core::Parameters.for_ui(kind,Core::Parameters.normalize(kind,{},Core::Preferences.defaults_for(kind),false),unit)
        end
        {'version'=>Draupr::EXTENSION_VERSION,'preferences'=>prefs,'defaults'=>defs,'selection'=>selection(unit),'project'=>Core::Project.snapshot(unit),'library'=>Core::Library.for_ui,'materials'=>Core::Materials.catalog}
      end
      def command(raw)
        request=nil
        raise 'Studio request exceeds 1 MB.' if raw.to_s.bytesize>1_000_000
        request=JSON.parse(raw.to_s);raise 'Malformed Studio request.' unless request.is_a?(Hash) && request['id'] && request['action']
        action=request['action'];data=request['payload']||{};raise 'Malformed command data.' unless data.is_a?(Hash)
        @ready=true if action=='ready'
        result=dispatch(action,data)
        event('response',{'id'=>request['id'],'ok'=>true,'data'=>result})
      rescue StandardError => e
        @last_error={'message'=>e.message,'backtrace'=>e.backtrace.to_a.first(15)};Core::Diag.log_error('Studio command',e)
        fields=e.respond_to?(:fields) ? e.fields : {}
        event('response',{'id'=>request && request['id'],'ok'=>false,'message'=>e.message,'fields'=>fields})
      end
      def configuration(data)
        kind=Core::Parameters.canonical(data['kind']);p=Core::Library.portable(kind,data.fetch('params',{}));[kind,p]
      end
      def dispatch(action,d)
        case action
        when 'ready','refresh';bootstrap
        when 'selection';selection
        when 'preferences'
          d.each { |k,v| Core::Preferences.set(k,v) if %w[language units keep_drawing theme workspace category tool].include?(k) };Core::Preferences.snapshot
        when 'changeUnits'
          unit=d['units'].to_s;raise 'Choose a supported display unit.' unless %w[mm cm m in ft model].include?(unit)
          Core::Preferences.set('units',unit);bootstrap(unit)
        when 'validate'
          kind,p=configuration(d);{'derived'=>Core::Parameters.derived(kind,p)}
        when 'defaults'
          kind,p=configuration(d);Core::Preferences.set("defaults_#{kind}",p);true
        when 'draw'
          kind,p=configuration(d);mode=d['mode']||Core::Parameters.tool(kind)['mode']
          allowed=case kind;when 'wall' then %w[path line];when 'roof','slab' then %w[rectangle rotated];when 'railing','curtain_wall' then %w[line path];when 'foundation' then %w[point rectangle rotated path];when 'skylight' then %w[host];when 'dormer' then %w[host];else [Core::Parameters.tool(kind)['mode']];end
          raise 'Unsupported drawing mode.' unless allowed.include?(mode)
          tool=if mode=='host' && %w[skylight dormer].include?(kind)
            Studio::RoofOpeningDrawTool.new(kind,p)
          else
            %w[door window].include?(kind) ? Studio::OpeningTool.new(kind,p) : Studio::DrawTool.new(kind,p,mode)
          end
          Sketchup.active_model.select_tool(tool);true
        when 'fromEdges'
          kind,p=configuration(d);Studio::PathCreation.create(kind,p,Studio::PathCreation.selected_edges,d['reverse']==true);selection
        when 'pickPath'
          kind,p=configuration(d);raise 'This object type does not support picked paths.' unless Studio::PathCreation.supported?(kind,p)
          Sketchup.active_model.select_tool(Studio::ConnectedPathPicker.new(kind,p));true
        when 'origin'
          kind,p=configuration(d);z=Core::Project.level_z(p['level_id'])+p['z_offset'];a=Geom::Point3d.new(0,0,z).transform(Sketchup.active_model.edit_transform.inverse)
          tr=Geom::Transformation.new(a)*Geom::Transformation.rotation(ORIGIN,Z_AXIS,p['rotation']*Math::PI/180)
          Core::Transactions.run('Create Draupr at origin') { g=Core::Objects.create(kind,p,tr);s=Sketchup.active_model.selection;s.clear;s.add(g) };selection
        when 'fromFace'
          kind,p=configuration(d);raise 'Selected-face creation supports slabs, roofs and molding profiles.' unless %w[slab roof molding].include?(kind)
          p=p.reject { |k,_| %w[footprint path_points end_trims openings].include?(k) }
          if kind=='molding'
            p=Studio::FaceCreation.molding_profile(p)
            Sketchup.active_model.select_tool(Studio::DrawTool.new(kind,p,'path'));true
          else
            Studio::FaceCreation.create(kind,p);selection
          end
        when 'libraryList';Core::LibraryService.list_payload
        when 'librarySetFolder'
          dir=UI.select_directory(title:'Choose the Draupr library folder',directory:Core::LibraryService.folder)
          Core::LibraryService.set_folder(dir) if dir
          Core::LibraryService.list_payload
        when 'librarySave';Core::LibraryService.save_selection(d['name'].to_s,d);Core::LibraryService.list_payload
        when 'libraryDelete';Core::LibraryService.delete_item(d['file'].to_s);Core::LibraryService.list_payload
        when 'libraryRename';Core::LibraryService.rename_item(d['file'].to_s,d['name'].to_s);Core::LibraryService.list_payload
        when 'libraryMetadata';Core::LibraryService.update_metadata(d['file'].to_s,d);Core::LibraryService.list_payload
        when 'libraryOpenFolder';Core::LibraryService.open_folder
        when 'libraryDiagnostics';Core::LibraryService.diagnostics
        when 'railingLibraryStatus';Core::WarehouseRailings.status
        when 'railingLibrarySetFolder'
          dir=UI.select_directory(title:'Choose Local Railing Sources / انتخاب منابع محلی نرده',directory:Core::WarehouseRailings.folder)
          Core::WarehouseRailings.set_folder(dir) if dir
          Core::WarehouseRailings.status
        when 'railingLibraryOpenFolder';Core::WarehouseRailings.open_folder
        when 'railingLibraryDiagnostics';Core::WarehouseRailings.diagnostics
        when 'libraryPlace'
          data=Core::LibraryService.load_item(d['file'].to_s)
          Sketchup.active_model.select_tool(Studio::LibraryPlacementTool.new(data,d));true
        when 'libraryReplace'
          data=Core::LibraryService.load_item(d['file'].to_s);Core::LibraryService.replace_selected(data);selection
        when 'roofIntersection';Core::RoofTools.create('intersection');true
        when 'roofValley';Core::RoofTools.create('valley');true
        when 'roofJoin';Sketchup.active_model.select_tool(Studio::RoofJoinTool.new);true
        when 'alignFaces';Sketchup.active_model.select_tool(Studio::FaceAlignTool.new);true
        when 'wallTrim';Sketchup.active_model.select_tool(Studio::WallTrimExtendTool.new);true
        when 'wallSplit';Sketchup.active_model.select_tool(Studio::AssemblySplitTool.new);true
        when 'modifySplit';Sketchup.active_model.select_tool(Studio::AssemblySplitTool.new);true
        when 'modifyTrim';Sketchup.active_model.select_tool(Studio::PathTrimBoundaryTool.new);true
        when 'modifyAlignBaseline';Sketchup.active_model.select_tool(Studio::BaselineAlignTool.new);true
        when 'modifyAttachBoundary'
          boundary=d['boundary'].to_s;raise 'Boundary must be top or base. / مرز باید بالا یا پایین باشد.' unless %w[top base].include?(boundary);Sketchup.active_model.select_tool(Studio::BoundaryAttachTool.new(boundary));true
        when 'modifyDetachBoundary'
          walls=Core::Objects.selected.select { |object| Core::Metadata.read(object)['type']=='wall' };raise 'Select exactly one Draupr wall. / دقیقاً یک دیوار Draupr انتخاب کنید.' unless walls.length==1;Core::ModifyTools.detach_boundaries(walls.first);selection
        when 'modifyStep'
          delta=Core::Parameters.length(d['delta']);raise 'Step delta cannot be zero. / اختلاف ارتفاع پله نمی‌تواند صفر باشد.' if delta.abs<1.mm;Sketchup.active_model.select_tool(Studio::StepPathTool.new(delta));true
        when 'modifyJunction'
          mode=d['mode'].to_s;raise 'Unsupported junction mode. / نوع اتصال پشتیبانی نمی‌شود.' unless %w[butt_left butt_right miter square fillet chamfer].include?(mode);radius=Core::Parameters.length(d['radius']||'300 mm');Sketchup.active_model.select_tool(Studio::JunctionModifierTool.new(mode,radius));true
        when 'modifyHealOpening';Sketchup.active_model.select_tool(Studio::OpeningModifierTool.new('heal'));true
        when 'modifySplayOpening'
          options={'angle'=>d['angle'].to_f,'sillSlope'=>d['sillSlope'].to_f,'setback'=>Core::Parameters.length(d['setback']||'0 mm')};Sketchup.active_model.select_tool(Studio::OpeningModifierTool.new('splay',options));true
        when 'modifySweep'
          options={'anchor'=>d['anchor'].to_s,'flip'=>d['flip']==true,'startReturn'=>d['startReturn']==true,'endReturn'=>d['endReturn']==true,'returnLength'=>Core::Parameters.length(d['returnLength']||'50 mm')};Sketchup.active_model.select_tool(Studio::SweepModifierTool.new(options));true
        when 'modifyDisassemble'
          raise 'Confirm the one-way disassembly first. / ابتدا جداسازی یک‌طرفه را تأیید کنید.' unless d['confirmed']==true;objects=d.fetch('ids',[]).map { |id| Core::Objects.get(id) };Core::ModifyTools.disassemble(objects);true
        when 'modifyEdgeDetail'
          style=d['style'].to_s;raise 'Choose chamfer or bullnose. / پخ یا گرده را انتخاب کنید.' unless %w[chamfer bullnose].include?(style);Core::ModifyTools.detail_edges(Sketchup.active_model.selection.grep(Sketchup::Edge),style,Core::Parameters.length(d['size']||'20 mm'));true
        when 'edit'
          Sketchup.active_model.select_tool(nil);Core::Objects.edit_many(d.fetch('ids',[]),d.fetch('changes',{}));selection
        when 'previewEdit'
          g=Core::Objects.resolve_for_edit(d['id']);old,p=Core::Objects.edited_params(g,d.fetch('changes',{}));kind=Core::Metadata.read(g)['type']
          if g.get_attribute('Draupr','hosts_json')
            host_record=Core::Hosts.records(g).first;host=Core::Hosts.resolve_record_host(g,host_record)
            if Core::Metadata.read(host)['type']=='roof'
              opening=Core::Hosts.roof_holes(host).find { |item| item['oid']==Core::Objects.id(g) };raise 'Roof opening record is missing.' unless opening
              surface_y=Geom::Vector3d.new(*opening['y']);factor=kind=='dormer' ? Geom::Vector3d.new(surface_y.x,surface_y.y,0).length : 1.0;surface_depth=kind=='dormer' ? p['depth'].to_f/[factor,0.0001].max : p['depth'].to_f
              preview_record=opening.merge('w'=>p['width'].to_f,'d'=>surface_depth);p,tr=Core::Hosts.roof_object_placement(kind,p,host,preview_record);Core::Builders.dormer_solution(p) if kind=='dormer'
            else
              f=Core::Hosts.frame(host,host_record['seg'],p);tr=f['transform'];p['depth']=f['depth']
            end
          else;tr=Core::Objects.next_transform(g,old,p,d.fetch('changes',{}));end
          Sketchup.active_model.select_tool(EditPreview.new(kind,p,tr));true
        when 'adopt';Core::Objects.adopt_selected;selection
        when 'delete','heal';destructive(action,d)
        when 'sync';Core::Hosts.sync;selection
        when 'cancelTool';Sketchup.active_model.select_tool(nil);true
        when 'materials';Core::Materials.catalog(d['query'],d['source'])
        when 'sample';Sketchup.active_model.select_tool(Studio::MaterialPicker.new('sample'));true
        when 'pickPart';Sketchup.active_model.select_tool(Studio::MaterialPicker.new('part'));true
        when 'assign';Core::Materials.assign(d);true
        when 'materialFavorite';Core::Materials.favorite(d['name'],d['value']);true
        when 'importTexture';Core::Materials.import_texture
        when 'editMaterial';Core::Materials.edit_material(d)
        when 'panel';edit_panel(d)
        when 'savePreset';Core::Library.save(d);Core::Library.for_ui
        when 'deletePreset';Core::Library.remove(d['id']);Core::Library.for_ui
        when 'favoritePreset';Core::Library.favorite(d['id'],d['value']);Core::Library.for_ui
        when 'exportPresets';Core::Library.export_file
        when 'importPresets';Core::Library.import_file;Core::Library.for_ui
        when 'levels';Core::Project.save_levels(d.fetch('levels',[]),d['active'])
        when 'audit';Core::Project.audit
        when 'quantities';Core::Reports.rows(Core::Preferences.get('units','mm'))
        when 'exportQuantities';Core::Reports.export('quantities')
        when 'exportSchedule';Core::Reports.export('openings')
        when 'exportMaterials';Core::Reports.export('materials')
        when 'exportLevels';Core::Reports.export('levels')
        when 'scenes';Core::Scenes.create_scenes;true
        when 'nativeTest';Core::NativeTest.run
        when 'diagnostics'
          path=::UI.savepanel('Export Draupr diagnostics',nil,'draupr_diagnostics.json');return false unless path
          info={'version'=>Draupr::EXTENSION_VERSION,'sketchup'=>Sketchup.version,'ruby'=>RUBY_VERSION,'time'=>Time.now.to_s,'preferencesSchema'=>Core::Preferences.schema_version,'dataSchema'=>Core::DataSchema::VERSION,'preferencesSchema'=>Core::Preferences.schema_version,'dataSchema'=>Core::DataSchema::VERSION,'preferences'=>Core::Preferences.snapshot,'audit'=>Core::Project.audit,'lastError'=>@last_error}
          File.write(path,JSON.pretty_generate(info),encoding:'UTF-8');true
        else;raise "Unsupported Studio command: #{action}"
        end
      end
      def destructive(action,d)
        raise 'Confirm the destructive operation first.' unless d['confirmed']==true
        Core::Transactions.run(action=='delete' ? 'Delete Draupr objects' : 'Heal Draupr walls') do
          groups=d.fetch('ids',[]).map { |id| Core::Objects.get(id) };raise 'Select an object first.' if groups.empty?
          raise 'A selected object is locked.' if groups.any?(&:locked?)
          if action=='delete'
            targets=groups.sort_by { |g| Core::Metadata.read(g)['type']=='wall' ? 1 : 0 }.map { |g| Core::Hosts.ensure_uid(g) }
            targets.each { |id| found=Core::Objects.all.find { |g| Core::Objects.id(g)==id };Core::Hosts.remove(found) if found }
          else
            raise 'Select only walls to heal.' unless groups.all? { |g| Core::Metadata.read(g)['type']=='wall' }
            ids=groups.map { |g| Core::Hosts.ensure_uid(g) }
            Core::Objects.all.select { |g| Core::Hosts.records(g).any? { |r| ids.include?(r['id']) } }.each { |g| Core::Hosts.remove(g) if g.valid? }
            walls=ids.map { |id| Core::Walls.recut(Core::Objects.get(id),[]) };sel=Sketchup.active_model.selection;sel.clear;walls.each { |g| sel.add(g) }
          end
        end;true
      end
      def edit_panel(d)
        g=Core::Objects.get(d['id']);raise 'Select a curtain wall.' unless Core::Metadata.read(g)['type']=='curtain_wall';raise 'Object is locked.' if g.locked?
        _old,p=Core::Objects.edited_params(g,{});key=d['part'].to_s;m=/\Apanel_(\d+)_(\d+)\z/.match(key);nx,ny=Core::Parameters.curtain_counts(p)
        raise 'Select a panel in the current grid.' unless m && m[1].to_i<ny && m[2].to_i<nx
        raise 'Choose vision, spandrel or open.' unless %w[vision spandrel open].include?(d['type'])
        material=d['material'].to_s;Core::Materials.by_name_or_default(material,:glass_clear) unless material.empty?
        p['panel_overrides']||={};p['panel_overrides'][key]={'type'=>d['type'],'material'=>material}
        p['part_overrides']=(p['part_overrides']||{}).reject { |k,_| k==key };uid=g.get_attribute('Draupr','uid')||SecureRandom.uuid;tr=g.transformation*Core::Objects.legacy_anchor(g)
        Core::Transactions.run('Edit curtain panel') do
          ng=Core::Objects.create('curtain_wall',p,tr,Core::Geometry.parent_entities(g),uid);Core::Objects.copy_identity(g,ng);ng.transformation=tr;Core::Objects.capture(ng,'curtain_wall',p,uid);g.erase!;s=Sketchup.active_model.selection;s.clear;s.add(ng)
        end;selection
      end
    end
  end
end
