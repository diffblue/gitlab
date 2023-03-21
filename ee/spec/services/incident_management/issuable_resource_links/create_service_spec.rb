# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::IssuableResourceLinks::CreateService, feature_category: :incident_management do
  let_it_be(:user_with_permissions) { create(:user) }
  let_it_be(:user_without_permissions) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:error_message) { 'You have insufficient permissions to manage resource links for this incident' }
  let_it_be_with_refind(:incident) { create(:incident, project: project) }

  let(:current_user) { user_with_permissions }
  let(:link) { 'https://gitlab.zoom.us/j/12345?pwd=1234555' }
  let(:link_type) { :zoom }
  let(:link_text) { 'Incident zoom link' }
  let(:args) { { link: link, link_type: link_type, link_text: link_text } }
  let(:service) { described_class.new(incident, current_user, args) }

  before do
    stub_licensed_features(issuable_resource_links: true)
  end

  before_all do
    project.add_reporter(user_with_permissions)
    project.add_guest(user_without_permissions)
  end

  describe '#execute' do
    shared_examples 'error_message' do |message|
      it 'has an informative message' do
        error_message_string = message.nil? ? error_message : message

        expect(execute).to be_error
        expect(execute.message).to eq(error_message_string)
        expect(SystemNoteService).not_to receive(:issuable_resource_link_added)
      end

      it_behaves_like 'does not track incident management event', :incident_management_issuable_resource_link_created
    end

    shared_examples 'success_response' do
      it 'has issuable resource link' do
        expect(execute).to be_success

        result = execute.payload[:issuable_resource_link]
        expect(result).to be_a(::IncidentManagement::IssuableResourceLink)
        expect(result.link).to eq(link)
        expect(result.issue).to eq(incident)
        expect(result.link_text).to eq(link_text)
        expect(result.link_type).to eq(link_type.to_s)
      end

      it 'creates a system note notification' do
        expect(SystemNoteService).to receive(:issuable_resource_link_added).with(incident, project, current_user,
          link_type.to_s)
        expect(SystemNoteService).not_to receive(:issuable_resource_link_removed)

        execute
      end

      it_behaves_like 'an incident management tracked event', :incident_management_issuable_resource_link_created
    end

    subject(:execute) { service.execute }

    context 'when current user is blank' do
      let(:current_user) { nil }

      it_behaves_like 'error_message'
    end

    context 'when user does not have permissions to create issuable resource links' do
      let(:current_user) { user_without_permissions }

      it_behaves_like 'error_message'
    end

    context 'when feature is not available' do
      before do
        stub_licensed_features(issuable_resource_links: false)
      end

      it_behaves_like 'error_message'
    end

    context 'when error occurs during creation' do
      let(:args) { {} }

      it_behaves_like 'error_message', "Link can't be blank and Link must be a valid URL"
    end

    context 'when a valid request' do
      it_behaves_like 'success_response'
    end

    context 'when link text is absent' do
      where(:link_text) { [nil, '', ' '] }

      with_them do
        it 'stores id as link text' do
          result = execute.payload[:issuable_resource_link]

          expect(execute).to be_success
          expect(result.link_text).to eq('Zoom #12345')
        end
      end
    end

    context 'when link type is general' do
      let(:link_type) { :general }
      let(:link) { 'https://gitlab.com/project/issue/1' }
      let(:link_text) { '' }

      it 'stores link as link text for general type' do
        result = execute.payload[:issuable_resource_link]

        expect(execute).to be_success
        expect(result.link_text).to eq(link)
      end
    end

    context 'when link type is absent' do
      shared_examples 'link_types' do |link_type|
        it 'sets correct link type based on link' do
          result = execute.payload[:issuable_resource_link]

          expect(execute).to be_success
          expect(result.link_type).to eq(link_type)
        end
      end

      context 'for slack' do
        let(:args) { { link: 'https://gitlab.slack.com/messages/IDHERE' } }

        it_behaves_like 'link_types', 'slack'
      end

      context 'for zoom' do
        let(:args) { { link: 'https://gitlab.zoom.us/j/IDHERE' } }

        it_behaves_like 'link_types', 'zoom'
      end

      context 'for pagerduty' do
        let(:args) { { link: 'https://gitlab.pagerduty.com/incidents/IDHERE' } }

        it_behaves_like 'link_types', 'pagerduty'
      end
    end

    it 'successfully creates a database record', :aggregate_failures do
      expect { execute }.to change { ::IncidentManagement::IssuableResourceLink.count }.by(1)
    end
  end
end
