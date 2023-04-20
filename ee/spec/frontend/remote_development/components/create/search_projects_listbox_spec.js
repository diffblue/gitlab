import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlCollapsibleListbox, GlIcon, GlListboxItem } from '@gitlab/ui';
import { logError } from '~/lib/logger';
import SelectProjectListbox, {
  i18n,
  PROJECTS_MAX_LIMIT,
} from 'ee/remote_development/components/create/search_projects_listbox.vue';
import searchProjectsQuery from 'ee/remote_development/graphql/queries/search_projects.query.graphql';
import {
  shallowMountExtended,
  mountExtended,
  extendedWrapper,
} from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { SEARCH_PROJECTS_QUERY_RESULT } from '../../mock_data';

Vue.use(VueApollo);

jest.mock('~/lib/logger');

describe('remote_development/components/create/search_projects_listbox', () => {
  let wrapper;
  let mockApollo;
  let searchProjectsQueryHandler;

  const buildMockApollo = () => {
    searchProjectsQueryHandler = jest.fn();
    searchProjectsQueryHandler.mockResolvedValueOnce(SEARCH_PROJECTS_QUERY_RESULT);
    mockApollo = createMockApollo([[searchProjectsQuery, searchProjectsQueryHandler]]);
  };
  const buildWrapper = ({ mountFn = shallowMountExtended, value = null } = {}) => {
    wrapper = mountFn(SelectProjectListbox, {
      apolloProvider: mockApollo,
      propsData: {
        value,
      },
      stubs: {
        GlCollapsibleListbox,
      },
    });
  };
  const findCollapsibleListbox = () => extendedWrapper(wrapper.findComponent(GlCollapsibleListbox));
  const getMockProjectsNameWithNamespace = () =>
    SEARCH_PROJECTS_QUERY_RESULT.data.projects.nodes.map(
      ({ nameWithNamespace }) => nameWithNamespace,
    );

  beforeEach(() => {
    buildMockApollo();
  });

  describe('default path', () => {
    beforeEach(async () => {
      buildWrapper();

      await waitForPromises();
    });

    it('initializes collapsible list box', () => {
      expect(findCollapsibleListbox().props()).toMatchObject({
        block: true,
        searchable: true,
        items: SEARCH_PROJECTS_QUERY_RESULT.data.projects.nodes.map((project) => ({
          text: project.nameWithNamespace,
          value: project.fullPath,
          project,
        })),
        headerText: i18n.dropdownHeader,
        noResultsText: i18n.noResultsMessage,
        searchPlaceholder: i18n.searchPlaceholder,
      });
    });

    it('fetches and displays project list', () => {
      getMockProjectsNameWithNamespace().forEach((name) => {
        expect(findCollapsibleListbox().text()).toContain(name);
      });
    });

    it('displays empty field placeholder as the toggle button text', () => {
      expect(findCollapsibleListbox().props().toggleText).toBe(i18n.emptyFieldPlaceholder);
    });
  });

  describe('when there is a selected project', () => {
    const selectedProject = SEARCH_PROJECTS_QUERY_RESULT.data.projects.nodes[0];

    beforeEach(async () => {
      buildWrapper({ value: selectedProject });

      await waitForPromises();
    });
    it('displays the project name with namespace as the toggle button text', () => {
      expect(findCollapsibleListbox().props().toggleText).toBe(selectedProject.nameWithNamespace);
    });

    it('sets the selected value in the collapsible list box component', () => {
      expect(findCollapsibleListbox().props().selected).toBe(selectedProject.fullPath);
    });
  });

  describe('when selecting a project', () => {
    it('emits input event and sends the selected project full path as data', async () => {
      const itemIndex = 0;
      const selectedProject = SEARCH_PROJECTS_QUERY_RESULT.data.projects.nodes[itemIndex];

      buildWrapper({ mountFn: mountExtended });

      await waitForPromises();

      await findCollapsibleListbox()
        .findAllComponents(GlListboxItem)
        .at(itemIndex)
        .trigger('click');

      expect(wrapper.emitted('input')).toEqual([[selectedProject]]);
    });
  });

  describe('when searching a project', () => {
    it('retriggers GraphQL query with the search term entered', async () => {
      const searchTerm = 'search term';

      buildWrapper({ mountFn: mountExtended });

      await waitForPromises();

      searchProjectsQueryHandler.mockReset();

      await findCollapsibleListbox().vm.$emit('search', searchTerm);

      expect(searchProjectsQueryHandler).toHaveBeenCalledWith({
        search: searchTerm,
        first: PROJECTS_MAX_LIMIT,
        sort: 'similarity',
      });
    });
  });

  describe('when the search projects graphql query fails', () => {
    const error = new Error('Failed to search projects');

    beforeEach(async () => {
      searchProjectsQueryHandler.mockReset();
      searchProjectsQueryHandler.mockRejectedValueOnce(error);

      buildWrapper({ mountFn: mountExtended });

      await waitForPromises();
    });

    it('displays error message', () => {
      expect(findCollapsibleListbox().text()).toContain(i18n.searchFailedMessage);
      expect(
        findCollapsibleListbox()
          .findByTestId('red-selector-error-list')
          .findComponent(GlIcon)
          .props(),
      ).toMatchObject({
        name: 'error',
        size: 16,
      });
    });

    it('logs the error', () => {
      expect(logError).toHaveBeenCalledWith(error);
    });
  });
});
