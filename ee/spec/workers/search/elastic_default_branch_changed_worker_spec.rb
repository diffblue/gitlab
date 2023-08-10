# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::ElasticDefaultBranchChangedWorker, feature_category: :global_search do
  let_it_be_with_reload(:project) { create(:project, :repository) }

  let(:default_branch_changed_event) { Repositories::DefaultBranchChangedEvent.new(data: data) }
  let(:container) { project }
  let(:data) { { container_id: container.id, container_type: container.class.name } }

  before do
    stub_ee_application_setting(elasticsearch_indexing: true)
    allow(ElasticCommitIndexerWorker).to receive(:perform_async).and_return(true)
    allow(ElasticWikiIndexerWorker).to receive(:perform_async).and_return(true)
  end

  it_behaves_like 'subscribes to event' do
    let(:event) { default_branch_changed_event }
  end

  context 'when passed a project' do
    it 'schedules ElasticCommitIndexerWorker' do
      expect(ElasticCommitIndexerWorker).to receive(:perform_async).with(project.id)

      consume_event(subscriber: described_class, event: default_branch_changed_event)
    end

    context 'when project does not exist' do
      let(:data) { { container_id: non_existing_record_id, container_type: container.class.name } }

      it 'does not schedule ElasticCommitIndexerWorker and does not raise an exception' do
        expect(ElasticCommitIndexerWorker).not_to receive(:perform_async)

        expect { consume_event(subscriber: described_class, event: default_branch_changed_event) }
          .not_to raise_exception
      end
    end

    context 'when project does not use elasticsearch' do
      before do
        stub_ee_application_setting(elasticsearch_limit_indexing: true)
      end

      it 'does not schedule ElasticCommitIndexerWorker' do
        expect(ElasticCommitIndexerWorker).not_to receive(:perform_async)

        consume_event(subscriber: described_class, event: default_branch_changed_event)
      end
    end

    context 'when elasticsearch_indexing is not enabled' do
      before do
        stub_ee_application_setting(elasticsearch_indexing: false)
      end

      it 'does not schedule ElasticCommitIndexerWorker' do
        expect(ElasticCommitIndexerWorker).not_to receive(:perform_async)

        consume_event(subscriber: described_class, event: default_branch_changed_event)
      end
    end
  end

  context 'when passed a group wiki' do
    let_it_be(:group_wiki) { create(:group_wiki) }

    let(:container) { group_wiki }

    before do
      allow(::Wiki).to receive(:use_separate_indices?).and_return(true)
    end

    it 'schedules ElasticWikiIndexerWorker' do
      expect(ElasticWikiIndexerWorker)
        .to receive(:perform_async).with(group_wiki.group.id, 'Group')

      consume_event(subscriber: described_class, event: default_branch_changed_event)
    end

    context 'when group does not exist' do
      let(:data) { { container_id: non_existing_record_id, container_type: container.class.name } }

      it 'does not schedule ElasticWikiIndexerWorker and does not raise an exception' do
        expect(ElasticWikiIndexerWorker).not_to receive(:perform_async)

        expect { consume_event(subscriber: described_class, event: default_branch_changed_event) }
          .not_to raise_exception
      end
    end

    context 'when group does not use elasticsearch' do
      before do
        stub_ee_application_setting(elasticsearch_limit_indexing: true)
      end

      it 'does not schedule ElasticWikiIndexerWorker' do
        expect(ElasticWikiIndexerWorker).not_to receive(:perform_async)

        consume_event(subscriber: described_class, event: default_branch_changed_event)
      end
    end

    context 'when Wiki.use_separate_indices? is false' do
      before do
        allow(::Wiki).to receive(:use_separate_indices?).and_return(false)
      end

      it 'does not schedule ElasticWikiIndexerWorker' do
        expect(ElasticWikiIndexerWorker).not_to receive(:perform_async)

        consume_event(subscriber: described_class, event: default_branch_changed_event)
      end
    end
  end

  context 'when passed a project wiki' do
    let_it_be(:project_wiki) { create(:project_wiki, project: project) }

    let(:container) { project_wiki }

    it 'schedules ElasticWikiIndexerWorker' do
      expect(ElasticWikiIndexerWorker).to receive(:perform_async).with(project.id, 'Project')

      consume_event(subscriber: described_class, event: default_branch_changed_event)
    end

    context 'when project wiki does not exist' do
      let(:data) { { container_id: non_existing_record_id, container_type: container.class.name } }

      it 'does not schedule ElasticWikiIndexerWorker and does not raise an exception' do
        expect(ElasticWikiIndexerWorker).not_to receive(:perform_async)

        expect { consume_event(subscriber: described_class, event: default_branch_changed_event) }
          .not_to raise_exception
      end
    end

    context 'when project wiki does not use elasticsearch' do
      before do
        stub_ee_application_setting(elasticsearch_limit_indexing: true)
      end

      it 'does not schedule ElasticWikiIndexerWorker' do
        expect(ElasticWikiIndexerWorker).not_to receive(:perform_async)

        consume_event(subscriber: described_class, event: default_branch_changed_event)
      end
    end
  end
end
