# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::HookData::IssueBuilder do
  let_it_be(:issue) { create(:issue) }

  let(:builder) { described_class.new(issue) }

  describe '#build' do
    let(:data) { builder.build }

    it 'includes safe attribute' do
      %w[
        assignee_id
        author_id
        closed_at
        confidential
        created_at
        description
        due_date
        id
        iid
        last_edited_at
        last_edited_by_id
        milestone_id
        moved_to_id
        project_id
        relative_position
        state_id
        time_estimate
        title
        updated_at
        updated_by_id
        weight
        health_status
      ].each do |key|
        expect(data).to include(key)
      end
    end

    context 'when the issue has an image in the description' do
      let(:issue_with_description) { create(:issue, description: 'test![Issue_Image](/uploads/abc/Issue_Image.png)') }
      let(:builder) { described_class.new(issue_with_description) }

      it 'sets the image to use an absolute URL' do
        expected_path = "#{issue_with_description.project.path_with_namespace}/uploads/abc/Issue_Image.png)"
        expect(data[:description]).to eq("test![Issue_Image](#{Settings.gitlab.url}/#{expected_path}")
      end
    end

    context 'for incident with escalation policies feature enabled' do
      let_it_be(:issue) { create(:incident, :with_escalation_status) }

      before do
        stub_licensed_features(oncall_schedules: true, escalation_policies: true)
      end

      it 'includes additional attr' do
        expect(data).to include(:escalation_policy)
      end
    end
  end
end
