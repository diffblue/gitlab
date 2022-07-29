# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Fuzzing::Coverage::Corpuses::CreateService do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_projects: [project] ) }
  let_it_be(:package) { create(:generic_package, :with_zip_file, project: project, creator: developer) }

  let_it_be(:default_params) do
    {
      package_id: package.id
    }
  end

  let(:params) { default_params }

  subject(:service_result) { described_class.new(project: project, current_user: developer, params: params).execute }

  describe 'execute' do
    before do
      stub_licensed_features(coverage_fuzzing: coverage_fuzzing_enabled?)
    end

    context 'when the feature coverage_fuzzing is not available' do
      let(:coverage_fuzzing_enabled?) { false }

      it 'communicates failure', :aggregate_failures do
        expect(service_result.status).to eq(:error)
        expect(service_result.message).to eq('Insufficient permissions')
      end
    end

    context 'when the feature coverage_fuzzing is enabled' do
      let(:coverage_fuzzing_enabled?) { true }

      it 'communicates success' do
        expect(service_result.status).to eq(:success)
      end

      it 'creates a corpus' do
        expect { service_result }.to change { AppSec::Fuzzing::Coverage::Corpus.count }.by(1)
      end

      it 'audits the creation', :aggregate_failures do
        corpus = service_result.payload[:corpus]

        audit_event = AuditEvent.find_by(target_id: corpus.id)

        expect(audit_event.author).to eq(developer)
        expect(audit_event.entity).to eq(project)
        expect(audit_event.target_id).to eq(corpus.id)
        expect(audit_event.target_type).to eq('AppSec::Fuzzing::Coverage::Corpus')
        expect(audit_event.target_details).to eq(developer.name)
        expect(audit_event.details).to eq({
          author_name: developer.name,
          author_class: developer.class.name,
          custom_message: 'Added Coverage Fuzzing Corpus',
          target_id: corpus.id,
          target_type: 'AppSec::Fuzzing::Coverage::Corpus',
          target_details: developer.name
        })
      end

      context 'when a param is missing' do
        let(:params) { default_params.except(:package_id) }

        it 'communicates failure', :aggregate_failures do
          expect(service_result.status).to eq(:error)
          expect(service_result.message).to eq('Key not found: :package_id')
        end
      end

      context 'when a param is incorrect' do
        let(:package_2) { create(:package) }
        let(:params) { { package_id: package_2.id } }

        it 'communicates failure', :aggregate_failures do
          allow_next_instance_of(AppSec::Fuzzing::Coverage::Corpus) do |service|
            allow(service).to receive(:save).and_return(false)
            allow(service).to receive_message_chain(:errors, :full_messages)
            .and_return(['error message'])
          end

          expect(service_result.status).to eq(:error)
          expect(service_result.message).to match_array(['error message'])
        end
      end
    end
  end
end
