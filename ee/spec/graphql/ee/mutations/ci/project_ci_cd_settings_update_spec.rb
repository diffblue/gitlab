# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Ci::ProjectCiCdSettingsUpdate, feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }

  let(:user) { project.first_owner }
  let(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  subject { mutation.resolve(full_path: project.full_path, **mutation_params) }

  before do
    stub_licensed_features(merge_pipelines: true, merge_trains: true)
    stub_feature_flags(disable_merge_trains: false)
    project.merge_pipelines_enabled = nil
    project.merge_trains_enabled = false
    subject
    project.reload
  end

  describe '#resolve' do
    context 'when merge trains are set to true and merge pipelines are set to false' do
      let(:mutation_params) do
        {
          full_path: project.full_path,
          merge_pipelines_enabled: false,
          merge_trains_enabled: true
        }
      end

      it 'does not enable merge trains' do
        expect(project.ci_cd_settings.merge_trains_enabled?).to eq(false)
      end
    end

    context 'when merge trains and merge pipelines are set to true' do
      let(:mutation_params) do
        {
          full_path: project.full_path,
          merge_pipelines_enabled: true,
          merge_trains_enabled: true
        }
      end

      it 'enables merge pipelines and merge trains' do
        expect(project.merge_pipelines_enabled?).to eq(true)
        expect(project.merge_trains_enabled?).to eq(true)
      end
    end
  end
end
