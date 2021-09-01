# frozen_string_literal: true

module TrialRegistrations
  module ReassurancesHelper
    LOGO_IMAGE_PATH = "marketing/logos/logo_%<filename>s.svg"
    DEFAULT_OPACITY_CSS_CLASS_LEVEL = 5

    class ReassuranceOrg
      attr_reader :name

      def initialize(name:, opacity_level: DEFAULT_OPACITY_CSS_CLASS_LEVEL)
        @name = name
        @opacity_level = opacity_level
      end

      def image_alt_text
        s_('InProductMarketing|%{organization_name} logo') % { organization_name: name }
      end

      def logo_image_path
        LOGO_IMAGE_PATH % { filename: name.parameterize }
      end

      def opacity_css_class
        "gl-opacity-#{@opacity_level}"
      end
    end

    def reassurance_orgs
      [
        ReassuranceOrg.new(name: 'Siemens', opacity_level: 6),
        ReassuranceOrg.new(name: 'Chorus'),
        ReassuranceOrg.new(name: 'KnowBe4', opacity_level: 7),
        ReassuranceOrg.new(name: 'Wish'),
        ReassuranceOrg.new(name: 'Hotjar')
      ]
    end
  end
end
