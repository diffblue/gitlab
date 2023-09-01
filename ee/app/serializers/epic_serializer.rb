# frozen_string_literal: true

class EpicSerializer < BaseSerializer
  # This overrided method takes care of which entity should be used
  # to serialize the `issue` based on `serializer` key in `opts` param.
  # Hence, `entity` doesn't need to be declared on the class scope.
  def represent(epic, opts = {})
    entity = choose_entity(opts)

    super(epic, opts, entity)
  end

  def choose_entity(opts)
    case opts[:serializer]
    when 'ai'
      EpicAiEntity
    else
      EpicEntity
    end
  end
end
