# frozen_string_literal: true

require "spec_helper"

RSpec.describe EE::EmailsHelper do
  describe '#action_title' do
    using RSpec::Parameterized::TableSyntax

    where(:path, :result) do
      'somedomain.com/groups/agroup/-/epics/231'     | 'View Epic'
      'somedomain.com/aproject/issues/231'           | 'View Issue'
      'somedomain.com/aproject/-/merge_requests/231' | 'View Merge request'
      'somedomain.com/aproject/-/commit/al3f231'     | 'View Commit'
    end

    with_them do
      it 'returns the expected title' do
        title = helper.action_title(path)
        expect(title).to eq(result)
      end
    end
  end

  describe '#service_desk_email_additional_text' do
    subject { helper.service_desk_email_additional_text }

    context 'when additional email text is enabled' do
      let(:custom_text) { 'this is some additional custom text' }

      before do
        stub_licensed_features(email_additional_text: true)
        stub_ee_application_setting(email_additional_text: custom_text)
      end

      it { expect(subject).to eq(custom_text) }
    end

    context 'when additional email text is disabled' do
      before do
        stub_licensed_features(email_additional_text: false)
      end

      it { expect(subject).to be_nil }
    end
  end
end
