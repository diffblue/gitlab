# frozen_string_literal: true

module EE
  module IdeHelper
    extend ::Gitlab::Utils::Override

    private

    override :new_ide_code_suggestions_data
    def new_ide_code_suggestions_data
      super.merge({
        'code-suggestions-enabled' => show_code_suggestions? ? 'true' : ''
      })
    end

    def show_code_suggestions?
      current_user.can?(:access_code_suggestions)
    end
  end
end

IdeHelper.prepend_mod
