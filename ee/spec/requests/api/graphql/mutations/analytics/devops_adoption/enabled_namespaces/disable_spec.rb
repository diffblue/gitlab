# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Analytics::DevopsAdoption::EnabledNamespaces::Disable, feature_category: :devops_reports do
  include GraphqlHelpers

  let_it_be(:display_group) { create :group }
  let_it_be(:group) { create :group, parent: display_group }
  let_it_be(:reporter) do
    create(:user).tap do |u|
      display_group.add_reporter(u)
      group.add_reporter(u)
    end
  end

  let(:current_user) { reporter }
  let!(:enabled_namespace) { create(:devops_adoption_enabled_namespace, namespace: group, display_namespace: display_group) }

  let(:variables) { { id: enabled_namespace.to_gid.to_s } }

  let(:mutation) do
    graphql_mutation(:disable_devops_adoption_namespace, variables) do
      <<~QL
        clientMutationId
        errors
      QL
    end
  end

  before do
    stub_licensed_features(group_level_devops_adoption: true)
  end

  def mutation_response
    graphql_mutation_response(:disable_devops_adoption_namespace)
  end

  context 'when the user cannot manage enabled_namespaces' do
    let(:current_user) { create(:user) }

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when the feature is not available' do
    before do
      stub_licensed_features(group_level_devops_adoption: false)
    end

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  it 'deletes the enabled_namespace' do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(mutation_response['errors']).to be_empty
    expect(::Analytics::DevopsAdoption::EnabledNamespace.find_by_id(enabled_namespace.id)).to eq(nil)
  end

  context 'with bulk ids' do
    let!(:enabled_namespace2) { create(:devops_adoption_enabled_namespace) }
    let!(:enabled_namespace3) { create(:devops_adoption_enabled_namespace) }

    let(:variables) { { id: [enabled_namespace.to_gid.to_s, enabled_namespace2.to_gid.to_s] } }

    before do
      enabled_namespace2.namespace.add_reporter(current_user)
      enabled_namespace2.display_namespace.add_reporter(current_user)
      enabled_namespace3.namespace.add_reporter(current_user)
      enabled_namespace3.display_namespace.add_reporter(current_user)
    end

    it 'deletes the enabled_namespaces specified for deletion' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response['errors']).to be_empty
      expect(::Analytics::DevopsAdoption::EnabledNamespace.where(id: [enabled_namespace.id, enabled_namespace2.id, enabled_namespace3.id]))
        .to match_array([enabled_namespace3])
    end
  end
end
