# frozen_string_literal: true

module ManualRenewalBannerHelper
  def manual_renewal_banner
    return unless current_user&.can_admin_all_resources?

    Gitlab::ManualRenewalBanner.new(actionable: License.current)
  end
end
