# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WikiPages::CreateService, feature_category: :wiki do
  include ::EE::GeoHelpers

  describe '#execute' do
    context 'with Geo replication' do
      let_it_be(:primary) { create(:geo_node, :primary) }
      let_it_be(:secondary) { create(:geo_node) }
      let_it_be(:user) { create(:user) }

      let(:container) { create(:project) }

      let(:opts) do
        {
          title: 'Title',
          content: 'Content for wiki page',
          format: 'markdown'
        }
      end

      subject(:service) { described_class.new(container: container, current_user: user, params: opts) }

      context 'with geo_project_wiki_repository_replication feature flag disabled' do
        before do
          stub_feature_flags(geo_project_wiki_repository_replication: false)
        end

        context 'when on a Geo primary site' do
          before do
            stub_current_geo_node(primary)
          end

          it 'does not create a Geo::Event' do
            expect { service.execute }
              .not_to change { ::Geo::Event.count }
          end
        end

        context 'when not on a Geo primary site' do
          before do
            stub_current_geo_node(secondary)
          end

          it 'does not create a Geo::Event' do
            expect { service.execute }
              .not_to change { ::Geo::Event.count }
          end
        end
      end

      context 'with geo_project_wiki_repository_replication feature flag enabled' do
        before do
          stub_feature_flags(geo_project_wiki_repository_replication: true)
        end

        context 'when on a Geo primary site' do
          before do
            stub_current_geo_node(primary)
          end

          it 'creates a Geo::Event' do
            event_params = {
              event_name: :updated,
              replicable_name: :project_wiki_repository
            }

            expect { service.execute }
              .to change { ::Geo::Event.where(event_params).count }.by(1)
          end
        end

        context 'when not on a Geo primary site' do
          before do
            stub_current_geo_node(secondary)
          end

          it 'does not create a Geo::Event' do
            expect { service.execute }
              .not_to change { ::Geo::Event.count }
          end
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
