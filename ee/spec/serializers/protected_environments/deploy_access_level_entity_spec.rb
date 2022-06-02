# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedEnvironments::DeployAccessLevelEntity do
  describe '#as_json' do
    it 'includes the exposed fields' do
      deploy_access_level = build(:protected_environment_deploy_access_level)
      output = described_class.new(deploy_access_level).as_json

      expect(output).to include(:id, :access_level, :protected_environment_id, :user_id, :group_id,
        :group_inheritance_type)
    end
  end
end
