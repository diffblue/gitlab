# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemCheck::Geo::AuthorizedKeysFlagCheck, :silence_stdout, feature_category: :geo_replication do
  describe '#check?' do
    it 'fails when write to authorized_keys still enabled' do
      stub_application_setting(authorized_keys_enabled: true)

      expect(subject.check?).to be_falsey
    end

    it 'succeed when write to authorized_keys is disabled' do
      stub_application_setting(authorized_keys_enabled: false)

      expect(subject.check?).to be_truthy
    end
  end
end
