# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Dast::ScannerProfiles::CreateService, :dynamic_analysis,
                                                             feature_category: :dynamic_application_security_testing do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, creator: user) }
  let(:name) { FFaker::Company.catch_phrase }
  let(:target_timeout) { 60 }
  let(:spider_timeout) { 600 }
  let(:scan_type) { 1 }
  let(:use_ajax_spider) { true }
  let(:show_debug_messages) { true }
  let(:tags) { [ActsAsTaggableOn::Tag.create!(name: 'ruby'), ActsAsTaggableOn::Tag.create!(name: 'postgres')] }
  let(:tag_list) { tags.map(&:name) }
  let(:params) do
    {
      name: name,
      target_timeout: target_timeout,
      spider_timeout: spider_timeout,
      scan_type: scan_type,
      use_ajax_spider: use_ajax_spider,
      show_debug_messages: show_debug_messages,
      tag_list: tag_list
    }
  end

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  describe '#execute' do
    subject { described_class.new(project: project, current_user: user, params: params).execute }

    let(:status) { subject.status }
    let(:message) { subject.message }
    let(:errors) { subject.errors }
    let(:payload) { subject.payload }

    context 'when a user does not have access to a project' do
      let(:project) { create(:project) }

      it 'returns an error status' do
        expect(status).to eq(:error)
      end

      it 'populates message' do
        expect(message).to eq('Insufficient permissions')
      end
    end

    context 'when the user does not have permission to run a dast scan' do
      before do
        project.add_guest(user)
      end

      it 'returns an error status' do
        expect(status).to eq(:error)
      end

      it 'populates message' do
        expect(message).to eq('Insufficient permissions')
      end
    end

    context 'when the user can run a dast scan' do
      before do
        project.add_developer(user)
      end

      it 'returns a success status' do
        expect(status).to eq(:success)
      end

      it 'creates a dast_scanner_profile' do
        expect { subject }.to change(DastScannerProfile, :count).by(1)
      end

      it 'creates a dast_scanner_profile with the given params' do
        aggregate_failures do
          expect(payload).to be_persisted
          expect(payload.spider_timeout).to eq(spider_timeout)
          expect(payload.target_timeout).to eq(target_timeout)
          expect(payload.name).to eq(name)
          expect(DastScannerProfile.scan_types[payload.scan_type]).to eq(scan_type)
          expect(payload.use_ajax_spider).to eq(use_ajax_spider)
          expect(payload.show_debug_messages).to eq(show_debug_messages)
          expect(payload.tags).to match_array(tags)
        end
      end

      it 'returns a dast_scanner_profile payload' do
        expect(payload).to be_a(DastScannerProfile)
      end

      it 'audits the creation' do
        profile = payload

        audit_event = AuditEvent.last

        aggregate_failures do
          expect(audit_event.author).to eq(user)
          expect(audit_event.entity).to eq(project)
          expect(audit_event.target_id).to eq(profile.id)
          expect(audit_event.target_type).to eq('DastScannerProfile')
          expect(audit_event.target_details).to eq(profile.name)
          expect(audit_event.details).to eq({
            author_name: user.name,
            author_class: user.class.name,
            custom_message: 'Added DAST scanner profile',
            target_id: profile.id,
            target_type: 'DastScannerProfile',
            target_details: profile.name
          })
        end
      end

      context 'when the dast_scanner_profile name exists' do
        before do
          create(:dast_scanner_profile, project: project, name: name)
        end

        it 'does not create a new dast_scanner_profile' do
          expect { subject }.not_to change(DastScannerProfile, :count)
        end

        it 'returns an error status' do
          expect(status).to eq(:error)
        end

        it 'populates message' do
          expect(message).to eq(['Name has already been taken'])
        end
      end

      context 'when on demand scan licensed feature is not available' do
        before do
          stub_licensed_features(security_on_demand_scans: false)
        end

        it 'returns an error status' do
          expect(status).to eq(:error)
        end

        it 'populates message' do
          expect(message).to eq('Insufficient permissions')
        end
      end

      context 'when there is a invalid tag' do
        let(:tag_list) { %w[invalid_tag] }

        it 'does not create a new dast_scanner_profile' do
          expect { subject }.not_to change(DastScannerProfile, :count)
        end

        it 'returns an error status' do
          expect(status).to eq(:error)
        end

        it 'populates message' do
          expect(message).to eq('Invalid tag_list')
        end
      end

      context 'when feature flag on_demand_scans_runner_tags is disabled' do
        before do
          stub_feature_flags(on_demand_scans_runner_tags: false)
        end

        it 'returns a success status' do
          expect(status).to eq(:success)
        end

        it 'creates a dast_scanner_profile ignoring the tags' do
          expect(payload.tags).to be_empty
        end
      end
    end
  end
end
