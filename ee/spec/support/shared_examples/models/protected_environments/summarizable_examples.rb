# frozen_string_literal: true

RSpec.shared_examples 'summarizable for deployment approvals' do
  let_it_be_with_refind(:deployment) { create(:deployment, :blocked, project: project, environment: environment) }

  let(:summary) { deployment.approval_summary }
  let(:rule_in_summary) { summary.rules.first }

  it 'is summarizable' do
    expect(summary.rules.count).to eq(1)
    expect(rule_in_summary).to be_a(described_class)
  end

  describe '#approved_count' do
    it 'returns one with approval' do
      create_approval(:approved)

      expect(rule_in_summary.approved_count).to eq(1)
    end

    it 'returns zero without approval' do
      expect(rule_in_summary.approved_count).to eq(0)
    end
  end

  describe '#approved?' do
    it 'returns true with approval' do
      create_approval(:approved)

      expect(rule_in_summary.approved?).to eq(true)
    end

    it 'returns false without approval' do
      expect(rule_in_summary.approved?).to eq(false)
    end
  end

  describe '#rejected?' do
    it 'returns true with rejection' do
      create_approval(:rejected)

      expect(rule_in_summary.rejected?).to eq(true)
    end

    it 'returns false without rejection' do
      expect(rule_in_summary.rejected?).to eq(false)
    end
  end

  describe '#status' do
    it 'returns approved with approval' do
      create_approval(:approved)

      expect(rule_in_summary.status).to eq('approved')
    end

    it 'returns rejected with rejection' do
      create_approval(:rejected)

      expect(rule_in_summary.status).to eq('rejected')
    end

    it 'returns pending approval without approval' do
      expect(rule_in_summary.status).to eq('pending_approval')
    end
  end

  describe '#pending_approval_count' do
    it 'returns zero with approval' do
      create_approval(:approved)

      expect(rule_in_summary.pending_approval_count).to eq(0)
    end

    it 'returns one without approval' do
      expect(rule_in_summary.pending_approval_count).to eq(1)
    end
  end

  def create_approval(status)
    create(:deployment_approval, status, deployment: deployment, user: approver, approval_rule: approval_rule)
  end
end
