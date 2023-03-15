# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ScannedResourcesCountingService, '#execute', feature_category: :vulnerability_management do
  before do
    stub_licensed_features(sast: true, dependency_scanning: true, container_scanning: true, dast: true)
  end

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline) { create(:ci_pipeline, :success, project: project) }

  context "The Pipeline has security builds" do
    before_all do
      create(:ci_build, :success, name: 'dast_job', pipeline: pipeline, project: project) do |job|
        create(:ee_ci_job_artifact, :dast, job: job, project: project)
      end
      create(:ci_build, :success, name: 'sast_job', pipeline: pipeline, project: project) do |job|
        create(:ee_ci_job_artifact, :sast, job: job, project: project)
      end
    end

    context 'All report types are requested' do
      subject { described_class.new(pipeline, %w[sast dast container_scanning dependency_scanning]).execute }

      it {
        is_expected.to match(a_hash_including("sast" => 0,
                                              "dast" => 6,
                                              "container_scanning" => 0,
                                              "dependency_scanning" => 0))
      }
    end

    context 'Only the report type dast is requested' do
      subject { described_class.new(pipeline, %w[dast]).execute }

      it {
        is_expected.to eq({ "dast" => 6 })
      }
    end
  end

  context "The Pipeline has no security builds" do
    let_it_be(:pipeline) { create(:ci_pipeline, :success) }

    subject { described_class.new(pipeline, %w[sast dast container_scanning dependency_scanning]).execute }

    it {
      is_expected.to match(a_hash_including("sast" => 0,
                                            "dast" => 0,
                                            "container_scanning" => 0,
                                            "dependency_scanning" => 0))
    }
  end
end
