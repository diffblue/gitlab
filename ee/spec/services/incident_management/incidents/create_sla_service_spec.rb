# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::Incidents::CreateSlaService, feature_category: :incident_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be_with_refind(:incident) { create(:incident, project: project) }

  describe '#execute' do
    subject(:create_issuable_sla_response) { described_class.new(incident, user).execute }

    let(:response_payload_sla) { create_issuable_sla_response.payload[:sla] }
    let(:response_payload_message) { create_issuable_sla_response.message }

    before_all do
      project.add_maintainer(user)
    end

    before do
      stub_licensed_features(incident_sla: true)
    end

    shared_examples 'no issuable sla created' do
      it 'does not create the issuable sla' do
        expect { subject }.not_to change(IssuableSla, :count)
      end

      it 'does not return a sla' do
        expect(response_payload_sla).to eq(nil)
      end
    end

    context 'incident setting not created' do
      it_behaves_like 'no issuable sla created'
    end

    context 'incident setting exists' do
      let(:sla_timer) { true }
      let(:sla_timer_minutes) { 30 }
      let!(:setting) { create(:project_incident_management_setting, project: project, sla_timer: sla_timer, sla_timer_minutes: sla_timer_minutes) }

      context 'project does not have incident_sla feature' do
        before do
          stub_licensed_features(incident_sla: false)
        end

        it_behaves_like 'no issuable sla created'
      end

      context 'sla timer setting is disabled' do
        let(:sla_timer) { false }

        it_behaves_like 'no issuable sla created'
      end

      context 'issuable sla already exists' do
        let!(:issuable_sla) { create(:issuable_sla, issue: incident) }

        it 'returns a success with the sla', :aggregate_failures do
          expect { subject }.not_to change(IssuableSla, :count)

          expect(create_issuable_sla_response.success?).to eq(true)
          expect(response_payload_sla).to be_a(IssuableSla)
        end
      end

      it 'creates the issuable sla with the given offset', :aggregate_failures do
        expect { subject }.to change(IssuableSla, :count)

        offset_time = incident.created_at + setting.sla_timer_minutes.minutes
        expect(response_payload_sla.due_at).to eq(offset_time)
      end

      it 'returns a success with the sla', :aggregate_failures do
        expect(create_issuable_sla_response.success?).to eq(true)
        expect(response_payload_sla).to be_a(IssuableSla)
      end

      context 'errors when saving' do
        before do
          allow_next_instance_of(IssuableSla) do |issuable_sla|
            allow(issuable_sla).to receive(:save).and_return(false)

            errors = ActiveModel::Errors.new(issuable_sla).tap { |e| e.add(:issue_id, 'error message') }
            allow(issuable_sla).to receive(:errors).and_return(errors)
          end
        end

        it 'does not create the issuable sla' do
          expect { subject }.not_to change(IssuableSla, :count)
        end

        it 'returns an error', :aggregate_failures do
          expect(create_issuable_sla_response.error?).to eq(true)
          expect(response_payload_message).to include('Issue error message')
        end
      end
    end
  end
end
