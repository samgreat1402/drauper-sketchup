# frozen_string_literal: true

# Draupr SketchUp Extension loader
require 'sketchup.rb'
require 'extensions.rb'
require 'json'

release_path=File.join(File.dirname(__FILE__),'Draupr','src','config','release.json')
release=JSON.parse(File.read(release_path,encoding:'UTF-8')).freeze
module Draupr
  EXTENSION_ID = 'com.draupr.architectural_modeler'
  EXTENSION_NAME = 'Draupr'
end
Draupr.const_set(:RELEASE,release) unless Draupr.const_defined?(:RELEASE)
Draupr.const_set(:EXTENSION_VERSION,release.fetch('version')) unless Draupr.const_defined?(:EXTENSION_VERSION)

unless file_loaded?(__FILE__)
  extension = SketchupExtension.new(Draupr::EXTENSION_NAME, 'Draupr/main')
  extension.description = 'Parametric architectural modeling, relationships, materials, libraries, and reports for SketchUp.'
  extension.version = Draupr::EXTENSION_VERSION
  extension.creator = 'Draupr Studio'
  Sketchup.register_extension(extension, true)
  file_loaded(__FILE__)
end
