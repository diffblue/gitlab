import { GlDropdown } from '@gitlab/ui';
import { nextTick } from 'vue';
import SeverityFilter, {
  DROPDOWN_OPTIONS,
} from 'ee/security_dashboard/components/shared/filters/severity_filter.vue';
import { ALL_ID } from 'ee/security_dashboard/components/shared/filters/constants';
import QuerystringSync from 'ee/security_dashboard/components/shared/filters/querystring_sync.vue';
import DropdownButtonText from 'ee/security_dashboard/components/shared/filters/dropdown_button_text.vue';
import FilterItem from 'ee/security_dashboard/components/shared/filters/filter_item.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';

const OPTION_IDS = DROPDOWN_OPTIONS.map(({ id }) => id);

describe('Severity Filter component', () => {
  let wrapper;

  const createWrapper = () => {
    wrapper = mountExtended(SeverityFilter, {
      stubs: { QuerystringSync: true },
    });
  };

  const findQuerystringSync = () => wrapper.findComponent(QuerystringSync);
  const findDropdownItems = () => wrapper.findAllComponents(FilterItem);
  const findDropdownItem = (id) => wrapper.findByTestId(id);

  const clickDropdownItem = async (id) => {
    findDropdownItem(id).vm.$emit('click');
    await nextTick();
  };

  const expectSelectedItems = (ids) => {
    const checkedItems = findDropdownItems()
      .wrappers.filter((item) => item.props('isChecked'))
      .map((item) => item.attributes('data-testid'));

    expect(checkedItems).toEqual(ids);
  };

  beforeEach(() => {
    createWrapper();
  });

  describe('QuerystringSync component', () => {
    it('has expected props', () => {
      expect(findQuerystringSync().props()).toMatchObject({
        querystringKey: 'severity',
        value: [],
      });
    });

    it('receives empty array when All Statuses option is clicked', async () => {
      await clickDropdownItem(ALL_ID);

      expect(findQuerystringSync().props('value')).toEqual([]);
    });

    it.each`
      emitted                          | expected
      ${['HIGH', 'MEDIUM']}            | ${['HIGH', 'MEDIUM']}
      ${['INVALID', 'LOW', 'UNKNOWN']} | ${['LOW', 'UNKNOWN']}
      ${['INVALID']}                   | ${[ALL_ID]}
      ${[]}                            | ${[ALL_ID]}
    `('restores selected items - $emitted', async ({ emitted, expected }) => {
      findQuerystringSync().vm.$emit('input', emitted);
      await nextTick();

      expectSelectedItems(expected);
    });
  });

  describe('default view', () => {
    it('shows the label', () => {
      expect(wrapper.find('label').text()).toBe(SeverityFilter.i18n.label);
    });

    it('shows the dropdown with correct header text', () => {
      expect(wrapper.findComponent(GlDropdown).props('headerText')).toBe(SeverityFilter.i18n.label);
    });

    it('shows the DropdownButtonText component with the correct props', () => {
      expect(wrapper.findComponent(DropdownButtonText).props()).toMatchObject({
        items: [SeverityFilter.i18n.allItemsText],
        name: SeverityFilter.i18n.label,
      });
    });
  });

  describe('dropdown items', () => {
    it('shows all dropdown items with correct text', () => {
      expect(findDropdownItems()).toHaveLength(DROPDOWN_OPTIONS.length + 1);

      expect(findDropdownItem(ALL_ID).text()).toBe(SeverityFilter.i18n.allItemsText);
      DROPDOWN_OPTIONS.forEach(({ id, text }) => {
        expect(findDropdownItem(id).text()).toBe(text);
      });
    });

    it('allows multiple items to be selected', async () => {
      const ids = [];

      for await (const id of OPTION_IDS) {
        await clickDropdownItem(id);
        ids.push(id);

        expectSelectedItems(ids);
      }
    });

    it('toggles the item selection when clicked on', async () => {
      for await (const id of OPTION_IDS) {
        await clickDropdownItem(id);

        expectSelectedItems([id]);

        await clickDropdownItem(id);

        expectSelectedItems([ALL_ID]);
      }
    });

    it('selects ALL item when created', () => {
      expectSelectedItems([ALL_ID]);
    });

    it('selects ALL item and deselects everything else when it is clicked', async () => {
      await clickDropdownItem(OPTION_IDS[0]);
      await clickDropdownItem(ALL_ID);
      await clickDropdownItem(ALL_ID); // Click again to verify that it doesn't toggle.

      expectSelectedItems([ALL_ID]);
    });

    it('deselects the ALL item when another item is clicked', async () => {
      await clickDropdownItem(OPTION_IDS[0]);

      expectSelectedItems([OPTION_IDS[0]]);
    });
  });

  describe('filter-changed event', () => {
    it('emits filter-changed event when selected item is changed', async () => {
      const ids = [];

      for await (const id of OPTION_IDS) {
        await clickDropdownItem(id);
        ids.push(id);

        expect(wrapper.emitted('filter-changed')[ids.length - 1][0].severity).toEqual(ids);
      }
    });
  });
});
