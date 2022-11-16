# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        class SamlSSOSignIn < QA::Page::Base
          view 'ee/app/views/groups/sso/saml.html.haml' do
            element :saml_sso_signin_button
          end

          def click_sign_in
            Support::Retrier.retry_until do
              click_element :saml_sso_signin_button
              !has_element?(:saml_sso_signin_button, wait: 0)
            end
          end
        end
      end
    end
  end
end
