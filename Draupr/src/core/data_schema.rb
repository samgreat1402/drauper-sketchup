# frozen_string_literal: true
module Draupr
  module Core
    module DataSchema
      VERSION=Draupr::RELEASE.fetch('data_schema_version').to_i
      module_function
      def version;VERSION;end
      def supported?(value);value.to_i==VERSION;end
    end
  end
end
