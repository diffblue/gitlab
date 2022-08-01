# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::RegisterRunnerAuditEventService do
  let_it_be(:user) { create(:user) }

  let(:author) { 'b6bce79c3a' }
  let(:service) { described_class.new(runner, author, entity) }
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
        ip_address: nil
      }
    }
  end

  shared_examples 'expected audit event' do
    it 'returns audit event attributes' do
      travel_to(timestamp) do
        expect(subject.attributes).to eq(attrs.stringify_keys)
      end
    end
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

      let(:entity) {}
      let(:extra_attrs) { {} }
      let(:target_details) {}
      let(:attrs) do
        common_attrs.deep_merge(
          author_name: nil,
          entity_id: -1,
          entity_type: 'User',
          entity_path: nil,
          target_details: target_details,
          details: {
            runner_registration_token: author[0...described_class::SAFE_TOKEN_LENGTH],
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
        let_it_be(:runner) { create(:ci_runner) }

        let(:target_details) { ::Gitlab::Routing.url_helpers.admin_runner_path(runner) }
        let(:extra_attrs) do
          { details: { custom_message: 'Registered instance CI runner' } }
        end

        it_behaves_like 'expected audit event'

        context 'with registration token prefixed with RUNNERS_TOKEN_PREFIX' do
          let(:author) { "#{::RunnersTokenPrefixable::RUNNERS_TOKEN_PREFIX}b6bce79c3a" }
          let(:extra_attrs) do
            {
              details: {
                custom_message: 'Registered instance CI runner',
                runner_registration_token: author[0...::RunnersTokenPrefixable::RUNNERS_TOKEN_PREFIX.length + described_class::SAFE_TOKEN_LENGTH]
              }
            }
          end

          it_behaves_like 'expected audit event'
        end
      end
    end

    context 'for group runner' do
      let_it_be(:entity) { create(:group) }

      let(:extra_attrs) { {} }
      let(:target_details) {}
      let(:attrs) do
        common_attrs.deep_merge(
          author_name: author[0...described_class::SAFE_TOKEN_LENGTH],
          entity_id: entity.id,
          entity_type: entity.class.name,
          entity_path: entity.full_path,
          target_details: target_details,
          details: {
            author_name: author[0...described_class::SAFE_TOKEN_LENGTH],
            runner_registration_token: author[0...described_class::SAFE_TOKEN_LENGTH],
            custom_message: 'Registered group CI runner',
            entity_id: entity.id,
            entity_type: entity.class.name,
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

        it_behaves_like 'expected audit event'
      end

      context 'for project runner' do
        let_it_be(:entity) { create(:project) }

        let(:extra_attrs) { {} }
        let(:target_details) {}
        let(:attrs) do
          common_attrs.deep_merge(
            author_name: author[0...described_class::SAFE_TOKEN_LENGTH],
            entity_id: entity.id,
            entity_type: entity.class.name,
            entity_path: entity.full_path,
            target_details: target_details,
            details: {
              author_name: author[0...described_class::SAFE_TOKEN_LENGTH],
              runner_registration_token: author[0...described_class::SAFE_TOKEN_LENGTH],
              entity_id: entity.id,
              entity_type: entity.class.name,
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

          it_behaves_like 'expected audit event'
        end
      end
    end
  end
end
