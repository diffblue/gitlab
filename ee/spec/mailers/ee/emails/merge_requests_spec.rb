# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe EE::Emails::MergeRequests do
  include EmailSpec::Matchers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:assignee, reload: true) { create(:user, email: 'assignee@example.com', name: 'John Doe') }
  let_it_be(:reviewer, reload: true) { create(:user, email: 'reviewer@example.com', name: 'Jane Doe') }
  let_it_be(:merge_request) { create(:merge_request, assignees: [assignee], reviewers: [reviewer]) }

  let(:recipient) { assignee }

  describe '#add_merge_request_approver_email' do
    subject { Notify.add_merge_request_approver_email(recipient.id, merge_request.id, current_user.id) }

    context 'when email_author_in_body is set' do
      it 'has the correct body with the name of the person who added the approver' do
        stub_application_setting(email_author_in_body: true)

        aggregate_failures do
          is_expected.to have_body_text(current_user.name)
          is_expected.to have_body_text('added you as an approver')
          is_expected.to have_text_part_content(assignee.name)
          is_expected.to have_html_part_content(assignee.name)
          is_expected.to have_text_part_content(reviewer.name)
          is_expected.to have_html_part_content(reviewer.name)
        end
      end
    end

    context 'when email_author_in_body is not set' do
      it 'has the correct body without the name of the person who added the approver' do
        stub_application_setting(email_author_in_body: false)

        aggregate_failures do
          is_expected.not_to have_body_text(current_user.name)
          is_expected.not_to have_body_text('added you as an approver')
          is_expected.to have_text_part_content(assignee.name)
          is_expected.to have_html_part_content(assignee.name)
          is_expected.to have_text_part_content(reviewer.name)
          is_expected.to have_html_part_content(reviewer.name)
        end
      end
    end
  end
end
