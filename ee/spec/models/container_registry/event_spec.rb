# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Event do
  using RSpec::Parameterized::TableSyntax
  include ::EE::GeoHelpers

  let_it_be(:group) { create(:group, name: 'group') }
  let_it_be(:project) { create(:project, path: 'test', namespace: group) }

  shared_examples 'creating a geo event' do
    it 'creates geo event' do
      expect { subject }
        .to change { ::Geo::Event.count }.by(1)
    end
  end

  shared_examples 'not creating a geo event' do
    it 'does not create geo event' do
      expect { subject }
        .not_to change { ::Geo::Event.count }
    end
  end

  describe '#handle!' do
    context 'geo event' do
      let_it_be(:container_repository) { create(:container_repository, name: 'container', project: project) }
      let_it_be(:primary_node)   { create(:geo_node, :primary) }
      let_it_be(:secondary_node) { create(:geo_node) }

      let(:raw_event) { { 'action' => action, 'target' => target } }

      subject { described_class.new(raw_event).handle! }

      before do
        stub_current_geo_node(primary_node)
      end

      context 'with a respository target' do
        let(:target) do
          {
            'mediaType' => ContainerRegistry::Client::DOCKER_DISTRIBUTION_MANIFEST_V2_TYPE,
            'repository' => repository_path
          }
        end

        where(:repository_path, :action, :example_name) do
          'group/test/container' | 'push'   | 'creating a geo event'
          'group/test/container' | 'delete' | 'creating a geo event'
          'foo/bar'              | 'push'   | 'not creating a geo event'
          'foo/bar'              | 'delete' | 'not creating a geo event'
        end

        with_them do
          it_behaves_like params[:example_name]
        end
      end

      context 'with a tag target' do
        let(:target) do
          {
            'mediaType' => ContainerRegistry::Client::DOCKER_DISTRIBUTION_MANIFEST_V2_TYPE,
            'repository' => repository_path,
            'tag' => 'latest'
          }
        end

        where(:repository_path, :action, :example_name) do
          'group/test/container' | 'push'   | 'creating a geo event'
          'group/test/container' | 'delete' | 'creating a geo event'
          'foo/bar'              | 'push'   | 'not creating a geo event'
          'foo/bar'              | 'delete' | 'not creating a geo event'
        end

        with_them do
          it_behaves_like params[:example_name]
        end

        context 'without media type' do
          let(:action) { 'push' }
          let(:repository_path) { 'group/test/container_repository' }
          let(:target) { super().without('mediaType') }

          it_behaves_like 'not creating a geo event'
        end
      end
    end
  end
end
