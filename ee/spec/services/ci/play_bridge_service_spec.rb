# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PlayBridgeService, '#execute', feature_category: :continuous_integration do
  it_behaves_like 'prevents playing job when credit card is required' do
    let(:user) { create(:user, maintainer_projects: [project, downstream_project]) }
    let(:project) { create(:project) }
    let(:pipeline) { create(:ci_pipeline, project: project) }
    let(:downstream_project) { create(:project) }
    let(:job) { create(:ci_bridge, :playable, pipeline: pipeline, downstream: downstream_project) }

    subject { described_class.new(project, user).execute(job) }
  end
end
