# frozen_string_literal: true

module TrialRegistrations
  module ReassurancesHelper
    def reassurance_logo_data
      # Create the basic data structure for the logos we want to showcase
      data = [
        { name: 'Siemens', css_classes: reassurance_logo_css_classes(opacity: 5, size: 9) },
        { name: 'Chorus', css_classes: reassurance_logo_css_classes(opacity: 5, size: 9) },
        { name: 'KnowBe4', css_classes: reassurance_logo_css_classes(opacity: 6, size: 9) },
        { name: 'Wish', css_classes: reassurance_logo_css_classes(opacity: 5, size: 8) },
        { name: 'Hotjar', css_classes: reassurance_logo_css_classes(opacity: 5, size: 8) }
      ]

      # Update each entry with a logo image path and alt text derived from the org's name
      data.each do |hash|
        hash[:image_path] = reassurance_logo_image_path(hash[:name])
        hash[:image_alt_text] = reassurance_logo_image_alt_text(hash[:name])
      end

      data
    end

    private

    def reassurance_logo_css_classes(size:, opacity:)
      "gl-w-#{size} gl-h-#{size} gl-mr-#{15 - size} gl-opacity-#{opacity}"
    end

    def reassurance_logo_image_path(org_name)
      'illustrations/third-party-logos/%s.svg' % org_name.parameterize
    end

    def reassurance_logo_image_alt_text(org_name)
      s_('InProductMarketing|%{organization_name} logo') % { organization_name: org_name }
    end
  end
end
