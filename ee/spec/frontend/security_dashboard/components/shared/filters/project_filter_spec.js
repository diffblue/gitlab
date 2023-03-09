import { GlIntersectionObserver, GlLoadingIcon, GlDropdown, GlSearchBoxByType } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import FilterItem from 'ee/security_dashboard/components/shared/filters/filter_item.vue';
import ProjectFilter from 'ee/security_dashboard/components/shared/filters/project_filter.vue';
import groupProjectsQuery from 'ee/security_dashboard/graphql/queries/group_projects.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';
import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { ALL_ID } from 'ee/security_dashboard/components/shared/filters/constants';
import QuerystringSync from 'ee/security_dashboard/components/shared/filters/querystring_sync.vue';
import DropdownButtonText from 'ee/security_dashboard/components/shared/filters/dropdown_button_text.vue';

Vue.use(VueApollo);

const projects = [
  { id: '1', name: 'Project 1' },
  { id: '2', name: 'Project 2' },
];
const groupFullPath = 'group';
// This is needed so that fetchMore() won't throw an error when it's not mocked out. We can't mock
// it out because we're testing that fetchMore() will make the query start loading, which in turn
// shows the loading spinner.
const cacheConfig = {
  typePolicies: { Query: { fields: { group: { merge: true } } } },
};
const getProjectsRequestHandler = ({ hasNextPage = true } = {}) =>
  jest.fn().mockResolvedValue({
    data: {
      group: {
        id: 'group',
        projects: {
          edges: projects.map((node) => ({ node })),
          pageInfo: { hasNextPage, endCursor: 'abc' },
        },
      },
    },
  });
const defaultProjectsRequestHandler = getProjectsRequestHandler();

