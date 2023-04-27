# frozen_string_literal: true

class DataSeeder
  def seed
    create(:group_label, group: @group, title: 'priority::1', color: '#FF0000')
    create(:group_label, group: @group, title: 'priority::2', color: '#DD0000')
    create(:group_label, group: @group, title: 'priority::3', color: '#CC0000')
    create(:group_label, group: @group, title: 'priority::4', color: '#CC1111')
  end
end
