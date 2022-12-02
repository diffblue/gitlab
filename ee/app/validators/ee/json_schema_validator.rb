# frozen_string_literal: true

module EE
  module JsonSchemaValidator
    private

    def schema_path
      @schema_path ||= if File.exist?(super)
                         super
                       else
                         Rails.root.join('ee', *base_directory, filename_with_extension).to_s
                       end
    end
  end
end
