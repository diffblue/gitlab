# frozen_string_literal: true

require "spec_helper"

RSpec.describe EE::AccessTokensHelper do
  describe '#expires_at_field_data', :freeze_time do
    before do
      stub_licensed_features(personal_access_token_expiration_policy: true)
    end

    it 'returns expected hash' do
      expect(helper).to receive(:personal_access_token_max_expiry_date).and_return(Time.new(2022, 3, 2, 10, 30, 45, 'UTC'))

      expect(helper.expires_at_field_data).to eq({
        min_date: 1.day.from_now.iso8601,
        max_date: '2022-03-02T10:30:45Z'
      })
    end
  end
end