describe('Project Filter component', () => {
  let wrapper;

  const createWrapper = ({ projectsRequestHandler = defaultProjectsRequestHandler } = {}) => {
    wrapper = mountExtended(ProjectFilter, {
      apolloProvider: createMockApollo(
        [[groupProjectsQuery, projectsRequestHandler]],
        {},
        cacheConfig,
      ),
      provide: {
        groupFullPath,
        dashboardType: DASHBOARD_TYPES.GROUP,
      },
      stubs: { QuerystringSync: true },
    });
  };

  const findQuerystringSync = () => wrapper.findComponent(QuerystringSync);
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findIntersectionObserver = () => wrapper.findComponent(GlIntersectionObserver);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const isLoadingIconVisible = () => !findLoadingIcon().classes('gl-visibility-hidden');
  const findDropdownItem = (id) => wrapper.findByTestId(id);
  const findDropdownItems = () => wrapper.findAllComponents(FilterItem);

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

  // Create wrapper, open dropdown, and wait for dropdown to render.
  const createWrapperAndOpenDropdown = async (options) => {
    createWrapper(options);
    findDropdown().vm.$emit('show');
    await nextTick();
  };

  // Create wrapper, open dropdown, wait for it to render, and wait for projects query to complete.
  const createWrapperAndWaitForQuery = async (options) => {
    await createWrapperAndOpenDropdown(options);
    await waitForPromises();
  };

  describe('before dropdown is opened', () => {
    it('does not run the projects query', () => {
      createWrapper();

      expect(defaultProjectsRequestHandler).not.toHaveBeenCalled();
    });
  });

  describe('when dropdown is opened', () => {
    it('runs the projects query', async () => {
      await createWrapperAndOpenDropdown();

      expect(defaultProjectsRequestHandler).toHaveBeenCalledTimes(1);
      expect(defaultProjectsRequestHandler).toHaveBeenCalledWith(
        expect.objectContaining({ fullPath: groupFullPath }),
      );
    });

    it('shows the loading icon while the query is running', async () => {
      await createWrapperAndOpenDropdown();

      expect(isLoadingIconVisible()).toBe(true);
    });

    it('hides the loading icon when the query is done', async () => {
      await createWrapperAndWaitForQuery();

      expect(isLoadingIconVisible()).toBe(false);
    });

    it('does not render the loading icon when there is no next page', async () => {
      const projectsRequestHandler = getProjectsRequestHandler({ hasNextPage: false });
      await createWrapperAndOpenDropdown({ projectsRequestHandler });

      expect(findLoadingIcon().exists()).toBe(true);

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('after dropdown is opened and queries are complete', () => {
    beforeEach(async () => {
      await createWrapperAndWaitForQuery();
    });

    describe('QuerystringSync component', () => {
      it('has expected props', () => {
        expect(findQuerystringSync().props()).toMatchObject({
          querystringKey: 'projectId',
          value: wrapper.vm.selected,
        });
      });

      it('receives empty array when All Projects option is clicked', async () => {
        await clickDropdownItem(ALL_ID);

        expect(findQuerystringSync().props('value')).toEqual([]);
      });

      it.each`
        emitted                             | expected
        ${[projects[0].id, projects[1].id]} | ${[projects[0].id, projects[1].id]}
        ${[]}                               | ${[ALL_ID]}
      `('restores selected items - $emitted', async ({ emitted, expected }) => {
        findQuerystringSync().vm.$emit('input', emitted);
        await nextTick();

        expectSelectedItems(expected);
      });

      it.each`
        querystringValues    | expected
        ${['999']}           | ${[ALL_ID]}
        ${['1', '2', '999']} | ${['1', '2']}
        ${['1', '2']}        | ${['1', '2']}
      `(
        'selects dropdown options $expected when querystring values are $querystringValues',
        async ({ querystringValues, expected }) => {
          await createWrapperAndOpenDropdown();
          findQuerystringSync().vm.$emit('input', querystringValues);
          await waitForPromises();

          expectSelectedItems(expected);
        },
      );
    });

    describe('default view', () => {
      it('shows the label', () => {
        expect(wrapper.find('label').text()).toBe(ProjectFilter.i18n.label);
      });

      it('shows the dropdown with correct header text', () => {
        expect(wrapper.findComponent(GlDropdown).props('headerText')).toBe(
          ProjectFilter.i18n.label,
        );
      });

      it('shows the DropdownButtonText component with the correct props', () => {
        expect(wrapper.findComponent(DropdownButtonText).props()).toEqual({
          items: [ProjectFilter.i18n.allItemsText],
          name: ProjectFilter.i18n.label,
        });
      });
    });

    describe('dropdown items', () => {
      it('shows all dropdown items with correct text', () => {
        expect(findDropdownItems()).toHaveLength(projects.length + 1);

        expect(findDropdownItem(ALL_ID).text()).toBe(ProjectFilter.i18n.allItemsText);
        projects.forEach(({ id, name }) => {
          expect(findDropdownItem(id).text()).toBe(name);
        });
      });

      it('allows multiple items to be selected', async () => {
        const ids = [];
        // Deselect everything to begin with.
        clickDropdownItem(ALL_ID);

        for await (const { id } of projects) {
          await clickDropdownItem(id);
          ids.push(id);

          expectSelectedItems(ids);
        }
      });

      it('toggles the item selection when clicked on', async () => {
        // Deselect everything to begin with.
        clickDropdownItem(ALL_ID);

        for await (const { id } of projects) {
          await clickDropdownItem(id);

          expectSelectedItems([id]);

          await clickDropdownItem(id);

          expectSelectedItems([ALL_ID]);
        }
      });

      it('selects All items when created', () => {
        expectSelectedItems([ALL_ID]);
      });

      it('selects ALL item and deselects everything else when it is clicked', async () => {
        await clickDropdownItem(ALL_ID);
        await clickDropdownItem(ALL_ID); // Click again to verify that it doesn't toggle.

        expectSelectedItems([ALL_ID]);
      });

      it('deselects the ALL item when another item is clicked', async () => {
        await clickDropdownItem(ALL_ID);
        await clickDropdownItem(projects[0].id);

        expectSelectedItems([projects[0].id]);
      });
    });

    describe('filter-changed event', () => {
      it('emits filter-changed event when selected item is changed', async () => {
        const ids = [];
        // Deselect everything to begin with.
        await clickDropdownItem(ALL_ID);

        expect(wrapper.emitted('filter-changed')[0][0].projectId).toEqual([]);

        for await (const { id } of projects) {
          await clickDropdownItem(id);
          ids.push(id);

          expect(wrapper.emitted('filter-changed')[ids.length][0].projectId).toEqual(ids);
        }
      });

      it('emits the raw querystring IDs before the valid IDs are fetched', async () => {
        createWrapper();
        const querystringIds = ['1', '2', '999'];
        findQuerystringSync().vm.$emit('input', querystringIds);
        await nextTick();

        expect(wrapper.emitted('filter-changed')[0][0].projectId).toEqual(querystringIds);
      });

      describe('after the valid IDs are fetched', () => {
        beforeEach(createWrapper);

        it('emits the raw querystring IDs if there is at least one valid ID', async () => {
          const querystringIds = ['1', '999', '998'];
          findQuerystringSync().vm.$emit('input', querystringIds);
          await waitForPromises();

          expect(wrapper.emitted('filter-changed')[1][0].projectId).toBe(querystringIds);
        });

        it('emits an empty array if there are no valid IDs', async () => {
          const querystringIds = ['998', '999'];
          findQuerystringSync().vm.$emit('input', querystringIds);
          await waitForPromises();

          expect(wrapper.emitted('filter-changed')[1][0].projectId).toEqual([]);
        });
      });
    });
  });

  describe('all projects dropdown item', () => {
    it.each`
      phrase             | searchTerm | isShown
      ${'shows'}         | ${''}      | ${true}
      ${'does not show'} | ${'abc'}   | ${false}
    `(
      '$phrase the All projects dropdown item when search term is "$searchTerm"',
      async ({ searchTerm, isShown }) => {
        await createWrapperAndOpenDropdown();
        findSearchBox().vm.$emit('input', searchTerm);
        await nextTick();

        expect(findDropdownItem(ALL_ID).exists()).toBe(isShown);
      },
    );
  });

  describe('searching', () => {
    it('clears the dropdown list when the search term is changed and new results are loading', async () => {
      await createWrapperAndWaitForQuery();

      expect(findDropdownItems()).toHaveLength(projects.length + 1);

      findSearchBox().vm.$emit('input', 'abc');
      await nextTick();

      expect(findDropdownItems()).toHaveLength(0);
      expect(isLoadingIconVisible()).toBe(true);
    });
  });

  describe('infinite scrolling', () => {
    it('does not show the intersection observer when there is no next page', async () => {
      const projectsRequestHandler = getProjectsRequestHandler({ hasNextPage: false });
      await createWrapperAndWaitForQuery({ projectsRequestHandler });

      expect(findIntersectionObserver().exists()).toBe(false);
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('shows the intersection observer when there is a next page and the projects query is not running', async () => {
      await createWrapperAndWaitForQuery();

      expect(findIntersectionObserver().exists()).toBe(true);
      expect(isLoadingIconVisible()).toBe(false);
    });

    it('shows the loading icon and fetches the next page when the intersection observer appears', async () => {
      await createWrapperAndWaitForQuery();
      const spy = jest.spyOn(wrapper.vm.$apollo.queries.projects, 'fetchMore');
      findIntersectionObserver().vm.$emit('appear');
      await nextTick();

      expect(findDropdownItems()).toHaveLength(projects.length + 1);
      expect(findIntersectionObserver().exists()).toBe(false);
      expect(isLoadingIconVisible()).toBe(true);
      expect(spy).toHaveBeenCalledTimes(1);
      expect(defaultProjectsRequestHandler).toHaveBeenCalledTimes(2);
    });
  });
});
