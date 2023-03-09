import { GlDropdown } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import FilterItem from 'ee/security_dashboard/components/shared/filters/filter_item.vue';
import ToolWithVendorFilter, {
  VENDOR_GITLAB,
  REPORT_TYPES,
  NULL_SCANNER_ID,
} from 'ee/security_dashboard/components/shared/filters/tool_with_vendor_filter.vue';
import QuerystringSync from 'ee/security_dashboard/components/shared/filters/querystring_sync.vue';
import { ALL_ID } from 'ee/security_dashboard/components/shared/filters/constants';
import { TYPENAME_VULNERABILITIES_SCANNER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import DropdownButtonText from 'ee/security_dashboard/components/shared/filters/dropdown_button_text.vue';

const GITLAB_SCANNERS = [
  { id: 1, vendor: VENDOR_GITLAB, report_type: 'DEPENDENCY_SCANNING' },
  { id: 2, vendor: VENDOR_GITLAB, report_type: 'DEPENDENCY_SCANNING' },
  { id: 3, vendor: VENDOR_GITLAB, report_type: 'SAST' },
  { id: 4, vendor: VENDOR_GITLAB, report_type: 'SAST' },
  { id: 5, vendor: VENDOR_GITLAB, report_type: 'SECRET_DETECTION' },
  { id: 6, vendor: VENDOR_GITLAB, report_type: 'CONTAINER_SCANNING' },
  { id: 7, vendor: VENDOR_GITLAB, report_type: 'DAST' },
  { id: 8, vendor: VENDOR_GITLAB, report_type: 'DAST' },
];

const CUSTOM_SCANNERS = [
  { id: 9, vendor: 'Custom', report_type: 'SAST' },
  { id: 10, vendor: 'Custom', report_type: 'SAST' },
  { id: 11, vendor: 'Custom', report_type: 'DAST' },
];

const EMPTY_VENDOR_SCANNERS = [
  { id: 12, vendor: '', report_type: 'SAST' },
  { id: 13, vendor: '   ', report_type: 'SAST' },
];

describe('Tool With Vendor Filter component', () => {
  let wrapper;

  const createWrapper = ({ scanners = CUSTOM_SCANNERS } = {}) => {
    wrapper = mountExtended(ToolWithVendorFilter, {
      provide: { scanners },
      stubs: {
        QuerystringSync: true,
      },
    });
  };

  const findQuerystringSync = () => wrapper.findComponent(QuerystringSync);
  const findDropdownHeader = (vendor) => wrapper.findByTestId(`${vendor}:header`);
  const findDropdownDivider = (vendor) => wrapper.findByTestId(`${vendor}:divider`);
  const findDropdownItems = () => wrapper.findAllComponents(FilterItem);
  const findDropdownItem = (vendor, id) => wrapper.findByTestId(`${vendor}.${id}`);

  const clickDropdownItem = async (vendor, id) => {
    if (vendor && id) {
      findDropdownItem(vendor, id).trigger('click');
      await nextTick();
    } else {
      await findDropdownHeader(vendor).trigger('click');
    }
  };

  const expectSelectedItems = (ids) => {
    const checkedItems = findDropdownItems()
      .wrappers.filter((item) => item.props('isChecked'))
      .map((item) => item.attributes('data-testid'));

    expect(checkedItems.sort()).toEqual(ids.sort());
  };

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    describe('QuerystringSync component', () => {
      it('has expected props', () => {
        expect(findQuerystringSync().props()).toMatchObject({
          querystringKey: 'scanner',
          value: [],
        });
      });

      it('receives empty array when All Statuses option is clicked', async () => {
        // Click on another item first so that we can verify clicking on the ALL item changes it.
        await clickDropdownItem(VENDOR_GITLAB, 'SAST');
        wrapper.findByTestId(ALL_ID).vm.$emit('click');
        await nextTick();

        expect(findQuerystringSync().props('value')).toEqual([]);
      });

      it.each`
        emitted                           | expected
        ${['GitLab.SAST', 'GitLab.DAST']} | ${['GitLab.SAST', 'GitLab.DAST']}
        ${['GitLab.SAST', 'Custom.SAST']} | ${['GitLab.SAST', 'Custom.SAST']}
        ${[]}                             | ${[ALL_ID]}
      `('restores selected items - $emitted', async ({ emitted, expected }) => {
        findQuerystringSync().vm.$emit('input', emitted);
        await nextTick();

        expectSelectedItems(expected);
      });
    });

    describe('default view', () => {
      it('shows the label', () => {
        expect(wrapper.find('label').text()).toBe(ToolWithVendorFilter.i18n.label);
      });

      it('shows the dropdown with correct header text', () => {
        expect(wrapper.findComponent(GlDropdown).props('headerText')).toBe(
          ToolWithVendorFilter.i18n.label,
        );
      });

      it('shows the DropdownButtonText component with the correct props', () => {
        expect(wrapper.findComponent(DropdownButtonText).props()).toMatchObject({
          items: [ToolWithVendorFilter.i18n.allItemsText],
          name: ToolWithVendorFilter.i18n.label,
        });
      });
    });
  });

  describe('GitLab scanners only', () => {
    it('shows the dropdown items with no headers or dividers', () => {
      const ids = Object.keys(REPORT_TYPES);
      createWrapper({ scanners: GITLAB_SCANNERS });

      expect(findDropdownItems()).toHaveLength(ids.length + 1);
      expect(findDropdownHeader(VENDOR_GITLAB).exists()).toBe(false);
      expect(findDropdownDivider(VENDOR_GITLAB).exists()).toBe(false);

      ids.forEach((id) => {
        expect(findDropdownItem(VENDOR_GITLAB, id).exists()).toBe(true);
      });
    });

    it('does not show CLUSTER_IMAGE_SCANNING dropdown item', () => {
      const CLUSTER_IMAGE_SCANNING = 'CLUSTER_IMAGE_SCANNING';
      const scanners = [
        ...GITLAB_SCANNERS,
        { id: 0, vendor: VENDOR_GITLAB, report_type: CLUSTER_IMAGE_SCANNING },
      ];

      createWrapper({ scanners });

      expect(findDropdownItem(VENDOR_GITLAB, CLUSTER_IMAGE_SCANNING).exists()).toBe(false);
    });
  });

  describe('GitLab and custom scanners', () => {
    it.each`
      vendor           | ids
      ${VENDOR_GITLAB} | ${Object.keys(REPORT_TYPES)}
      ${'Custom'}      | ${['SAST', 'DAST']}
    `('shows the dropdown items for vendor $vendor', ({ vendor, ids }) => {
      createWrapper();

      expect(findDropdownHeader(vendor).exists()).toBe(true);
      expect(findDropdownDivider(vendor).exists()).toBe(true);

      ids.forEach((id) => {
        expect(findDropdownItem(vendor, id).exists()).toBe(true);
      });
    });

    it('does not show header for empty vendors', () => {
      createWrapper({ scanners: EMPTY_VENDOR_SCANNERS });

      EMPTY_VENDOR_SCANNERS.forEach(({ vendor }) => {
        expect(findDropdownHeader(vendor).exists()).toBe(false);
        expect(findDropdownDivider(vendor).exists()).toBe(false);
      });
    });

    describe('vendor header click', () => {
      it('selects all items for a vendor when the vendor header is clicked', async () => {
        createWrapper();

        await clickDropdownItem(VENDOR_GITLAB);

        expectSelectedItems(Object.keys(REPORT_TYPES).map((id) => `${VENDOR_GITLAB}.${id}`));
      });

      it('selects all items for a vendor when the vendor header is clicked and some items are selected', async () => {
        createWrapper();
        await clickDropdownItem(VENDOR_GITLAB, 'DAST');
        await clickDropdownItem(VENDOR_GITLAB);

        expectSelectedItems(Object.keys(REPORT_TYPES).map((id) => `${VENDOR_GITLAB}.${id}`));
      });

      it('deselects all items for a vendor when the vendor header is clicked and all items are selected', async () => {
        createWrapper();
        // Click the header to select all items.
        await clickDropdownItem(VENDOR_GITLAB);
        // Sanity check to verify that all items were selected.
        expectSelectedItems(Object.keys(REPORT_TYPES).map((id) => `${VENDOR_GITLAB}.${id}`));
        // Click the header again to deselect all items.
        await clickDropdownItem(VENDOR_GITLAB);

        expectSelectedItems([ALL_ID]);
      });
    });
  });

  describe('filter-changed event', () => {
    it('emits expected event data for selected items', async () => {
      const scanners = [...GITLAB_SCANNERS, ...CUSTOM_SCANNERS];
      const ids = scanners
        .map(({ id }) => convertToGraphQLId(TYPENAME_VULNERABILITIES_SCANNER, id))
        .sort();

      createWrapper({ scanners });
      clickDropdownItem(VENDOR_GITLAB);
      await clickDropdownItem('Custom');

      expect(wrapper.emitted('filter-changed')[0][0].scannerId.sort()).toEqual(ids);
    });

    it('emits null scanner ID when there are selected items but no scanner IDs', async () => {
      createWrapper({ scanners: [] });
      await clickDropdownItem(VENDOR_GITLAB, 'SAST');

      expect(wrapper.emitted('filter-changed')[0][0]).toEqual({ scannerId: [NULL_SCANNER_ID] });
    });
  });
});
