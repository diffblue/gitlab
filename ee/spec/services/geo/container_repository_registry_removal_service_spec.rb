# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::ContainerRepositoryRegistryRemovalService, :geo, feature_category: :geo_replication do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers

  let_it_be(:secondary) { create(:geo_node) }

  before do
    stub_current_geo_node(secondary)
  end

  def expect_to_log_a_message_with(container_repository_id, message, level: :error)
    allow(Gitlab::Geo::Logger)
        .to receive(level)
        .with(any_args)

    Array(message).each do |message|
      expect(Gitlab::Geo::Logger)
        .to receive(level)
        .with(
          hash_including(
            message: message,
            container_repository_id: container_repository_id
          )
        )
    end
  end

  describe '#execute' do
    let_it_be(:container_repository) { create(:container_repository) }

    subject(:service) { described_class.new(container_repository.id, container_repository.path) }

    before do
      stub_exclusive_lease(
        "container_repository_registry_removal_service:container_repository:#{container_repository.id}",
        timeout: described_class::LEASE_TIMEOUT
      )
    end

    context 'when the registry record exists' do
      let!(:registry) { create(:geo_container_repository_registry, container_repository_id: container_repository.id) }

      it 'removes the container repository and the registry' do
        expect_next_instance_of(ContainerRepository) do |container_repository|
          expect(container_repository).to receive(:delete_tags!)
        end

        service.execute

        expect(Geo::ContainerRepositoryRegistry).not_to be_exist(registry.id)
      end

      context 'when something went wrong removing the container repository' do
        before do
          allow_next_instance_of(ContainerRepository) do |container_repository|
            allow(container_repository).to receive(:delete_tags!)
                                             .and_raise(SystemCallError, 'Something went wrong')
          end
        end

        it 'logs an error message' do
          expect_to_log_a_message_with(container_repository.id, 'Could not remove repository')

          expect { service.execute }.to raise_error(SystemCallError, /Something went wrong/)
        end

        it 'does not remove the upload registry record' do
          expect { service.execute }
            .to change(Geo::ContainerRepositoryRegistry, :count).by(0)
            .and(raise_error(SystemCallError, /Something went wrong/))
        end
      end
    end

    context 'when the registry record does not exist' do
      it 'removes the container repository' do
        expect_next_instance_of(ContainerRepository) do |container_repository|
          expect(container_repository).to receive(:delete_tags!)
        end

        service.execute
      end
    end
  end
end
