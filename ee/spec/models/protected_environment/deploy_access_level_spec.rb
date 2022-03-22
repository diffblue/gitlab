# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ProtectedEnvironment::DeployAccessLevel do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:access_level) }
  end

  it_behaves_like 'authorizable for protected environments',
    factory_name: :protected_environment_deploy_access_level
end
