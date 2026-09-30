# frozen_string_literal: true
module Draupr
  module Core
    # Per-model index for Draupr root groups. Invalidated after every model transaction
    # and whenever a Draupr root is captured.
    module ObjectIndex
      module_function
      def invalidate(_model=nil);@model=nil;@items=nil;@uids=nil;true;end
      def scan(entities,out,seen)
        entities.grep(Sketchup::Group).each do |group|
          next unless group.valid?;key=group.object_id;next if seen[key];seen[key]=true
          type=group.get_attribute('Draupr','type').to_s
          if Parameters::TOOLS.key?(type);out<<group
          else;scan(group.entities,out,seen);end
        end
      end
      def rebuild
        model=Sketchup.active_model;items=[];scan(model.entities,items,{})
        scan(model.active_entities,items,{}) if model.active_path
        @model=model;@items=items.uniq;@uids=@items.group_by { |group| group.get_attribute('Draupr','uid') || "pid:#{group.persistent_id}" };@items
      end
      def all
        rebuild unless @model.equal?(Sketchup.active_model) && @items
        @items.select(&:valid?)
      end
      def find(uid)
        rebuild unless @model.equal?(Sketchup.active_model) && @uids
        Array(@uids[uid.to_s]).select(&:valid?)
      end
    end
  end
end
