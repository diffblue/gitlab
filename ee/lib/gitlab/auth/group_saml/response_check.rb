# frozen_string_literal: true

module Gitlab
  module Auth
    module GroupSaml
      class ResponseCheck
        include ActiveModel::Model

        attr_reader :xml_response, :identity

        delegate :name_id, :name_id_format, :xml, to: :xml_response

        validate :response_error_passthrough!
        validates :name_id, presence: true
        validate :name_id_matches_identity!
        validate :name_id_format_persistent!
        validate :name_id_randomly_generated!
        validates :name_id_format, presence: true

        def initialize(xml_response:, identity: nil)
          @xml_response = xml_response
          @identity = identity
        end

        def self.for_group(group:, raw_response:, user:)
          identity = GroupSamlIdentityFinder.new(user: user).find_linked(group: group)
          xml_response = XmlResponse.new(group: group, raw_response: raw_response)
          self.new(xml_response: xml_response, identity: identity)
        end

        private

        def response_error_passthrough!
          return if xml_response.valid?

          xml_response.errors.each do |message|
            errors.add(:xml_response, message)
          end
        end

        def name_id_matches_identity!
          return unless name_id_changed?

          message = s_('GroupSAML|must match stored NameID of "%{extern_uid}" to identify user and allow sign in') % { extern_uid: identity&.extern_uid }
          errors.add(:name_id, message)
        end

        def name_id_format_persistent!
          return if name_id_format.ends_with?(':persistent')
          return if name_id_format.ends_with?(':emailAddress') && name_id_is_email?

          errors.add(:name_id_format, s_('GroupSAML|"persistent" recommended'))
        end

        def name_id_randomly_generated!
          return unless name_id_is_new? && unreliable_name_id?

          errors.add(:name_id, s_('GroupSAML|recommend persistent ID instead of email'))
        end

        def unreliable_name_id?
          name_id_is_email?
        end

        def name_id_is_email?
          name_id.include?('@')
        end

        def name_id_is_new?
          !name_id_from_identity || name_id_changed?
        end

        def name_id_changed?
          name_id_from_identity && name_id != name_id_from_identity
        end

        def name_id_from_identity
          identity&.extern_uid
        end
      end
    end
  end
end
