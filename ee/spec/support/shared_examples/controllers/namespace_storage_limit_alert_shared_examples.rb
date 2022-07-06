# frozen_string_literal: true

RSpec.shared_examples 'namespace storage limit alert' do
  let(:alert_level) { :info }

  before do
    stub_ee_application_setting(should_check_namespace_plan: true)
    stub_ee_application_setting(enforce_namespace_storage_limit: true)
    stub_ee_application_setting(automatic_purchased_storage_allocation: true)
    allow_next_instance_of(EE::Namespace::Storage::Notification, namespace, user) do |notification|
      allow(notification).to receive(:payload).and_return({
        alert_level: alert_level,
        usage_message: "Usage",
        explanation_message: "Explanation",
        root_namespace: namespace.root_ancestor
      })
      allow(notification).to receive(:alert_level).and_return(:alert_level)
    end

    allow(controller).to receive(:current_user).and_return(user)
    namespace.add_owner(user)
  end

  render_views

  it 'does render' do
    subject

    expect(response.body).to match(/Explanation/)
    expect(response.body).to have_css('.js-namespace-storage-alert-dismiss')
  end

  context 'when alert_level is error' do
    let(:alert_level) { :error }

    it 'does not render a dismiss button' do
      subject

      expect(response.body).not_to have_css('.js-namespace-storage-alert-dismiss')
    end
  end

  context 'when cookie is set' do
    before do
      cookies["hide_storage_limit_alert_#{namespace.id}_info"] = 'true'
    end

    it 'does not render alert' do
      subject

      expect(response.body).not_to match(/Explanation/)
    end
  end
end
