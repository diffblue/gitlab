# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExternalStatusChecks::UpdateService do
  let_it_be(:project) { create(:project) }
  let_it_be(:check) { create(:external_status_check, project: project) }
  let_it_be(:protected_branch) { create(:protected_branch, project: project) }

  let(:current_user) { project.first_owner }
  let(:params) { { id: project.id, check_id: check.id, external_url: 'http://newvalue.com', name: 'new name', protected_branch_ids: [protected_branch.id] } }

  subject { described_class.new(container: project, current_user: current_user, params: params).execute }

  context 'when current user is project owner' do
    it 'updates an approval rule' do
      subject

      check.reload

      expect(check.external_url).to eq('http://newvalue.com')
      expect(check.name).to eq('new name')
      expect(check.protected_branches).to contain_exactly(protected_branch)
    end

    it 'is successful' do
      expect(subject.success?).to be true
    end
  end

  context 'when current user is not a project owner' do
    let_it_be(:current_user) { create(:user) }

    it 'does not change an approval rule' do
      expect { subject }.not_to change { check.name }
    end

    it 'is unsuccessful' do
      expect(subject.error?).to be true
    end

    it 'returns an unauthorized status' do
      expect(subject.http_status).to eq(:unauthorized)
    end

    it 'contains an appropriate message and error' do
      expect(subject.message).to eq('Failed to update rule')
      expect(subject.payload[:errors]).to contain_exactly('Not allowed')
    end
  end
end
