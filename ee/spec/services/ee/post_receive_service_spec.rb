# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PostReceiveService, :geo do
  include EE::GeoHelpers

  let_it_be(:primary_url) { 'http://primary.example.com' }
  let_it_be(:secondary_url) { 'http://secondary.example.com' }
  let_it_be(:primary_node, reload: true) { create(:geo_node, :primary, url: primary_url) }
  let_it_be(:secondary_node, reload: true) { create(:geo_node, url: secondary_url) }

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  let(:gl_repository) { "project-#{project.id}" }
  let(:repository) { project.repository }
  let(:identifier) { 'key-123' }
  let(:git_push_http) { double('GitPushHttp') }

  let(:params) do
    {
      gl_repository: gl_repository,
      identifier: identifier,
      changes: []
    }
  end

  subject do
    service = described_class.new(user, repository, project, params)
    service.execute.messages.as_json
  end

  describe 'Geo' do
    before do
      stub_current_geo_node(primary_node)

      allow(Gitlab::Geo::GitPushHttp).to receive(:new).with(identifier, gl_repository).and_return(git_push_http)
      allow(git_push_http).to receive(:fetch_referrer_node).and_return(node)
    end

    context 'when the push was redirected from a Geo secondary to the primary' do
      let(:node) { secondary_node }

      context 'when the secondary has a GeoNodeStatus' do
        let!(:status) { create(:geo_node_status, geo_node: secondary_node, db_replication_lag_seconds: db_replication_lag_seconds) }

        context 'when the GeoNodeStatus db_replication_lag_seconds is greater than 0' do
          let(:db_replication_lag_seconds) { 17 }

          it 'includes current Geo secondary lag in the output' do
            expect(subject).to include({
              'type' => 'basic',
              'message' => "Current replication lag: 17 seconds"
            })
          end
        end

        context 'when the GeoNodeStatus db_replication_lag_seconds is 0' do
          let(:db_replication_lag_seconds) { 0 }

          it 'does not include current Geo secondary lag in the output' do
            expect(subject).not_to include({ 'message' => a_string_matching('replication lag'), 'type' => anything })
          end
        end

        context 'when the GeoNodeStatus db_replication_lag_seconds is nil' do
          let(:db_replication_lag_seconds) { nil }

          it 'does not include current Geo secondary lag in the output' do
            expect(subject).not_to include({ 'message' => a_string_matching('replication lag'), 'type' => anything })
          end
        end
      end

      context 'when the secondary does not have a GeoNodeStatus' do
        it 'does not include current Geo secondary lag in the output' do
          expect(subject).not_to include({ 'message' => a_string_matching('replication lag'), 'type' => anything })
        end
      end

      it 'includes a message advising a redirection occurred' do
        redirect_message = <<~STR
        This request to a Geo secondary node will be forwarded to the
        Geo primary node:

          http://primary.example.com/#{project.full_path}.git
        STR

        expect(subject).to include({
          'type' => 'basic',
          'message' => redirect_message
        })
      end
    end

    context 'when the push was not redirected from a Geo secondary to the primary' do
      let(:node) { nil }

      it 'does not include current Geo secondary lag in the output' do
        expect(subject).not_to include({ 'message' => a_string_matching('replication lag'), 'type' => anything })
      end
    end
  end

  describe 'storage size limit alerts' do
    using RSpec::Parameterized::TableSyntax

    let(:storage_notification_payload) { {} }
    let(:alert_level) { :none }

    where(additional_repo_storage_by_namespace_enabled: [false, true])

    with_them do
      before do
        stub_ee_application_setting(should_check_namespace_plan: true)
        stub_ee_application_setting(enforce_namespace_storage_limit: true)
        stub_ee_application_setting(automatic_purchased_storage_allocation: true)
        allow(project.namespace).to receive(:additional_repo_storage_by_namespace_enabled?)
          .and_return(additional_repo_storage_by_namespace_enabled)

        allow(user).to receive(:can?).with(:maintainer_access, project.namespace.root_ancestor).and_return(true)
        allow_next_instance_of(EE::Namespace::Storage::Notification, project.namespace, user) do |notification|
          allow(notification).to receive(:payload).and_return(storage_notification_payload)
          allow(notification).to receive(:alert_level).and_return(alert_level)
        end
      end

      context 'when there is no payload' do
        it 'adds no alert' do
          expect(subject).to be_empty
        end
      end

      context 'when there is payload' do
        context 'for namespace enforcement' do
          let(:alert_level) { :info }

          let(:storage_notification_payload) do
            {
              enforcement_type: :namespace,
              alert_level: alert_level,
              usage_message: "Usage",
              explanation_message: {
                main: {
                  text: "Explanation",
                  link: {
                    text: "Learn more.",
                    href: "/usage_quotas"
                  }
                },
                footer: {
                  text: "Footer",
                  link: {
                    text: "Learn even more.",
                    href: "/usage_quotas#more"
                  }
                }
              },
              root_namespace: project.namespace.root_ancestor
            }
          end

          it 'adds an alert' do
            response = subject

            expect(response).to be_present
            expect(response).to include({
              'type' => 'alert',
              'message' => "##### INFO #####\nUsage\nExplanation\nFooter"
            })
          end
        end

        context 'for repository enforcement' do
          let(:alert_level) { :error }

          let(:storage_notification_payload) do
            {
              enforcement_type: :repository,
              alert_level: alert_level,
              usage_message: "Usage",
              explanation_message: {
                main: {
                  text: "Explanation",
                  link: {
                    text: "Learn more.",
                    href: "/usage_quotas"
                  }
                }
              },
              root_namespace: project.namespace.root_ancestor
            }
          end

          it 'adds an alert' do
            response = subject

            expect(response).to be_present
            expect(response).to include({
              'type' => 'alert',
              'message' => "##### ERROR #####\nUsage\nExplanation"
            })
          end
        end
      end
    end
  end
end
