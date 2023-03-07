# frozen_string_literal: true
require 'spec_helper'

RSpec.describe IssueFeatureFlags::ListService, feature_category: :team_planning do
  let(:user) { create(:user) }
  let(:project) { create(:project_empty_repo, :private) }
  let(:issue) { create(:issue, project: project) }
  let(:feature_flag) { create(:operations_feature_flag, project: project) }

  describe '#execute' do
    subject { described_class.new(issue, user).execute }

    let(:feature_flag_b) { create(:operations_feature_flag, project: project) }
    let(:feature_flag_c) { create(:operations_feature_flag, project: project) }
    let(:feature_flag_d) { create(:operations_feature_flag, project: project) }

    before do
      create(:feature_flag_issue, feature_flag: feature_flag_b, issue: issue)
      create(:feature_flag_issue, feature_flag: feature_flag_c, issue: issue)
      create(:feature_flag_issue, feature_flag: feature_flag_d, issue: issue)
      create(:feature_flag_issue, feature_flag: feature_flag, issue: issue)
    end

    context 'when user can see feature flags' do
      before do
        project.add_developer(user)
      end

      it 'ensures no N+1 queries are made' do
        control_count = ActiveRecord::QueryRecorder.new { described_class.new(issue, user).execute }.count

        expect { described_class.new(issue, user).execute }.not_to exceed_query_limit(control_count)
      end

      it 'returns related feature flags' do
        expect(subject.size).to eq(4)

        expect(subject).to include(include(id: feature_flag.id,
                                           name: feature_flag.name,
                                           path: "/#{project.full_path}/-/feature_flags/#{feature_flag.iid}/edit"))
        expect(subject).to include(include(id: feature_flag_b.id,
                                           name: feature_flag_b.name,
                                           path: "/#{project.full_path}/-/feature_flags/#{feature_flag_b.iid}/edit"))
        expect(subject).to include(include(id: feature_flag_c.id,
                                           name: feature_flag_c.name,
                                           path: "/#{project.full_path}/-/feature_flags/#{feature_flag_c.iid}/edit"))
        expect(subject).to include(include(id: feature_flag_d.id,
                                           name: feature_flag_d.name,
                                           path: "/#{project.full_path}/-/feature_flags/#{feature_flag_d.iid}/edit"))
      end
    end

    context 'when user can not see feature flags' do
      it 'returns nothing' do
        expect(subject.size).to eq(0)
      end
    end
  end
end
