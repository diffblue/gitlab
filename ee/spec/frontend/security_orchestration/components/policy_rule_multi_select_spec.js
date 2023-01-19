import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PolicyRuleMultiSelect from 'ee/security_orchestration/components/policy_rule_multi_select.vue';

const items = { start: 'Start now', middle: 'Almost there', end: 'Done' };
const itemsKeys = Object.keys(items);
const itemsLength = itemsKeys.length;
const itemsLengthIncludingSelectAll = itemsLength + 1;
// +1 due to the item Select all

describe('Policy Rule Multi Select', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(PolicyRuleMultiSelect, {
      propsData: {
        itemTypeName: 'demo items',
        items,
        value: [],
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findAllSelectedItem = () => wrapper.find('[data-testid="all-items-selected"]');

  describe('Initialization', () => {
    it('renders dropdown', () => {
      expect(findDropdown().exists()).toBe(true);
    });

    it('renders text based on itemTypeName property', () => {
      expect(findDropdown().props('text')).toBe('Select demo items');
    });

    describe('Without any selected item', () => {
      it('does not have any selected item', () => {
        expect(findDropdownItems().filter((element) => element.props('isChecked'))).toHaveLength(0);
      });

      it('displays text related to the performing of a selection', () => {
        expect(findDropdown().props('text')).toBe('Select demo items');
      });

      it('does not have select all item selected', () => {
        expect(findAllSelectedItem().props('isChecked')).toBe(false);
      });
    });

    describe('With one selected item', () => {
      const expectedKey = 'start';
      const expectedValue = items[expectedKey];

      beforeEach(() => {
        createComponent({ value: [expectedKey] });
      });

      it('has one item selected', () => {
        expect(findDropdownItems().filter((element) => element.props('isChecked'))).toHaveLength(1);
      });

      it('displays text related to the selected item', () => {
        expect(findDropdown().props('text')).toBe(expectedValue);
      });

      it('does not have select all item selected', () => {
        expect(findAllSelectedItem().props('isChecked')).toBe(false);
      });
    });

    describe('With multiple selected items', () => {
      const expectedKeys = ['start', 'middle'];
      const expectedLength = expectedKeys.length;
      const expectedValue = 'Start now +1 more';

      beforeEach(() => {
        createComponent({ value: expectedKeys });
      });

      it('has multiple items selected', () => {
        expect(findDropdownItems().filter((element) => element.props('isChecked'))).toHaveLength(
          expectedLength,
        );
      });

      it('displays text related to the first selected item followed by the number of additional items', () => {
        expect(findDropdown().props('text')).toBe(expectedValue);
      });

      it('does not have select all item selected', () => {
        expect(findAllSelectedItem().props('isChecked')).toBe(false);
      });
    });

    describe('With all selected items', () => {
      const expectedValue = 'All demo items';

      beforeEach(() => {
        createComponent({ value: itemsKeys });
      });

      it('has all items selected', () => {
        expect(findDropdownItems().filter((element) => element.props('isChecked'))).toHaveLength(
          itemsLengthIncludingSelectAll,
        );
      });

      it('displays text related to all items being selected', () => {
        expect(findDropdown().props('text')).toBe(expectedValue);
      });

      it('has select all item selected', () => {
        expect(findAllSelectedItem().props('isChecked')).toBe(true);
      });
    });
  });

  it('has all items selected after select all is checked', async () => {
    const allSelectItem = findAllSelectedItem();
    const allDropdownItems = findDropdownItems();

    expect(allDropdownItems.filter((element) => element.props('isChecked'))).toHaveLength(0);

    await allSelectItem.trigger('click');

    expect(allDropdownItems.filter((element) => element.props('isChecked'))).toHaveLength(
      itemsLengthIncludingSelectAll,
    );
    expect(wrapper.emitted().input).toEqual([[itemsKeys]]);
  });

  it('has all items unselected after select all is unchecked', async () => {
    createComponent({ value: itemsKeys });
    const allSelectItem = findAllSelectedItem();
    const allDropdownItems = findDropdownItems();

    expect(allDropdownItems.filter((element) => element.props('isChecked'))).toHaveLength(
      itemsLengthIncludingSelectAll,
    );

    await allSelectItem.trigger('click');

    expect(allDropdownItems.filter((element) => element.props('isChecked'))).toHaveLength(0);
    expect(wrapper.emitted().input).toEqual([[[]]]);
  });

  it('has an item selected after it is checked', async () => {
    const expectedKey = 'end';
    const expectedValue = items[expectedKey];
    const dropdownItemsWithDone = findDropdownItems().filter((element) =>
      element.html().includes(expectedValue),
    );

    expect(dropdownItemsWithDone.filter((element) => element.props('isChecked'))).toHaveLength(0);

    await dropdownItemsWithDone.at(0).trigger('click');

    expect(dropdownItemsWithDone.filter((element) => element.props('isChecked'))).toHaveLength(1);
    expect(wrapper.emitted().input).toEqual([[[expectedKey]]]);
  });

  it('has an item unselected after it is unchecked', async () => {
    const expectedKey = 'end';
    const expectedValue = items[expectedKey];
    createComponent({ value: [expectedKey] });
    const dropdownItemsWithDone = findDropdownItems().filter((element) =>
      element.html().includes(expectedValue),
    );

    expect(dropdownItemsWithDone.filter((element) => element.props('isChecked'))).toHaveLength(1);

    await dropdownItemsWithDone.at(0).trigger('click');

    expect(dropdownItemsWithDone.filter((element) => element.props('isChecked'))).toHaveLength(0);
    expect(wrapper.emitted().input).toEqual([[[]]]);
  });

  describe('with includeSelectAll set to false', () => {
    beforeEach(() => {
      createComponent({ includeSelectAll: false });
    });

    it('does not show select all option', () => {
      expect(findAllSelectedItem().exists()).toBe(false);
    });
  });
});
