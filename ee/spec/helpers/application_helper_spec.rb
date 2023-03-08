# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationHelper do
  include EE::GeoHelpers
  include Devise::Test::ControllerHelpers

  describe '#read_only_message', :geo do
    let(:default_maintenance_mode_message) { 'GitLab is undergoing maintenance' }

    context 'when not in a Geo secondary' do
      it 'returns a fallback message if database is readonly', :aggregate_failures do
        expect(Gitlab::Database).to receive(:read_only?).and_return(true)

        expect(helper.read_only_message).to match('You are on a read-only GitLab instance.')
      end

      it 'returns nil when database is not read_only' do
        expect(helper.read_only_message).to be_nil
      end

      context 'maintenance mode' do
        context 'enabled' do
          before do
            stub_maintenance_mode_setting(true)
          end

          it 'returns default message' do
            expect(helper.read_only_message).to match(default_maintenance_mode_message)
          end

          it 'returns user set custom maintenance mode message' do
            custom_message = 'Maintenance window ends at 00:00.'
            stub_application_setting(maintenance_mode_message: custom_message)

            expect(helper.read_only_message).to match(/#{custom_message}/)
          end
        end

        context 'disabled' do
          before do
            stub_maintenance_mode_setting(false)
          end

          it 'returns nil' do
            expect(helper.read_only_message).to be_nil
          end
        end
      end
    end

    context 'when in a Geo Secondary' do
      let_it_be(:geo_primary) { create(:geo_node, :primary) }

      before do
        stub_current_geo_node(create(:geo_node))
      end

      context 'maintenance mode' do
        context 'enabled' do
          before do
            stub_maintenance_mode_setting(true)
          end

          it 'returns default message' do
            expect(helper.read_only_message).to match(default_maintenance_mode_message)
          end

          it 'returns user set custom maintenance mode message' do
            custom_message = 'Maintenance window ends at 00:00.'
            stub_application_setting(maintenance_mode_message: custom_message)

            expect(helper.read_only_message).to match(/#{custom_message}/)
          end
        end

        context 'disabled' do
          before do
            stub_maintenance_mode_setting(false)
          end

          it 'returns nil' do
            expect(helper.read_only_message).to be_nil
          end
        end
      end
    end
  end

  describe '#read_only_description', :geo do
    context 'when not in a Geo secondary' do
      context 'maintenance mode' do
        context 'enabled' do
          before do
            stub_maintenance_mode_setting(true)
          end

          it 'returns read-only message' do
            expect(helper.read_only_description).to match('You are on a read-only GitLab instance.')
          end
        end

        context 'disabled' do
          before do
            stub_maintenance_mode_setting(false)
          end

          it 'returns nil' do
            expect(helper.read_only_description).to be_nil
          end
        end
      end
    end

    context 'when in a Geo Secondary' do
      let_it_be(:geo_primary) { create(:geo_node, :primary) }

      before do
        stub_current_geo_node(create(:geo_node))
      end

      context 'maintenance mode' do
        context 'enabled' do
          before do
            stub_maintenance_mode_setting(true)
          end

          it 'returns nil' do
            expect(helper.read_only_description).to be_nil
          end
        end

        context 'disabled' do
          before do
            stub_maintenance_mode_setting(false)
          end

          it 'returns nil' do
            expect(helper.read_only_description).to be_nil
          end
        end
      end
    end
  end

  describe '#geo_secondary_read_only_description', :geo do
    context 'when not in a Geo secondary' do
      it 'returns nil' do
        expect(helper.geo_secondary_read_only_description).to be_nil
      end

      context 'maintenance mode' do
        context 'enabled' do
          before do
            stub_maintenance_mode_setting(true)
          end

          it 'returns nil' do
            expect(helper.geo_secondary_read_only_description).to be_nil
          end
        end

        context 'disabled' do
          before do
            stub_maintenance_mode_setting(false)
          end

          it 'returns nil' do
            expect(helper.geo_secondary_read_only_description).to be_nil
          end
        end
      end
    end

    context 'when in a Geo Secondary' do
      let_it_be(:geo_primary) { create(:geo_node, :primary) }

      before do
        stub_current_geo_node(create(:geo_node))
      end

      it 'returns a read-only Geo message', :aggregate_failures do
        expect(helper.geo_secondary_read_only_description).to match(/You are on a secondary/)
        expect(helper.geo_secondary_read_only_description).to match(/If you want to make changes, you must visit the primary site./)
      end

      it 'returns a limited actions message when @limited_actions_message is true' do
        assign(:limited_actions_message, true)

        expect(helper.geo_secondary_read_only_description).to match(/You may be able to make a limited amount of changes or perform a limited amount of actions on this page/)
      end

      it 'includes a warning about database lag', :aggregate_failures do
        allow_any_instance_of(::Gitlab::Geo::HealthCheck).to receive(:db_replication_lag_seconds).and_return(120)

        expect(helper.geo_secondary_read_only_description).to match(/If you want to make changes, you must visit the primary site./)
        expect(helper.geo_secondary_read_only_description).to match(/The database is currently 2 minutes behind the primary site/)
      end

      context 'event lag' do
        it 'includes a lag warning about a node lag', :aggregate_failures do
          event_log = create(:geo_event_log, created_at: 4.minutes.ago)
          create(:geo_event_log, created_at: 3.minutes.ago)
          create(:geo_event_log_state, event_id: event_log.id)

          expect(helper.geo_secondary_read_only_description).to match(/If you want to make changes, you must visit the primary site./)
          expect(helper.geo_secondary_read_only_description).to match(/The site is currently 3 minutes behind the primary/)
        end

        it 'does not include a lag warning because the last event is too fresh', :aggregate_failures do
          event_log = create(:geo_event_log, created_at: 3.minutes.ago)
          create(:geo_event_log)
          create(:geo_event_log_state, event_id: event_log.id)

          expect(helper.geo_secondary_read_only_description).to match(/If you want to make changes, you must visit the primary site./)
          expect(helper.geo_secondary_read_only_description).not_to match(/The site is currently 3 minutes behind the primary/)
        end

        it 'does not include a lag warning because the last event is processed', :aggregate_failures do
          event_log = create(:geo_event_log, created_at: 3.minutes.ago)
          create(:geo_event_log_state, event_id: event_log.id)

          expect(helper.geo_secondary_read_only_description).to match(/If you want to make changes, you must visit the primary site./)
          expect(helper.geo_secondary_read_only_description).not_to match(/The site is currently 3 minutes behind the primary/)
        end

        it 'does not include a lag warning because there are no events yet', :aggregate_failures do
          expect(helper.geo_secondary_read_only_description).to match(/If you want to make changes, you must visit the primary site./)
          expect(helper.geo_secondary_read_only_description).not_to match(/minutes behind the primary/)
        end
      end
    end
  end

  describe '#autocomplete_data_sources', feature_category: :team_planning do
    def expect_autocomplete_data_sources(object, noteable_type, source_keys)
      sources = helper.autocomplete_data_sources(object, noteable_type)
      expect(sources.keys).to match_array(source_keys)
      sources.keys.each do |key|
        expect(sources[key]).not_to be_nil
      end
    end

    context 'group' do
      let(:autocomplete_data_sources) { [:members, :issues, :mergeRequests, :labels, :commands, :milestones, :epics] }
      let(:object) { create(:group) }
      let(:noteable_type) { Epic }

      context 'when licensed features are disabled' do
        before do
          stub_licensed_features(security_dashboard: false, iterations: false)
        end

        it 'returns paths for autocomplete_sources_controller', :aggregate_failures do
          expect_autocomplete_data_sources(object, noteable_type, autocomplete_data_sources)
        end
      end

      context 'when licensed features are enabled' do
        before do
          stub_licensed_features(security_dashboard: true, iterations: true)
        end

        it 'returns paths for autocomplete_sources_controller including iterations and vulnerabilities', :aggregate_failures do
          expect_autocomplete_data_sources(object, noteable_type, autocomplete_data_sources + [:iterations, :vulnerabilities])
        end
      end
    end

    context 'project' do
      let(:autocomplete_data_sources) { [:members, :issues, :mergeRequests, :labels, :commands, :milestones, :snippets, :contacts] }
      let(:object) { create(:project) }
      let(:noteable_type) { Issue }

      context 'when licensed features are enabled' do
        before do
          stub_licensed_features(epics: true, security_dashboard: true, iterations: true)
        end

        it 'returns paths for autocomplete_sources_controller for personal projects' do
          expect_autocomplete_data_sources(object, noteable_type, autocomplete_data_sources + [:vulnerabilities])
        end

        it 'returns paths for autocomplete_sources_controller including epics, iterations and vulnerabilities for group projects' do
          object.update!(group: create(:group))

          expect_autocomplete_data_sources(object, noteable_type, autocomplete_data_sources + [:epics, :iterations, :vulnerabilities])
        end
      end

      context 'when licensed features are disabled' do
        before do
          stub_licensed_features(epics: false, security_dashboard: false, iterations: false)
        end

        it 'returns paths for autocomplete_sources_controller' do
          expect_autocomplete_data_sources(object, noteable_type, autocomplete_data_sources)
        end
      end
    end
  end

  context 'when both CE and EE has partials with the same name' do
    let(:partial) { 'projects/settings/archive' }
    let(:view) { 'projects/merge_requests/show' }
    let(:project) { build_stubbed(:project) }

    describe '#render_ce' do
      before do
        helper.instance_variable_set(:@project, project)

        allow(project).to receive(:marked_for_deletion?)
      end

      it 'renders the CE partial' do
        helper.render_ce(partial)

        expect(project).not_to receive(:marked_for_deletion?)
      end
    end

    describe '#find_ce_template' do
      let(:expected_partial_path) do
        "app/views/#{File.dirname(partial)}/_#{File.basename(partial)}.html.haml"
      end

      let(:expected_view_path) do
        "app/views/#{File.dirname(view)}/#{File.basename(view)}.html.haml"
      end

      it 'finds the CE partial', :aggregate_failures do
        ce_partial = helper.find_ce_template(partial)

        expect(ce_partial.short_identifier).to eq(expected_partial_path)

        # And it could still find the EE partial
        ee_partial = helper.lookup_context.find(partial, [], true)
        expect(ee_partial.short_identifier).to eq("ee/#{expected_partial_path}")
      end

      it 'finds the CE view', :aggregate_failures do
        ce_view = helper.find_ce_template(view)

        expect(ce_view.short_identifier).to eq(expected_view_path)

        # And it could still find the EE view
        ee_view = helper.lookup_context.find(view, [], false)
        expect(ee_view.short_identifier).to eq("ee/#{expected_view_path}")
      end
    end
  end

  describe '#page_class' do
    let_it_be(:expected_class) { 'logged-out-marketing-header' }

    let(:current_user) { nil }

    subject(:page_class) do
      helper.page_class.flatten
    end

    before do
      allow(helper).to receive(:current_user) { current_user }
    end

    it { is_expected.not_to include(expected_class) }

    context 'when SaaS', :saas do
      it { is_expected.to include(expected_class) }

      context 'when a user is logged in' do
        let(:current_user) { build(:user) }

        it { is_expected.not_to include(expected_class) }
      end
    end
  end
end
