import { GlTab, GlBadge, GlButton, GlTabs, GlDisclosureDropdown } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import { nextTick } from 'vue';
import RequirementsTabs from 'ee/requirements/components/requirements_tabs.vue';
import { filterState } from 'ee/requirements/constants';

import { mockRequirementsCount } from '../mock_data';

const createComponent = ({
  filterBy = filterState.opened,
  requirementsCount = mockRequirementsCount,
  showCreateForm = false,
  canCreateRequirement = true,
} = {}) =>
  shallowMount(RequirementsTabs, {
    propsData: {
      filterBy,
      requirementsCount,
      showCreateForm,
      canCreateRequirement,
    },
    stubs: {
      GlTabs,
      GlTab,
    },
  });

describe('RequirementsTabs', () => {
  let wrapper;

  const findGlButton = () => wrapper.findComponent(GlButton);
  const findGlDisclosureDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findAllGlTabs = () => wrapper.findAllComponents(GlTab);

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('template', () => {
    it('renders "Open" tab', () => {
      const tabEl = findAllGlTabs().at(0);

      expect(tabEl.text()).toContain('Open');
      expect(tabEl.findComponent(GlBadge).text()).toBe(`${mockRequirementsCount.OPENED}`);
    });

    it('renders "Archived" tab', () => {
      const tabEl = findAllGlTabs().at(1);

      expect(tabEl.text()).toContain('Archived');
      expect(tabEl.findComponent(GlBadge).text()).toBe(`${mockRequirementsCount.ARCHIVED}`);
    });

    it('renders "All" tab', () => {
      const tabEl = findAllGlTabs().at(2);

      expect(tabEl.text()).toContain('All');
      expect(tabEl.findComponent(GlBadge).text()).toBe(`${mockRequirementsCount.ALL}`);
    });

    it('renders class `active` on currently selected tab', () => {
      const tabEl = findAllGlTabs().at(0);

      expect(tabEl.attributes('active')).toBeDefined();
    });

    it('renders "New requirement" button when current tab is "Open" tab', async () => {
      wrapper.setProps({
        filterBy: filterState.opened,
      });

      await nextTick();

      expect(findGlButton().exists()).toBe(true);
      expect(findGlButton().text()).toBe('New requirement');
    });

    it('does not render "New requirement" button when current tab is not "Open" tab', async () => {
      wrapper.setProps({
        filterBy: filterState.archived,
      });

      await nextTick();

      expect(findGlButton().exists()).toBe(false);
    });

    it('does not render "New requirement" button when `canCreateRequirement` prop is false', async () => {
      wrapper.setProps({
        filterBy: filterState.opened,
        canCreateRequirement: false,
      });

      await nextTick();

      expect(findGlButton().exists()).toBe(false);
    });

    it('disables "New requirement" button when `showCreateForm` is true', async () => {
      wrapper.setProps({
        showCreateForm: true,
      });

      await nextTick();

      expect(findGlButton().props('disabled')).toBe(true);
      expect(findGlDisclosureDropdown().props('disabled')).toBe(true);
    });
  });
});
