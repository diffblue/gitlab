# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WikiPages::CreateService, feature_category: :wiki do
  include ::EE::GeoHelpers

  let(:user) { create(:user) }

  let(:opts) do
    {
      title: 'Title',
      content: 'Content for wiki page',
      format: 'markdown'
    }
  end

  subject(:service) { described_class.new(container: container, current_user: user, params: opts) }

  describe '#execute' do
    let(:container) { create(:project, :wiki_repo) }

    context 'with geo_project_wiki_repository_replication feature flag disabled' do
      before do
        stub_feature_flags(geo_project_wiki_repository_replication: false)
      end

      it 'calls Geo::RepositoryUpdatedService when running on a Geo primary site' do
        stub_primary_node

        expect_next_instance_of(::Geo::RepositoryUpdatedService, container.wiki.repository) do |service|
          expect(service).to receive(:execute).once
        end

        service.execute
      end

      it 'does not call Geo::RepositoryUpdatedService when not running on a Geo primary site' do
        stub_secondary_node

        expect_next_instance_of(::Geo::RepositoryUpdatedService).never

        service.execute
      end
    end

    context 'with geo_project_wiki_repository_replication feature flag enabled' do
      before do
        stub_feature_flags(geo_project_wiki_repository_replication: true)
      end

      context 'when on a Geo primary site' do
        before do
          stub_primary_node
        end

        it 'does not call Geo::RepositoryUpdatedService' do
          expect_next_instance_of(::Geo::RepositoryUpdatedService).never

          service.execute
        end

        it 'calls replicator to update Geo' do
          expect(container.wiki_repository.replicator).to receive(:handle_after_update)

          service.execute
        end
      end

      context 'when not on a Geo primary site' do
        before do
          stub_secondary_node
        end

        it 'does not call replicator to update Geo' do
          expect_next_instance_of(Geo::ProjectWikiRepositoryReplicator).never

          service.execute
        end
      end
    end
  end

  it_behaves_like 'WikiPages::CreateService#execute', :group do
    # TODO: Geo support for group wiki https://gitlab.com/gitlab-org/gitlab/-/issues/208147
    it 'does not call Geo::RepositoryUpdatedService when container is group' do
      stub_primary_node

      expect(::Geo::RepositoryUpdatedService).not_to receive(:new)

      service.execute
    end
  end
end
