# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Adding a Note to an Epic', feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:epic) { create(:epic, group: group) }

  let(:variables_extra) { {} }
  let(:variables) do
    {
      noteable_id: GitlabSchema.id_from_object(epic).to_s,
      body: 'Body text'
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
  end
end
