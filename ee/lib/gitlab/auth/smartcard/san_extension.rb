# frozen_string_literal: true

module Gitlab
  module Auth
    module Smartcard
      class SANExtension
        # From X.509 RFC https://www.rfc-editor.org/rfc/rfc5280
        # A.2. Implicitly Tagged Module, 1988 Syntax ....................
        # page-127
        #        Names                           TAG     Type
        ##########################################################
        #        otherName                       [0]     OtherName
        #        rfc822Name(email)               [1]     IA5String
        #        dNSName                         [2]     IA5String
        #        x400Address                     [3]     ORAddress
        #        directoryName                   [4]     Name
        #        ediPartyName                    [5]     EDIPartyName
        #        uniformResourceIdentifier       [6]     IA5String
        #        iPAddress                       [7]     OCTET STRING
        #        registeredID                    [8]     OBJECT IDENTIFIER
        EMAIL_TAG = 1
        URI_TAG = 6

        def initialize(certificate, gitlab_host)
          @certificate = certificate
          @gitlab_host = gitlab_host
        end

        def email_identity
          email_entry =
            if alternate_emails.size == 1
              alternate_emails.first
            else
              alternate_emails.find { |name| gitlab_host?(name[URI_TAG]) }
            end

          email_entry&.fetch(EMAIL_TAG, nil)
        end

        def alternate_emails
          @alternate_emails ||= subject_alternate_email_identities
        end

        private

        attr_reader :certificate, :gitlab_host

        def subject_alternate_email_identities
          subject_alt_names = certificate.extensions.select { |e| e.oid == 'subjectAltName' }

          subject_alt_names.each_with_object([]) do |entry, san_entries|
            # Parse the subject alternate name certificate extension as ASN1, first value should be the key
            asn_san = OpenSSL::ASN1.decode(entry)
            # And the second value should be a nested ASN1 sequence
            asn_san_sequence = OpenSSL::ASN1.decode(asn_san.value[1].value)

            san_entries << asn_san_sequence.each_with_object({}) do |asn_data, alternate_names|
              alternate_names[asn_data.tag] = asn_data.value if [EMAIL_TAG, URI_TAG].include?(asn_data.tag)
            end
          end
        end

        def gitlab_host?(uri)
          URI.parse(uri).host == gitlab_host
        rescue URI::InvalidURIError
          false
        end
      end
    end
  end
end
