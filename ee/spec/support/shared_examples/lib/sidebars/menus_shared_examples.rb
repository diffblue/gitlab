# frozen_string_literal: true

RSpec.shared_examples_for 'a panel without placeholders' do
  # EE sidebars are a superset of CE sidebars.
  # There might be placeholders in CE, which would only be filled in EE
  # By checking that EE has no placeholders,
  # we implicitly checked that everything is alright in CE as well
  let(:menu_items) do
    subject.instance_variable_get(:@menus).flat_map { |menu| menu.instance_variable_get(:@items) }
  end

  it 'has no Sidebars::NilMenuItem' do
    nil_items = menu_items
                     .select { |item| item.is_a?(::Sidebars::NilMenuItem) }
                     .map(&:item_id)

    expect(nil_items).to match_array([])
  end
end
