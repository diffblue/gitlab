# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::Repositories do
  let(:progress) { spy(:stdout) }
  let(:strategy) { spy(:strategy) }

  subject { described_class.new(progress, strategy: strategy) }

  describe '#dump' do
    context 'hashed storage' do
      let_it_be(:project) { create(:project, :repository) }
      let_it_be(:group) { create(:group, :wiki_repo) }

      it 'calls enqueue for each repository type', :aggregate_failures do
        create(:wiki_page, container: group)

        subject.dump(max_concurrency: 1, max_storage_concurrency: 1)

        expect(strategy).to have_received(:start).with(:create)
        expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
        expect(strategy).to have_received(:enqueue).with(group, Gitlab::GlRepository::WIKI)
        expect(strategy).to have_received(:wait)
      end
    end

    context 'no concurrency' do
      let_it_be(:groups) { create_list(:group, 5, :wiki_repo) }

      it 'creates the expected number of threads' do
        expect(Thread).not_to receive(:new)

        expect(strategy).to receive(:start).with(:create)
        groups.each do |group|
          expect(strategy).to receive(:enqueue).with(group, Gitlab::GlRepository::WIKI)
        end
        expect(strategy).to receive(:wait)

        subject.dump(max_concurrency: 1, max_storage_concurrency: 1)
      end

      describe 'command failure' do
        it 'enqueue_group raises an error' do
          allow(strategy).to receive(:enqueue).with(anything, Gitlab::GlRepository::WIKI).and_raise(IOError)

          expect { subject.dump(max_concurrency: 1, max_storage_concurrency: 1) }.to raise_error(IOError)
        end

        it 'group query raises an error' do
          allow(Group).to receive_message_chain(:includes, :find_each).and_raise(ActiveRecord::StatementTimeout)

          expect { subject.dump(max_concurrency: 1, max_storage_concurrency: 1) }.to raise_error(ActiveRecord::StatementTimeout)
        end
      end

      it 'avoids N+1 database queries' do
        control_count = ActiveRecord::QueryRecorder.new do
          subject.dump(max_concurrency: 1, max_storage_concurrency: 1)
        end.count

        create_list(:group, 2, :wiki_repo)

        expect do
          subject.dump(max_concurrency: 1, max_storage_concurrency: 1)
        end.not_to exceed_query_limit(control_count)
      end
    end
  end

  describe '#restore' do
    let_it_be(:project) { create(:project) }
    let_it_be(:group) { create(:group) }

    it 'calls enqueue for each repository type', :aggregate_failures do
      subject.restore

      expect(strategy).to have_received(:start).with(:restore)
      expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
      expect(strategy).to have_received(:enqueue).with(group, Gitlab::GlRepository::WIKI)
      expect(strategy).to have_received(:wait)
    end
  end
end
