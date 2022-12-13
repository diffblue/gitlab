# frozen_string_literal: true

# goal of this context: provide a close/stable representation of how SaaS is configured currently
# things that belong in here:
# - settled-not-yet-removed-in-saas feature flag settings
# - application settings for SaaS
# - .com specific type things like enforcing of terms
# things that don't belong in here:
# - unsettled feature flag settings in SaaS(still in rollout), instead test both branches to cover SaaS
RSpec.shared_context 'with saas settings for registration flows', shared_context: :metadata do
  include TermsHelper
  include SaasRegistrationHelpers

  before do
    # Saas doesn't require admin approval.
    stub_application_setting(require_admin_approval_after_user_signup: false)

    # SaaS always requires confirmation
    stub_application_setting_enum('email_confirmation_setting', 'hard')

    stub_feature_flags(
      # our focus isn't around arkose/signup challenges, so we'll omit those
      arkose_labs_signup_challenge: false,
      # Saas will always need emails confirmed
      soft_email_confirmation: false,
      # currently being rolled out, not yet on in prod
      identity_verification: false
    )

    enforce_terms
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'with saas settings for registration flows', saas_registration: true
end
