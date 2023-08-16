# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::Catalog::ResourceResolver, feature_category: :pipeline_composition do
  include GraphqlHelpers

  let_it_be(:namespace) { create(:group) }
  let_it_be(:project) { create(:project, namespace: namespace) }
  let_it_be(:resource) { create(:catalog_resource, project: project) }
  let_it_be(:user) { create(:user) }

  describe '#resolve' do
    context 'when ci catalog feature is enabled' do
      before do
        stub_licensed_features(ci_namespace_catalog: true)
      end

      context 'and user is the namespace owner' do
        before do
          namespace.add_owner(user)
        end

        context 'when resource is found' do
          it 'returns a single CI/CD Catalog resource' do
            result = resolve(described_class, ctx: { current_user: user },
              args: { id: resource.to_global_id.to_s })

            expect(result.id).to eq(resource.id)
            expect(result.class).to eq(Ci::Catalog::Resource)
          end
        end

        context 'when resource does not exist' do
          it 'raises ResourceNotAvailable error' do
            result = resolve(described_class, ctx: { current_user: user },
              args: { id: "gid://gitlab/Ci::Catalog::Resource/not-a-real-id" })

            expect(result).to be_a(::Gitlab::Graphql::Errors::ResourceNotAvailable)
          end
        end
      end

      context 'and user is not the namespace owner' do
        before do
          namespace.add_guest(user)
        end

        context 'when user doesnt have correct level of authorisation to see this record' do
          it 'raises ResourceNotAvailable error' do
            result = resolve(described_class, ctx: { current_user: user },
              args: { id: resource.to_global_id.to_s })

            expect(result).to be_a(::Gitlab::Graphql::Errors::ResourceNotAvailable)
          end
        end

        context 'when resource does not exist' do
          it 'raises ResourceNotAvailable error' do
            result = resolve(described_class, ctx: { current_user: user },
              args: { id: "gid://gitlab/Ci::Catalog::Resource/not-a-real-id" })

            expect(result).to be_a(::Gitlab::Graphql::Errors::ResourceNotAvailable)
          end
        end
      end
    end

    context 'when ci catalog feature is not enabled' do
      before do
        stub_licensed_features(ci_namespace_catalog: false)
      end

      context 'and the user is a namespace owner' do
        before do
          namespace.add_owner(user)
        end

        it 'raises ResourceNotAvailable error' do
          result = resolve(described_class, ctx: { current_user: user },
            args: { id: resource.to_global_id.to_s })

          expect(result).to be_a(::Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when user is not the namespace owner' do
        before do
          namespace.add_guest(user)
        end

        it 'raises ResourceNotAvailable error' do
          result = resolve(described_class, ctx: { current_user: user },
            args: { id: resource.to_global_id.to_s })

          expect(result).to be_a(::Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end
    end
  end
end
