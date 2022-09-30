# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::Latest::IssueClassProxy, :elastic do
  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  subject { described_class.new(Issue, use_separate_indices: true) }

  describe '#issue_aggregations' do
    let!(:project) { create(:project, :public) }
    let!(:label) { create(:label) }
    let!(:issue) { create(:labeled_issue, title: 'test', project: project, labels: [label]) }

    let(:user) { create(:user) }
    let(:options) do
      {
        current_user: user,
        project_ids: [project.id],
        public_and_internal_projects: false,
        order_by: nil,
        sort: nil
      }
    end

    before do
      project.add_developer(user)

      ensure_elasticsearch_index!
    end

    it 'returns aggregations', :sidekiq_inline do
      result = subject.issue_aggregations('test', options)

      expect(result.first.name).to eq('labels')
      expect(result.first.buckets.first.symbolize_keys).to match(
        key: label.id.to_s,
        count: 1,
        title: label.title,
        type: label.type,
        color: label.color.to_s,
        parent_full_name: label.project.full_name
      )
    end
  end
end
