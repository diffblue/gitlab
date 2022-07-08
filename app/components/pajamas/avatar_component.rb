# frozen_string_literal: true

module Pajamas
  class AvatarComponent < Pajamas::Component
    # @param record [User, Project, Group]
    # @param alt [String] text for the alt tag
    # @param class [String] custom CSS class(es)
    # @param size [Integer] size in pixel
    def initialize(record, alt: nil, class: "", size: 64)
      @record = record
      @alt = alt
      @class = binding.local_variable_get(:class)
      @size = filter_attribute(size.to_i, SIZE_OPTIONS, default: 64)
    end

    private

    SIZE_OPTIONS = [16, 24, 32, 48, 64, 96].freeze

    def avatar_classes
      classes = ["gl-avatar", "gl-avatar-s#{@size}", @class]
      classes.push("gl-avatar-circle") if @record.is_a?(User)

      unless src
        classes.push("gl-avatar-identicon")
        classes.push("gl-avatar-identicon-bg#{(@record.id % 7) + 1}")
      end

      classes.join(' ')
    end

    def src
      if @record.is_a?(User)
        # Users show a gravatar instead of an identicon. Also avatars of
        # blocked users are only shown if the current_user is an admin.
        # To not duplicate this logic, we are using existing helpers here.
        current_user = helpers.current_user rescue nil
        return helpers.avatar_icon_for_user(@record, @size, current_user: current_user)
      end

      return unless @record.try(:avatar_url)

      "#{@record.avatar_url}?width=#{@size}"
    end

    def alt
      @alt || @record.name
    end

    def initial
      @record.name[0, 1].upcase
    end

    def circle?
      @record.is_a? User
    end
  end
end
