# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::Latest::IssueClassProxy, :elastic, :sidekiq_inline, feature_category: :global_search do
  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  subject { described_class.new(Issue, use_separate_indices: true) }

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

  describe '#issue_aggregations' do
    before do
      project.add_developer(user)
      ensure_elasticsearch_index!
    end

    it 'returns aggregations' do
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

  describe '#elastic_search' do
    describe 'search on basis of hidden attribute' do
      let(:result) { subject.elastic_search('test', options: options) }

      context 'when author of the issue is banned' do
        before do
          issue.author.ban
          ensure_elasticsearch_index!
        end

        it 'current_user is an admin user then user can see the issue' do
          allow(user).to receive(:can_admin_all_resources?).and_return(true)
          expect(elasticsearch_hit_ids(result)).to include issue.id
        end

        it 'current_user is a non admin user then user can not see the issue' do
          expect(elasticsearch_hit_ids(result)).not_to include issue.id
        end

        it 'current_user is empty then user can not see the issue' do
          options[:current_user] = nil
          result = subject.elastic_search('test', options: options)
          expect(elasticsearch_hit_ids(result)).not_to include issue.id
        end
      end

      context 'when author of the issue is active' do
        before do
          ensure_elasticsearch_index!
        end

        it 'current_user is an admin user then user can see the issue' do
          allow(user).to receive(:can_admin_all_resources?).and_return(true)
          expect(elasticsearch_hit_ids(result)).to include issue.id
        end

        it 'current_user is a non admin user then user can see the issue' do
          expect(elasticsearch_hit_ids(result)).to include issue.id
        end

        it 'current_user is empty then user can see the issue' do
          options[:current_user] = nil
          result = subject.elastic_search('test', options: options)
          expect(elasticsearch_hit_ids(result)).to include issue.id
        end
      end
    end
  end
end
