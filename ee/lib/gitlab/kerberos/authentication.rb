# frozen_string_literal: true

module Gitlab
  module Kerberos
    class Authentication
      def self.kerberos_default_realm
        krb5 = krb5_class.new
        default_realm = krb5.get_default_realm
        krb5.close # release memory allocated by the krb5 library
        default_realm
      end

      def self.krb5_class
        @krb5_class ||= begin
          require "krb5_auth"
          Krb5Auth::Krb5
        end
      end
    end
  end
end
