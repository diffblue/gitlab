# frozen_string_literal: true

class TestLicense
  def self.init
    setup_encryption_key!

    FactoryBot.create(:license)
  end

  def self.setup_encryption_key!
    return if defined?(@encryption_key_setup)

    Gitlab::License.encryption_key = OpenSSL::PKey::RSA.generate(3072)

    @encryption_key_setup = true
  end
  private_class_method :setup_encryption_key!
end
