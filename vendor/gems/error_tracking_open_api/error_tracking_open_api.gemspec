# -*- encoding: utf-8 -*-

=begin
#Error Tracking REST API

#This schema describes the API endpoints for the error tracking feature

The version of the OpenAPI document: 0.0.1

Generated by: https://openapi-generator.tech
OpenAPI Generator version: 6.0.0

=end

$:.push File.expand_path("../lib", __FILE__)
require "error_tracking_open_api/version"

Gem::Specification.new do |s|
  s.name        = "error_tracking_open_api"
  s.version     = ErrorTrackingOpenAPI::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["OpenAPI-Generator"]
  s.email       = [""]
  s.homepage    = "https://openapi-generator.tech"
  s.summary     = "Error Tracking REST API Ruby Gem"
  s.description = "This schema describes the API endpoints for the error tracking feature"
  s.license     = "MIT"
  s.required_ruby_version = ">= 2.4"

  s.add_runtime_dependency 'typhoeus', '~> 1.0', '>= 1.0.1'

  s.add_development_dependency 'rspec', '~> 3.6', '>= 3.6.0'

  s.files         = Dir.glob("lib/**/*")
  s.test_files    = []
  s.executables   = []
  s.require_paths = ["lib"]
end
