# frozen_string_literal: true

module EE
  module Groups
    module ApplicationController
      extend ::Gitlab::Utils::Override

      def check_group_feature_available!(feature)
        render_404 unless group.licensed_feature_available?(feature)
      end

      override :method_missing
      def method_missing(method_sym, *arguments, &block)
        case method_sym.to_s
        when /\Acheck_(.*)_available!\z/
          check_group_feature_available!(Regexp.last_match(1).to_sym)
        else
          super
        end
      end
    end
  end
end
