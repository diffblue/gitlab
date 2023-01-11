# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RackAttack, :aggregate_failures do
  describe '.configure' do
    let(:fake_rack_attack) { class_double("Rack::Attack") }
    let(:fake_rack_attack_request) { class_double("Rack::Attack::Request") }
    let(:fake_cache) { instance_double("Rack::Attack::Cache") }

    before do
      allow(fake_rack_attack).to receive(:throttled_responder=)
      allow(fake_rack_attack).to receive(:throttle)
      allow(fake_rack_attack).to receive(:track)
      allow(fake_rack_attack).to receive(:safelist)
      allow(fake_rack_attack).to receive(:blocklist)
      allow(fake_rack_attack).to receive(:cache).and_return(fake_cache)
      allow(fake_cache).to receive(:store=)

      fake_rack_attack.const_set(:Request, fake_rack_attack_request)
      stub_const("Rack::Attack", fake_rack_attack)
    end

    it 'adds the incident management throttle' do
      described_class.configure(fake_rack_attack)

      expect(fake_rack_attack).to have_received(:throttle)
        .with('throttle_incident_management_notification_web', Gitlab::Throttle.authenticated_web_options)
    end
  end
end
