# frozen_string_literal: true

module World
  include ::Gitlab::Utils::StrongMemoize
  extend self

  COUNTRY_DENYLIST = [
    'BY', # Belarus
    'CU', # Cuba
    'IR', # Iran (Islamic Republic of)
    'KP', # Korea (Democratic People's Republic of)
    'RU', # Russian Federation
    'SD', # Sudan
    'SY' # Syrian Arab Republic
  ].freeze

  JH_MARKET = [
    'CN', # China
    'HK', # Hong Kong
    'MO' # Macao
  ].freeze

  STATE_DENYLIST_FOR_COUNTRY = {
    # For reason, see: https://gitlab.com/gitlab-com/legal-and-compliance/-/issues/1024
    'UA' => ["Donets'ka Oblast'", "Luhans'ka Oblast'", "Respublika Krym"].freeze
  }.freeze

  def country_deny_list
    COUNTRY_DENYLIST + JH_MARKET
  end

  def countries_for_select
    strong_memoize(:countries_for_select) { supported_countries.sort_by(&:name).map { |c| [c.name, c.alpha2, c.emoji_flag, c.country_code] } }
  end

  def states_for_country(country_code)
    strong_memoize("states_for_country_#{country_code}") do
      country = ISO3166::Country.find_country_by_alpha2(country_code)
      next unless country

      country.states
        &.reject { |_, state| state.name.nil? || STATE_DENYLIST_FOR_COUNTRY[country_code]&.include?(state.name) }
        &.sort_by { |_, state| state.name }
        &.map { |code, state| [state.name, code] }.to_h
    end
  end

  def supported_countries
    ISO3166::Country.all.reject { |item| country_deny_list.include?(item.alpha2) }
  end

  def alpha3_from_alpha2(alpha2)
    ISO3166::Country[alpha2]&.alpha3
  end
end

World.prepend_mod
