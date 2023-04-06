# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::Catalog::ResourcesResolver, feature_category: :pipeline_composition do
  include GraphqlHelpers

  let_it_be(:namespace) { create(:group) }
  let_it_be(:project_1) { create(:project, name: 'Component Repository 1', namespace: namespace) }
  let_it_be(:project_2) { create(:project, name: 'Component Repository 2', namespace: namespace) }
  let_it_be(:resource_1) { create(:catalog_resource, project: project_1) }
  let_it_be(:resource_2) { create(:catalog_resource, project: project_2) }
  let_it_be(:user) { create(:user) }

  describe '#resolve' do
    it 'returns all CI Catalog resources visible to the current user in the namespace' do
      stub_licensed_features(ci_namespace_catalog: true)
      namespace.add_owner(user)

      result = resolve(described_class, ctx: { current_user: user }, args: { project_path: project_1.full_path })

      expect(result.items.count).to be(2)
      expect(result.items.pluck(:name)).to contain_exactly('Component Repository 1', 'Component Repository 2')
    end

    context 'when the current user cannot read the namespace catalog' do
      it 'raises ResourceNotAvailable' do
        stub_licensed_features(ci_namespace_catalog: true)
        namespace.add_guest(user)

        result = resolve(described_class, ctx: { current_user: user }, args: { project_path: project_1.full_path })

        expect(result).to be_a(::Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when the namespace catalog feature is not available' do
      it 'raises ResourceNotAvailable' do
        namespace.add_owner(user)

        result = resolve(described_class, ctx: { current_user: user }, args: { project_path: project_1.full_path })

        expect(result).to be_a(::Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end
end
