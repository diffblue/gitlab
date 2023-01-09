# frozen_string_literal: true

RSpec.shared_examples 'namespace storage limit alert' do
  let(:alert_level) { :info }

  before do
    stub_ee_application_setting(should_check_namespace_plan: true)
    stub_ee_application_setting(enforce_namespace_storage_limit: true)
    stub_ee_application_setting(automatic_purchased_storage_allocation: true)
    allow_next_instance_of(EE::Namespace::Storage::Notification) do |notification|
      allow(notification).to receive(:payload).and_return({
        alert_level: alert_level,
        enforcement_type: :namespace,
        root_namespace: namespace.root_ancestor,
        usage_message: "Usage",
        explanation_message: {
          main: {
            text: "Explanation",
            link: { text: 'link', href: '/link' }
          },
          footer: {
            text: "Footer for explanation",
            link: { text: 'footer link', href: '/footer/link' }
          }
        }
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
    expect(response.body).to match(/Footer for explanation/)
    expect(response.body).to have_css('.js-namespace-storage-alert')
  end

  context 'when user has dismissed already' do
    before do
      allow(user).to receive(:dismissed_callout?).and_return(true)
      allow(user).to receive(:dismissed_callout_for_group?).and_return(true)
    end

    it 'does not render alert' do
      subject

      expect(response.body).not_to match(/Explanation/)
      expect(response.body).not_to have_css('.js-namespace-storage-alert')
    end
  end
end
