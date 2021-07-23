# frozen_string_literal: true

require 'spec_helper'

# There must be a methods or lets called `project` and `dast_profile` defined.
RSpec.shared_examples 'it creates a DAST on-demand scan pipeline' do
  let(:pipeline) do
    Ci::Pipeline.find_by!(
      project: project,
      sha: project.repository.commit.sha,
      source: :ondemand_dast_scan,
      config_source: :parameter_source
    )
  end

  it 'creates a new ci_pipeline for the given project', :aggregate_failures do
    expect { subject }.to change { Ci::Pipeline.where(project: project).count }.by(1)

    expect(pipeline.triggered_for_ondemand_dast_scan?).to be_truthy
  end

  it 'creates a single build associated with the ci_pipeline' do
    subject

    expect(pipeline.builds.map(&:name)).to eq(['dast'])
  end

  it 'creates an association between the dast_profile and the ci_pipeline' do
    subject

    expect(pipeline.dast_profile).to eq(dast_profile)
  end

  it 'returns the pipeline_url' do
    subject

    expected_url = Rails.application.routes.url_helpers.project_pipeline_url(
      project,
      pipeline
    )

    expect(subject[:pipeline_url]).to eq(expected_url)
  end
end
