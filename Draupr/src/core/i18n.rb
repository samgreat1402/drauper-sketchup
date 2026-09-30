# frozen_string_literal: true
module Draupr
  module Core
    module I18n
      module_function
      def language;Preferences.get('language','en').to_s;rescue StandardError;'en';end
      def message(english,persian);language=='fa' ? "#{persian} / #{english}" : "#{english} / #{persian}";end
      def status(english,persian);Sketchup.set_status_text(message(english,persian));end
    end
  end
end
