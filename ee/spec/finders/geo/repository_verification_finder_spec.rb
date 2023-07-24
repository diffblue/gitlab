# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::RepositoryVerificationFinder, feature_category: :geo_replication do
  let_it_be(:project) { create(:project) }

  describe '#find_failed_repositories' do
    it 'returns projects where next retry attempt is in the past' do
      create(:repository_state, :repository_failed, :wiki_verified, project: project)

      expect(subject.find_failed_repositories(batch_size: 10))
        .to match_array(project)
    end

    it 'does not return projects where next retry attempt is in the future' do
      create(:repository_state, :repository_failed, :wiki_verified, repository_retry_at: 5.minutes.from_now)

      expect(subject.find_failed_repositories(batch_size: 10)).to be_empty
    end

    it 'does not return projects where repository was recently updated' do
      create(:repository_state, :repository_outdated, project: project)

      expect(subject.find_failed_repositories(batch_size: 10)).to be_empty
    end

    it 'does not return projects where repository verification is pending' do
      create(:repository_state, :wiki_verified, project: project)

      expect(subject.find_failed_repositories(batch_size: 10)).to be_empty
    end

    it 'returns projects ordered by next retry time' do
      next_project = create(:project)
      create(:repository_state, :repository_failed, repository_retry_at: 1.hour.ago, project: project)
      create(:repository_state, :repository_failed, repository_retry_at: 30.minutes.ago, project: next_project)

      expect(subject.find_failed_repositories(batch_size: 10)).to eq [project, next_project]
    end

    context 'with shard restriction' do
      subject { described_class.new(shard_name: project.repository_storage) }

      it 'does not return projects on other shards' do
        project_other_shard = create(:project)
        project_other_shard.update_column(:repository_storage, 'other')
        create(:repository_state, :repository_failed, project: project)
        create(:repository_state, :repository_failed, project: project_other_shard)

        expect(subject.find_failed_repositories(batch_size: 10))
          .to match_array(project)
      end
    end
  end

  describe '#find_recently_updated_projects' do
    it 'returns projects where repository was recently updated' do
      create(:repository_state, :repository_outdated, project: project)

      expect(subject.find_recently_updated_projects(batch_size: 10))
        .to match_array(project)
    end

    it 'returns projects where repository verification is pending' do
      create(:repository_state, :wiki_verified, project: project)

      expect(subject.find_recently_updated_projects(batch_size: 10))
        .to match_array(project)
    end

    it 'does not return projects where repository verification failed' do
      create(:repository_state, :repository_failed, :wiki_verified, project: project)

      expect(subject.find_recently_updated_projects(batch_size: 10)).to be_empty
    end

    it 'returns projects where wiki was recently updated' do
      create(:repository_state, :wiki_outdated, project: project)

      expect(subject.find_recently_updated_projects(batch_size: 10))
        .to match_array(project)
    end

    it 'does not return projects where wiki verification is pending' do
      create(:repository_state, :repository_verified, project: project)

      expect(subject.find_recently_updated_projects(batch_size: 10))
        .to be_empty
    end

    it 'does not return projects where wiki verification failed' do
      create(:repository_state, :repository_verified, :wiki_failed, project: project)

      expect(subject.find_recently_updated_projects(batch_size: 10)).to be_empty
    end

    it 'returns less active projects first' do
      less_active_project = create(:project)
      create(:repository_state, :repository_outdated, project: project)
      create(:repository_state, :repository_outdated, project: less_active_project)
      project.update_column(:last_repository_updated_at, 30.minutes.ago)
      less_active_project.update_column(:last_repository_updated_at, 2.days.ago)

      expect(subject.find_recently_updated_projects(batch_size: 10)).to eq [less_active_project, project]
    end

    context 'with shard restriction' do
      subject { described_class.new(shard_name: project.repository_storage) }

      it 'does not return projects on other shards' do
        project_other_shard = create(:project)
        project_other_shard.update_column(:repository_storage, 'other')
        create(:repository_state, :repository_outdated, project: project)
        create(:repository_state, :repository_outdated, project: project_other_shard)

        expect(subject.find_recently_updated_projects(batch_size: 10))
          .to match_array(project)
      end
    end
  end

  describe '#find_never_verified_projects' do
    it 'returns projects that never have been verified' do
      create(:repository_state, :repository_outdated)
      create(:repository_state, :wiki_outdated)

      expect(subject.find_never_verified_projects(batch_size: 10))
        .to match_array(project)
    end

    context 'with shard restriction' do
      subject { described_class.new(shard_name: project.repository_storage) }

      it 'does not return projects on other shards' do
        project_other_shard = create(:project)
        project_other_shard.update_column(:repository_storage, 'other')

        expect(subject.find_never_verified_projects(batch_size: 10))
          .to match_array(project)
      end
    end
  end

  describe '#find_reverifiable_repositories' do
    it "returns projects where repository was verified before the minimum re-verification interval" do
      project_recently_verified = create(:project)
      create(:repository_state, :repository_verified,
        project: project, last_repository_verification_ran_at: 2.days.ago)
      create(:repository_state, :repository_verified,
        project: project_recently_verified, last_repository_verification_ran_at: Time.now)

      expect(subject.find_reverifiable_repositories(interval: 1.day.ago, batch_size: 10))
        .to match_array(project)
    end

    it "does not return projects where repository was recently updated" do
      create(:repository_state, :repository_outdated,
        project: project, last_repository_verification_ran_at: 2.days.ago)

      expect(subject.find_reverifiable_repositories(interval: 1.day.ago, batch_size: 10))
        .to be_empty
    end

    it "does not return projects where repository verification failed" do
      create(:repository_state, :repository_failed,
        project: project, last_repository_verification_ran_at: 2.days.ago)

      expect(subject.find_reverifiable_repositories(interval: 1.day.ago, batch_size: 10))
        .to be_empty
    end

    it 'returns less active projects first' do
      less_active_project = create(:project)
      create(:repository_state, :repository_verified,
        project: project, last_repository_verification_ran_at: 2.days.ago)
      create(:repository_state, :repository_verified,
        project: less_active_project, last_repository_verification_ran_at: 2.days.ago)
      project.update_column(:last_repository_updated_at, 30.minutes.ago)
      less_active_project.update_column(:last_repository_updated_at, 2.days.ago)

      expect(subject.find_reverifiable_repositories(interval: 1.day.ago, batch_size: 10))
        .to eq [less_active_project, project]
    end

    context 'with shard restriction' do
      subject { described_class.new(shard_name: project.repository_storage) }

      it 'does not return projects on other shards' do
        project_other_shard = create(:project)
        project_other_shard.update_column(:repository_storage, 'other')
        create(:repository_state, :repository_verified,
          project: project, last_repository_verification_ran_at: 2.days.ago)
        create(:repository_state, :repository_verified,
          project: project_other_shard, last_repository_verification_ran_at: 2.days.ago)

        expect(subject.find_reverifiable_repositories(interval: 1.day.ago, batch_size: 10))
          .to match_array(project)
      end
    end
  end

  describe '#count_verified_repositories' do
    context 'when a repository is verified' do
      it 'includes the repository' do
        create(:repository_state, :repository_verified)

        expect(subject.count_verified_repositories).to eq(1)
      end
    end

    context 'when a repository failed verification' do
      it 'excludes the repository' do
        create(:repository_state, :repository_failed)

        expect(subject.count_verified_repositories).to eq(0)
      end
    end

    context 'when a repository has outdated verification' do
      it 'excludes the repository' do
        create(:repository_state, :repository_outdated)

        expect(subject.count_verified_repositories).to eq(0)
      end
    end
  end
end
