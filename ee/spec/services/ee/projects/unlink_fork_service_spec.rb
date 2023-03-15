# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::UnlinkForkService, :use_clean_rails_memory_store_caching, feature_category: :projects do
  include ProjectForksHelper

  subject(:unlink_fork) { described_class.new(forked_project, user).execute }

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user) }

  context 'when forked project is unlinked from parent' do
    let!(:forked_project) { fork_project(project, user) }

    it 'creates an audit event', :aggregate_failures do
      expect(::Gitlab::Audit::Auditor)
            .to receive(:audit).with(
              hash_including({ name: "project_fork_relationship_removed" })).and_call_original

      expect { unlink_fork }.to change(AuditEvent, :count).by(1)

      expect(AuditEvent.last).to have_attributes({
                                                   author: user,
                                                   entity_id: forked_project.id,
                                                   target_type: project.class.name,
                                                   details: {
                                                     author_class: user.class.name,
                                                     author_name: user.name,
                                                     custom_message: "Project unlinked from #{project.name}",
                                                     target_details: forked_project.name,
                                                     target_id: forked_project.id,
                                                     target_type: forked_project.class.name
                                                   }
                                                 })
    end

    context 'when forked project does not exist' do
      before do
        project.destroy!
      end

      it 'creates an audit event', :aggregate_failures do
        expect(::Gitlab::Audit::Auditor)
          .to receive(:audit).with(
            hash_including({ name: "project_fork_relationship_removed" })).and_call_original

        expect { unlink_fork }.to change(AuditEvent, :count).by(1)

        expect(AuditEvent.last).to have_attributes({
                                                     author: user,
                                                     entity_id: forked_project.id,
                                                     target_type: project.class.name,
                                                     details: {
                                                       author_class: user.class.name,
                                                       author_name: user.name,
                                                       custom_message: "Project unlinked from ",
                                                       target_details: forked_project.name,
                                                       target_id: forked_project.id,
                                                       target_type: forked_project.class.name
                                                     }
                                                   })
      end
    end
  end

  context 'when no unlinking is performed' do
    let(:forked_project) { project }

    it 'does not create an audit event' do
      expect { subject }.not_to change(AuditEvent, :count)
    end
  end
end
