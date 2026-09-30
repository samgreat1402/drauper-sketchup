# frozen_string_literal: true

module Draupr
  module Core
    module Scenes
      PLAN_NAME='Draupr Plan'.freeze
      ELEVATION_NAME='Draupr Elevation'.freeze
      module_function
      def page(model,name)
        found=model.pages.find { |p| p.name==name }
        found || model.pages.add(name)
      end
      def plan_section(model,cut_z)
        ents=model.entities
        sp=ents.grep(Sketchup::SectionPlane).find { |q| q.get_attribute('Draupr','scene_role')=='plan_cut' }
        sp ||= ents.add_section_plane([0,0,cut_z],[0,0,-1])
        sp.set_attribute('Draupr','scene_role','plan_cut')
        sp.name='Draupr Plan Cut' if sp.respond_to?(:name=)
        sp.set_plane([0,0,cut_z],[0,0,-1]) if sp.respond_to?(:set_plane)
        sp
      end
      def create_scenes
        model=Sketchup.active_model;level=Core::Project.level_z.to_f;cut_z=level+1200.mm;ents=model.entities;result=nil
        Transactions.run('Create Draupr scenes') do
          sp=plan_section(model,cut_z);ents.active_section_plane=sp if ents.respond_to?(:active_section_plane=)
          cam=Sketchup::Camera.new([0,0,cut_z+10000.mm],[0,0,cut_z],[0,1,0]);cam.perspective=false;model.active_view.camera=cam
          plan=page(model,PLAN_NAME);plan.update
          ents.active_section_plane=nil if ents.respond_to?(:active_section_plane=)
          eye=[2500.mm,-9000.mm,level+1500.mm];cam2=Sketchup::Camera.new(eye,[2500.mm,0,level+1500.mm],[0,0,1]);cam2.perspective=false;model.active_view.camera=cam2
          elevation=page(model,ELEVATION_NAME);elevation.update
          result={'plan'=>PLAN_NAME,'elevation'=>ELEVATION_NAME,'level_id'=>Core::Project.active_level}
        end
        ::UI.messagebox(I18n.message('Plan and Elevation scenes updated for the active level.','صحنه‌های پلان و نما برای تراز فعال به‌روزرسانی شدند.'))
        result
      rescue StandardError=>e
        Core::Diag.log_error('Create scenes',e) if defined?(Core::Diag)
        ::UI.messagebox("Draupr scenes failed:
#{e.message}");false
      end
    end
  end
end
