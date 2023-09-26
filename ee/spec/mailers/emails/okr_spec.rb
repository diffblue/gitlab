# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Emails::Okr, feature_category: :team_planning do
  include EmailSpec::Matchers

  let_it_be(:project_member) { create(:project_member, :maintainer) } # rubocop:disable RSpec/FactoryBot/AvoidCreate
  let_it_be(:project) { project_member.project }
  let_it_be(:user) { project_member.user }
  let_it_be(:kr) { create(:work_item, :key_result, project: project) } # rubocop:disable RSpec/FactoryBot/AvoidCreate

  let_it_be(:email_subject) { "#{project.name} | #{kr.title} (##{kr.iid})" }

  subject(:email) { Notify.okr_checkin_reminder_notification(user: user, work_item: kr, project: project) }

  describe '#okr_checkin_reminder_notification' do
    context 'when user exists' do
      it 'sends mail with expected contents' do
        kr.assignees = [user]

        expect(email).to have_subject(email_subject)
        expect(email).to have_body_text("requires an update")
        expect(email).to have_body_text(kr.assignees.pluck(:name).to_sentence)
        expect(email).to have_body_text("An update is due on:")
        expect(email).to be_delivered_to([user.notification_email_or_default])
      end
    end

    context 'when user exists but is not assigned to the key result' do
      it 'the email is not set' do
        kr.assignees = []
        expect(email).not_to have_subject(email_subject)
        expect(email).not_to be_delivered_to([user.notification_email_or_default])
      end
    end
  end
end
