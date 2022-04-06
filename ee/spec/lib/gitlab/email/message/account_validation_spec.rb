# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Message::AccountValidation do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:project) { create(:project, :repository, namespace: namespace) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  subject(:message) { described_class.new(pipeline) }

  it 'contains the correct message', :aggregate_failures, :saas do
    expect(message.subject_line).to eq 'Fix your pipelines by validating your account'
    expect(message.title).to eq "Looks like you’ll need to validate your account to use free CI/CD minutes"
    expect(message.body_line1).to eq "In order to use free CI/CD minutes on shared runners, you'll need to validate your account using one of our verification options. If you prefer not to, you can run pipelines by bringing your own runners and disabling shared runners for your project."
    expect(message.body_line2).to include(
      'Verification is required to discourage and reduce the abuse on GitLab infrastructure.',
      'If you verify with a credit or debit card, <b>GitLab will not charge your card, it will only be used for validation.</b>',
      '<a href="https://about.gitlab.com/blog/2021/05/17/prevent-crypto-mining-abuse/">Learn more.</a>'
    )
    expect(message.cta_text).to eq 'Validate your account'
    expect(message.cta2_text).to eq "I'll bring my own runners"
    expect(message.logo_path).to eq 'mailers/in_product_marketing/verify-2.png'
    expect(message.unsubscribe).to include('%tag_unsubscribe_url%')
  end
end
