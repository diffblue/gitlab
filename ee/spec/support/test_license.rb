# frozen_string_literal: true

class TestLicense
  def self.init
    Gitlab::License.encryption_key = OpenSSL::PKey::RSA.generate(3072)

    FactoryBot.create(:license)
  end
end
