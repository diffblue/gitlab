# frozen_string_literal: true

module EE
  module API
    module Support
      module GitAccessActor
        extend ActiveSupport::Concern

        class_methods do
          extend ::Gitlab::Utils::Override

          override :from_params
          def from_params(params)
            if params[:krb5principal]
              new(user: ::User.by_provider_and_extern_uid(:kerberos, params[:krb5principal]).first)
            else
              super
            end
          end
        end
      end
    end
  end
end
