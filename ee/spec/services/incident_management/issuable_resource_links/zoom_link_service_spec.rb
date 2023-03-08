# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::IssuableResourceLinks::ZoomLinkService, feature_category: :incident_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:issue) { create(:incident) }

  let(:project) { issue.project }
  let(:service) { described_class.new(project: project, current_user: user, incident: issue) }
  let(:zoom_link) { 'https://zoom.us/j/123456789' }
  let(:link_text) { 'Demo meeting' }

  before do
    stub_licensed_features(issuable_resource_links: true)
    project.add_reporter(user)
  end

  shared_context 'when insufficient issue create/update permissions' do
    before do
      project.add_guest(user)
    end
  end

  describe '#add_link' do
    shared_examples 'can add meeting' do
      it 'appends the new meeting to zoom_meetings' do
        expect(result).to be_success
      end

      it 'tracks the add event', :snowplow do
        result

        expect_snowplow_event(
          category: 'IncidentManagement::ZoomIntegration',
          action: 'add_zoom_meeting',
          label: 'Issue ID',
          value: issue.id,
          user: user,
          project: project,
          namespace: project.namespace
        )
      end
    end

    shared_examples 'cannot add meeting' do
      it 'cannot add the meeting' do
        expect(result).to be_error
        expect(result.message).to eq('Failed to add a Zoom meeting')
      end
    end

    subject(:result) { service.add_link(zoom_link, link_text) }

    context 'when issue is incident type' do
      let(:current_user) { user }

      include_examples 'can add meeting'
      it_behaves_like 'an incident management tracked event', :incident_management_issuable_resource_link_created
    end

    context 'with insufficient issue update permissions' do
      include_context 'when insufficient issue create/update permissions'
      include_examples 'cannot add meeting'
    end

    context 'when link text has multiple commas' do
      let(:link_text) { 'Demo meeeting, On fire, need to check' }

      include_examples 'can add meeting'
    end

    context 'when service fails to create' do
      before do
        allow_next_instance_of(IncidentManagement::IssuableResourceLink) do |model|
          allow(model).to receive(:save).and_return(false)
        end
      end

      include_examples 'cannot add meeting'
    end

    context 'with invalid Zoom url' do
      let(:zoom_link) { 'https://not-zoom.link' }

      include_examples 'cannot add meeting'
    end

    context 'with issue type issue' do
      let(:issue) { create(:issue) }

      include_examples 'cannot add meeting'
    end
  end

  describe '#can_add_link?' do
    subject { service.can_add_link? }

    it { is_expected.to eq(true) }

    context 'with insufficient issue update permissions' do
      include_context 'when insufficient issue create/update permissions'

      it { is_expected.to eq(false) }
    end
  end

  describe '#parse_link' do
    subject { service.parse_link(link_params) }

    context 'with valid Zoom links' do
      where(:link_params, :link, :link_text) do
        [
          ['https://zoom.us/j/123456789 Demo meeting', 'https://zoom.us/j/123456789', 'Demo meeting'],
          ['https://zoom.us/j/123456789 http://example.com Space fire, fire again', 'https://zoom.us/j/123456789',
           'http://example.com Space fire, fire again'],
          ['https://zoom.us/my/name https://zoom.us/j/123456789 Fire, fire on!, extinguishe now!',
           'https://zoom.us/my/name', 'https://zoom.us/j/123456789 Fire, fire on!, extinguishe now!'],
          ['https://zoom.us/my/name https://zoom.us/j/123456789', 'https://zoom.us/my/name', 'https://zoom.us/j/123456789']
        ]
      end

      with_them do
        it { is_expected.to eq([link, link_text]) }
      end
    end

    context 'with invalid Zoom links' do
      where(:link_params) do
        [
          nil,
          '',
          'Text only',
          'Non-Zoom http://example.com',
          'Almost Zoom http://zoom.us'
        ]
      end

      with_them do
        it { is_expected.to eq(nil) }
      end
    end
  end
end
