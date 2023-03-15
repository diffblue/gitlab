# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StatusPage::PublishDetailsService, feature_category: :incident_management do
  include ::StatusPage::PublicationServiceResponses

  let_it_be(:project, refind: true) { create(:project) }

  let(:user_notes) { [] }
  let(:incident_id) { 1 }
  let(:issue) { instance_double(Issue, notes: user_notes, description: 'Incident Occuring', iid: incident_id) }
  let(:key) { Gitlab::StatusPage::Storage.details_path(incident_id) }
  let(:content) { { id: incident_id } }

  let(:service) { described_class.new(project: project) }

  subject(:result) { service.execute(issue, user_notes) }

  describe '#execute' do
    before do
      allow(serializer).to receive(:represent_details).with(issue, user_notes)
        .and_return(content)
    end

    include_examples 'publish incidents'

    context 'when serialized content is missing id' do
      let(:content) { { other_id: incident_id } }

      it 'returns an error' do
        expect(result).to be_error
        expect(result.message).to eq('Missing object key')
      end
    end

    context 'publishing attachments' do
      before do
        allow(storage_client).to receive(:upload_object).and_return(success)
        allow(storage_client).to receive(:list_object_keys).and_return([])
      end

      context 'when successful' do
        let(:success_response) { double(error?: false, success?: true) }

        it 'sends attachments to storage and returns success' do
          expect_next_instance_of(StatusPage::PublishAttachmentsService) do |service|
            expect(service).to receive(:execute).and_return(success_response)
          end

          expect(subject.success?).to be true
        end
      end

      context 'when error returned from PublishAttachmentsService' do
        let(:error_response) { double(error?: true, success?: false) }

        it 'returns an error' do
          expect_next_instance_of(StatusPage::PublishAttachmentsService) do |service|
            expect(service).to receive(:execute).and_return(error_response)
          end

          expect(subject.success?).to be false
        end
      end
    end
  end
end
