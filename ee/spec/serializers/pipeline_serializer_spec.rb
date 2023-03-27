# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PipelineSerializer do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:serializer) do
    described_class.new(current_user: user, project: project)
  end

  subject { serializer.represent(pipeline, details: true) }

  context 'when pipeline contains failed bridge jobs' do
    let(:pipeline) do
      create(:ci_empty_pipeline, project: project, status: :success, ref: :master)
    end

    before do
      create(:ci_bridge, pipeline: pipeline, status: :failed)
    end

    it 'serializes bridge job correctly' do
      name = subject.dig(:details, :stages, 0, :latest_statuses, 0, :name)

      expect(name).to eq 'bridge'
    end
  end

  describe 'N+1 checks' do
    let_it_be(:production) { create(:environment, :production, project: project) }
    let_it_be(:staging) { create(:environment, :staging, project: project) }
    let_it_be(:protected_production) { create(:protected_environment, project: project, name: production.name) }
    let_it_be(:protected_staging) { create(:protected_environment, project: project, name: staging.name) }

    context 'with protected environments' do
      before do
        stub_licensed_features(protected_environments: true)
      end

      it 'executes minimal queries to fetch all related protected environments', :request_store do
        pipeline = create(:ci_pipeline, project: project)
        create(:ci_build, :manual, pipeline: pipeline, environment: production.name)
        create(:ci_build, :manual, pipeline: pipeline, environment: staging.name)
        create(:ci_build, :scheduled, pipeline: pipeline, environment: production.name)
        create(:ci_build, :scheduled, pipeline: pipeline, environment: staging.name)

        expect { serializer.represent(Ci::Pipeline.all, preload: true) }
          .not_to exceed_query_limit(2).for_query /SELECT "protected_environments".*/
      end
    end
  end
end
