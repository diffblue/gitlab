import { GlDropdown, GlDropdownItem, GlSearchBoxByType, GlLoadingIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import GroupSelect from 'ee/boards/components/group_select.vue';
import defaultState from 'ee/boards/stores/state';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { mockList } from 'jest/boards/mock_data';
import { mockGroup0, mockSubGroups } from '../mock_data';

describe('GroupSelect component', () => {
  let wrapper;
  let store;

  const findLabel = () => wrapper.findByTestId('header-label');
  const findGlDropdown = () => wrapper.findComponent(GlDropdown);
  const findGlDropdownLoadingIcon = () =>
    findGlDropdown().find('button:first-child').findComponent(GlLoadingIcon);
  const findGlSearchBoxByType = () => wrapper.findComponent(GlSearchBoxByType);
  const findGlDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findFirstGlDropdownItem = () => findGlDropdownItems().at(0);
  const findInMenuLoadingIcon = () => wrapper.findByTestId('dropdown-text-loading-icon');
  const findEmptySearchMessage = () => wrapper.findByTestId('empty-result-message');

  const createStore = ({ state = {}, subGroups, selectedGroup, moreGroupsLoading = false }) => {
    Vue.use(Vuex);

    store = new Vuex.Store({
      state: {
        ...state,
        subGroups,
        selectedGroup,
        subGroupsFlags: {
          isLoading: moreGroupsLoading,
          pageInfo: {
            hasNextPage: false,
          },
        },
      },
      actions: {
        fetchSubGroups: jest.fn(),
        setSelectedGroup: jest.fn(),
      },
    });
  };

  const createWrapper = ({
    state = defaultState,
    subGroups = [],
    selectedGroup = {},
    loading = false,
    moreGroupsLoading = false,
  } = {}) => {
    createStore({
      state,
      subGroups,
      selectedGroup,
      loading,
      moreGroupsLoading,
    });

    wrapper = extendedWrapper(
      mount(GroupSelect, {
        propsData: {
          list: mockList,
        },
        data() {
          return {
            initialLoading: loading,
          };
        },
        store,
        provide: {
          groupId: 1,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('displays a header title', () => {
    createWrapper();

    expect(findLabel().text()).toBe('Groups');
  });

  it('renders a default dropdown text', () => {
    createWrapper();

    expect(findGlDropdown().exists()).toBe(true);
    expect(findGlDropdown().text()).toContain('Loading groups');
  });

  describe('when mounted', () => {
    it('displays a loading icon while descendant groups are being fetched', async () => {
      createWrapper({ loading: true });
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({ initialLoading: true });
      await nextTick();

      expect(findGlDropdownLoadingIcon().exists()).toBe(true);
    });
  });

  describe('when dropdown menu is open', () => {
    describe('by default', () => {
      beforeEach(() => {
        createWrapper({ subGroups: mockSubGroups });
      });

      it('shows GlSearchBoxByType with default attributes', () => {
        expect(findGlSearchBoxByType().exists()).toBe(true);
        expect(findGlSearchBoxByType().vm.$attrs).toMatchObject({
          placeholder: 'Search groups',
          debounce: '250',
        });
      });

      it("displays the fetched groups's name", () => {
        expect(findFirstGlDropdownItem().exists()).toBe(true);
        expect(findFirstGlDropdownItem().text()).toContain(mockGroup0.name);
      });

      it("doesn't render loading icon in the menu", () => {
        expect(findInMenuLoadingIcon().isVisible()).toBe(false);
      });

      it('does not render empty search result message', () => {
        expect(findEmptySearchMessage().exists()).toBe(false);
      });
    });

    describe('when no groups are being returned', () => {
      it('renders empty search result message', () => {
        createWrapper();

        expect(findEmptySearchMessage().exists()).toBe(true);
      });
    });

    describe('when a group is selected', () => {
      it('renders the name of the selected group', () => {
        createWrapper({ subGroups: mockSubGroups, selectedGroup: mockGroup0 });

        expect(findGlDropdown().find('.gl-new-dropdown-button-text').text()).toBe(mockGroup0.name);
      });
    });

    describe('when groups are loading', () => {
      it('displays and hides gl-loading-icon while and after fetching data', () => {
        createWrapper({ moreGroupsLoading: true });

        expect(findInMenuLoadingIcon().isVisible()).toBe(true);
      });
    });
  });
});
