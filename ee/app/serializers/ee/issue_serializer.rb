# frozen_string_literal: true

module EE
  module IssueSerializer
    extend ::Gitlab::Utils::Override

    override :choose_entity
    def choose_entity(opts)
      if opts[:serializer] == 'ai'
        IssueAiEntity
      else
        super(opts)
      end
    end
  end
end
