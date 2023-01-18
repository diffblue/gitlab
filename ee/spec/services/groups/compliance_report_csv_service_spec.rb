# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::ComplianceReportCsvService, feature_category: :compliance_management do
  subject(:service) { described_class.new(user, group, filters) }

  let(:filters) { { from: 10.years.ago, to: Time.current } }

  let_it_be(:user) { create(:user, name: 'John Cena') }

  let_it_be(:group) { create(:group, name: 'Kombucha lovers') }
  let_it_be(:sub_group) { create(:group, name: 'sub-group', parent: group) }

  let_it_be(:project1) { create(:project, :repository, namespace: group, name: 'Starter kit') }
  let_it_be(:project2) { create(:project, :repository, namespace: group, name: 'Starter kit 2') }
  let_it_be(:sub_group_project) { create(:project, :repository, namespace: sub_group, name: 'Alpha') }

  let_it_be(:merge_user) { create(:user, name: 'Brock Lesnar') }

  let_it_be(:project1_merge_request) do
    create(:merge_request_with_diffs,
           :with_merged_metrics,
           merged_by: merge_user,
           source_project: project1,
           target_project: project1,
           author: user,
           merge_commit_sha: '347yrv45')
  end

  let_it_be(:project2_merge_request) do
    create(:merge_request_with_diffs,
           :with_merged_metrics,
           merged_by: merge_user,
           source_project: project2,
           target_project: project2,
           author: user,
           merge_commit_sha: '347yrv46')
  end

  let_it_be(:sub_group_merge_request) do
    create(:merge_request_with_diffs,
           :with_merged_metrics,
           merged_by: merge_user,
           source_project: sub_group_project,
           target_project: sub_group_project,
           author: user,
           state: :merged,
           merge_commit_sha: '6f4907e7')
  end

  let_it_be(:project1_approval1) { create(:approval, merge_request: project1_merge_request, user: merge_user) }
  let_it_be(:project1_approval2) do
    create(:approval, merge_request: project1_merge_request, user_id: create(:user, name: 'Kane').id)
  end

  let_it_be(:project2_approval1) { create(:approval, merge_request: project2_merge_request, user: merge_user) }
  let_it_be(:project2_approval2) do
    create(:approval, merge_request: project2_merge_request, user_id: create(:user, name: 'Kane').id)
  end

  let_it_be(:open_merge_request) do
    create(:merge_request, source_project: project2, target_project: project2, author: user)
  end

  context 'when group is missing' do
    subject { described_class.new(user, nil) }

    it "raises an ArgumentError" do
      expect { subject }.to raise_error ArgumentError
    end
  end

  context 'when user is missing' do
    subject { described_class.new(nil, group) }

    it "raises an ArgumentError" do
      expect { subject }.to raise_error ArgumentError
    end
  end

  describe '#csv_data' do
    before_all do
      project1.add_maintainer(user)
      project2.add_maintainer(user)
      sub_group_project.add_maintainer(user)
    end

    it { expect(service.csv_data).to be_success }

    it 'includes the appropriate headers' do
      expect(csv.headers).to eq([
        'Commit Sha',
        'Commit Author',
        'Committed By',
        'Date Committed',
        'Group',
        'Project',
        'Merge Commit',
        'Merge Request',
        'Merged By',
        'Merged At',
        'Pipeline',
        'Approver(s)'
      ])
    end

    context 'when verifying the csv data' do
      let(:all_commits) do
        commits = project1.repository.commits(nil, limit: 100).map(&:sha) +
          project2.repository.commits(nil, limit: 100).map(&:sha) +
          sub_group_project.repository.commits(nil, limit: 100).map(&:sha)
        commits.sort.uniq
      end

      it 'contains all commits from all projects' do
        commits_in_csv = csv.to_a[1..].filter_map(&:first)
        expect(commits_in_csv.sort.uniq).to match_array(all_commits)
      end

      context 'when the row is a commit that belongs to a merge commit' do
        let(:row) { csv.find { |row| row['Merge Request'] == project1_merge_request.id.to_s } }

        specify 'Merge Commit' do
          expect(row['Merge Commit']).to eq project1_merge_request.merge_commit_sha
        end

        specify 'Commit Author' do
          expect(row['Commit Author']).to eq 'John Cena'
        end

        specify 'Merge Request' do
          expect(row['Merge Request']).to eq project1_merge_request.id.to_s
        end

        specify 'Merged By' do
          expect(row['Merged By']).to eq 'Brock Lesnar'
        end

        specify 'Merged At' do
          expect(row['Merged At']).to eq project1_merge_request.merged_at.to_s
        end

        specify 'Pipeline' do
          expect(row['Pipeline']).to eq project1_merge_request.metrics.pipeline_id.to_s
        end

        specify 'Group' do
          expect(row['Group']).to eq 'Kombucha lovers'
        end

        specify 'Project' do
          expect(row['Project']).to eq project1.name
        end

        specify 'Approver(s)' do
          expect(row['Approver(s)']).to eq 'Brock Lesnar | Kane'
        end
      end

      context 'when project inside a subgroup' do
        let(:service) { described_class.new(user, group, filters) }
        let(:row) { csv.find { |row| row['Merge Commit'] == sub_group_merge_request.merge_commit_sha } }

        it { expect(service.csv_data).to be_success }

        it do
          expect(row['Merge Commit']).to eq sub_group_merge_request.merge_commit_sha
        end
      end
    end

    def csv
      data = service.csv_data.payload

      CSV.parse(data, headers: true)
    end
  end

  describe '#enqueue_worker' do
    subject(:service) { described_class.new(user, group, filters) }

    let(:filters) { super().merge(commit_sha: 'a-commit-sha') }
    let(:expected_worker_args) { { user_id: user.id, group_id: group.id, commit_sha: 'a-commit-sha' } }

    before do
      allow(ComplianceManagement::ChainOfCustodyReportWorker).to receive(:perform_async)
    end

    it 'enqueues a worker' do
      response = service.enqueue_worker

      expect(response).to be_success
      expect(ComplianceManagement::ChainOfCustodyReportWorker).to have_received(:perform_async)
                                                                    .with(expected_worker_args)
    end
  end
end
