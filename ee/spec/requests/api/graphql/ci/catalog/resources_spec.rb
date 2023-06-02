# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.ciCatalogResources', feature_category: :pipeline_composition do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:group) }
  let_it_be(:project2) { create(:project, namespace: namespace) }

  let_it_be(:project1) do
    create(
      :project, :with_avatar, :custom_repo,
      name: 'Component Repository',
      description: 'A simple component',
      namespace: namespace,
      star_count: 1,
      files: { 'README.md' => '**Test**' }
    )
  end

  let_it_be(:resource1) { create(:catalog_resource, project: project1) }

  let(:query) do
    <<~GQL
      query {
        ciCatalogResources(projectPath: "#{project1.full_path}") {
          nodes {
            #{all_graphql_fields_for('CiCatalogResource', max_depth: 1)}
          }
        }
      }
    GQL
  end

  subject(:post_query) { post_graphql(query, current_user: user) }

  shared_examples 'avoids N+1 queries' do
    it do
      ctx = { current_user: user }

      control_count = ActiveRecord::QueryRecorder.new do
        run_with_clean_state(query, context: ctx)
      end

      create(:catalog_resource, project: project2)

      expect do
        run_with_clean_state(query, context: ctx)
      end.not_to exceed_query_limit(control_count)
    end
  end

  context 'when the CI Namespace Catalog feature is available' do
    before do
      stub_licensed_features(ci_namespace_catalog: true)
    end

    context 'when the current user has permission to read the namespace catalog' do
      before do
        namespace.add_developer(user)
      end

      it 'returns the resource with the expected data' do
        post_query

        expect(graphql_data_at(:ciCatalogResources, :nodes)).to contain_exactly(
          a_graphql_entity_for(
            resource1, :name, :description,
            icon: project1.avatar_path,
            webPath: "/#{project1.full_path}",
            starCount: project1.star_count,
            forksCount: project1.forks_count,
            readmeHtml: a_string_including('<strong>Test</strong>')
          )
        )
      end

      context 'when there are two resources visible to the current user in the namespace' do
        it 'returns both resources with the expected data' do
          resource2 = create(:catalog_resource, project: project2)

          post_query

          expect(graphql_data_at(:ciCatalogResources, :nodes)).to contain_exactly(
            a_graphql_entity_for(resource1),
            a_graphql_entity_for(
              resource2, :name, :description,
              icon: project2.avatar_path,
              webPath: "/#{project2.full_path}",
              starCount: project2.star_count,
              forksCount: project2.forks_count,
              readmeHtml: ''
            )
          )
        end

        it_behaves_like 'avoids N+1 queries'
      end
    end

    context 'when the current user does not have permission to read the namespace catalog' do
      it 'returns an empty response' do
        namespace.add_guest(user)

        post_query

        expect(graphql_data_at(:ciCatalogResources)).to be_nil
      end
    end
  end

  context 'when the CI Namespace Catalog feature is not available' do
    it 'returns an empty response' do
      namespace.add_developer(user)

      post_query

      expect(graphql_data_at(:ciCatalogResources)).to be_nil
    end
  end

  describe 'versions' do
    before do
      stub_licensed_features(ci_namespace_catalog: true)
      namespace.add_developer(user)
    end

    let(:params) { '' }

    let(:query) do
      <<~GQL
        query {
          ciCatalogResources(projectPath: "#{project1.full_path}") {
            nodes {
              id
              versions#{params} {
                nodes {
                  id
                  tagName
                  releasedAt
                  author {
                    id
                    name
                    webUrl
                  }
                }
              }
            }
          }
        }
      GQL
    end

    context 'when the resource has versions' do
      let_it_be(:resource1_author) { create(:user, name: 'resource1_author') }
      let_it_be(:resource2_author) { create(:user, name: 'resource2_author') }

      let_it_be(:resource1_version1) do
        create(:release, project: project1, released_at: '2023-01-01T00:00:00Z', author: resource1_author)
      end

      let_it_be(:resource1_version2) do
        create(:release, project: project1, released_at: '2023-02-01T00:00:00Z', author: resource1_author)
      end

      let_it_be(:resource2_version1) do
        create(:release, project: project2, released_at: '2023-03-01T00:00:00Z', author: resource2_author)
      end

      let_it_be(:resource2_version2) do
        create(:release, project: project2, released_at: '2023-04-01T00:00:00Z', author: resource2_author)
      end

      it 'returns the resource with the versions data' do
        post_query

        expect(graphql_data_at(:ciCatalogResources, :nodes)).to contain_exactly(
          a_graphql_entity_for(resource1)
        )

        expect(graphql_data_at(:ciCatalogResources, :nodes, 0, :versions, :nodes)).to contain_exactly(
          a_graphql_entity_for(
            resource1_version1,
            tagName: resource1_version1.tag,
            releasedAt: resource1_version1.released_at,
            author: a_graphql_entity_for(resource1_author, :name)
          ),
          a_graphql_entity_for(
            resource1_version2,
            tagName: resource1_version2.tag,
            releasedAt: resource1_version2.released_at,
            author: a_graphql_entity_for(resource1_author, :name)
          )
        )
      end

      it 'returns the versions by released_at in descending order by default' do
        post_query

        version_ids = graphql_data_at(:ciCatalogResources, :nodes, 0, :versions, :nodes).pluck('id')

        expect(version_ids).to eq([resource1_version2.to_global_id.to_s, resource1_version1.to_global_id.to_s])
      end

      context 'when sort parameter RELEASED_AT_ASC is provided' do
        let(:params) { '(sort: RELEASED_AT_ASC)' }

        it 'returns the versions by released_at in ascending order' do
          post_query

          version_ids = graphql_data_at(:ciCatalogResources, :nodes, 0, :versions, :nodes).pluck('id')

          expect(version_ids).to eq([resource1_version1.to_global_id.to_s, resource1_version2.to_global_id.to_s])
        end
      end

      context 'when there are two resources visible to the current user in the namespace' do
        it 'returns both resources with the versions data' do
          resource2 = create(:catalog_resource, project: project2)

          post_query

          expect(graphql_data_at(:ciCatalogResources, :nodes)).to contain_exactly(
            a_graphql_entity_for(resource1),
            a_graphql_entity_for(resource2)
          )

          expect([
            graphql_data_at(:ciCatalogResources, :nodes, 0, :versions, :nodes),
            graphql_data_at(:ciCatalogResources, :nodes, 1, :versions, :nodes)
          ].flatten).to contain_exactly(
            a_graphql_entity_for(resource1_version1, author: a_graphql_entity_for(resource1_author)),
            a_graphql_entity_for(resource1_version2, author: a_graphql_entity_for(resource1_author)),
            a_graphql_entity_for(resource2_version1, author: a_graphql_entity_for(resource2_author)),
            a_graphql_entity_for(resource2_version2, author: a_graphql_entity_for(resource2_author))
          )
        end

        it_behaves_like 'avoids N+1 queries'

        context 'when obtaining the latest version of the resource' do
          let(:params) { '(first: 1)' }

          it 'returns the latest versions of both resources' do
            create(:catalog_resource, project: project2)

            post_query

            expect([
              graphql_data_at(:ciCatalogResources, :nodes, 0, :versions, :nodes),
              graphql_data_at(:ciCatalogResources, :nodes, 1, :versions, :nodes)
            ].flatten).to contain_exactly(
              a_graphql_entity_for(resource1_version2, author: a_graphql_entity_for(resource1_author)),
              a_graphql_entity_for(resource2_version2, author: a_graphql_entity_for(resource2_author))
            )
          end
        end
      end
    end

    context 'when the resource does not have a version' do
      it 'returns versions as an empty array' do
        post_query

        expect(graphql_data_at(:ciCatalogResources, :nodes)).to contain_exactly(
          a_graphql_entity_for(resource1, versions: { 'nodes' => [] })
        )
      end
    end
  end

  describe 'rootNamespace' do
    before do
      stub_licensed_features(ci_namespace_catalog: true)
      namespace.add_developer(user)
    end

    let(:query) do
      <<~GQL
        query {
          ciCatalogResources(projectPath: "#{project1.full_path}") {
            nodes {
              id
              rootNamespace {
                id
                name
                path
              }
            }
          }
        }
      GQL
    end

    it 'returns the correct root namespace data' do
      post_query

      expect(graphql_data_at(:ciCatalogResources, :nodes)).to contain_exactly(
        a_graphql_entity_for(
          resource1,
          rootNamespace: a_graphql_entity_for(namespace, :name, :path)
        )
      )
    end

    shared_examples 'returns the correct root namespace for both resources' do
      it do
        resource2 = create(:catalog_resource, project: project2)

        post_query

        expect(graphql_data_at(:ciCatalogResources, :nodes)).to contain_exactly(
          a_graphql_entity_for(resource1, rootNamespace: a_graphql_entity_for(namespace)),
          a_graphql_entity_for(resource2, rootNamespace: a_graphql_entity_for(namespace2))
        )
      end
    end

    shared_examples 'when there are two resources visible to the current user' do
      it_behaves_like 'returns the correct root namespace for both resources'
      it_behaves_like 'avoids N+1 queries'

      context 'when a resource is within a nested namespace' do
        let_it_be(:nested_namespace) { create(:group, parent: namespace2) }
        let_it_be(:project2) { create(:project, namespace: nested_namespace) }

        it_behaves_like 'returns the correct root namespace for both resources'
        it_behaves_like 'avoids N+1 queries'
      end
    end

    context 'when there are multiple resources visible to the current user from the same root namespace' do
      let_it_be(:namespace2) { namespace }

      it_behaves_like 'when there are two resources visible to the current user'
    end

    # We expect the resources resolver will eventually support returning resources from multiple root namespaces.
    context 'when there are multiple resources visible to the current user from different root namespaces' do
      before do
        # In order to mock this scenario, we allow the resolver to return
        # all existing resources without scoping to a specific namespace.
        allow_next_instance_of(::Ci::Catalog::Listing) do |instance|
          allow(instance).to receive(:resources).and_return(::Ci::Catalog::Resource.includes(:project))
        end
      end

      # Make the current user an Admin so it has `:read_namespace` ability on all namespaces
      let_it_be(:user) { create(:admin) }

      let_it_be(:namespace2) { create(:group) }
      let_it_be(:project2) { create(:project, namespace: namespace2) }

      it_behaves_like 'when there are two resources visible to the current user'

      context 'when a resource is within a User namespace' do
        let_it_be(:namespace2) { create(:user).namespace }
        let_it_be(:project2) { create(:project, namespace: namespace2) }

        # A response containing any number of 'User' type root namespaces will always execute 1 extra
        # query than a response with only 'Group' type root namespaces. This is due to their different
        # policies. Here we preemptively create another resource with a 'User' type root namespace so
        # that the control_count in the N+1 test includes this extra query.
        let_it_be(:namespace3) { create(:user).namespace }
        let_it_be(:resource3) { create(:catalog_resource, project: create(:project, namespace: namespace3)) }

        it 'returns the correct root namespace for all resources' do
          resource2 = create(:catalog_resource, project: project2)

          post_query

          expect(graphql_data_at(:ciCatalogResources, :nodes)).to contain_exactly(
            a_graphql_entity_for(resource1, rootNamespace: a_graphql_entity_for(namespace)),
            a_graphql_entity_for(resource2, rootNamespace: a_graphql_entity_for(namespace2)),
            a_graphql_entity_for(resource3, rootNamespace: a_graphql_entity_for(namespace3))
          )
        end

        it_behaves_like 'avoids N+1 queries'
      end
    end
  end
end
