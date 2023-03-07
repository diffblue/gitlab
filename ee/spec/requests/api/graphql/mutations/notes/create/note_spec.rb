# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Adding a Note to an Epic', feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:noteable) { create(:epic, group: group) }

  let(:body) { 'Body text' }
  let(:variables_extra) { {} }
  let(:variables) do
    {
      noteable_id: GitlabSchema.id_from_object(noteable).to_s,
      body: body
    }.merge(variables_extra)
  end

  let(:mutation) do
    graphql_mutation(:create_note, variables)
  end

  def mutation_response
    graphql_mutation_response(:create_note)
  end

  before do
    stub_licensed_features(epics: true)
  end

  context 'when the user does not have permission' do
    it_behaves_like 'a Note mutation when the user does not have permission'
  end

  context 'when the user has permission' do
    before do
      group.add_developer(current_user)
    end

    context 'when using internal param' do
      let(:variables_extra) { { internal: true } }

      it_behaves_like 'a Note mutation with confidential notes'
    end

    context 'when using deprecated confidential param' do
      let(:variables_extra) { { confidential: true } }

      it_behaves_like 'a Note mutation with confidential notes'
    end

    context 'when body contains quick actions' do
      let_it_be(:project) { create(:project, group: group) }
      let_it_be(:noteable) { create(:work_item, project: project) }

      let(:variables_extra) { {} }

      before do
        stub_licensed_features(issuable_health_status: true, issue_weights: true)
      end

      it_behaves_like 'work item supports weights widget updates via quick actions'
      it_behaves_like 'work item does not support weights widget updates via quick actions'
      it_behaves_like 'work item supports health status widget updates via quick actions'
      it_behaves_like 'work item does not support health status widget updates via quick actions'
    end
  end
end
