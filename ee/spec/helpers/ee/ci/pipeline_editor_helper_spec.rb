# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Ci::PipelineEditorHelper do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user) { create(:user) }

  describe '#js_pipeline_editor_data' do
    before do
      allow(helper)
        .to receive(:namespace_project_new_merge_request_path)
        .and_return('/mock/project/-/merge_requests/new')

      allow(helper)
        .to receive(:image_path)
        .and_return('foo')

      allow(helper)
        .to receive(:current_user)
        .and_return(user)

      stub_all_feature_flags
    end

    subject(:pipeline_editor_data) { helper.js_pipeline_editor_data(project) }

    shared_examples 'no licensed features keys' do
      it 'returns dataset with no licensed features keys' do
        expect(pipeline_editor_data.keys).not_to include('api-fuzzing-configuration-path')
        expect(pipeline_editor_data.keys).not_to include('dast-configuration-path')
        expect(pipeline_editor_data.keys).not_to include('ai_chat_available')
      end
    end

    shared_examples 'api fuzzing only' do
      it 'includes keys for only api fuzzing' do
        expect(pipeline_editor_data.keys).to include('api-fuzzing-configuration-path')
        expect(pipeline_editor_data.keys).to include('dast-configuration-path')
        expect(pipeline_editor_data.keys).not_to include('ai_chat_available')
      end
    end

    context 'with api_fuzzing enabled' do
      before do
        stub_licensed_features(api_fuzzing: true)
      end

      it_behaves_like 'api fuzzing only'
    end

    context 'with ai ci config chat enabled' do
      before do
        allow_next_instance_of(Ai::Project::Conversations) do |conversations|
          allow(conversations).to receive(:ci_config_chat_enabled?).and_return(true)
        end
      end

      context 'when user can create a pipeline' do
        before do
          project.add_developer(user)
        end

        it 'includes ai_config_chat key only' do
          expect(pipeline_editor_data.keys).not_to include('api-fuzzing-configuration-path')
          expect(pipeline_editor_data.keys).not_to include('dast-configuration-path')
          expect(pipeline_editor_data.keys).to include('ai_chat_available')
        end
      end

      context 'when the user cannot create a pipeline' do
        it_behaves_like 'no licensed features keys'
      end
    end

    context 'with ai ci config chat and api_fuzzing enabled' do
      before do
        stub_licensed_features(api_fuzzing: true)
        allow_next_instance_of(Ai::Project::Conversations) do |conversations|
          allow(conversations).to receive(:ci_config_chat_enabled?).and_return(true)
        end
      end

      context 'when user can create a pipeline' do
        before do
          project.add_developer(user)
        end

        it 'includes keys for all features' do
          expect(pipeline_editor_data.keys).to include('api-fuzzing-configuration-path')
          expect(pipeline_editor_data.keys).to include('dast-configuration-path')
          expect(pipeline_editor_data.keys).to include('ai_chat_available')
        end
      end

      context 'when user cannot create a pipeline' do
        it_behaves_like 'api fuzzing only'
      end
    end

    context 'without features licensed and enabled' do
      context 'when user can create a pipeline' do
        before do
          project.add_developer(user)
        end

        it_behaves_like 'no licensed features keys'
      end

      context 'when user cannot create a pipeline' do
        it_behaves_like 'no licensed features keys'
      end
    end
  end
end
