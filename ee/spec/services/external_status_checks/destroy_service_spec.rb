# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExternalStatusChecks::DestroyService do
  let_it_be(:project) { create(:project) }
  let_it_be(:rule) { create(:external_status_check, project: project) }

  let(:current_user) { project.first_owner }

  subject { described_class.new(container: project, current_user: current_user).execute(rule) }

  context 'when current user is project owner' do
    it 'deletes an approval rule' do
      expect { subject }.to change { MergeRequests::ExternalStatusCheck.count }.by(-1)
    end

    it 'is successful' do
      expect(subject.success?).to be true
    end
  end

  context 'when current user is not a project owner' do
    let_it_be(:current_user) { create(:user) }

    it 'does not delete an approval rule' do
      expect { subject }.not_to change { MergeRequests::ExternalStatusCheck.count }
    end

    it 'is unsuccessful' do
      expect(subject.error?).to be true
    end

    it 'returns an unauthorized status' do
      expect(subject.http_status).to eq(:unauthorized)
    end

    it 'contains an appropriate message and error' do
      expect(subject.message).to eq('Failed to destroy rule')
      expect(subject.payload[:errors]).to contain_exactly('Not allowed')
    end
  end
end
