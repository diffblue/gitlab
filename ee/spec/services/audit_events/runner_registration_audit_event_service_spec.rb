# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::RunnerRegistrationAuditEventService do
  let(:registration_token) { 'b6bce79c3a' }
  let(:service) { described_class.new(runner, registration_token, entity, action) }
  let(:common_attrs) do
    {
      author_id: -1,
      created_at: timestamp,
      id: subject.id,
      target_type: runner.class.name,
      target_id: runner.id,
      ip_address: nil,
      details: {
        target_type: runner.class.name,
        target_id: runner.id,
        runner_registration_token: registration_token[0...8],
        ip_address: nil
      }
    }
  end

  describe '#track_event' do
    before do
      stub_licensed_features(admin_audit_log: true)
    end

    subject { service.track_event }

    let(:timestamp) { Time.zone.local(2021, 12, 28) }

    context 'for instance runner' do
      before do
        stub_licensed_features(extended_audit_events: true, admin_audit_log: true)
      end

      let(:entity) { }

      context 'with action as :register' do
        let(:action) { :register }
        let(:extra_attrs) { {} }
        let(:target_details) { }
        let(:attrs) do
          common_attrs.deep_merge(
            author_name: nil,
            entity_id: -1,
            entity_type: 'User',
            entity_path: nil,
            target_details: target_details,
            details: {
              custom_message: 'Registered instance CI runner',
              entity_path: nil,
              target_details: target_details
            }
          ).deep_merge(extra_attrs)
        end

        context 'on runner that failed to create' do
          let(:runner) { build(:ci_runner) }
          let(:extra_attrs) do
            {
              details: {
                custom_message: 'Failed to register instance CI runner',
                errors: ['Runner some error']
              }
            }
          end

          before do
            allow(runner).to receive(:valid?) do
              runner.errors.add :runner, 'some error'
              false
            end
          end

          it 'returns audit event attributes of a failed runner registration', :aggregate_failures do
            travel_to(timestamp) do
              expect(subject.attributes).to eq(attrs.stringify_keys)
              expect(runner.persisted?).to be_falsey
            end
          end
        end

        context 'on persisted runner' do
          let(:runner) { create(:ci_runner) }
          let(:target_details) { ::Gitlab::Routing.url_helpers.admin_runner_path(runner) }
          let(:extra_attrs) do
            { details: { custom_message: 'Registered instance CI runner' } }
          end

          it 'returns audit event attributes' do
            travel_to(timestamp) do
              expect(subject.attributes).to eq(attrs.stringify_keys)
            end
          end
        end
      end

      context 'with unknown action' do
        let(:runner) { create(:ci_runner) }
        let(:action) { :unknown }

        it 'is not logged' do
          is_expected.to be_nil
        end
      end
    end

    context 'for group runner' do
      let(:entity) { create(:group) }

      context 'with action as :register' do
        let(:action) { :register }
        let(:extra_attrs) { {} }
        let(:target_details) { }
        let(:attrs) do
          common_attrs.deep_merge(
            author_name: registration_token[0...8],
            entity_id: entity.id,
            entity_type: entity.class.name,
            entity_path: entity.full_path,
            target_details: target_details,
            details: {
              author_name: registration_token[0...8],
              custom_message: 'Registered group CI runner',
              entity_path: entity.full_path,
              target_details: target_details
            }
          ).deep_merge(extra_attrs)
        end

        context 'on runner that failed to create' do
          let(:runner) { build(:ci_runner, :group, groups: [entity]) }
          let(:extra_attrs) do
            {
              details: {
                custom_message: 'Failed to register group CI runner',
                errors: ['Runner some error']
              }
            }
          end

          before do
            allow(runner).to receive(:valid?) do
              runner.errors.add :runner, 'some error'
              false
            end
          end

          it 'returns audit event attributes of a failed runner registration', :aggregate_failures do
            travel_to(timestamp) do
              expect(subject.attributes).to eq(attrs.stringify_keys)
              expect(runner.persisted?).to be_falsey
            end
          end
        end

        context 'on persisted runner' do
          let(:runner) { create(:ci_runner, :group, groups: [entity]) }
          let(:target_details) { ::Gitlab::Routing.url_helpers.group_runner_path(entity, runner) }
          let(:extra_attrs) do
            { details: { custom_message: 'Registered group CI runner' } }
          end

          it 'returns audit event attributes' do
            travel_to(timestamp) do
              expect(subject.attributes).to eq(attrs.stringify_keys)
            end
          end
        end
      end

      context 'with unknown action' do
        let(:runner) { create(:ci_runner, :group, groups: [entity]) }
        let(:action) { :unknown }

        it 'is not logged' do
          is_expected.to be_nil
        end
      end
    end

    context 'for project runner' do
      let(:entity) { create(:project) }

      context 'with action as :register' do
        let(:action) { :register }
        let(:extra_attrs) { {} }
        let(:target_details) { }
        let(:attrs) do
          common_attrs.deep_merge(
            author_name: registration_token[0...8],
            entity_id: entity.id,
            entity_type: entity.class.name,
            entity_path: entity.full_path,
            target_details: target_details,
            details: {
              author_name: registration_token[0...8],
              entity_path: entity.full_path,
              target_details: target_details
            }
          ).deep_merge(extra_attrs)
        end

        context 'on runner that failed to create' do
          let(:runner) { build(:ci_runner, :project, projects: [entity]) }
          let(:extra_attrs) do
            {
              details: {
                custom_message: 'Failed to register project CI runner',
                errors: ['Runner some error']
              }
            }
          end

          before do
            allow(runner).to receive(:valid?) do
              runner.errors.add :runner, 'some error'
              false
            end
          end

          it 'returns audit event attributes of a failed runner registration', :aggregate_failures do
            travel_to(timestamp) do
              expect(subject.attributes).to eq(attrs.stringify_keys)
              expect(runner.persisted?).to be_falsey
            end
          end
        end

        context 'on persisted runner' do
          let(:runner) { create(:ci_runner, :project, projects: [entity]) }
          let(:target_details) { ::Gitlab::Routing.url_helpers.project_runner_path(entity, runner) }
          let(:extra_attrs) do
            { details: { custom_message: 'Registered project CI runner' } }
          end

          it 'returns audit event attributes' do
            travel_to(timestamp) do
              expect(subject.attributes).to eq(attrs.stringify_keys)
            end
          end
        end
      end
    end
  end
end
