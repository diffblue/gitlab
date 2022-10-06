# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Deployments::ApprovalSummary do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:group_user_1) { create(:user) }
  let_it_be(:group_user_2) { create(:user) }
  let_it_be(:approver_user) { create(:user) }
  let_it_be(:project_maintainer) { create(:user) }
  let_it_be_with_refind(:environment) { create(:environment, project: project) }
  let_it_be_with_refind(:deployment) { create(:deployment, project: project, environment: environment) }

  let_it_be_with_refind(:protected_environment) do
    create(:protected_environment, name: environment.name, project: project)
  end

  let_it_be_with_refind(:approval_rule_group) do
    create(:protected_environment_approval_rule,
           group: group, protected_environment: protected_environment, required_approvals: 2)
  end

  let_it_be_with_refind(:approval_rule_user) do
    create(:protected_environment_approval_rule, user: approver_user, protected_environment: protected_environment)
  end

  let_it_be_with_refind(:approval_rule_role) do
    create(:protected_environment_approval_rule, :maintainer_access, protected_environment: protected_environment)
  end

  let(:approval_summary) { described_class.new(deployment: deployment) }

  before_all do
    group.add_developer(group_user_1)
    group.add_developer(group_user_2)
    project.add_maintainer(project_maintainer)
  end

  shared_context 'with all rules have been approved' do
    before do
      create(:deployment_approval, deployment: deployment, user: group_user_1, approval_rule: approval_rule_group)
      create(:deployment_approval, deployment: deployment, user: group_user_2, approval_rule: approval_rule_group)
      create(:deployment_approval, deployment: deployment, user: approver_user, approval_rule: approval_rule_user)
      create(:deployment_approval, deployment: deployment, user: project_maintainer, approval_rule: approval_rule_role)
    end
  end

  shared_context 'with one rule has multiple approvals' do
    before do
      create(:deployment_approval, deployment: deployment, user: group_user_1, approval_rule: approval_rule_group)
      create(:deployment_approval, deployment: deployment, user: group_user_2, approval_rule: approval_rule_group)
    end
  end

  shared_context 'with one rule has been approved' do
    before do
      create(:deployment_approval, deployment: deployment, user: approver_user, approval_rule: approval_rule_user)
    end
  end

  shared_context 'with one rule has been rejected' do
    before do
      create(:deployment_approval, :rejected, deployment: deployment, user: approver_user,
                                              approval_rule: approval_rule_user)
    end
  end

  shared_context 'with unrelated deployment approvals exist' do
    before do
      create(:deployment_approval, user: group_user_1, approval_rule: approval_rule_group)
      create(:deployment_approval, user: group_user_2, approval_rule: approval_rule_group)
      create(:deployment_approval, user: approver_user, approval_rule: approval_rule_user)
      create(:deployment_approval, user: project_maintainer, approval_rule: approval_rule_role)
    end
  end

  describe '#total_required_approvals' do
    subject { approval_summary.total_required_approvals }

    it { is_expected.to eq(4) }
  end

  describe '#total_pending_approval_count' do
    subject { approval_summary.total_pending_approval_count }

    context 'when all rules have been approved' do
      include_context 'with all rules have been approved'

      it { is_expected.to eq(0) }
    end

    context 'when one rule has multiple approvals' do
      include_context 'with one rule has multiple approvals'

      it { is_expected.to eq(2) }
    end

    context 'when one rule has been approved' do
      include_context 'with one rule has been approved'

      it { is_expected.to eq(3) }
    end

    context 'when one rule has been rejected' do
      include_context 'with one rule has been rejected'

      it { is_expected.to eq(4) }
    end

    context 'when no rules have been approved' do
      it { is_expected.to eq(4) }
    end

    context 'when unrelated deployment approvals exist' do
      include_context 'with unrelated deployment approvals exist'

      it { is_expected.to eq(4) }
    end
  end

  describe '#status' do
    subject { approval_summary.status }

    context 'when all rules have been approved' do
      include_context 'with all rules have been approved'

      it { is_expected.to eq(described_class::STATUS_APPROVED) }
    end

    context 'when one rule has multiple approvals' do
      include_context 'with one rule has multiple approvals'

      it { is_expected.to eq(described_class::STATUS_PENDING_APPROVAL) }
    end

    context 'when one rule has been approved' do
      include_context 'with one rule has been approved'

      it { is_expected.to eq(described_class::STATUS_PENDING_APPROVAL) }
    end

    context 'when one rule has been rejected' do
      include_context 'with one rule has been rejected'

      it { is_expected.to eq(described_class::STATUS_REJECTED) }
    end

    context 'when no rules have been approved' do
      it { is_expected.to eq(described_class::STATUS_PENDING_APPROVAL) }
    end

    context 'when unrelated deployment approvals exist' do
      include_context 'with unrelated deployment approvals exist'

      it { is_expected.to eq(described_class::STATUS_PENDING_APPROVAL) }
    end
  end

  describe '#rules' do
    subject { approval_summary.rules }

    let(:group_type_rule) { subject.find(&:group_type?) }
    let(:user_type_rule) { subject.find(&:user_type?) }
    let(:role_type_rule) { subject.find(&:role?) }

    shared_examples 'contains the required approval counts per type' do
      it do
        expect(group_type_rule.required_approvals).to eq(2)
        expect(user_type_rule.required_approvals).to eq(1)
        expect(role_type_rule.required_approvals).to eq(1)
      end
    end

    context 'when all rules have been approved' do
      include_context 'with all rules have been approved'
      it_behaves_like 'contains the required approval counts per type'

      it 'correctly renders the approval summary' do
        expect(group_type_rule.approvals_for_summary.map(&:user)).to contain_exactly(group_user_1, group_user_2)
        expect(user_type_rule.approvals_for_summary.map(&:user)).to contain_exactly(approver_user)
        expect(role_type_rule.approvals_for_summary.map(&:user)).to contain_exactly(project_maintainer)
      end
    end

    context 'when one rule has multiple approvals' do
      include_context 'with one rule has multiple approvals'
      it_behaves_like 'contains the required approval counts per type'

      it 'correctly renders the approval summary' do
        expect(group_type_rule.approvals_for_summary.map(&:user)).to contain_exactly(group_user_1, group_user_2)
        expect(role_type_rule.approvals_for_summary.map(&:user)).to be_empty
        expect(role_type_rule.approvals_for_summary.map(&:user)).to be_empty
      end
    end

    context 'when one rule has been approved' do
      include_context 'with one rule has been approved'
      it_behaves_like 'contains the required approval counts per type'

      it 'correctly renders the approval summary' do
        expect(group_type_rule.approvals_for_summary.map(&:user)).to be_empty
        expect(user_type_rule.approvals_for_summary.map(&:user)).to contain_exactly(approver_user)
        expect(role_type_rule.approvals_for_summary.map(&:user)).to be_empty
      end
    end

    context 'when no rules have been approved' do
      it_behaves_like 'contains the required approval counts per type'

      it 'correctly renders the approval summary' do
        expect(group_type_rule.approvals_for_summary.map(&:user)).to be_empty
        expect(user_type_rule.approvals_for_summary.map(&:user)).to be_empty
        expect(role_type_rule.approvals_for_summary.map(&:user)).to be_empty
      end
    end

    context 'when unrelated deployment approvals exist' do
      include_context 'with unrelated deployment approvals exist'
      it_behaves_like 'contains the required approval counts per type'

      it 'correctly renders the approval summary' do
        expect(group_type_rule.approvals_for_summary.map(&:user)).to be_empty
        expect(user_type_rule.approvals_for_summary.map(&:user)).to be_empty
        expect(role_type_rule.approvals_for_summary.map(&:user)).to be_empty
      end
    end
  end
end
