# frozen_string_literal: true

require 'airborne'

module QA
  RSpec.describe 'Systems', :orchestrated, :geo, product_group: :geo do
    describe 'Geo Nodes API' do
      before(:all) do
        get_personal_access_token
      end

      shared_examples 'retrieving configuration about Geo nodes' do |testcase|
        it 'GET /geo_nodes', testcase: testcase do
          get api_endpoint('/geo_nodes')

          expect_status(200)
          expect(json_body.size).to be >= 2
          expect_json('?', primary: true)
          expect_json_types('*', primary: :boolean, current: :boolean,
                                 files_max_capacity: :integer, repos_max_capacity: :integer,
                                 clone_protocol: :string, _links: :object)
        end
      end

      shared_examples 'retrieving configuration about Geo nodes/:id' do |testcase|
        it 'GET /geo_nodes/:id', testcase: testcase do
          get api_endpoint("/geo_nodes/#{geo_node[:id]}")

          expect_status(200)
          expect(json_body).to eq geo_node
        end
      end

      describe 'on primary node', :geo do
        before(:context) do
          fetch_nodes(:geo_primary)
        end

        let(:geo_node) { @primary_node }

        include_examples 'retrieving configuration about Geo nodes', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348042'
        include_examples 'retrieving configuration about Geo nodes/:id', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348041'

        describe 'editing a Geo node' do
          it 'PUT /geo_nodes/:id for secondary node',
             testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348043' do
            endpoint = api_endpoint("/geo_nodes/#{@secondary_node[:id]}")
            new_attributes = { enabled: false, files_max_capacity: 1000, repos_max_capacity: 2000 }

            put endpoint, new_attributes

            expect_status(200)
            expect_json(new_attributes)

            # restore the original values
            put endpoint, { enabled: @secondary_node[:enabled],
                            files_max_capacity: @secondary_node[:files_max_capacity],
                            repos_max_capacity: @secondary_node[:repos_max_capacity] }

            expect_status(200)
          end
        end
      end

      describe 'on secondary node', :geo do
        before(:context) do
          fetch_nodes(:geo_secondary)
        end

        let(:geo_node) { @nodes.first }

        include_examples 'retrieving configuration about Geo nodes', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348044'
        include_examples 'retrieving configuration about Geo nodes/:id', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348045'
      end

      def api_endpoint(endpoint)
        QA::Runtime::API::Request.new(@api_client, endpoint).url
      end

      def fetch_nodes(node_type)
        @api_client = Runtime::API::Client.new(node_type, personal_access_token: @personal_access_token)

        get api_endpoint('/geo_nodes')

        @nodes          = json_body
        @primary_node   = @nodes.detect { |node| node[:primary] == true }
        @secondary_node = @nodes.detect { |node| node[:primary] == false }
      end

      # go to the primary and create a personal_access_token, which will be used
      # for accessing both the primary and secondary
      def get_personal_access_token
        api_client = Runtime::API::Client.as_admin
        @personal_access_token = api_client.personal_access_token
      end
    end
  end
end
