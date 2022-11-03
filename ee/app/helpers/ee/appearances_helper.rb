# frozen_string_literal: true

module EE
  module AppearancesHelper
    extend ::Gitlab::Utils::Override

    override :default_brand_title
    def default_brand_title
      _('GitLab Enterprise Edition')
    end
  end
end
