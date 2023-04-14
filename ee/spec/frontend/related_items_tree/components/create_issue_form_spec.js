import {
  GlDropdown,
  GlDropdownItem,
  GlFormInput,
  GlSearchBoxByType,
  GlLoadingIcon,
  GlDropdownDivider,
  GlDropdownSectionHeader,
} from '@gitlab/ui';
import Vue from 'vue';
import Vuex from 'vuex';
import MockAdapter from 'axios-mock-adapter';

import axios from '~/lib/utils/axios_utils';
import { ENTER_KEY } from '~/lib/utils/keys';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

import Api from 'ee/api';
import mockProjects from 'test_fixtures_static/projects.json';
import CreateIssueForm from 'ee/related_items_tree/components/create_issue_form.vue';
import createDefaultStore from 'ee/related_items_tree/store';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';

import {
  mockInitialConfig,
  mockDefaultProjectForIssueCreation,
  mockParentItem,
  mockFrequentlyUsedProjects,
  mockMixedFrequentlyUsedProjects,
} from '../mock_data';

Vue.use(Vuex);

describe('CreateIssueForm', () => {
  const mockProject = mockProjects[1];
  let wrapper;
  let store;
  let mockAxios;

  const createComponent = ({ defaultProjectForIssueCreation = null } = {}) => {
    store = createDefaultStore();
    store.dispatch('setInitialConfig', mockInitialConfig);
    store.dispatch('setInitialParentItem', mockParentItem);
    store.dispatch('setDefaultProjectForIssueCreation', defaultProjectForIssueCreation);

    wrapper = shallowMountExtended(CreateIssueForm, {
      store,
      stubs: {
        GlSearchBoxByType,
      },
    });
  };

  const findCancelBtn = () => wrapper.findByTestId('cancel-btn');
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownContentDivider = () => wrapper.findComponent(GlDropdownDivider);
  const findDropdownHeader = () => wrapper.findComponent(GlDropdownSectionHeader);
  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findDropdownItem = (index) => findDropdownItems().at(index);
  const findIssueTitleInput = () => wrapper.findComponent(GlFormInput);
  const findIssueTitleLabel = () => wrapper.findAll('label').at(0);
  const findProjectItem = (project) => wrapper.findByTestId(`project-item-${project.id}`);
  const findProjectsDropdownLabel = () => wrapper.findAll('label').at(1);
  const findRecentDropdown = () => wrapper.findByTestId('recent-items-content');
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findSubmitButton = () => wrapper.findByTestId('submit-button');
  const findTitleInput = () => wrapper.findByTestId('title-input');

  const getLocalstorageKey = () => {
    return 'root/frequent-projects';
  };

  const setLocalstorageFrequentItems = (json = mockFrequentlyUsedProjects) => {
    localStorage.setItem(getLocalstorageKey(), JSON.stringify(json));
  };

  const removeLocalstorageFrequentItems = () => {
    localStorage.removeItem(getLocalstorageKey());
  };

  const selectProject = async (project = mockProject) => {
    await store.dispatch('receiveProjectsSuccess', mockProjects);

    findProjectItem(project).vm.$emit('click');
  };

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
    gon.current_username = 'root';
  });

  describe('Project name', () => {
    describe('when no name property is found', () => {
      beforeEach(() => {
        createComponent({ defaultProjectForIssueCreation: mockDefaultProjectForIssueCreation });
      });

      it('returns project name of default project', () => {
        expect(findDropdown().props().text).toBe(
          mockDefaultProjectForIssueCreation.nameWithNamespace,
        );
      });
    });

    describe('when `selectedProject` is not empty', () => {
      it('returns project name from name_with_namespace property', async () => {
        createComponent();

        await selectProject();

        expect(findDropdown().props().text).toBe(mockProject.name_with_namespace);
      });

      describe('and does not have name_with_namespace property', () => {
        beforeEach(() => {
          createComponent();
        });

        it('returns project name from namespace property', async () => {
          const project = {
            ...mockProject,
            name_with_namespace: undefined,
            namespace: 'H5bp / Html5 Boilerplate',
          };

          await selectProject(project);

          expect(findDropdown().props().text).toBe(project.namespace);
        });
      });
    });
  });

  describe('events', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('when clicking the cancel button', () => {
      it('emits event `cancel` event', async () => {
        await findCancelBtn().vm.$emit('click');

        expect(wrapper.emitted('cancel')).toEqual([[]]);
      });
    });

    describe('createIssue', () => {
      it('emits event `submit` on component when `selectedProject` is not empty', async () => {
        const input = findTitleInput();
        const endpoint = Api.buildUrl(Api.projectCreateIssuePath).replace(':id', mockProject.id);

        await selectProject();
        await input.vm.$emit('input', 'Some issue');
        await findSubmitButton().vm.$emit('click');

        expect(wrapper.emitted('submit')[0]).toEqual(
          expect.arrayContaining([{ issuesEndpoint: endpoint, title: 'Some issue' }]),
        );
        expect(input.attributes('value')).toBe('');
      });

      it('emits event `submit` on enter', async () => {
        const input = findTitleInput();
        const endpoint = Api.buildUrl(Api.projectCreateIssuePath).replace(':id', mockProject.id);

        await selectProject();
        await input.vm.$emit('input', 'Some issue');
        await input.vm.$emit('keyup', new KeyboardEvent({ key: ENTER_KEY }));

        expect(wrapper.emitted('submit')[0]).toEqual(
          expect.arrayContaining([{ issuesEndpoint: endpoint, title: 'Some issue' }]),
        );
        expect(input.attributes('value')).toBe('');
      });

      it('emits correct event when using the defaultProjectForIssueCreation', async () => {
        const endpoint = Api.buildUrl(Api.projectCreateIssuePath).replace(':id', '1');

        createComponent({ defaultProjectForIssueCreation: mockDefaultProjectForIssueCreation });
        const input = findTitleInput();

        await input.vm.$emit('input', 'Some issue');
        await findSubmitButton().vm.$emit('click');

        expect(wrapper.emitted('submit')[0]).toEqual(
          expect.arrayContaining([{ issuesEndpoint: endpoint, title: 'Some issue' }]),
        );
      });

      it('does not emit event `submit` when `selectedProject` is empty', async () => {
        const input = findTitleInput();

        await input.vm.$emit('input', 'Some issue');
        await findSubmitButton().vm.$emit('click');

        expect(wrapper.emitted('submit')).toBeUndefined();
        expect(input.attributes('value')).toBe('Some issue');
      });

      it('does not emit event `submit` when `title` is empty', async () => {
        await selectProject();
        await findSubmitButton().vm.$emit('click');

        expect(wrapper.emitted('submit')).toBeUndefined();
      });
    });
  });

  describe('When dropdown is shown', () => {
    beforeEach(async () => {
      createComponent();
      await findDropdown().vm.$emit('show');
      await waitForPromises();
    });

    it('sets `searchKey` prop to empty string', () => {
      expect(findSearchBox().props().value).toBe('');
    });

    it('calls action `fetchProjects`', () => {
      expect(mockAxios.history.get).toHaveLength(1);
    });
  });

  describe('templates', () => {
    beforeEach(() => {
      createComponent();
    });

    afterEach(() => {
      removeLocalstorageFrequentItems();
    });

    it('renders Issue title input field', () => {
      expect(findIssueTitleLabel().text()).toBe('Title');
      expect(findIssueTitleInput().attributes('placeholder')).toBe('New issue title');
    });

    it('renders Projects dropdown field', () => {
      expect(findProjectsDropdownLabel().text()).toBe('Project');
      expect(findDropdown().props('text')).toBe('Select a project');
    });

    it('renders Projects dropdown contents', async () => {
      await store.dispatch('receiveProjectsSuccess', mockProjects);

      const projectsDropdownButton = findDropdown();
      const dropdownItem = findDropdownItem(0);

      expect(projectsDropdownButton.findComponent(GlSearchBoxByType).exists()).toBe(true);
      expect(projectsDropdownButton.findComponent(GlLoadingIcon).exists()).toBe(true);

      expect(findDropdownItems()).toHaveLength(mockProjects.length);

      expect(dropdownItem.text()).toContain(mockProjects[0].name);
      expect(dropdownItem.text()).toContain(mockProjects[0].namespace.name);
      expect(dropdownItem.findComponent(ProjectAvatar).props()).toMatchObject(
        expect.objectContaining({
          projectId: mockProjects[0].id,
          projectName: mockProjects[0].name,
          projectAvatarUrl: mockProjects[0].avatar_url,
        }),
      );
    });

    it('renders dropdown contents without recent items when `recentItems` are empty', () => {
      expect(findDropdownContentDivider().exists()).toBe(false);
      expect(findDropdownHeader().exists()).toBe(false);
      expect(findRecentDropdown().exists()).toBe(false);
    });

    it('renders recent items when localStorage has recent items', async () => {
      setLocalstorageFrequentItems();

      expect(findDropdownContentDivider().exists()).toBe(false);
      expect(findDropdownHeader().exists()).toBe(false);

      await findDropdown().vm.$emit('show');

      expect(findDropdownContentDivider().exists()).toBe(true);
      expect(findDropdownHeader().exists()).toBe(true);

      const content = findRecentDropdown();
      expect(content.exists()).toBe(true);
      expect(content.findAllComponents(GlDropdownItem)).toHaveLength(
        mockFrequentlyUsedProjects.length,
      );
    });

    it('renders recent items from the group when localStorage has recent items with mixed groups', async () => {
      setLocalstorageFrequentItems(mockMixedFrequentlyUsedProjects);

      await findDropdown().vm.$emit('show');

      expect(findRecentDropdown().findAllComponents(GlDropdownItem)).toHaveLength(
        mockMixedFrequentlyUsedProjects.length - 1,
      );
    });

    it('renders Projects dropdown contents containing only matching project when searchKey is provided', async () => {
      const searchKey = 'Underscore';
      const filteredMockProjects = mockProjects.filter((project) => project.name === searchKey);

      await findDropdown().vm.$emit('show');
      await findSearchBox().vm.$emit('input', searchKey);

      await store.dispatch('receiveProjectsSuccess', filteredMockProjects);
      expect(wrapper.findAllComponents(GlDropdownItem)).toHaveLength(1);
    });

    it('renders Projects dropdown contents containing string string "No matches found" when searchKey provided does not match any project', async () => {
      const searchKey = "this-project-shouldn't exist";
      const filteredMockProjects = mockProjects.filter((project) => project.name === searchKey);

      await findDropdown().vm.$emit('show');
      await findSearchBox().vm.$emit('input', searchKey);

      await store.dispatch('receiveProjectsSuccess', filteredMockProjects);
      expect(findDropdown().text()).toContain('No matches found');
    });

    it('renders `Create issue` button', () => {
      const createIssueButton = findSubmitButton();

      expect(createIssueButton.exists()).toBe(true);
      expect(createIssueButton.text()).toBe('Create issue');
    });

    describe('when `itemCreateInProgress` is true', () => {
      beforeEach(async () => {
        await store.dispatch('requestCreateItem');
      });

      it('renders loading icon within `Create issue` button', () => {
        const createIssueButton = findSubmitButton();

        expect(createIssueButton.exists()).toBe(true);
        expect(createIssueButton.props('disabled')).toBe(true);
        expect(createIssueButton.props('loading')).toBe(true);
      });
    });

    describe('when selecting recent items', () => {
      beforeEach(async () => {
        setLocalstorageFrequentItems();
        await findDropdown().vm.$emit('show');
      });

      it('renders loading icon within `Create issue` button', async () => {
        const recentDropdown = findRecentDropdown();
        const createIssueButton = findSubmitButton();

        expect(recentDropdown.exists()).toBe(true);

        expect(createIssueButton.exists()).toBe(true);
        expect(createIssueButton.props()).toMatchObject({
          disabled: true,
          loading: false,
        });

        const dropdownItem = recentDropdown.findAllComponents(GlDropdownItem).at(0);
        await dropdownItem.vm.$emit('click');

        expect(createIssueButton.props()).toMatchObject({
          disabled: true,
          loading: true,
        });
      });
    });

    it('renders `Cancel` button', () => {
      const cancelButton = findCancelBtn();

      expect(cancelButton.exists()).toBe(true);
      expect(cancelButton.text()).toBe('Cancel');
    });
  });
});
