import { GlEmptyState, GlModal } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import Vuex from 'vuex';
import VueDraggable from 'vuedraggable';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import Dashboard from 'ee/operations/components/dashboard/dashboard.vue';
import Project from 'ee/operations/components/dashboard/project.vue';
import ProjectSelector from '~/vue_shared/components/project_selector/project_selector.vue';
import createStore from 'ee/vue_shared/dashboards/store';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { mockProjectData, mockText } from '../../mock_data';

Vue.use(Vuex);

describe('dashboard component', () => {
  const mockAddEndpoint = 'mock-addPath';
  const mockListEndpoint = 'mock-listPath';
  const store = createStore();
  let wrapper;
  let mockAxios;

  const emptyDashboardHelpPath = '/help/user/operations_dashboard/index.html';
  const operationsDashboardHelpPath = '/help/user/operations_dashboard/index.html';
  const emptyDashboardSvgPath = '/assets/illustrations/operations-dashboard_empty.svg';

  const mountComponent = ({ state = {} } = {}) =>
    mountExtended(Dashboard, {
      store,
      propsData: {
        addPath: mockAddEndpoint,
        listPath: mockListEndpoint,
        emptyDashboardSvgPath,
        emptyDashboardHelpPath,
        operationsDashboardHelpPath,
      },
      state,
      stubs: { GlModal: true },
    });

  const findModal = () => wrapper.findComponent(GlModal);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findAddProjectButton = () => wrapper.findByTestId('add-projects-button');
  const findRemoveProjectButton = () => wrapper.findByTestId('remove-project-button');
  const findAllProjects = () => wrapper.findAllComponents(Project);
  const findProjectSelector = () => wrapper.findComponent(ProjectSelector);
  const findVueDraggable = () => wrapper.findComponent(VueDraggable);

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
    mockAxios.onGet(mockListEndpoint).replyOnce(HTTP_STATUS_OK, { projects: mockProjectData(1) });
    wrapper = mountComponent();
  });

  afterEach(() => {
    mockAxios.restore();
  });

  it('renders dashboard title', () => {
    const dashboardTitle = wrapper.element.querySelector('.js-dashboard-title');

    expect(dashboardTitle.innerText.trim()).toEqual(mockText.DASHBOARD_TITLE);
  });

  describe('add projects button', () => {
    it('renders add projects text', () => {
      expect(findAddProjectButton().text()).toBe(mockText.ADD_PROJECTS);
    });

    describe('when a project is added', () => {
      it('immediately requests the project list again', async () => {
        mockAxios.reset();
        mockAxios
          .onGet(mockListEndpoint)
          .replyOnce(HTTP_STATUS_OK, { projects: mockProjectData(2) });
        mockAxios.onPost(mockAddEndpoint).replyOnce(HTTP_STATUS_OK, { added: [1], invalid: [] });

        await nextTick();

        findProjectSelector().vm.$emit('projectClicked', { id: 1 });
        await waitForPromises();

        findModal().vm.$emit('primary');
        await waitForPromises();

        expect(findAllProjects()).toHaveLength(2);
      });
    });
  });

  describe('wrapped components', () => {
    describe('dashboard project component', () => {
      const projectCount = 1;

      beforeEach(() => {
        store.state.projects = mockProjectData(projectCount);
        wrapper = mountComponent();
      });

      it('includes a dashboard project component for each project', () => {
        expect(findAllProjects()).toHaveLength(projectCount);
      });

      it('passes each project to the dashboard project component', () => {
        const [oneProject] = store.state.projects;
        const projectComponent = wrapper.findComponent(Project);

        expect(projectComponent.props().project).toEqual(oneProject);
      });

      it('dispatches setProjects when projects changes', () => {
        const dispatch = jest.spyOn(store, 'dispatch').mockImplementation(() => {});
        const projects = mockProjectData(3);

        findVueDraggable().vm.$emit('input', projects);

        expect(dispatch).toHaveBeenCalledWith('setProjects', projects);
      });

      describe('when a project is removed', () => {
        it('immediately requests the project list again', async () => {
          mockAxios.reset();
          mockAxios.onDelete(store.state.projects[0].remove_path).reply(HTTP_STATUS_OK);
          mockAxios.onGet(mockListEndpoint).replyOnce(HTTP_STATUS_OK, { projects: [] });

          findRemoveProjectButton().vm.$emit('click');
          await waitForPromises();

          expect(wrapper.findAllComponents(Project).length).toEqual(0);
        });
      });
    });

    describe('add projects modal', () => {
      beforeEach(() => {
        store.state.projectSearchResults = mockProjectData(2);
        store.state.selectedProjects = mockProjectData(1);
      });

      it('clears state when adding a valid project', async () => {
        mockAxios.onPost(mockAddEndpoint).replyOnce(HTTP_STATUS_OK, { added: [1], invalid: [] });

        await nextTick();

        findModal().vm.$emit('primary');
        await waitForPromises();

        expect(store.state.projectSearchResults).toHaveLength(0);
        expect(store.state.selectedProjects).toHaveLength(0);
      });

      it('clears state when adding an invalid project', async () => {
        mockAxios.onPost(mockAddEndpoint).replyOnce(HTTP_STATUS_OK, { added: [], invalid: [1] });

        await nextTick();

        findModal().vm.$emit('primary');
        await waitForPromises();

        expect(store.state.projectSearchResults).toHaveLength(0);
        expect(store.state.selectedProjects).toHaveLength(0);
      });

      it('clears state when canceled', async () => {
        await nextTick();

        findModal().vm.$emit('canceled');
        await waitForPromises();

        expect(store.state.projectSearchResults).toHaveLength(0);
        expect(store.state.selectedProjects).toHaveLength(0);
      });

      it('clears state on error', async () => {
        mockAxios.onPost(mockAddEndpoint).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR, {});

        await nextTick();

        expect(store.state.projectSearchResults.length).not.toBe(0);
        expect(store.state.selectedProjects.length).not.toBe(0);

        findModal().vm.$emit('primary');
        await waitForPromises();

        expect(store.state.projectSearchResults).toHaveLength(0);
        expect(store.state.selectedProjects).toHaveLength(0);
      });
    });

    describe('when no projects have been added', () => {
      beforeEach(() => {
        store.state.projects = [];
        store.state.isLoadingProjects = false;
      });

      it('should render the empty state', () => {
        expect(findEmptyState().exists()).toBe(true);
      });

      it('should link to the documentation', () => {
        const link = findEmptyState().find('[data-testid="documentation-link"]');

        expect(link.exists()).toBe(true);
        expect(link.attributes().href).toEqual(emptyDashboardHelpPath);
      });

      it('should render the add projects button', () => {
        const button = findAddProjectButton();

        expect(button.exists()).toBe(true);
        expect(button.text()).toEqual('Add projects');
      });
    });
  });
});
