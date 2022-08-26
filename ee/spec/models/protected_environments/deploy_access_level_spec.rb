# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ProtectedEnvironments::DeployAccessLevel do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:access_level) }

    it {
      is_expected.to validate_inclusion_of(:group_inheritance_type)
                          .in_array(ProtectedEnvironments::Authorizable::GROUP_INHERITANCE_TYPE.values)
    }
  end

  it_behaves_like 'authorizable for protected environments',
    factory_name: :protected_environment_deploy_access_level
end
