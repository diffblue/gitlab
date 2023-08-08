import { GlCollapsibleListbox } from '@gitlab/ui';
import { nextTick } from 'vue';
import StatusFilter, {
  GROUPS,
} from 'ee/security_dashboard/components/shared/filters/status_with_dismissal_filter.vue';
import { ALL_ID as ALL_STATUS_VALUE } from 'ee/security_dashboard/components/shared/filters/constants';
import QuerystringSync from 'ee/security_dashboard/components/shared/filters/querystring_sync.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';

const STATUS_OPTION_VALUES = GROUPS[0].options.map(({ value }) => value);
const DEFAULT_VALUES = ['DETECTED', 'CONFIRMED'];

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
        value: DEFAULT_VALUES,
        validValues: [
          'ALL',
          'DETECTED',
          'CONFIRMED',
          'RESOLVED',
          'DISMISSED',
          'ACCEPTABLE_RISK',
          'FALSE_POSITIVE',
          'MITIGATING_CONTROL',
          'USED_IN_TESTS',
          'NOT_APPLICABLE',
        ],
      });
    });

    it('receives ALL_STATUS_VALUE when All Statuses option is clicked', async () => {
      await clickDropdownItem(ALL_STATUS_VALUE);

      expect(findQuerystringSync().props('value')).toEqual([ALL_STATUS_VALUE]);
    });

    it.each`
      emitted                      | expected
      ${['CONFIRMED', 'RESOLVED']} | ${['CONFIRMED', 'RESOLVED']}
      ${[ALL_STATUS_VALUE]}        | ${[ALL_STATUS_VALUE]}
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

  describe('toggle text', () => {
    it('shows "Confirmed +1 more" by default', () => {
      expect(findListbox().props('toggleText')).toBe('Needs triage +1 more');
    });

    it('shows "Dismissed (all reasons)" when only "All dismissal reasons" option is selected', async () => {
      await clickDropdownItem('DISMISSED');
      expect(findListbox().props('toggleText')).toBe('Dismissed (all reasons)');
    });

    it('shows "Dismissed (2 reasons)" when only 2 dismissal reasons are selected', async () => {
      await clickDropdownItem('FALSE_POSITIVE', 'ACCEPTABLE_RISK');
      expect(findListbox().props('toggleText')).toBe('Dismissed (2 reasons)');
    });

    it('shows "Confirmed +1 more" when confirmed and a dismissal reason are selected', async () => {
      await clickDropdownItem('CONFIRMED', 'FALSE_POSITIVE');
      expect(findListbox().props('toggleText')).toBe('Confirmed +1 more');
    });
  });

  describe('dropdown items', () => {
    it('shows all dropdown items with correct text', () => {
      expect(findListbox().props('items')).toEqual(GROUPS);
    });

    it('toggles the item selection when clicked on', async () => {
      await clickDropdownItem('CONFIRMED', 'RESOLVED');
      expect(findListbox().props('selected')).toEqual(['CONFIRMED', 'RESOLVED']);
      await clickDropdownItem('DETECTED');
      expect(findListbox().props('selected')).toEqual(['DETECTED']);
    });

    it('selects default items when created', () => {
      expect(findListbox().props('selected')).toEqual(DEFAULT_VALUES);
    });

    describe('ALL item', () => {
      it('selects "All statuses" and deselects everything else when it is clicked', async () => {
        await clickDropdownItem(ALL_STATUS_VALUE);
        expect(findListbox().props('selected')).toEqual([ALL_STATUS_VALUE]);
      });

      it('selects "All statuses" when nothing is selected', async () => {
        await clickDropdownItem();
        expect(findListbox().props('selected')).toEqual([ALL_STATUS_VALUE]);
      });

      it('deselects the "All statuses" when another item is clicked', async () => {
        await clickDropdownItem(ALL_STATUS_VALUE, 'CONFIRMED');
        expect(findListbox().props('selected')).toEqual(['CONFIRMED']);
      });
    });

    describe('dismissal reasons', () => {
      it('allows selecting status and dismissal reason', async () => {
        await clickDropdownItem('RESOLVED', 'FALSE_POSITIVE');
        expect(findListbox().props('selected')).toEqual(['RESOLVED', 'FALSE_POSITIVE']);
      });

      it('deselects "All dismissal reason" when selecting a dismissal reason', async () => {
        await clickDropdownItem('DISMISSED', 'FALSE_POSITIVE');
        expect(findListbox().props('selected')).toEqual(['FALSE_POSITIVE']);
      });
    });
  });

  describe('filter-changed event', () => {
    it('is emitted with DEFAULT_VALUES when created', () => {
      expect(wrapper.emitted('filter-changed')[0][0]).toEqual({
        state: DEFAULT_VALUES,
        dismissalReason: [],
      });
    });

    it('is emitted with empty `state` when "All statuses" is selected', async () => {
      await clickDropdownItem(ALL_STATUS_VALUE);

      expect(wrapper.emitted('filter-changed')[1][0]).toEqual({ state: [], dismissalReason: [] });
    });

    it('is emitted with correct `state` when selected status is changed', async () => {
      await clickDropdownItem(...STATUS_OPTION_VALUES);

      expect(wrapper.emitted('filter-changed')[1][0]).toEqual({
        state: STATUS_OPTION_VALUES.filter((id) => id !== ALL_STATUS_VALUE),
        dismissalReason: [],
      });
    });

    it('is emitted with correct `state` and `dismissalReason` when status and dismissal reason is changed', async () => {
      await clickDropdownItem('RESOLVED', 'NEEDS_TRIAGE', 'FALSE_POSITIVE', 'ACCEPTABLE_RISK');

      expect(wrapper.emitted('filter-changed')[1][0]).toEqual({
        state: ['RESOLVED', 'NEEDS_TRIAGE'],
        dismissalReason: ['FALSE_POSITIVE', 'ACCEPTABLE_RISK'],
      });
    });

    it('is emitted without "DISMISSED" status when dismissal reason is selected', async () => {
      await clickDropdownItem('FALSE_POSITIVE');

      expect(wrapper.emitted('filter-changed')[1][0]).toEqual({
        state: [],
        dismissalReason: ['FALSE_POSITIVE'],
      });
    });
  });
});
