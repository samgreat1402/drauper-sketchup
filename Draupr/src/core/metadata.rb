# frozen_string_literal: true

module Draupr
  module Core
    module Metadata
      DICT = 'Draupr'

      def self.write(entity, values)
        values.each { |k, v| entity.set_attribute(DICT, k.to_s, v) }
        entity.set_attribute(DICT, 'version', Draupr::EXTENSION_VERSION) if defined?(Draupr::EXTENSION_VERSION)
      end

      def self.read(entity)
        dict = entity.attribute_dictionary(DICT, false)
        return {} unless dict
        dict.keys.each_with_object({}) { |k, memo| memo[k] = dict[k] }
      end
    end
  end
end
