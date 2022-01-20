import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { EntityTypes } from 'ee/threat_monitoring/components/policy_editor/network_policy/lib';
import PolicyRuleEntity from 'ee/threat_monitoring/components/policy_editor/network_policy/policy_rule_entity.vue';

describe('PolicyRuleEntity component', () => {
  let wrapper;

  const factory = ({ value = [] } = {}) => {
    wrapper = shallowMount(PolicyRuleEntity, {
      propsData: {
        value,
      },
    });
  };

  beforeEach(() => {
    factory();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const findDropdown = () => wrapper.findComponent(GlDropdown);

  describe("when value has 'all' entity", () => {
    beforeEach(() => {
      factory({ value: [EntityTypes.ALL, EntityTypes.HOST] });
    });

    it('selects all items', () => {
      const dropdown = findDropdown();
      const selectedItems = dropdown
        .findAllComponents(GlDropdownItem)
        .filter((el) => el.props('isChecked'));
      expect(selectedItems.length).toEqual(Object.keys(EntityTypes).length);
      expect(dropdown.props('text')).toEqual('All selected');
    });
  });

  describe('when all entities are selected', () => {
    beforeEach(() => {
      const value = Object.keys(EntityTypes)
        .map((key) => EntityTypes[key])
        .filter((entity) => entity !== EntityTypes.ALL && entity !== EntityTypes.HOST);
      factory({ value });
    });

    it("emits change with 'all' entity", () => {
      const dropdown = findDropdown();
      dropdown
        .findAllComponents(GlDropdownItem)
        .filter((el) => el.text() === EntityTypes.HOST)
        .at(0)
        .vm.$emit('click');

      const emitted = wrapper.emitted().change;
      expect(emitted.length).toEqual(1);
      expect(emitted[0]).toEqual([[EntityTypes.ALL]]);
    });
  });
});
