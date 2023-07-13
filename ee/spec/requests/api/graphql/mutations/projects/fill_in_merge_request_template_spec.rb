# frozen_string_literal: true

require "spec_helper"

RSpec.describe 'AiAction for Fill In Merge Request Template', :saas, feature_category: :code_review_workflow do
  include GraphqlHelpers
  include Graphql::Subscriptions::Notes::Helper

  let_it_be(:group) { create(:group_with_plan, :public, plan: :ultimate_plan) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:current_user) { create(:user, developer_projects: [project]) }

  let(:mutation) do
    params = {
      fill_in_merge_request_template: {
        resource_id: project.to_gid,
        source_project_id: project.id,
        source_branch: 'feature',
        target_branch: 'master',
        title: 'A merge request',
        content: 'This is content'
      }
    }

    graphql_mutation(:ai_action, params) do
      <<-QL.strip_heredoc
        errors
      QL
    end
  end

  before do
    stub_ee_application_setting(should_check_namespace_plan: true)
    stub_licensed_features(fill_in_merge_request_template: true, ai_features: true)
    group.namespace_settings.update!(third_party_ai_features_enabled: true, experiment_features_enabled: true)
  end

  before_all do
    group.add_developer(current_user)
  end

  it 'successfully performs an explain code request' do
    expect(Llm::CompletionWorker).to receive(:perform_async).with(
      current_user.id,
      project.id,
      'Project',
      :fill_in_merge_request_template,
      {
        markup_format: :raw,
        request_id: an_instance_of(String),
        source_project_id: project.id.to_s,
        source_branch: 'feature',
        target_branch: 'master',
        title: 'A merge request',
        content: 'This is content'
      }
    )

    post_graphql_mutation(mutation, current_user: current_user)

    expect(graphql_mutation_response(:ai_action)['errors']).to eq([])
  end

  context 'when openai_experimentation feature flag is disabled' do
    before do
      stub_feature_flags(openai_experimentation: false)
    end

    it 'returns nil' do
      expect(Llm::CompletionWorker).not_to receive(:perform_async)

      post_graphql_mutation(mutation, current_user: current_user)

      expect(fresh_response_data['errors'][0]['message']).to eq("`openai_experimentation` feature flag is disabled.")
    end
  end

  context 'when third_party_ai_features_enabled disabled' do
    before do
      group.namespace_settings.update!(third_party_ai_features_enabled: false)
    end

    it 'returns nil' do
      expect(Llm::CompletionWorker).not_to receive(:perform_async)

      post_graphql_mutation(mutation, current_user: current_user)
    end
  end

  context 'when experiment_features_enabled disabled' do
    before do
      group.namespace_settings.update!(experiment_features_enabled: false)
    end

    it 'returns nil' do
      expect(Llm::CompletionWorker).not_to receive(:perform_async)

      post_graphql_mutation(mutation, current_user: current_user)
    end
  end
end
