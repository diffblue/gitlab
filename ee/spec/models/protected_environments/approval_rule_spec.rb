# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ProtectedEnvironments::ApprovalRule do
  describe 'associations' do
    it { is_expected.to have_many(:deployment_approvals).class_name('Deployments::Approval').inverse_of(:approval_rule) }
  end

  it_behaves_like 'authorizable for protected environments',
    factory_name: :protected_environment_approval_rule

  describe 'validation' do
    it 'has a limit on required_approvals' do
      is_expected.to validate_numericality_of(:required_approvals)
        .only_integer.is_greater_than_or_equal_to(1).is_less_than_or_equal_to(5)
    end

    it {
      is_expected.to validate_inclusion_of(:group_inheritance_type)
                          .in_array(ProtectedEnvironments::Authorizable::GROUP_INHERITANCE_TYPE.values)
    }
  end
end
