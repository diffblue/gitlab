# frozen_string_literal: true

module EE
  module NotesFinder
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    override :noteables_for_type
    def noteables_for_type(noteable_type)
      case noteable_type
      when 'epic'
        return EpicsFinder.new(@current_user, group_id: @params[:group_id]) # rubocop:disable Gitlab/ModuleWithInstanceVariables
      when 'vulnerability'
        return ::Security::VulnerabilitiesFinder.new(@project) # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end

      super
    end
  end
end
