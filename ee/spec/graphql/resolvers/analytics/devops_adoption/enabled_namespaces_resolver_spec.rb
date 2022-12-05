# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Analytics::DevopsAdoption::EnabledNamespacesResolver do
  include GraphqlHelpers

  let_it_be(:admin_user) { create(:user, :admin) }

  def resolve_enabled_namespaces(args = {}, context = {})
    resolve(described_class, args: args, ctx: context)
  end

  before do
    stub_licensed_features(instance_level_devops_adoption: true, group_level_devops_adoption: true)
  end

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let(:params) { {} }
    let_it_be(:root_group_1) { create(:group, name: 'bbb') }
    let_it_be(:root_group_2) { create(:group, name: 'aaa') }
    let_it_be(:enabled_namespace_1) { create(:devops_adoption_enabled_namespace, namespace: root_group_1, display_namespace: root_group_1) }
    let_it_be(:enabled_namespace_2) { create(:devops_adoption_enabled_namespace, namespace: root_group_1, display_namespace: nil) }
    let_it_be(:enabled_namespace_3) { create(:devops_adoption_enabled_namespace, namespace: root_group_2, display_namespace: root_group_2) }
    let_it_be(:enabled_namespace_4) { create(:devops_adoption_enabled_namespace, namespace: root_group_2, display_namespace: nil) }

    subject(:resolved_enabled_namespaces) { resolve_enabled_namespaces(params, { current_user: current_user }) }

    context 'for instance level', :enable_admin_mode do
      let(:current_user) { admin_user }

      context 'as an admin user' do
        it 'returns enabled_namespaces for all groups without display_namespace' do
          expect(resolved_enabled_namespaces).to match_array([enabled_namespace_2, enabled_namespace_4])
        end
      end

      context 'as a non-admin user' do
        let(:current_user) { user }

        it 'generates ResourceNotAvailable error' do
          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
            resolved_enabled_namespaces
          end
        end
      end

      context 'when the feature is not available' do
        before do
          stub_licensed_features(instance_level_devops_adoption: false)
        end

        it 'generates ResourceNotAvailable error' do
          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
            resolved_enabled_namespaces
          end
        end
      end
    end

    context 'for group level' do
      let(:params) { { display_namespace_id: root_group_1.to_gid.to_s } }
      let(:current_user) { user }

      context 'for reporter+' do
        before do
          root_group_1.add_reporter(user)
        end

        it 'returns enabled_namespaces for given parent group and its descendants' do
          expect(resolved_enabled_namespaces).to eq([enabled_namespace_1])
        end
      end

      context 'for guests' do
        before do
          root_group_1.add_guest(user)
        end

        it 'generates ResourceNotAvailable error' do
          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
            resolved_enabled_namespaces
          end
        end
      end

      context 'when the feature is not available' do
        before do
          stub_licensed_features(instance_level_devops_adoption: false)
        end

        it 'generates ResourceNotAvailable error' do
          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
            resolved_enabled_namespaces
          end
        end
      end
    end
  end
end
