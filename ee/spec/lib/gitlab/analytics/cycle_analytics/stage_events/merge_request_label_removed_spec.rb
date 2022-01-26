# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLabelRemoved do
  it_behaves_like 'value stream analytics event' do
    let(:label_id) { 10 }
    let(:params) { { label: GroupLabel.new(id: label_id) } }
    let(:expected_hash_code) { Digest::SHA256.hexdigest("#{instance.class.identifier}-#{label_id}") }
  end

  it_behaves_like 'LEFT JOIN-able value stream analytics event' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:label) { create(:label, project: project) }
    let_it_be(:record_with_data) { create(:labeled_merge_request, :unique_branches, source_project: project, labels: [label]) }
    let_it_be(:record_without_data) { create(:merge_request) }
    let_it_be(:user) { project.first_owner }

    let(:params) { { label: label } }

    before(:context) do
      Sidekiq::Worker.skipping_transaction_check do
        MergeRequests::UpdateService.new(project: project, current_user: user, params: { label_ids: [] }).execute(record_with_data)
      end
    end
  end
end
