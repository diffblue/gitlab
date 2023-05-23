# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ProtectedEnvironments::DeployAccessLevel do
  describe 'validations' do
    it {
      is_expected.to validate_inclusion_of(:group_inheritance_type)
                          .in_array(ProtectedEnvironments::Authorizable::GROUP_INHERITANCE_TYPE.values)
    }

    it 'gets a validation error when all of the authorizable attributes are missing' do
      deploy_access_level = build(:protected_environment_deploy_access_level)
      deploy_access_level.user_id = nil
      deploy_access_level.group_id = nil
      deploy_access_level.access_level = nil

      expect(deploy_access_level).not_to be_valid
      expect(deploy_access_level.errors[:base])
        .to include('Only one of the Group ID, User ID or Access Level must be specified.')
    end

    it 'passes a validation when one of the authorizable attributes is present' do
      deploy_access_level = build(:protected_environment_deploy_access_level)
      deploy_access_level.user_id = nil
      deploy_access_level.group_id = nil
      deploy_access_level.access_level = Gitlab::Access::MAINTAINER

      expect(deploy_access_level).to be_valid
    end

    it 'fails validation when two of the authorizable attributes are present' do
      deploy_access_level = build(:protected_environment_deploy_access_level)
      deploy_access_level.user = create(:user)
      deploy_access_level.group_id = nil
      deploy_access_level.access_level = Gitlab::Access::MAINTAINER

      expect(deploy_access_level).not_to be_valid
      expect(deploy_access_level.errors[:base])
        .to include('Only one of the Group ID, User ID or Access Level must be specified.')
    end

    it 'passes the validation when a valid group_id is set' do
      group = create(:group)

      deploy_access_level = build(:protected_environment_deploy_access_level)
      deploy_access_level.user_id = nil
      deploy_access_level.group_id = group.id
      deploy_access_level.access_level = nil

      expect(deploy_access_level).to be_valid
    end

    it 'fails the validation when an invalid group_id is set' do
      namespace = create(:namespace)

      deploy_access_level = build(:protected_environment_deploy_access_level)
      deploy_access_level.user_id = nil
      deploy_access_level.group_id = namespace.id
      deploy_access_level.access_level = nil

      expect(deploy_access_level).not_to be_valid
      expect(deploy_access_level.errors[:base])
        .to include('There is no corresponding group to the specified Group ID.')
    end
  end

  it_behaves_like 'authorizable for protected environments',
    factory_name: :protected_environment_deploy_access_level

  describe '#access_level' do
    subject { deploy_access_level.access_level }

    it 'returns a value when role type' do
      deploy_access_level = create(:protected_environment_deploy_access_level, :maintainer_access)

      expect(deploy_access_level.access_level).to eq(Gitlab::Access::MAINTAINER)
    end

    it 'returns nil when user type' do
      deploy_access_level = create(:protected_environment_deploy_access_level, user: create(:user))

      expect(deploy_access_level.access_level).to be_nil
    end

    it 'returns nil when group type' do
      deploy_access_level = create(:protected_environment_deploy_access_level, group: create(:group))

      expect(deploy_access_level.access_level).to be_nil
    end
  end
end
