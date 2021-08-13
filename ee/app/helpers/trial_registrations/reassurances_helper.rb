# frozen_string_literal: true

module TrialRegistrations
  module ReassurancesHelper
    LOGO_IMAGE_PATH = "marketing/logos/logo_%<filename>s.svg"
    DEFAULT_OPACITY_CSS_CLASS_LEVEL = 5

    Struct.new('ReassuranceOrg', :name, :opacity_level, keyword_init: true) do
      def image_alt_text
        s_('InProductMarketing|%{organization_name} logo') % { organization_name: name }
      end

      def logo_image_path
        LOGO_IMAGE_PATH % { filename: name.parameterize }
      end

      def opacity_css_class
        "gl-opacity-#{opacity_level}"
      end

      def opacity_level
        self[:opacity_level] || DEFAULT_OPACITY_CSS_CLASS_LEVEL
      end
    end

    def reassurance_orgs
      [
        Struct::ReassuranceOrg.new(name: 'Siemens', opacity_level: 6),
        Struct::ReassuranceOrg.new(name: 'Chorus'),
        Struct::ReassuranceOrg.new(name: 'KnowBe4', opacity_level: 7),
        Struct::ReassuranceOrg.new(name: 'Wish'),
        Struct::ReassuranceOrg.new(name: 'Hotjar')
      ]
    end
  end
end
