# frozen_string_literal: true

module EE
  module Search
    module Navigation
      extend ::Gitlab::Utils::Override

      override :tabs
      def tabs
        super.merge(epics: { sort: 3, label: _("Epics"), condition: show_epics_search_tab? })
      end

      private

      def show_epics_search_tab?
        project.nil? && !!options[:show_epics]
      end
    end
  end
end
