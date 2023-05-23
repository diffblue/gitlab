import { GlCollapsibleListbox } from '@gitlab/ui';
import SeverityFilter, {
  SEVERITY_LEVEL_ITEMS,
  FILTER_ITEMS,
} from 'ee/security_dashboard/components/shared/filters/severity_filter.vue';
import { ALL_ID } from 'ee/security_dashboard/components/shared/filters/constants';
import QuerystringSync from 'ee/security_dashboard/components/shared/filters/querystring_sync.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';

const OPTION_IDS = SEVERITY_LEVEL_ITEMS.map(({ value }) => value);

describe('Severity Filter component', () => {
  let wrapper;

  const createWrapper = () => {
    wrapper = mountExtended(SeverityFilter, {
      stubs: { QuerystringSync: true },
    });
  };

  const findQuerystringSync = () => wrapper.findComponent(QuerystringSync);
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findListboxItem = (id) => wrapper.findByTestId(`listbox-item-${id}`);

  const clickListboxItem = (id) => findListboxItem(id).trigger('click');

  const expectSelectedItems = (ids) => {
    expect(findListbox().props('selected')).toEqual(ids);
  };

  beforeEach(() => {
    createWrapper();
  });

  describe('QuerystringSync component', () => {
    it('has expected props', () => {
      expect(findQuerystringSync().props()).toMatchObject({
        querystringKey: 'severity',
        value: [ALL_ID],
        validValues: OPTION_IDS,
      });
    });

    it('receives "ALL_ID" when All Statuses option is clicked', async () => {
      await clickListboxItem(ALL_ID);

      expect(findQuerystringSync().props('value')).toEqual([ALL_ID]);
    });

    it.each`
      emitted               | expected
      ${['HIGH', 'MEDIUM']} | ${['HIGH', 'MEDIUM']}
      ${[]}                 | ${[ALL_ID]}
    `('restores selected items - $emitted', async ({ emitted, expected }) => {
      await findQuerystringSync().vm.$emit('input', emitted);

      expectSelectedItems(expected);
    });
  });

  describe('default view', () => {
    it('shows the label', () => {
      expect(wrapper.find('label').text()).toBe(SeverityFilter.i18n.label);
    });

    it('shows the ListBox component with the correct props', () => {
      expect(findListbox().props()).toMatchObject({
        items: FILTER_ITEMS,
        toggleText: 'All severities',
        multiple: true,
        block: true,
      });
    });
  });

  describe('dropdown items', () => {
    it.each(OPTION_IDS)('toggles the item selection when clicked on %s', async (id) => {
      await clickListboxItem(id);

      expectSelectedItems([id]);

      await clickListboxItem(id);

      expectSelectedItems([ALL_ID]);
    });

    it('selects ALL item when created', () => {
      expectSelectedItems([ALL_ID]);
    });

    it('selects ALL item and deselects everything else when it is clicked', async () => {
      await clickListboxItem(OPTION_IDS[0]);
      await clickListboxItem(ALL_ID);
      await clickListboxItem(ALL_ID); // Click again to verify that it doesn't toggle.

      expectSelectedItems([ALL_ID]);
    });

    it('deselects the ALL item when another item is clicked', async () => {
      await clickListboxItem(OPTION_IDS[0]);

      expectSelectedItems([OPTION_IDS[0]]);
    });
  });

  describe('filter-changed event', () => {
    it('emits filter-changed event when selected item is changed', async () => {
      const ids = [];

      for await (const id of OPTION_IDS) {
        await clickListboxItem(id);
        ids.push(id);

        expect(wrapper.emitted('filter-changed').at(-1)[0].severity).toEqual(ids);
      }
    });
  });
});
