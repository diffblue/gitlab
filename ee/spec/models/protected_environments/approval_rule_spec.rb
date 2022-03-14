# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ProtectedEnvironments::ApprovalRule do
  describe 'associations' do
    it { is_expected.to have_many(:deployment_approvals).class_name('Deployments::Approval').inverse_of(:approval_rule) }
  end

  it_behaves_like 'authorizable for protected environments',
    factory_name: :protected_environment_approval_rule
end
