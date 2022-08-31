# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::ProtectedEnvironments::DeployAccessLevel do
  subject { described_class.new(deploy_access_level).as_json }

  let(:deploy_access_level) { build(:protected_environment_deploy_access_level) }

  it 'exposes correct attributes' do
    expect(subject.keys).to contain_exactly(:id, :user_id, :group_id,
                                            :access_level, :access_level_description,
                                            :group_inheritance_type)
  end
end
