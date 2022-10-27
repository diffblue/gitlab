# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ProtectedEnvironments::ApprovalRule do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:environment) { create(:environment, project: project) }
  let_it_be(:approver) { create(:user) }

  let!(:protected_environment) { create(:protected_environment, project: project, name: environment.name) }

  let!(:approval_rule) do
    create(:protected_environment_approval_rule, protected_environment: protected_environment,
                                                 user: approver,
                                                 required_approvals: 1)
  end

  describe 'associations' do
    it { is_expected.to have_many(:deployment_approvals).class_name('Deployments::Approval').inverse_of(:approval_rule) }
  end

  it_behaves_like 'authorizable for protected environments',
    factory_name: :protected_environment_approval_rule

  it_behaves_like 'summarizable for deployment approvals'

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
