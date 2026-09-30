# frozen_string_literal: true

module Draupr
  module Core
    module Preferences
      # Use a conservative SketchUp defaults section and namespaced keys.
      KEY='Draupr'
      KEY_PREFIX='studio_'.freeze
      SCHEMA_KEY='studio_preferences_schema'.freeze
      LEGACY_KEYS=['Draupr_Studio_Preferences','com.draupr.studio','Draupr_Studio_040'].freeze
      SCHEMA_VERSION=4
      VALUE_PREFIX='draupr-json-v1:'.freeze
      MIGRATABLE_KEYS=(%w[language units keep_drawing theme workspace category tool presets library_folder railing_library_folder material_favorites material_recent]+%w[wall curtain_wall door window column foundation beam slab grid stair roof railing louver ramp skylight dormer molding].map { |k| "defaults_#{k}" }).freeze
      module_function
      def storage_key(key);"#{KEY_PREFIX}#{key}";end
      def decode(raw,fallback=nil)
        return fallback if raw.nil?
        return raw unless raw.is_a?(String)
        text=raw
        4.times do
          return JSON.parse(text[VALUE_PREFIX.length..]) if text.start_with?(VALUE_PREFIX)
          begin
            parsed=JSON.parse(text)
            return parsed unless parsed.is_a?(String) && parsed!=text
            text=parsed
          rescue StandardError
            return text
          end
        end
        text
      rescue StandardError
        raw
      end
      def encode(value)
        # Native strings are the most portable SketchUp preference values.
        value.is_a?(String) ? value : VALUE_PREFIX+JSON.generate(value)
      end
      def memory;@memory||={};end
      def migrate!
        return if @migrated
        @migrated=true
        current=Sketchup.read_default(KEY,SCHEMA_KEY,nil)
        return if current.to_i>=SCHEMA_VERSION
        MIGRATABLE_KEYS.each do |name|
          target=storage_key(name);next unless Sketchup.read_default(KEY,target,nil).nil?
          raw=nil
          LEGACY_KEYS.each do |legacy|
            raw=Sketchup.read_default(legacy,name,nil);break unless raw.nil?
          end
          Sketchup.write_default(KEY,target,encode(decode(raw))) unless raw.nil?
        end
        Sketchup.write_default(KEY,SCHEMA_KEY,SCHEMA_VERSION)
      rescue StandardError => e
        @migrated=false;Diag.log_error('Preference migration',e) if defined?(Diag)
      end
      def reload!(clear_memory=false)
        @migrated=false;@memory={} if clear_memory;migrate!;true
      end
      def get(key,fallback=nil)
        migrate!;name=key.to_s;return memory[name] if memory.key?(name)
        value=decode(Sketchup.read_default(KEY,storage_key(name),nil),fallback);memory[name]=value;value
      rescue StandardError
        memory.fetch(key.to_s,fallback)
      end
      def set(key,value)
        migrate!;name=key.to_s;memory[name]=value
        Sketchup.write_default(KEY,storage_key(name),encode(value))
        persisted=decode(Sketchup.read_default(KEY,storage_key(name),nil),nil)
        Diag.log("Preference #{name} kept in session memory; SketchUp returned #{persisted.inspect}.") if persisted!=value && defined?(Diag)
        value
      rescue StandardError => e
        Diag.log_error("Preference #{key}",e) if defined?(Diag);value
      end
      def schema_version;migrate!;Sketchup.read_default(KEY,SCHEMA_KEY,SCHEMA_VERSION).to_i;end
      def defaults_for(kind);get("defaults_#{kind}",{});end
      def snapshot
        fallbacks={'language'=>'en','units'=>'mm','keep_drawing'=>true,'theme'=>'light','workspace'=>'create','category'=>'envelope','tool'=>'wall'}
        fallbacks.each_with_object({}) { |(k,v),h| h[k]=get(k,v) }
      end
    end
    module Transactions
      @depth=0
      module_function
      def busy?;@depth.to_i>0;end
      def run(name)
        owner=false;return yield if busy?;owner=true;model=Sketchup.active_model;started=false;@depth=1
        model.start_operation(name,true);started=true;result=yield;model.commit_operation;started=false;result
      rescue StandardError=>e
        model.abort_operation if started;Diag.log_error(name,e) if defined?(Diag);raise
      ensure
        @depth=0 if owner
      end
    end
  end
end
