# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::ProjectRepositoryRegistry, :geo, type: :model, feature_category: :geo_replication do
  include ::EE::GeoHelpers

  let_it_be(:registry) { build(:geo_project_repository_registry) }

  specify 'factory is valid' do
    expect(registry).to be_valid
  end

  include_examples 'a Geo framework registry'

  describe '.repository_out_of_date?' do
    let_it_be(:project) { create(:project) }

    context 'for a non-Geo setup' do
      it 'returns false' do
        expect(described_class.repository_out_of_date?(project.id)).to be_falsey
      end
    end

    context 'for a Geo setup' do
      before do
        stub_current_geo_node(current_node)
      end

      context 'for a Geo Primary' do
        let(:current_node) { create(:geo_node, :primary) }

        it 'returns false' do
          expect(described_class.repository_out_of_date?(project.id)).to be_falsey
        end
      end

      context 'for a Geo secondary' do
        let(:current_node) { create(:geo_node) }

        context 'when Primary node is not configured' do
          it 'returns false' do
            expect(described_class.repository_out_of_date?(project.id)).to be_falsey
          end
        end

        context 'when Primary node is configured' do
          before do
            create(:geo_node, :primary)
          end

          context 'when project_repository_registry entry does not exist' do
            it 'returns true' do
              expect(described_class.repository_out_of_date?(project.id)).to be_truthy
            end
          end

          context 'when project_repository_registry entry does exist' do
            context 'when last_repository_updated_at is not set' do
              it 'returns false' do
                registry = create(:geo_project_repository_registry, :synced)
                registry.project.update!(last_repository_updated_at: nil)

                expect(described_class.repository_out_of_date?(registry.project_id)).to be_falsey
              end
            end

            context 'when last_repository_updated_at is set' do
              context 'when sync failed' do
                it 'returns true' do
                  registry = create(:geo_project_repository_registry, :failed)

                  expect(described_class.repository_out_of_date?(registry.project_id)).to be_truthy
                end
              end

              context 'when last_synced_at is not set' do
                it 'returns true' do
                  registry = create(:geo_project_repository_registry, last_synced_at: nil)

                  expect(described_class.repository_out_of_date?(registry.project_id)).to be_truthy
                end
              end

              context 'when last_synced_at is set', :freeze_time do
                using RSpec::Parameterized::TableSyntax

                let_it_be(:project_repository_state) { create(:repository_state, project: project) }

                where(:project_last_updated, :project_state_last_updated, :project_registry_last_synced, :expected) do
                  (Time.current - 3.minutes) | nil                        | (Time.current - 5.minutes) | true
                  (Time.current - 3.minutes) | nil                        | (Time.current - 1.minute)  | false
                  (Time.current - 3.minutes) | Time.current               | (Time.current - 1.minute)  | true
                  (Time.current - 3.minutes) | (Time.current - 2.minutes) | (Time.current - 1.minute)  | false
                  (Time.current - 3.minutes) | Time.current               | (Time.current - 5.minutes) | true
                end

                with_them do
                  before do
                    project.update!(last_repository_updated_at: project_last_updated)
                    project_repository_state.update!(last_repository_updated_at: project_state_last_updated)
                    create(:geo_project_repository_registry, :synced,
                      project: project, last_synced_at: project_registry_last_synced)
                  end

                  it 'returns the expected value' do
                    expect(described_class.repository_out_of_date?(project.id)).to eq(expected)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
