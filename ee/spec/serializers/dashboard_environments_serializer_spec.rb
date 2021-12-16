# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DashboardEnvironmentsSerializer do
  describe '.represent' do
    it 'returns an empty array when there are no projects' do
      current_user = create(:user)
      projects = []

      result = described_class.new(current_user: current_user).represent(projects)

      expect(result).to eq([])
    end

    it 'includes project attributes' do
      current_user = create(:user)
      project = create(:project)
      create(:environment, project: project, state: :available)
      projects = [project]

      result = described_class.new(current_user: current_user).represent(projects)

      expect(result.first.keys.sort).to eq([:avatar_url, :environments, :id, :name, :namespace, :remove_path, :web_url])
    end

    it 'preloads only relevant ci_builds and does not result in N+1' do
      current_user = create(:user)
      project = create(:project, :repository)

      pipeline = create(:ci_pipeline, user: current_user, project: project, sha: project.commit.sha)

      ci_build_a = create(:ci_build, user: current_user, project: project, pipeline: pipeline)
      ci_build_b = create(:ci_build, user: current_user, project: project, pipeline: pipeline)
      ci_build_c = create(:ci_build, user: current_user, project: project, pipeline: pipeline)

      environment_a = create(:environment, project: project, state: :available)
      environment_b = create(:environment, project: project, state: :available)

      projects = [project]

      create(:deployment, :success, project: project, environment: environment_a, deployable: ci_build_a)
      create(:deployment, :success, project: project, environment: environment_a, deployable: ci_build_b)
      create(:deployment, :success, project: project, environment: environment_b, deployable: ci_build_c)

      expect(CommitStatus).to receive(:instantiate)
        .with(a_hash_including("id" => ci_build_b.id), anything)
        .at_least(:once)
        .and_call_original

      expect(CommitStatus).to receive(:instantiate)
        .with(a_hash_including("id" => ci_build_c.id), anything)
        .at_least(:once)
        .and_call_original

      described_class.new(current_user: current_user).represent(projects)
    end
  end
end
