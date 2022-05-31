# frozen_string_literal: true

module Pajamas
  class BannerComponent < Pajamas::Component
    # @param [Boolean] embedded
    # @param [Symbol] variant
    # @param [String] svg_path
    # @param [Hash] banner_options
    # @param [Hash] close_options
    def initialize(
      embedded: false,
      variant: :promotion,
      svg_path: nil,
      banner_options: {},
      close_options: {}
    )
      @embedded = embedded
      @variant = variant.to_sym
      @svg_path = svg_path.to_s
      @banner_options = banner_options
      @close_options = close_options
    end

    private

    def banner_class
      classes = []
      classes.push('gl-border-none') if @embedded
      classes.push('gl-banner-introduction') if introduction?
      classes.join(' ')
    end

    def close_class
      if introduction?
        'btn-confirm btn-confirm-tertiary'
      else
        'btn-default btn-default-tertiary'
      end
    end

    delegate :sprite_icon, to: :helpers

    renders_one :title
    renders_one :illustration
    renders_one :actions

    def introduction?
      @variant == :introduction
    end
  end
end
