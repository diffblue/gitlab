import { GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import { getByText } from '@testing-library/dom';
import { shallowMount } from '@vue/test-utils';
import DevopsAdoptionAddDropdown from 'ee/analytics/devops_reports/devops_adoption/components/devops_adoption_add_dropdown.vue';
import DevopsAdoptionEmptyState from 'ee/analytics/devops_reports/devops_adoption/components/devops_adoption_empty_state.vue';
import DevopsAdoptionSection from 'ee/analytics/devops_reports/devops_adoption/components/devops_adoption_section.vue';
import DevopsAdoptionTable from 'ee/analytics/devops_reports/devops_adoption/components/devops_adoption_table.vue';
import { DEVOPS_ADOPTION_TABLE_CONFIGURATION } from 'ee/analytics/devops_reports/devops_adoption/constants';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { devopsAdoptionNamespaceData, groupNodes } from '../mock_data';

describe('DevopsAdoptionSection', () => {
  let wrapper;

  const createComponent = (props) => {
    wrapper = extendedWrapper(
      shallowMount(DevopsAdoptionSection, {
        propsData: {
          isLoading: false,
          hasEnabledNamespaceData: true,
          timestamp: '2020-10-31 23:59',
          hasGroupData: true,
          cols: DEVOPS_ADOPTION_TABLE_CONFIGURATION[0].cols,
          enabledNamespaces: devopsAdoptionNamespaceData,
          groups: groupNodes,
          searchTerm: '',
          isLoadingGroups: false,
          hasSubgroups: true,
          ...props,
        },
        stubs: {
          GlSprintf,
        },
      }),
    );
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findTableHeaderSection = () => wrapper.findByTestId('tableHeader');
  const findTable = () => wrapper.findComponent(DevopsAdoptionTable);
  const findEmptyState = () => wrapper.findComponent(DevopsAdoptionEmptyState);
  const findDropdown = () => wrapper.findComponent(DevopsAdoptionAddDropdown);

  describe('while loading', () => {
    beforeEach(() => {
      createComponent({ isLoading: true });
    });

    it('displays a loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not display the table header section', () => {
      expect(findTableHeaderSection().exists()).toBe(false);
    });

    it('does not display the table', () => {
      expect(findTable().exists()).toBe(false);
    });
  });

  describe('with enabledNamespace data', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not display a loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('does not display an empty state', () => {
      expect(findEmptyState().exists()).toBe(false);
    });

    it('displays the table header section', () => {
      expect(findTableHeaderSection().exists()).toBe(true);
    });

    it('displays the table', () => {
      expect(findTableHeaderSection().exists()).toBe(true);
    });
  });

  describe('with no enabledNamespace data', () => {
    beforeEach(() => {
      createComponent({ hasEnabledNamespaceData: false });
    });

    it('displays an empty state', () => {
      expect(findEmptyState().exists()).toBe(true);
    });
  });

  describe('table header section', () => {
    it('displays the header message with timestamp', () => {
      createComponent();

      const text =
        'Feature adoption is based on usage in the previous calendar month. Data is updated at the beginning of each month. Last updated: 2020-10-31 23:59.';
      expect(getByText(wrapper.element, text)).not.toBeNull();
    });

    it('displays the add groups dropdown', () => {
      createComponent();

      expect(findDropdown().exists()).toBe(true);
    });
  });
});
