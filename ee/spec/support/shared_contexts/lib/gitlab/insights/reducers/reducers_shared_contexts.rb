# frozen_string_literal: true

RSpec.shared_context 'Insights issues reducer context' do |state = :opened|
  around do |example|
    travel_to(Time.utc(2019, 5, 5)) { example.run }
  end

  let(:period_fied) do
    case state
    when :closed
      :closed_at
    else
      :created_at
    end
  end

  let(:project) { create(:project, :public) }
  let(:label_bug) { create(:label, project: project, name: 'Bug') }
  let(:label_manage) { create(:label, project: project, name: 'Manage') }
  let(:label_plan) { create(:label, project: project, name: 'Plan') }
  let!(:issuable0) { create(:labeled_issue, state, period_fied => Time.utc(2019, 1, 5), project: project) }
  let!(:issuable1) { create(:labeled_issue, state, period_fied => Time.utc(2019, 1, 5), labels: [label_bug], project: project) }
  let!(:issuable2) { create(:labeled_issue, state, period_fied => Time.utc(2019, 3, 5), labels: [label_bug, label_manage, label_plan], project: project) }
  let!(:issuable3) { create(:labeled_issue, state, period_fied => Time.utc(2019, 4, 5), labels: [label_bug, label_plan], project: project) }
end

RSpec.shared_context 'Insights merge requests reducer context' do |state = :opened|
  around do |example|
    travel_to(Time.utc(2019, 5, 5)) { example.run }
  end

  let(:project) { create(:project, :public) }
  let(:label_bug) { create(:label, project: project, name: 'Bug') }
  let(:label_manage) { create(:label, project: project, name: 'Manage') }
  let(:label_plan) { create(:label, project: project, name: 'Plan') }
  let!(:issuable0) { create(:labeled_merge_request, state, :simple, created_at: Time.utc(2019, 1, 5), source_project: project) }
  let!(:issuable1) { create(:labeled_merge_request, state, :with_image_diffs, created_at: Time.utc(2019, 1, 5), labels: [label_bug], source_project: project) }
  let!(:issuable2) { create(:labeled_merge_request, state, :without_diffs, created_at: Time.utc(2019, 3, 5), labels: [label_bug, label_manage, label_plan], source_project: project) }
  let!(:issuable3) { create(:labeled_merge_request, state, :rebased, created_at: Time.utc(2019, 4, 5), labels: [label_bug, label_plan], source_project: project) }
end
