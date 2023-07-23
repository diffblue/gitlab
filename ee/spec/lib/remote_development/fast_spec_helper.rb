# frozen_string_literal: true

if $LOADED_FEATURES.include?(File.expand_path('../../../../spec/spec_helper.rb', __dir__.to_s))
  # return if spec_helper is already loaded, so we don't accidentally override any configuration in it
  return
end

if ENV['SPRING_TMP_PATH']
  warn "\n\n\nERROR: Spring is detected as running due to ENV['SPRING_TMP_PATH']=#{ENV['SPRING_TMP_PATH']} found.\n\n" \
       "Do not run #{__FILE__} with Spring enabled, it can cause Zeitwerk errors.\n\n" \
       "Exiting.\n\n"

  exit 1
end

require_relative '../../../../spec/fast_spec_helper'
require_relative '../../../../spec/support/helpers/next_instance_of'
require_relative '../../../../spec/support/matchers/result_matchers'
require_relative '../../support/helpers/remote_development/railway_oriented_programming_helpers'
require_relative '../../support/shared_contexts/remote_development/agent_info_status_fixture_not_implemented_error'
require_relative '../../support/shared_contexts/remote_development/remote_development_shared_contexts'

require 'rspec-parameterized'
require 'json_schemer'
require 'devfile'

RSpec.configure do |config|
  config.include NextInstanceOf
  config.mock_with :rspec do |mocks|
    mocks.verify_doubled_constant_names = false
  end
end
