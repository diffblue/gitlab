# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PlayBuildService, '#execute', feature_category: :continuous_integration do
  it_behaves_like 'restricts access to protected environments' do
    subject { service.execute(build) }
  end

  it_behaves_like 'prevents playing job when credit card is required' do
    let(:user) { create(:user, maintainer_projects: [project]) }
    let(:project) { create(:project) }
    let(:pipeline) { create(:ci_pipeline, project: project) }
    let(:job) { create(:ci_build, :manual, pipeline: pipeline) }

    subject { described_class.new(project, user).execute(job) }
  end
end
