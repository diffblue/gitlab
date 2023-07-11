import { GlLoadingIcon, GlCollapsibleListbox } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import ProjectFilter from 'ee/security_dashboard/components/shared/filters/project_filter.vue';
import groupProjectsQuery from 'ee/security_dashboard/graphql/queries/group_projects.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';
import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { ALL_ID } from 'ee/security_dashboard/components/shared/filters/constants';
import QuerystringSync from 'ee/security_dashboard/components/shared/filters/querystring_sync.vue';

Vue.use(VueApollo);

const mockProjects = [
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
const getProjectsRequestHandler = ({ projects = mockProjects, hasNextPage = true } = {}) =>
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
  let requestHandler;

  const { i18n } = ProjectFilter;

  const createWrapper = ({ projectsRequestHandler = defaultProjectsRequestHandler } = {}) => {
    requestHandler = projectsRequestHandler;

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
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findListboxItem = (value) => wrapper.findByTestId(`listbox-item-${value}`);
  const findMaxProjectsText = () => wrapper.findByTestId('max-projects-message');

  const clickListboxItem = async (value) => {
    await findListboxItem(value).trigger('click');
  };

  const expectSelectedItems = (values) => {
    expect(findListbox().props('selected')).toEqual(values);
  };

  const createWrapperAndOpenListbox = async (options) => {
    createWrapper(options);
    await findListbox().vm.$emit('shown');
  };

  const createWrapperAndWaitForQuery = async (options) => {
    await createWrapperAndOpenListbox(options);
    await waitForPromises();
  };

  describe('before listbox is opened', () => {
    it('does not run the projects query', () => {
      createWrapper();

      expect(defaultProjectsRequestHandler).not.toHaveBeenCalled();
    });
  });

  describe('when listbox is opened', () => {
    it('runs the projects query', async () => {
      await createWrapperAndOpenListbox();

      expect(defaultProjectsRequestHandler).toHaveBeenCalledTimes(1);
      expect(defaultProjectsRequestHandler).toHaveBeenCalledWith(
        expect.objectContaining({ fullPath: groupFullPath }),
      );
    });

    it('shows the loading icon while the query is running', async () => {
      await createWrapperAndOpenListbox();

      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('hides the loading icon when the query is done', async () => {
      await createWrapperAndWaitForQuery();

      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('does not render the loading icon when there is no next page', async () => {
      const projectsRequestHandler = getProjectsRequestHandler({ hasNextPage: false });
      await createWrapperAndOpenListbox({ projectsRequestHandler });

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
          value: [],
        });
      });

      it('receives empty array when All Projects option is clicked', async () => {
        await clickListboxItem(ALL_ID);

        expect(findQuerystringSync().props('value')).toEqual([]);
      });

      it.each`
        emitted                                     | expected
        ${[mockProjects[0].id, mockProjects[1].id]} | ${[mockProjects[0].id, mockProjects[1].id]}
        ${[]}                                       | ${[ALL_ID]}
      `('restores selected items - $emitted', async ({ emitted, expected }) => {
        await findQuerystringSync().vm.$emit('input', emitted);

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
          await createWrapperAndOpenListbox();
          findQuerystringSync().vm.$emit('input', querystringValues);
          await waitForPromises();

          expectSelectedItems(expected);
        },
      );
    });

    describe('default view', () => {
      it('shows the label', () => {
        expect(wrapper.find('label').text()).toBe(i18n.label);
      });

      it('passes default props', () => {
        expect(findListbox().props()).toMatchObject({
          headerText: i18n.label,
          searchPlaceholder: i18n.searchPlaceholder,
          noResultsText: i18n.noMatchingResults,
          toggleText: i18n.allItemsText,
          block: true,
          multiple: true,
          searchable: true,
          infiniteScroll: true,
          loading: false,
          selected: [ALL_ID],
        });
      });

      it('passes default items', () => {
        expect(findListbox().props('items')).toEqual([
          { value: ALL_ID, text: i18n.allItemsText },
          { value: '1', text: 'Project 1' },
          { value: '2', text: 'Project 2' },
        ]);
      });
    });

    describe('toggle text', () => {
      it('shows "Project 1" when project 1 is selected', async () => {
        await clickListboxItem(mockProjects[0].id);

        expect(findListbox().props('toggleText')).toBe(mockProjects[0].name);
      });

      it('shows "Project 1 +1 more" when both projects are selected', async () => {
        await clickListboxItem(mockProjects[0].id);
        await clickListboxItem(mockProjects[1].id);

        expect(findListbox().props('toggleText')).toBe(`${mockProjects[0].name} +1 more`);
      });
    });

    describe('listbox items', () => {
      it('allows multiple items to be selected', async () => {
        const ids = [];

        for await (const { id } of mockProjects) {
          await clickListboxItem(id);
          ids.push(id);

          expectSelectedItems(ids);
        }
      });

      it.each(mockProjects)('toggles the item selection when clicked on', async ({ id }) => {
        await clickListboxItem(id);

        expectSelectedItems([id]);

        await clickListboxItem(id);

        expectSelectedItems([ALL_ID]);
      });

      it('selects ALL item and deselects everything else when it is clicked', async () => {
        await clickListboxItem(ALL_ID);
        await clickListboxItem(ALL_ID); // Click again to verify that it doesn't toggle.

        expectSelectedItems([ALL_ID]);
      });

      it('puts selected projects on top, followed by All projects, followed by unselected projects', async () => {
        const secondProjectId = mockProjects[1].id;
        await clickListboxItem(secondProjectId);

        expect(findListbox().props('items')[0].value).toEqual(secondProjectId);
        expect(findListbox().props('items')[1].value).toEqual(ALL_ID);
        expect(findListbox().props('items')[2].value).toEqual(mockProjects[0].id);
      });
    });

    describe('filter-changed event', () => {
      it('emits filter-changed event when selected item is changed', async () => {
        const ids = [];
        // Deselect everything to begin with.
        await clickListboxItem(ALL_ID);

        expect(wrapper.emitted('filter-changed')).toEqual([[{ projectId: [] }]]);

        for await (const { id } of mockProjects) {
          await clickListboxItem(id);
          ids.push(id);

          expect(wrapper.emitted('filter-changed')[ids.length]).toEqual([{ projectId: ids }]);
        }
      });

      it('emits the raw querystring IDs before the valid IDs are fetched', async () => {
        createWrapper();
        const querystringIds = ['1', '2', '999'];
        await findQuerystringSync().vm.$emit('input', querystringIds);

        expect(wrapper.emitted('filter-changed')[0][0].projectId).toEqual(querystringIds);
      });

      describe('after the valid IDs are fetched', () => {
        beforeEach(createWrapper);

        it('emits the raw querystring IDs if there is at least one valid ID', async () => {
          const querystringIds = ['1', '999', '998'];
          findQuerystringSync().vm.$emit('input', querystringIds);
          await waitForPromises();

          expect(wrapper.emitted('filter-changed')[1]).toEqual([{ projectId: querystringIds }]);
        });

        it('emits an empty array if there are no valid IDs', async () => {
          const querystringIds = ['998', '999'];
          findQuerystringSync().vm.$emit('input', querystringIds);
          await waitForPromises();

          expect(wrapper.emitted('filter-changed')[1]).toEqual([{ projectId: [] }]);
        });
      });
    });
  });

  describe('all projects listbox item', () => {
    it.each`
      phrase             | searchTerm | isShown
      ${'shows'}         | ${''}      | ${true}
      ${'does not show'} | ${'abc'}   | ${false}
    `(
      '$phrase the All projects listbox item when search term is "$searchTerm"',
      async ({ searchTerm, isShown }) => {
        await createWrapperAndOpenListbox();
        await findListbox().vm.$emit('search', searchTerm);

        expect(findListboxItem(ALL_ID).exists()).toBe(isShown);
      },
    );
  });

  describe('searching', () => {
    beforeEach(async () => {
      await createWrapperAndWaitForQuery();
    });

    it('clears the listbox when the search term is changed and new results are loading', async () => {
      expect(findListbox().props('items')).toHaveLength(mockProjects.length + 1);

      await findListbox().vm.$emit('search', 'abc');

      expect(findListbox().props('items')).toHaveLength(0);
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not show the All projects item', async () => {
      await findListbox().vm.$emit('search', 'abc');

      expect(findListboxItem(ALL_ID).exists()).toBe(false);
    });

    it('shows the more characters message when fewer than 3 characters entered', async () => {
      await findListbox().vm.$emit('search', 'ab');

      expect(findListbox().props('noResultsText')).toBe(i18n.enterMoreCharactersToSearch);
    });

    it('passes the no results message when 3 or more characters are entered', async () => {
      await findListbox().vm.$emit('search', 'abc');

      expect(findListbox().props('noResultsText')).toBe(i18n.noMatchingResults);
    });

    it('does not show selected projects on top', async () => {
      const secondProjectId = mockProjects[1].id;

      await clickListboxItem(secondProjectId);
      await findListbox().vm.$emit('search', 'Project');
      await waitForPromises();

      expect(findListbox().props('items')[0].value).toBe(mockProjects[0].id);
      expect(findListbox().props('items')[1].value).toBe(mockProjects[1].id);
    });
  });

  describe('max projects', () => {
    // mock response with >100 projects so we can test the max projects selected value (=100)
    const SELECTED_PROJECTS_MAX_COUNT = 100;
    const maxCountIds = [...Array(SELECTED_PROJECTS_MAX_COUNT).keys()];
    const mockManyProjects = maxCountIds.map((id) => ({
      id,
      name: `Project ${i18n}`,
    }));

    beforeEach(async () => {
      const projectsRequestHandler = getProjectsRequestHandler({
        hasNextPage: false,
        projects: mockManyProjects,
      });
      await createWrapperAndWaitForQuery({ projectsRequestHandler });
    });

    it('does not show max projects message when fewer than 100 projects are selected', () => {
      expect(findMaxProjectsText().exists()).toBe(false);
    });

    describe('when 100 or more projects are selected', () => {
      beforeEach(async () => {
        await findListbox().vm.$emit('select', maxCountIds);
      });

      it('shows max projects message', () => {
        expect(findMaxProjectsText().exists()).toBe(true);
      });

      it('disables search', () => {
        expect(findListbox().props('searchable')).toBe(false);
      });

      it('does not show unselected projects or All projects item', () => {
        expect(findListbox().props('items')).toHaveLength(SELECTED_PROJECTS_MAX_COUNT);
      });
    });
  });

  describe('highlighting', () => {
    beforeEach(async () => {
      await createWrapperAndWaitForQuery();
    });

    it('highlights the searchTerm in the items', async () => {
      await findListbox().vm.$emit('search', 'ject 1');
      await waitForPromises();

      expect(findListboxItem(mockProjects[0].id).find('div').html()).toEqual(
        '<div>Pro<b>ject</b> <b>1</b></div>',
      );
    });

    it('does not highlight when not searching', () => {
      expect(findListboxItem(mockProjects[0].id).find('div').html()).toEqual(
        '<div>Project 1</div>',
      );
    });
  });

  describe('infinite scrolling', () => {
    it('does not show infinite scrolling when there is no next page', async () => {
      const projectsRequestHandler = getProjectsRequestHandler({ hasNextPage: false });
      await createWrapperAndWaitForQuery({ projectsRequestHandler });

      expect(findListbox().props('infiniteScroll')).toBe(false);
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('shows the infinite scrolling when there is a next page and the projects query is not running', async () => {
      await createWrapperAndWaitForQuery();

      expect(findListbox().props('infiniteScroll')).toBe(true);
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('shows the loading icon and fetches the next page when the bottom is reached', async () => {
      await createWrapperAndWaitForQuery();
      await findListbox().vm.$emit('bottom-reached');

      expect(findListbox().props('items')).toHaveLength(mockProjects.length + 1);
      expect(findListbox().props('infiniteScroll')).toBe(false);
      expect(findLoadingIcon().exists()).toBe(true);
      expect(requestHandler).toHaveBeenCalledTimes(2);
      expect(defaultProjectsRequestHandler).toHaveBeenCalledTimes(2);
    });
  });
});
