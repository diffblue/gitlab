# frozen_string_literal: true

module EE
  module Identity
    extend ActiveSupport::Concern

    prepended do
      include ScimPaginatable

      belongs_to :saml_provider

      validates :name_id, presence: true, if: :saml_provider

      validates :saml_provider_id, presence: true, if: :group_saml?

      validates :secondary_extern_uid,
        allow_blank: true,
        uniqueness: {
          scope: ::Identity::UniquenessScopes.scopes,
          case_sensitive: false
        }

      validate :validate_managing_group

      scope :with_secondary_extern_uid, ->(provider, secondary_extern_uid) do
        iwhere(secondary_extern_uid: normalize_uid(provider, secondary_extern_uid)).with_provider(provider)
      end

      def name_id
        extern_uid
      end

      def group_saml?
        provider.to_s == "group_saml"
      end
    end

    class_methods do
      extend ::Gitlab::Utils::Override

      override :human_attribute_name
      def human_attribute_name(name, *args)
        if name.to_sym == :name_id
          "SAML NameID"
        else
          super
        end
      end

      def find_by_extern_uid(provider, extern_uid)
        with_extern_uid(provider, extern_uid).take
      end

      def where_group_saml_uid(saml_provider, extern_uid)
        where(provider: :group_saml, saml_provider: saml_provider, extern_uid: extern_uid)
      end

      def find_by_group_saml_uid(saml_provider, extern_uid)
        where_group_saml_uid(saml_provider, extern_uid).take
      end

      def preload_saml_group
        preload(saml_provider: { group: :route })
      end
    end

    private

    def validate_managing_group
      return unless saml_provider&.enforced_group_managed_accounts?

      errors.add(:base, _('Group requires separate account')) if saml_provider.group != user.managing_group
    end
  end
end
