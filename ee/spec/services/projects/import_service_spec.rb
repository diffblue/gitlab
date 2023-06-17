# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportService, feature_category: :importers do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.creator }

  subject { described_class.new(project, user) }

  before do
    allow(project).to receive(:lfs_enabled?).and_return(true)
    project.import_url = Project::UNKNOWN_IMPORT_URL
  end

  context 'when imported in to a group' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }

    context 'when audit_events is licensed' do
      before do
        stub_licensed_features(audit_events: true)
      end

      it 'does audit' do
        expect(::Gitlab::Audit::Auditor).to receive(:audit).with(
          hash_including(name: 'project_imported')
        ).and_call_original

        expect { subject.execute }.to change { AuditEvent.count }.by(1)
      end
    end

    context 'when audit_events is unlicensed' do
      before do
        allow(group).to receive(:feature_available?).and_return(false)
        stub_licensed_features(audit_events: false)
      end

      it 'does not audit' do
        expect { subject.execute }.not_to change { AuditEvent.count }
      end
    end
  end

  context 'when not imported in to a group' do
    let_it_be(:project) { create(:project) }

    context 'when audit_events is licensed' do
      before do
        stub_licensed_features(audit_events: true)
      end

      it 'does not audit' do
        expect { subject.execute }.not_to change { AuditEvent.count }
      end
    end

    context 'when audit_events is unlicensed' do
      before do
        stub_licensed_features(audit_events: false)
      end

      it 'does not audit' do
        expect { subject.execute }.not_to change { AuditEvent.count }
      end
    end
  end

  it 'validates repository size' do
    expect_next_instance_of(::Import::ValidateRepositorySizeService, project) do |service|
      expect(service).to receive(:execute)
    end

    subject.execute
  end
end
