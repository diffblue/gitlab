# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Search::NamespaceIndexIntegrityWorker, feature_category: :global_search do
  include ExclusiveLeaseHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:projects) { create_list(:project, 3, :repository, namespace: group) }

  subject(:worker) { described_class.new }

  describe '#perform' do
    context 'when namespace_id is not provided' do
      it 'does nothing' do
        expect(::Search::ProjectIndexIntegrityWorker).not_to receive(:perform_in)

        worker.perform(nil)
      end
    end

    context 'when namespace_id is provided', :elastic_delete_by_query do
      before do
        stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
      end

      it_behaves_like 'an idempotent worker' do
        let(:job_args) { [group.id] }

        it 'schedules ProjectIndexIntegrityWorker for each project with a delay' do
          stub_const("#{described_class.name}::PROJECT_DELAY_INTERVAL", 5)

          group.all_projects.each do |p|
            expect(::Search::ProjectIndexIntegrityWorker).to receive(:perform_in).with(
              within(5.seconds).of(5.seconds),
              p.id
            ).and_call_original
          end

          worker.perform(group.id)
        end
      end

      it 'executes under an exclusive lease' do
        expect_to_obtain_exclusive_lease("#{described_class.name.underscore}/namespace/#{group.id}",
          timeout: described_class::LEASE_TIMEOUT)

        worker.perform(group.id)
      end

      context 'when project.should_check_index_integrity? is false' do
        it 'does not schedule ProjectIndexIntegrityWorker for that project' do
          allow_next_found_instance_of(Project) do |p|
            allow(p).to receive(:should_check_index_integrity?).and_return(false)
          end

          expect(::Search::ProjectIndexIntegrityWorker).not_to receive(:perform_in)

          worker.perform(group.id)
        end
      end

      context 'when a namespace has sub-groups', :sidekiq_inline do
        it 'recursively schedules itself for each child namespace with a delay', :aggregate_failures do
          stub_const("#{described_class.name}::NAMESPACE_DELAY_INTERVAL", 10)

          sg_1 = create(:group, parent: group)
          sg_2 = create(:group, parent: sg_1)

          expect(described_class).to receive(:perform_in)
            .with(within(10.seconds).of(10.seconds), sg_1.id).and_call_original
          expect(described_class).to receive(:perform_in)
            .with(within(10.seconds).of(10.seconds), sg_2.id).and_call_original

          worker.perform(group.id)
        end
      end

      context 'when namespace is not found' do
        it 'does nothing' do
          expect(::Search::ProjectIndexIntegrityWorker).not_to receive(:perform_in)

          worker.perform(non_existing_record_id)
        end
      end

      context 'when namespace.use_elasticsearch? is false' do
        it 'does nothing' do
          allow_next_found_instance_of(Namespace) do |p|
            allow(p).to receive(:use_elasticsearch?).and_return(false)
          end

          expect(::Search::ProjectIndexIntegrityWorker).not_to receive(:perform_in)
          expect(described_class).not_to receive(:perform_in)

          worker.perform(group.id)
        end
      end
    end
  end
end
