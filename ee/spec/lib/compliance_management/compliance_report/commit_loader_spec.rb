# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::ComplianceManagement::ComplianceReport::CommitLoader, feature_category: :compliance_management do
  let(:project1) { create(:project, :repository, namespace: group, name: 'Starter kit') }
  let(:sub_group_project) { create(:project, :repository, namespace: sub_group, name: 'Alpha') }

  let_it_be(:user) { create(:user, name: 'John Cena') }
  let_it_be(:group) { create(:group, name: 'Kombucha lovers') }
  let_it_be(:sub_group) { create(:group, name: 'sub-group', parent: group) }

  context 'when group is missing' do
    subject(:loader) { described_class.new(nil, user) }

    it "raises an ArgumentError" do
      expect { loader }.to raise_error ArgumentError
    end
  end

  context 'when user is missing' do
    subject(:loader) { described_class.new(group, nil) }

    it "raises an ArgumentError" do
      expect { loader }.to raise_error ArgumentError
    end
  end

  describe '#find_each' do
    subject(:loader) { described_class.new(group, user) }

    before do
      project1.add_maintainer(user)
      sub_group_project.add_maintainer(user)
      stub_const("#{described_class}::COMMITS_PER_PROJECT", 1)
      stub_const("#{described_class}::COMMIT_BATCH_SIZE", 2)
    end

    context 'when an MR exists' do
      subject(:loaded_commit_shas) { [] }

      let(:mr_sha) { create_commit(project1, "merge commit") }
      let(:mr_params) do
        {
          source_project: project1,
          target_project: project1,
          merge_commit_sha: mr_sha
        }
      end

      before do
        create_commit(project1, "commit")
        create(:merge_request_with_diffs, :with_merged_metrics, **mr_params)

        loader.find_each { |r| loaded_commit_shas << r.merge_commit }
      end

      it { expect(loaded_commit_shas.uniq).to match_array [mr_sha] }
    end

    context 'when a project has more than the max commits' do
      let(:expected_size) { described_class::COMMITS_PER_PROJECT }
      let(:commits) do
        commits = []
        loader.find_each { |row| commits << row.sha }
        commits
      end

      before do
        # create commits within a defined 1-month window
        3.times { |i| create_commit(project1, "commit #{i}") }
      end

      it 'only returns the max commits' do
        expect(commits.size).to eq expected_size
      end
    end

    context 'with a subgroup project' do
      let(:commit_messages) do
        commits = []
        loader.find_each { |row| commits << row.commit.message }
        commits
      end

      before do
        # create commits within a defined 1-month window
        create_commit(project1, 'group commit')
        create_commit(sub_group_project, 'subgroup commit')
      end

      it 'returns group and subgroup commits' do
        expect(commit_messages.size).to eq 2
        expect(commit_messages.uniq).to match_array ['subgroup commit', 'group commit']
      end
    end

    context 'with commits that span the 1 month window' do
      let(:commit_messages) do
        commits = []
        loader.find_each { |row| commits << row.commit.message }
        commits
      end

      let(:now) { Time.current }

      before do
        travel_to(now - (1.month + 1.day)) do
          create_commit(project1, 'more than 1 month')
        end
        travel_to(now - 1.month) do
          2.times { |i| create_commit(project1, '1 month') }
        end

        stub_const("#{described_class}::COMMITS_PER_PROJECT", 5)
      end

      it 'returns only the commits within 1 month' do
        travel_to(now) do
          expect(commit_messages.size).to eq 2
          expect(commit_messages.uniq).to match_array ['1 month']
        end
      end
    end

    context 'when a project does not have a repository' do
      let(:project1) { create(:project, namespace: group, name: 'no repo') }
      let(:commits) do
        commits = []
        loader.find_each { |row| commits << row&.commit }
        commits
      end

      it 'does not throw a NoRepository error' do
        expect { loader.find_each { |row| row } }.not_to raise_error
      end

      it 'returns an empty array' do
        expect(commits).to eq([])
      end
    end

    context 'when given a commit sha to filter by' do
      subject(:loader) { described_class.new(group, user, commit_sha: filter_sha) }

      context 'when the sha is a merge commit sha' do
        subject(:loaded_commit_shas) { [] }

        let(:filter_sha) { mr_sha }
        let(:mr_sha) { create_commit(project1, "merge commit 1") }
        let(:mr_params) do
          {
            source_project: project1,
            target_project: project1,
            merge_commit_sha: mr_sha
          }
        end

        before do
          create_commit(project1, "commit")
          create(:merge_request_with_diffs, :with_merged_metrics, **mr_params)
          create(
            :merge_request_with_diffs,
            :with_merged_metrics,
            source_project: project1,
            target_project: project1,
            merge_commit_sha: create_commit(project1, "merge commit 2")
          )
          loader.find_each { |r| loaded_commit_shas << r.merge_commit }
        end

        it { expect(loaded_commit_shas.uniq).to match_array [mr_sha] }
      end

      context 'when the commit is a non-merge commit' do
        subject(:loaded_commit_shas) { [] }

        let(:filter_sha) { create_commit(project1, "child commit") }
        let(:mr_sha) { create_commit(project1, "merge commit 1") }
        let(:mr_params) do
          {
            source_project: project1,
            target_project: project1,
            merge_commit_sha: mr_sha
          }
        end

        before do
          filter_sha
          create(:merge_request_with_diffs, :with_merged_metrics, **mr_params)
          loader.find_each { |r| loaded_commit_shas << r.sha }
        end

        it { expect(loaded_commit_shas.uniq).to match_array [filter_sha] }
      end
    end
  end

  def create_commit(project, message = 'commit message')
    project.repository.raw.commit_files(
      user,
      branch_name: project.repository.root_ref,
      message: message,
      actions: []
    ).newrev
  end
end
