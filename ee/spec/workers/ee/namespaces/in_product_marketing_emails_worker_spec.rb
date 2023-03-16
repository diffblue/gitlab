# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::InProductMarketingEmailsWorker, '#perform', feature_category: :experimentation_activation do
  using RSpec::Parameterized::TableSyntax

  let(:license) { build(:license) }

  where(:in_product_marketing_emails_enabled, :on_gitlab_dot_com, :paid_license, :executes_service) do
    true     | true     | true   | true
    true     | true     | false  | true
    true     | false    | true   | false
    true     | false    | false  | true
    false    | true     | true   | false
    false    | true     | false  | false
    false    | false    | true   | false
    false    | false    | false  | false
  end

  with_them do
    before do
      stub_application_setting(in_product_marketing_emails_enabled: in_product_marketing_emails_enabled)
      allow(::Gitlab).to receive(:com?).and_return(on_gitlab_dot_com)
      allow(License).to receive(:current).and_return(license)
      allow(license).to receive(:paid?).and_return(paid_license)
    end

    it 'executes the email service' do
      if executes_service
        expect(Namespaces::InProductMarketingEmailsService).to receive(:send_for_all_tracks_and_intervals)
      else
        expect(Namespaces::InProductMarketingEmailsService).not_to receive(:send_for_all_tracks_and_intervals)
      end

      subject.perform
    end
  end
end
