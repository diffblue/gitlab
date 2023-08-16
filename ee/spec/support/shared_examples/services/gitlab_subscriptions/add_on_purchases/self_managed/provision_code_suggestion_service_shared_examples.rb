# frozen_string_literal: true

RSpec.shared_examples 'call service to handle the provision of code suggestions' do
  it 'calls the service to handle the provision of code suggestions' do
    expect_next_instance_of(
      GitlabSubscriptions::AddOnPurchases::SelfManaged::ProvisionCodeSuggestionsService
    ) do |service|
      expect(service).to receive(:execute).and_call_original
    end

    subject
  end
end
