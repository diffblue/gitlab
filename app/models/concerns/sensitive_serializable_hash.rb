# frozen_string_literal: true

module SensitiveSerializableHash
  extend ActiveSupport::Concern

  # Override serializable_hash to exclude sensitive attributes by default
  #
  # In general, prefer NOT to use serializable_hash / to_json / as_json in favor
  # of serializers / entities instead which has an allowlist of attributes
  def serializable_hash(options = nil)
    return super(options) if options && options[:unsafe_serialization_hash]

    options = options.try(:dup) || {}
    options[:except] = Array(options[:except]).dup

    if self.class.respond_to?(:token_authenticatable_fields)
      options[:except].concat self.class.token_authenticatable_fields

      # See https://gitlab.com/gitlab-org/security/gitlab/-/tree/master/app/models/concerns/token_authenticatable_strategies
      # TODO expose this fields from the TokenAuthenticatable module instead
      options[:except].concat self.class.token_authenticatable_fields.map { |token_field| "#{token_field}_expires_at" }
      options[:except].concat self.class.token_authenticatable_fields.map { |token_field| "#{token_field}_digest" }
      options[:except].concat self.class.token_authenticatable_fields.map { |token_field| "#{token_field}_encrypted" }
    end

    if self.class.respond_to?(:encrypted_attributes)
      options[:except].concat self.class.encrypted_attributes.keys

      # Per https://github.com/attr-encrypted/attr_encrypted/blob/a96693e9a2a25f4f910bf915e29b0f364f277032/lib/attr_encrypted.rb#L413
      options[:except].concat self.class.encrypted_attributes.values.map { |v| v[:attribute] }
      options[:except].concat self.class.encrypted_attributes.values.map { |v| "#{v[:attribute]}_iv" }
    end

    super(options)
  end
end
