# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::PipelinesController, type: :request, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :repository, :private) }
  let_it_be(:user) { create(:user) }

  before do
    login_as(user)
  end

  describe "GET #licenses" do
    subject { get licenses_project_pipeline_path(project, pipeline) }

    context 'when the project has software license policies' do
      let_it_be(:pipeline) { create(:ci_pipeline, project: project, builds: [create(:ee_ci_build, :license_scan_v2_1, :success)]) }

      before do
        stub_licensed_features(license_scanning: true)
        subject # Warm the cache
      end

      it 'does not cause extra queries' do
        control_count = ActiveRecord::QueryRecorder.new { subject }

        create_list(:software_license_policy, 5, project: project)

        expect { subject }.not_to exceed_query_limit(control_count)
      end
    end
  end
end
