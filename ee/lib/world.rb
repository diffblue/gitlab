# frozen_string_literal: true

module World
  include ::Gitlab::Utils::StrongMemoize
  extend self

  DENYLIST = ['Iran (Islamic Republic of)', 'Sudan', 'Syrian Arab Republic', 'Korea (Democratic People\'s Republic of)', 'Cuba', 'Belarus', 'Russian Federation'].freeze
  JH_MARKET = ['China', 'Hong Kong', 'Macao'].freeze

  def countries_for_select
    strong_memoize(:countries_for_select) { all_countries.sort_by(&:name).map { |c| [c.name, c.alpha2] } }
  end

  def states_for_country(country_code)
    strong_memoize("states_for_country_#{country_code}") do
      country = ISO3166::Country.find_country_by_alpha2(country_code)
      next unless country

      country.states
        &.reject { |_, state| state.name.nil? }
        &.sort_by { |_, state| state.name }
        &.map { |code, state| [state.name, code] }.to_h
    end
  end

  def all_countries
    strong_memoize(:all_countries) { ISO3166::Country.all.reject {|item| DENYLIST.include?(item.name) || JH_MARKET.include?(item.name) } }
  end

  def alpha3_from_alpha2(alpha2)
    ISO3166::Country[alpha2]&.alpha3
  end
end

World.prepend_mod
