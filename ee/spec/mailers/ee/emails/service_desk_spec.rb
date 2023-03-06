# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe Emails::ServiceDesk, feature_category: :team_planning do
  include EmailSpec::Matchers

  include_context 'with service desk mailer'

  let_it_be(:project_namespace) { build_stubbed(:project_namespace) }
  let_it_be(:project) { build_stubbed(:project, project_namespace: project_namespace) }
  let_it_be(:issue) { build_stubbed(:issue, project: project) }
  let_it_be(:email) { 'someone@gitlab.com' }
  let_it_be(:custom_text) { 'this is some additional custom text' }

  let(:template) { instance_double(Gitlab::Template::BaseTemplate, content: template_content) }

  before do
    allow(Issue).to receive(:find).with(issue.id).and_return(issue)
  end

  shared_examples 'custom template content' do |template_key|
    before do
      allow(Gitlab::Template::ServiceDeskTemplate).to receive(:find)
        .with(template_key, issue.project)
        .and_return(template)
    end

    it 'builds the email correctly' do
      is_expected.to have_body_text(expected_body)
    end
  end

  describe '.service_desk_thank_you_email' do
    let(:template_content) { 'thank you, your new issue has been created. %{ADDITIONAL_TEXT}' }

    subject { ServiceEmailClass.service_desk_thank_you_email(issue.id) }

    context 'when additional email text is enabled' do
      before do
        stub_licensed_features(email_additional_text: true)
        stub_ee_application_setting(email_additional_text: custom_text)
      end

      context 'with an additional text placeholder' do
        let(:expected_body) { "thank you, your new issue has been created. #{custom_text}" }

        it_behaves_like 'custom template content', 'thank_you'
      end
    end

    context 'when additional email text is disabled' do
      before do
        stub_licensed_features(email_additional_text: false)
      end

      context 'with an additional text placeholder' do
        let(:expected_body) { "thank you, your new issue has been created." }

        it_behaves_like 'custom template content', 'thank_you'
      end
    end
  end

  describe '.service_desk_new_note_email' do
    let_it_be(:note) { build_stubbed(:note_on_issue, noteable: issue, project: project) }
    let(:template_content) { 'thank you, new note on issue has been created. %{ADDITIONAL_TEXT}' }

    subject { ServiceEmailClass.service_desk_new_note_email(issue.id, note.id, email) }

    before do
      allow(Note).to receive(:find).with(note.id).and_return(note)
    end

    context 'when additional email text is enabled' do
      before do
        stub_licensed_features(email_additional_text: true)
        stub_ee_application_setting(email_additional_text: custom_text)
      end

      context 'with an additional text placeholders' do
        let(:expected_body) { "thank you, new note on issue has been created. #{custom_text}" }

        it_behaves_like 'custom template content', 'new_note'
      end
    end

    context 'when additional email text is disabled' do
      before do
        stub_licensed_features(email_additional_text: false)
      end

      context 'with an additional text placeholder' do
        let(:expected_body) { "thank you, new note on issue has been created." }

        it_behaves_like 'custom template content', 'new_note'
      end
    end
  end
end
