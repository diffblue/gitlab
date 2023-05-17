import { GlCollapsibleListbox } from '@gitlab/ui';
import { nextTick } from 'vue';
import StatusFilter, {
  DEFAULT_IDS,
  VALID_IDS,
  DROPDOWN_OPTIONS,
} from 'ee/security_dashboard/components/shared/filters/status_filter.vue';
import { ALL_ID } from 'ee/security_dashboard/components/shared/filters/constants';
import QuerystringSync from 'ee/security_dashboard/components/shared/filters/querystring_sync.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';

const OPTION_IDS = DROPDOWN_OPTIONS.map(({ value }) => value);

describe('Status Filter component', () => {
  let wrapper;

  const createWrapper = () => {
    wrapper = mountExtended(StatusFilter, {
      stubs: { QuerystringSync: true },
    });
  };

  const findQuerystringSync = () => wrapper.findComponent(QuerystringSync);
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);

  const clickDropdownItem = async (...ids) => {
    findListbox().vm.$emit('select', [...ids]);
    await nextTick();
  };

  beforeEach(() => {
    createWrapper();
  });

  describe('QuerystringSync component', () => {
    it('has expected props', () => {
      expect(findQuerystringSync().props()).toMatchObject({
        querystringKey: 'state',
        value: DEFAULT_IDS,
        validValues: VALID_IDS,
      });
    });

    it('receives ALL_ID when All Statuses option is clicked', async () => {
      await clickDropdownItem(ALL_ID);

      expect(findQuerystringSync().props('value')).toEqual([ALL_ID]);
    });

    it.each`
      emitted                      | expected
      ${['CONFIRMED', 'RESOLVED']} | ${['CONFIRMED', 'RESOLVED']}
      ${[ALL_ID]}                  | ${[ALL_ID]}
    `('restores selected items - $emitted', async ({ emitted, expected }) => {
      findQuerystringSync().vm.$emit('input', emitted);
      await nextTick();

      expect(findListbox().props('selected')).toEqual(expected);
    });
  });

  describe('default view', () => {
    it('shows the label', () => {
      expect(wrapper.find('label').text()).toBe(StatusFilter.i18n.label);
    });

    it('shows the dropdown with correct header text', () => {
      expect(findListbox().props('headerText')).toBe(StatusFilter.i18n.label);
    });

    it('shows the placeholder correctly', async () => {
      await clickDropdownItem('CONFIRMED', 'RESOLVED');
      expect(findListbox().props('toggleText')).toBe('Confirmed +1 more');
    });
  });

  describe('dropdown items', () => {
    it('shows all dropdown items with correct text', () => {
      expect(findListbox().props('items')).toEqual(DROPDOWN_OPTIONS);
    });

    it('toggles the item selection when clicked on', async () => {
      await clickDropdownItem('CONFIRMED', 'RESOLVED');
      expect(findListbox().props('selected')).toEqual(['CONFIRMED', 'RESOLVED']);
      await clickDropdownItem('DETECTED');
      expect(findListbox().props('selected')).toEqual(['DETECTED']);
    });

    it('selects default items when created', () => {
      expect(findListbox().props('selected')).toEqual(DEFAULT_IDS);
    });

    it('selects ALL item and deselects everything else when it is clicked', async () => {
      await clickDropdownItem(ALL_ID);
      expect(findListbox().props('selected')).toEqual([ALL_ID]);
    });

    it('deselects the ALL item when another item is clicked', async () => {
      await clickDropdownItem(ALL_ID, 'CONFIRMED');
      expect(findListbox().props('selected')).toEqual(['CONFIRMED']);
    });
  });

  describe('filter-changed event', () => {
    it('emits filter-changed event with default IDs when created', () => {
      expect(wrapper.emitted('filter-changed')[0][0].state).toEqual(DEFAULT_IDS);
    });

    it('emits filter-changed event when selected item is changed', async () => {
      await clickDropdownItem(ALL_ID);

      expect(wrapper.emitted('filter-changed')[1][0].state).toEqual([]);

      await clickDropdownItem(...OPTION_IDS);

      expect(wrapper.emitted('filter-changed')[2][0].state).toEqual(
        OPTION_IDS.filter((id) => id !== ALL_ID),
      );
    });
  });
});
