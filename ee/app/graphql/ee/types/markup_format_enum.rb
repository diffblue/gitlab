# frozen_string_literal: true

module EE
  module Types
    class MarkupFormatEnum < ::Types::BaseEnum
      graphql_name 'MarkupFormat'
      description 'List markup formats'

      value 'HTML', description: 'HTML format.', value: :html
      value 'RAW', description: 'Raw format.', value: :raw
    end
  end
end
