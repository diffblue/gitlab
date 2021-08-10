# frozen_string_literal: true

# Used by Operations dashboard
get 'operations' => 'operations#index'
post 'operations' => 'operations#create', as: :add_operations_project
delete 'operations' => 'operations#destroy', as: :remove_operations_project

# Used by Environments dashboard
get 'operations/environments' => 'operations#environments'
post 'operations/environments' => 'operations#create', as: :add_operations_environments_project
delete 'operations/environments' => 'operations#destroy', as: :remove_operations_environments_project
