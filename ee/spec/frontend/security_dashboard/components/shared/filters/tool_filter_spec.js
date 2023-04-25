import { GlDropdown } from '@gitlab/ui';
import { nextTick } from 'vue';
import ToolFilter from 'ee/security_dashboard/components/shared/filters/tool_filter.vue';
import QuerystringSync from 'ee/security_dashboard/components/shared/filters/querystring_sync.vue';
import DropdownButtonText from 'ee/security_dashboard/components/shared/filters/dropdown_button_text.vue';
import FilterItem from 'ee/security_dashboard/components/shared/filters/filter_item.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { ALL_ID } from 'ee/security_dashboard/components/shared/filters/constants';
import {
  REPORT_TYPES_WITH_MANUALLY_ADDED,
  REPORT_TYPES_WITH_CLUSTER_IMAGE,
} from 'ee/security_dashboard/store/constants';

const OPTION_IDS = Object.keys(REPORT_TYPES_WITH_MANUALLY_ADDED).map((id) => id.toUpperCase());

describe('Tool Filter component', () => {
  let wrapper;

  const createWrapper = ({ dashboardType = 'group' } = {}) => {
    wrapper = mountExtended(ToolFilter, {
      provide: { dashboardType },
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
        querystringKey: 'reportType',
        value: [],
      });
    });

    it.each`
      emitted                    | expected
      ${[]}                      | ${[ALL_ID]}
      ${[ALL_ID]}                | ${[]}
      ${['SAST']}                | ${['SAST']}
      ${['SAST', 'API_FUZZING']} | ${['API_FUZZING', 'SAST']}
    `('restores selected items - $emitted', async ({ emitted, expected }) => {
      findQuerystringSync().vm.$emit('input', emitted);
      await nextTick();

      expectSelectedItems(expected);
    });
  });

  describe('default view', () => {
    it('shows the label', () => {
      expect(wrapper.find('label').text()).toBe('Tool');
    });

    it('shows the dropdown with correct header text', () => {
      expect(wrapper.findComponent(GlDropdown).props('headerText')).toBe('Tool');
    });

    it('shows the DropdownButtonText component with the correct props', () => {
      expect(wrapper.findComponent(DropdownButtonText).props()).toMatchObject({
        items: ['All tools'],
        name: 'Tool',
      });
    });
  });

  describe('dropdown items', () => {
    it.each`
      dashboardType | reportTypes
      ${'group'}    | ${REPORT_TYPES_WITH_MANUALLY_ADDED}
      ${'instance'} | ${REPORT_TYPES_WITH_MANUALLY_ADDED}
      ${'pipeline'} | ${REPORT_TYPES_WITH_CLUSTER_IMAGE}
    `(
      'shows all dropdown items with correct text for dashboard type $dashboardType',
      ({ dashboardType, reportTypes }) => {
        createWrapper({ dashboardType });
        const dropdownOptions = Object.entries(reportTypes).map(([id, text]) => ({
          id: id.toUpperCase(),
          text,
        }));

        expect(findDropdownItems()).toHaveLength(dropdownOptions.length + 1);
        expect(findDropdownItem(ALL_ID).text()).toBe('All tools');
        dropdownOptions.forEach(({ id, text }) => {
          expect(findDropdownItem(id).text()).toBe(text);
        });
      },
    );

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
      await clickDropdownItem(ALL_ID);
      await clickDropdownItem(ALL_ID); // Click again to verify that it doesn't toggle.

      expectSelectedItems([ALL_ID]);
    });

    it('deselects the ALL item when another item is clicked', async () => {
      await clickDropdownItem(ALL_ID);
      await clickDropdownItem(OPTION_IDS[0]);

      expectSelectedItems([OPTION_IDS[0]]);
    });
  });

  describe('filter-changed event', () => {
    it('emits filter-changed event when selected item is changed', async () => {
      const ids = [];
      await clickDropdownItem(ALL_ID);

      expect(wrapper.emitted('filter-changed')[0][0].reportType).toEqual([]);

      for await (const id of OPTION_IDS) {
        await clickDropdownItem(id);
        ids.push(id);

        expect(wrapper.emitted('filter-changed')[ids.length][0].reportType).toEqual(ids);
      }
    });
  });
});
