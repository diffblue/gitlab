# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationHelper do
  include EE::GeoHelpers

  describe '#read_only_message', :geo do
    let(:default_maintenance_mode_message) { 'This GitLab instance is undergoing maintenance and is operating in read-only mode.' }

    context 'when not in a Geo secondary' do
      it 'returns a fallback message if database is readonly' do
        expect(Gitlab::Database.main).to receive(:read_only?) { true }

        expect(helper.read_only_message).to match('You are on a read-only GitLab instance')
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

          context 'when database is read-only' do
            it 'stacks read-only and maintenance mode messages' do
              expect(Gitlab::Database.main).to receive(:read_only?).twice { true }

              expect(helper.read_only_message).to match('You are on a read-only GitLab instance')
              expect(helper.read_only_message).to match(/#{default_maintenance_mode_message}/)
            end
          end
        end

        context 'disabled' do
          it 'returns nil' do
            stub_maintenance_mode_setting(false)

            expect(helper.read_only_message).to be_nil
          end
        end
      end
    end

    context 'on a geo secondary' do
      context 'maintenance mode on' do
        it 'returns messages for both' do
          expect(Gitlab::Geo).to receive(:secondary?).twice { true }
          stub_maintenance_mode_setting(true)

          expect(helper.read_only_message).to match(/you must visit the primary site/)
          expect(helper.read_only_message).to match(/#{default_maintenance_mode_message}/)
        end
      end
    end

    context 'when in a Geo Secondary' do
      let_it_be(:geo_primary) { create(:geo_node, :primary) }

      before do
        stub_current_geo_node(create(:geo_node))
      end

      it 'includes button to visit primary node' do
        expect(helper.read_only_message).to match(/Go to the primary site/)
        expect(helper.read_only_message).to include(geo_primary.url)
      end

      it 'returns a read-only Geo message with a link to primary node' do
        expect(helper.read_only_message).to match(/If you want to make changes, you must visit the primary site./)
        expect(helper.read_only_message).to include(geo_primary.url)
      end

      it 'returns a limited actions message when @limited_actions_message is true' do
        assign(:limited_actions_message, true)

        expect(helper.read_only_message).to match(/You may be able to make a limited amount of changes or perform a limited amount of actions on this page/)
        expect(helper.read_only_message).to include(geo_primary.url)
      end

      it 'includes a warning about database lag' do
        allow_any_instance_of(::Gitlab::Geo::HealthCheck).to receive(:db_replication_lag_seconds).and_return(120)

        expect(helper.read_only_message).to match(/If you want to make changes, you must visit the primary site./)
        expect(helper.read_only_message).to match(/The database is currently 2 minutes behind the primary node/)
        expect(helper.read_only_message).to include(geo_primary.url)
      end

      context 'event lag' do
        it 'includes a lag warning about a node lag' do
          event_log = create(:geo_event_log, created_at: 4.minutes.ago)
          create(:geo_event_log, created_at: 3.minutes.ago)
          create(:geo_event_log_state, event_id: event_log.id)

          expect(helper.read_only_message).to match(/If you want to make changes, you must visit the primary site./)
          expect(helper.read_only_message).to match(/The node is currently 3 minutes behind the primary/)
          expect(helper.read_only_message).to include(geo_primary.url)
        end

        it 'does not include a lag warning because the last event is too fresh' do
          event_log = create(:geo_event_log, created_at: 3.minutes.ago)
          create(:geo_event_log)
          create(:geo_event_log_state, event_id: event_log.id)

          expect(helper.read_only_message).to match(/If you want to make changes, you must visit the primary site./)
          expect(helper.read_only_message).not_to match(/The node is currently 3 minutes behind the primary/)
          expect(helper.read_only_message).to include(geo_primary.url)
        end

        it 'does not include a lag warning because the last event is processed' do
          event_log = create(:geo_event_log, created_at: 3.minutes.ago)
          create(:geo_event_log_state, event_id: event_log.id)

          expect(helper.read_only_message).to match(/If you want to make changes, you must visit the primary site./)
          expect(helper.read_only_message).not_to match(/The node is currently 3 minutes behind the primary/)
          expect(helper.read_only_message).to include(geo_primary.url)
        end

        it 'does not include a lag warning because there are no events yet' do
          expect(helper.read_only_message).to match(/If you want to make changes, you must visit the primary site./)
          expect(helper.read_only_message).not_to match(/minutes behind the primary/)
          expect(helper.read_only_message).to include(geo_primary.url)
        end
      end
    end
  end

  describe '#autocomplete_data_sources' do
    def expect_autocomplete_data_sources(object, noteable_type, source_keys)
      sources = helper.autocomplete_data_sources(object, noteable_type)
      expect(sources.keys).to match_array(source_keys)
      sources.keys.each do |key|
        expect(sources[key]).not_to be_nil
      end
    end

    context 'group' do
      let(:object) { create(:group) }
      let(:noteable_type) { Epic }

      it 'returns paths for autocomplete_sources_controller' do
        expect_autocomplete_data_sources(object, noteable_type, [:members, :issues, :mergeRequests, :labels, :epics, :commands, :milestones])
      end

      context 'when vulnerabilities are enabled' do
        before do
          stub_licensed_features(security_dashboard: true)
        end

        it 'returns paths for autocomplete_sources_controller with vulnerabilities' do
          expect_autocomplete_data_sources(object, noteable_type, [:members, :issues, :mergeRequests, :labels, :epics, :vulnerabilities, :commands, :milestones])
        end
      end
    end

    context 'project' do
      let(:object) { create(:project) }
      let(:noteable_type) { Issue }

      context 'when epics and vulnerabilities are enabled' do
        before do
          stub_licensed_features(epics: true, security_dashboard: true)
        end

        it 'returns paths for autocomplete_sources_controller for personal projects' do
          expect_autocomplete_data_sources(object, noteable_type, [:members, :issues, :mergeRequests, :labels, :milestones, :commands, :snippets, :vulnerabilities])
        end

        it 'returns paths for autocomplete_sources_controller including epics and vulnerabilities for group projects' do
          object.update!(group: create(:group))

          expect_autocomplete_data_sources(object, noteable_type, [:members, :issues, :mergeRequests, :labels, :milestones, :commands, :snippets, :epics, :vulnerabilities])
        end
      end

      context 'when epics and vulnerabilities are disabled' do
        it 'returns paths for autocomplete_sources_controller' do
          expect_autocomplete_data_sources(object, noteable_type, [:members, :issues, :mergeRequests, :labels, :milestones, :commands, :snippets])
        end
      end
    end
  end

  context 'when both CE and EE has partials with the same name' do
    let(:partial) { 'shared/issuable/form/default_templates' }
    let(:view) { 'projects/merge_requests/show' }
    let(:project) { build_stubbed(:project) }

    describe '#render_ce' do
      before do
        helper.instance_variable_set(:@project, project)

        allow(project).to receive(:feature_available?)
      end

      it 'renders the CE partial' do
        helper.render_ce(partial)

        expect(project).not_to receive(:feature_available?)
      end
    end

    describe '#find_ce_template' do
      let(:expected_partial_path) do
        "app/views/#{File.dirname(partial)}/_#{File.basename(partial)}.html.haml"
      end

      let(:expected_view_path) do
        "app/views/#{File.dirname(view)}/#{File.basename(view)}.html.haml"
      end

      it 'finds the CE partial' do
        ce_partial = helper.find_ce_template(partial)

        expect(ce_partial.short_identifier).to eq(expected_partial_path)

        # And it could still find the EE partial
        ee_partial = helper.lookup_context.find(partial, [], true)
        expect(ee_partial.short_identifier).to eq("ee/#{expected_partial_path}")
      end

      it 'finds the CE view' do
        ce_view = helper.find_ce_template(view)

        expect(ce_view.short_identifier).to eq(expected_view_path)

        # And it could still find the EE view
        ee_view = helper.lookup_context.find(view, [], false)
        expect(ee_view.short_identifier).to eq("ee/#{expected_view_path}")
      end
    end
  end
end
