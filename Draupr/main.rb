# frozen_string_literal: true
require 'sketchup.rb'
require 'json'
require 'securerandom'
require 'tmpdir'
require 'base64'
require 'csv'
require 'fileutils'
require 'digest'
module Draupr
  ROOT=File.dirname(__FILE__) unless const_defined?(:ROOT)
  SRC=File.join(ROOT,'src') unless const_defined?(:SRC)
  %w[data_schema settings materials tags geometry metadata diag preferences parameters transforms path_frames object_index i18n parts project builders molding_profiles railing_presets warehouse_railings builders_architecture].each { |name| Sketchup.require File.join(SRC,'core',name) }
  # Read-only legacy geometry recovery; no native boolean operation is used.
  Sketchup.require File.join(SRC,'tools','walls','wall_carve')
  %w[walls objects wall_junctions wall_connections hosts material_service reports scenes library_service roof_tools modify_tools modifier_suite].each { |name| Sketchup.require File.join(SRC,'core',name) }
  Sketchup.require File.join(SRC,'studio','draw_tool')
  Sketchup.require File.join(SRC,'studio','pickers')
  Sketchup.require File.join(SRC,'studio','modifier_pickers')
  Sketchup.require File.join(SRC,'ui','dialog')
  Core::Diag.clear
  Core::Diag.log("Draupr #{EXTENSION_VERSION}; SketchUp #{Sketchup.version}")
  def self.show_panel;UI::Dialog.show;end
  def self.edit_selection;UI::Dialog.show('edit');end
  def self.start_wall_tool
    p=Core::Parameters.normalize('wall',{},Core::Preferences.defaults_for('wall'))
    p['level_id']=Core::Project.active_level
    Sketchup.active_model.select_tool(Studio::DrawTool.new('wall',p,'path'))
  rescue StandardError => e;::UI.messagebox(e.message);end
  unless file_loaded?(__FILE__)
    menu=::UI.menu('Extensions').add_submenu('Draupr')
    commands={
      'Open Draupr Studio'=>proc { Draupr.show_panel },
      'Edit Draupr Selection'=>proc { Draupr.edit_selection },
      'Draw Draupr Wall'=>proc { Draupr.start_wall_tool },
      'Sample Material'=>proc { Draupr.show_panel;Sketchup.active_model.select_tool(Studio::MaterialPicker.new('sample')) }
    }
    toolbar=::UI::Toolbar.new('Draupr')
    commands.each do |name,action|
      cmd=::UI::Command.new(name,&action);cmd.tooltip=name;cmd.status_bar_text=name
      file=name.include?('Wall') ? 'wall' : 'icon'
      cmd.small_icon=File.join(SRC,'assets',"#{file}_16.png");cmd.large_icon=File.join(SRC,'assets',"#{file}_24.png")
      # Only the Studio launcher goes on the toolbar; the rest stay in the Extensions menu.
      menu.add_item(cmd);toolbar.add_item(cmd) if name=='Open Draupr Studio'
    end
    menu.add_separator
    menu.add_item('Synchronize Linked Openings') { begin;Core::Hosts.sync;rescue StandardError=>e;::UI.messagebox(e.message);end }
    menu.add_item('Run Native Smoke Test (Empty Model)') { begin;result=Core::NativeTest.run;::UI.messagebox(JSON.pretty_generate(result)) if result;rescue StandardError=>e;::UI.messagebox(e.message);end }
    ::UI.add_context_menu_handler do |context|
      next if Core::Objects.selected.empty?
      context.add_item('Edit in Draupr Studio') { Draupr.edit_selection }
    end
    toolbar.show;file_loaded(__FILE__)
  end
end
