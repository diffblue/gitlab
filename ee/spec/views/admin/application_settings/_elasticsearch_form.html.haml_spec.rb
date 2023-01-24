# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/_elasticsearch_form', feature_category: :global_search do
  let_it_be(:admin) { create(:admin) }

  let(:page) { Capybara::Node::Simple.new(rendered) }
  let(:pause_indexing) { false }
  let(:pending_migrations) { false }
  let(:elastic_reindexing_task) { build(:elastic_reindexing_task) }

  before do
    assign(:application_setting, application_setting)
    assign(:elasticsearch_reindexing_task, elastic_reindexing_task)
    allow(view).to receive(:current_user) { admin }
    allow(view).to receive(:expanded) { true }
  end

  context 'es indexing' do
    let(:application_setting) { build(:application_setting) }
    let(:button_text) { 'Index all projects' }

    before do
      allow(Gitlab::CurrentSettings).to(receive(:elasticsearch_indexing?)).and_return(es_indexing)
      allow(Gitlab::CurrentSettings).to(receive(:elasticsearch_pause_indexing?)).and_return(pause_indexing)
      allow(Elastic::DataMigrationService).to(receive(:pending_migrations?)).and_return(pending_migrations)
    end

    context 'indexing is enabled' do
      let(:es_indexing) { true }

      it 'hides index button when indexing is disabled' do
        render

        expect(rendered).to have_css('a.btn-confirm', text: button_text)
      end

      it 'renders an enabled pause checkbox' do
        render

        expect(rendered).to have_css('input[id=application_setting_elasticsearch_pause_indexing]')
        expect(rendered).not_to have_css('input[id=application_setting_elasticsearch_pause_indexing][disabled="disabled"]')
      end

      context 'pending migrations' do
        using RSpec::Parameterized::TableSyntax

        let(:pending_migrations) { true }
        let(:migration) { Elastic::DataMigrationService.migrations.first }

        before do
          allow(Elastic::DataMigrationService).to receive(:pending_migrations).and_return([migration])
          allow(migration).to receive(:running?).and_return(running)
          allow(migration).to receive(:pause_indexing?).and_return(pause_indexing)
        end

        where(:running, :pause_indexing, :disabled) do
          false | false | false
          false | true  | false
          true  | false | false
          true  | true  | true
        end

        with_them do
          it 'renders pause checkbox with disabled set appropriately' do
            render

            if disabled
              expect(rendered).to have_css('input[id=application_setting_elasticsearch_pause_indexing][disabled="disabled"]')
            else
              expect(rendered).not_to have_css('input[id=application_setting_elasticsearch_pause_indexing][disabled="disabled"]')
            end
          end
        end
      end
    end

    context 'indexing is disabled' do
      let(:es_indexing) { false }

      it 'shows index button when indexing is enabled' do
        render

        expect(rendered).not_to have_css('a.btn-confirm', text: button_text)
      end

      it 'renders a disabled pause checkbox' do
        render

        expect(rendered).to have_css('input[id=application_setting_elasticsearch_pause_indexing][disabled="disabled"]')
      end
    end
  end

  context 'when elasticsearch_aws_secret_access_key is not set' do
    let(:application_setting) { build(:application_setting) }

    it 'has field with "AWS Secret Access Key" label and no value' do
      render
      expect(rendered).to have_field('AWS Secret Access Key', type: 'password')
      expect(page.find_field('AWS Secret Access Key').value).to be_blank
    end
  end

  context 'when elasticsearch_aws_secret_access_key is set' do
    let(:application_setting) { build(:application_setting, elasticsearch_aws_secret_access_key: 'elasticsearch_aws_secret_access_key') }

    it 'has field with "Enter new AWS Secret Access Key" label and a masked value' do
      render
      expect(rendered).to have_field('Enter new AWS Secret Access Key', type: 'password')
      expect(page.find_field('Enter new AWS Secret Access Key').value).to eq(ApplicationSetting::MASK_PASSWORD)
    end
  end

  context 'zero-downtime elasticsearch reindexing' do
    let(:application_setting) { build(:application_setting) }

    before do
      assign(:last_elasticsearch_reindexing_task, task)
    end

    context 'when task is in progress' do
      let(:task) { build(:elastic_reindexing_task, state: :reindexing) }

      it 'renders a disabled pause checkbox' do
        render

        expect(rendered).to have_css('input[id=application_setting_elasticsearch_pause_indexing][disabled="disabled"]')
      end

      it 'renders a disabled trigger cluster reindexing link' do
        render

        expect(rendered).to have_button('Trigger cluster reindexing', disabled: true)
      end
    end

    context 'without extended details' do
      let(:task) { build(:elastic_reindexing_task) }

      it 'renders the task' do
        render

        expect(rendered).to include("Reindexing Status: #{task.state}")
        expect(rendered).not_to include("Task ID:")
        expect(rendered).not_to include("Error:")
        expect(rendered).not_to include("Expected documents:")
        expect(rendered).not_to include("Documents reindexed:")
      end
    end

    context 'with extended details' do
      let!(:task) { create(:elastic_reindexing_task, state: :reindexing, error_message: 'error-message') }
      let!(:subtask) { create(:elastic_reindexing_subtask, elastic_reindexing_task: task, documents_count_target: 5, documents_count: 10) }

      it 'renders the task information' do
        render

        expect(rendered).to include("Reindexing Status: #{task.state}")
        expect(rendered).to include("Error: #{task.error_message}")
        expect(rendered).to include("Expected documents: #{subtask.documents_count}")
        expect(rendered).to include("Documents reindexed: #{subtask.documents_count_target} (50.0%)")
      end
    end

    context 'with extended details, but without documents_count_target' do
      let!(:task) { create(:elastic_reindexing_task, state: :reindexing) }
      let!(:subtask) { create(:elastic_reindexing_subtask, elastic_reindexing_task: task, documents_count: 10) }

      it 'renders the task information' do
        render

        expect(rendered).to include("Reindexing Status: #{task.state}")
        expect(rendered).to include("Expected documents: #{subtask.documents_count}")
        expect(rendered).not_to include("Error:")
        expect(rendered).not_to include("Documents reindexed:")
      end
    end

    context 'when there are 0 documents expected' do
      let_it_be(:task) { create(:elastic_reindexing_task, state: :reindexing) }
      let_it_be(:subtask) { create(:elastic_reindexing_subtask, elastic_reindexing_task: task, documents_count_target: 0, documents_count: 0) }

      it 'renders 100% completed progress' do
        render

        expect(rendered).to include('Expected documents: 0')
        expect(rendered).to include('Documents reindexed: 0 (100%)')
      end
    end
  end

  context 'when there are elasticsearch indexed namespaces' do
    let(:application_setting) { build(:application_setting, elasticsearch_limit_indexing: true) }

    before do
      create(:elasticsearch_indexed_namespace)
      create(:elasticsearch_indexed_namespace)
      create(:elasticsearch_indexed_namespace)
    end

    it 'shows the input' do
      render
      expect(rendered).to have_selector('.js-namespaces-indexing-restrictions')
    end

    context 'when there are too many elasticsearch indexed namespaces' do
      before do
        create_list :elasticsearch_indexed_namespace, 60
      end

      it 'hides the input' do
        render
        expect(rendered).not_to have_selector('.js-namespaces-indexing-restrictions')
      end
    end
  end

  context 'when there are elasticsearch indexed projects' do
    let(:application_setting) { build(:application_setting, elasticsearch_limit_indexing: true) }

    before do
      create(:elasticsearch_indexed_project)
      create(:elasticsearch_indexed_project)
      create(:elasticsearch_indexed_project)
    end

    it 'shows the input' do
      render
      expect(rendered).to have_selector('.js-projects-indexing-restrictions')
    end

    context 'when there are too many elasticsearch indexed projects' do
      before do
        create_list :elasticsearch_indexed_project, 60
      end

      it 'hides the input' do
        render
        expect(rendered).not_to have_selector('.js-projects-indexing-restrictions')
      end
    end
  end

  context 'elasticsearch migrations' do
    let(:application_setting) { build(:application_setting) }

    it 'does not show the retry migration card' do
      render

      expect(rendered).not_to include('Elasticsearch migration halted')
      expect(rendered).not_to include('Retry migration')
    end

    context 'when Elasticsearch migration halted' do
      let(:migration) { Elastic::DataMigrationService.migrations.last }

      before do
        allow(Elastic::DataMigrationService).to receive(:halted_migrations?).and_return(true)
        allow(Elastic::DataMigrationService).to receive(:halted_migration).and_return(migration)
      end

      context 'when there is no reindexing' do
        it 'shows the retry migration card' do
          render

          expect(rendered).to include('Elasticsearch migration halted')
          expect(rendered).to have_css('a', text: 'Retry migration')
          expect(rendered).not_to have_css('a[disabled="disabled"]', text: 'Retry migration')
        end
      end

      context 'when there is a reindexing task in progress' do
        before do
          assign(:last_elasticsearch_reindexing_task, build(:elastic_reindexing_task))
        end

        it 'shows the retry migration card with retry button disabled' do
          render

          expect(rendered).to include('Elasticsearch migration halted')
          expect(rendered).to have_css('a[disabled="disabled"]', text: 'Retry migration')
        end
      end
    end

    context 'when elasticsearch is unreachable' do
      before do
        allow(Gitlab::Elastic::Helper.default).to receive(:ping?).and_return(false)
      end

      it 'does not show the retry migration card' do
        render

        expect(rendered).not_to include('Elasticsearch migration halted')
        expect(rendered).not_to include('Retry migration')
      end
    end
  end
end
