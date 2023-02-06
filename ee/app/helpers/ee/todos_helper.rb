# frozen_string_literal: true

module EE
  module TodosHelper
    extend ::Gitlab::Utils::Override

    override :todo_types_options
    def todo_types_options
      super + [{ id: 'Epic', text: s_('Todos|Epic') }]
    end

    override :todo_author_display?
    def todo_author_display?(todo)
      super && !todo.merge_train_removed?
    end

    override :show_todo_state?
    def show_todo_state?(todo)
      super || (todo.target.is_a?(Epic) && todo.target.state == 'closed')
    end
  end
end
