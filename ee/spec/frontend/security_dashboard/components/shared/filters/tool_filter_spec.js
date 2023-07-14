import { GlCollapsibleListbox } from '@gitlab/ui';
import { nextTick } from 'vue';
import ToolFilter from 'ee/security_dashboard/components/shared/filters/tool_filter.vue';
import QuerystringSync from 'ee/security_dashboard/components/shared/filters/querystring_sync.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { ALL_ID } from 'ee/security_dashboard/components/shared/filters/constants';
import {
  REPORT_TYPES_WITH_MANUALLY_ADDED,
  REPORT_TYPES_WITH_CLUSTER_IMAGE,
} from 'ee/security_dashboard/store/constants';
import { REPORT_TYPE_PRESETS } from 'ee/security_dashboard/components/shared/vulnerability_report/constants';

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
  const findListBox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findListboxItem = (id) => wrapper.findByTestId(`listbox-item-${id}`);
  const clickListboxItem = (id) => findListboxItem(id).trigger('click');

  const expectSelectedItems = (ids) => {
    expect(findListBox().props('selected')).toMatchObject(ids);
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
      ${[ALL_ID]}                | ${['ALL']}
      ${['SAST']}                | ${['SAST']}
      ${['SAST', 'API_FUZZING']} | ${['SAST', 'API_FUZZING']}
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
      expect(wrapper.find('label').text()).toBe(ToolFilter.i18n.label);
      expect(findListBox().props('headerText')).toBe(ToolFilter.i18n.label);
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
          value: id.toUpperCase(),
          text,
        }));

        expect(findListBox().props('items')).toHaveLength(dropdownOptions.length + 1);
        expect(findListboxItem(ALL_ID).text()).toBe('All tools');
        dropdownOptions.forEach(({ value, text }) => {
          expect(findListboxItem(value).text()).toBe(text);
        });
      },
    );

    it('allows multiple items to be selected', async () => {
      const ids = [];

      for await (const id of OPTION_IDS) {
        await clickListboxItem(id);
        ids.push(id);

        expectSelectedItems(ids);
      }
    });

    it('toggles the item selection when clicked on', async () => {
      for await (const id of OPTION_IDS) {
        await clickListboxItem(id);

        expectSelectedItems([id]);

        await clickListboxItem(id);

        expectSelectedItems([ALL_ID]);
      }
    });

    it('selects ALL item when created', () => {
      expectSelectedItems([ALL_ID]);
    });

    it('selects ALL item and deselects everything else when it is clicked', async () => {
      await clickListboxItem(ALL_ID);
      await clickListboxItem(ALL_ID); // Click again to verify that it doesn't toggle.

      expectSelectedItems([ALL_ID]);
    });

    it('deselects the ALL item when another item is clicked', async () => {
      await clickListboxItem(ALL_ID);
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

        expect(wrapper.emitted('filter-changed')[ids.length - 1][0].reportType).toEqual(ids);
      }
    });

    it('emits filter-changed event with preset report types when ALL item is clicked', async () => {
      await clickListboxItem(ALL_ID);

      expect(wrapper.emitted('filter-changed')[0][0].reportType).toEqual(
        REPORT_TYPE_PRESETS.DEVELOPMENT,
      );
    });
  });
});
