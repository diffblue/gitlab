# frozen_string_literal: true

module Gitlab
  module Ci
    module SecureFiles
      class P12
        attr_reader :error

        def initialize(filedata, password = nil)
          @filedata = filedata
          @password = password
        end

        def certificate_data
          @certificate_data ||= begin
            OpenSSL::PKCS12.new(@filedata, @password).certificate
          rescue StandardError => err
            @error = err.to_s
            nil
          end
        end

        def metadata
          return {} unless certificate_data

          {
            issuer: issuer,
            subject: subject,
            id: serial,
            expires_at: expires_at
          }
        end

        def expires_at
          return unless certificate_data

          certificate_data.not_before
        end

        private

        def serial
          certificate_data.serial.to_s
        end

        def issuer
          X509Name.parse(certificate_data.issuer)
        end

        def subject
          X509Name.parse(certificate_data.subject)
        end
      end
    end
  end
end
