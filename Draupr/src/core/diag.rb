# frozen_string_literal: true

module Draupr
  module Core
    # Diagnostic log: every placement/carve/trim step is appended to a
    # plain-text log so failures on a user's machine can be pinpointed.
    # The log path is %TEMP%\draupr_debug.log (Windows) or $TMPDIR / home.
    module Diag
      def self.log(message)
        File.open(log_path, 'a') do |f|
          f.puts("#{Time.now.strftime('%Y-%m-%d %H:%M:%S.%L')} #{message}")
        end
      rescue
        nil
      end

      def self.log_error(context, error)
        bt = error.backtrace ? error.backtrace.first(6).join(' | ') : ''
        log("ERROR #{context}: #{error.class}: #{error.message} :: #{bt}")
      end

      def self.log_path
        dir = ENV['TEMP'] || ENV['TMP'] || ENV['TMPDIR'] || safe_home || Dir.pwd
        File.join(dir, 'draupr_debug.log')
      end

      def self.safe_home
        Dir.home
      rescue
        nil
      end

      def self.clear
        File.delete(log_path) if File.exist?(log_path)
      rescue
        nil
      end
    end
  end
end
