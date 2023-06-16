# frozen_string_literal: true

module FreeUserCapHelpers
  def enforce_free_user_caps
    stub_ee_application_setting(dashboard_limit_enabled: true)
    stub_feature_flags(free_user_cap_new_namespaces: true)
    stub_ee_application_setting(dashboard_limit_new_namespace_creation_enforcement_date: 2.days.ago)
    stub_ee_application_setting(dashboard_limit: 5)
  end

  def exceed_user_cap(namespace)
    create_list(:group_member, 6, source: namespace)
  end
end
