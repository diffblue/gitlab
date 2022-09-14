import {
  GlButton,
  GlDropdown,
  GlDropdownItem,
  GlFormInput,
  GlSearchBoxByType,
  GlLoadingIcon,
  GlDropdownDivider,
  GlDropdownSectionHeader,
} from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { ENTER_KEY } from '~/lib/utils/keys';

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

  const createComponent = ({ defaultProjectForIssueCreation = null } = {}) => {
    const store = createDefaultStore();

    store.dispatch('setInitialConfig', mockInitialConfig);
    store.dispatch('setInitialParentItem', mockParentItem);
    store.dispatch('setDefaultProjectForIssueCreation', defaultProjectForIssueCreation);

    wrapper = shallowMount(CreateIssueForm, {
      store,
    });
  };

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
    wrapper.vm.$store.dispatch('receiveProjectsSuccess', mockProjects);
    await nextTick();

    const item = wrapper.find(`[data-testid="project-item-${project.id}"]`);
    item.vm.$emit('click');
  };

  const findSubmitButton = () => wrapper.find('[data-testid="submit-button"]');
  const findTitleInput = () => wrapper.find('[data-testid="title-input"]');

  beforeEach(() => {
    createComponent();
    gon.current_username = 'root';
  });

  afterEach(() => {
    wrapper.destroy();
    delete gon.current_username;
  });

  describe('data', () => {
    it('initializes data props with default values', () => {
      expect(wrapper.vm.selectedProject).toBeNull();
      expect(wrapper.vm.searchKey).toBe('');
      expect(wrapper.vm.title).toBe('');
    });
  });

  describe('computed', () => {
    describe('dropdownToggleText', () => {
      it('returns project name with name_with_namespace when `selectedProject` is not empty', async () => {
        await selectProject();

        expect(wrapper.vm.dropdownToggleText).toBe(mockProject.name_with_namespace);
      });
      it('returns project name with namespace when `selectedProject` is not empty and dont have name_with_namespace', async () => {
        const project = {
          ...mockProject,
          name_with_namespace: undefined,
          namespace: 'H5bp / Html5 Boilerplate',
        };

        await selectProject(project);

        expect(wrapper.vm.dropdownToggleText).toBe(project.namespace);
      });
      it('returns project name of default project', async () => {
        createComponent({ defaultProjectForIssueCreation: mockDefaultProjectForIssueCreation });

        expect(wrapper.vm.dropdownToggleText).toBe(
          mockDefaultProjectForIssueCreation.nameWithNamespace,
        );
      });
    });
  });

  describe('methods', () => {
    describe('cancel', () => {
      it('emits event `cancel` on component', async () => {
        wrapper.vm.cancel();

        await nextTick();
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

    describe('handleDropdownShow', () => {
      it('sets `searchKey` prop to empty string and calls action `fetchProjects`', () => {
        const handleDropdownShow = jest
          .spyOn(wrapper.vm, 'fetchProjects')
          .mockImplementation(jest.fn());

        wrapper.vm.handleDropdownShow();

        expect(wrapper.vm.searchKey).toBe('');
        expect(handleDropdownShow).toHaveBeenCalled();
      });
    });
  });

  describe('templates', () => {
    it('renders Issue title input field', () => {
      const issueTitleFieldLabel = wrapper.findAll('label').at(0);
      const issueTitleFieldInput = wrapper.findComponent(GlFormInput);

      expect(issueTitleFieldLabel.text()).toBe('Title');
      expect(issueTitleFieldInput.attributes('placeholder')).toBe('New issue title');
    });

    it('renders Projects dropdown field', () => {
      const projectsDropdownLabel = wrapper.findAll('label').at(1);
      const projectsDropdownButton = wrapper.findComponent(GlDropdown);

      expect(projectsDropdownLabel.text()).toBe('Project');
      expect(projectsDropdownButton.props('text')).toBe('Select a project');
    });

    it('renders Projects dropdown contents', async () => {
      wrapper.vm.$store.dispatch('receiveProjectsSuccess', mockProjects);

      await nextTick();
      const projectsDropdownButton = wrapper.findComponent(GlDropdown);
      const dropdownItems = projectsDropdownButton.findAllComponents(GlDropdownItem);
      const dropdownItem = dropdownItems.at(0);

      expect(projectsDropdownButton.findComponent(GlSearchBoxByType).exists()).toBe(true);
      expect(projectsDropdownButton.findComponent(GlLoadingIcon).exists()).toBe(true);
      expect(dropdownItems).toHaveLength(mockProjects.length);
      expect(dropdownItem.text()).toContain(mockProjects[0].name);
      expect(dropdownItem.text()).toContain(mockProjects[0].namespace.name);
      expect(dropdownItem.findComponent(ProjectAvatar).props()).toMatchObject({
        projectId: mockProjects[0].id,
        projectName: mockProjects[0].name,
        projectAvatarUrl: mockProjects[0].avatar_url,
      });
    });

    it('renders dropdown contents without recent items when `recentItems` are empty', () => {
      const projectsDropdownButton = wrapper.findComponent(GlDropdown);
      expect(projectsDropdownButton.findComponent(GlDropdownSectionHeader).exists()).toBe(false);
      expect(projectsDropdownButton.findComponent(GlDropdownDivider).exists()).toBe(false);
      expect(projectsDropdownButton.find('[data-testid="recent-items-content"]').exists()).toBe(
        false,
      );
    });

    it('renders recent items when localStorage has recent items', async () => {
      setLocalstorageFrequentItems();

      wrapper.vm.setRecentItems();

      await nextTick();

      const projectsDropdownButton = wrapper.findComponent(GlDropdown);

      expect(projectsDropdownButton.findComponent(GlDropdownSectionHeader).exists()).toBe(true);
      expect(projectsDropdownButton.findComponent(GlDropdownDivider).exists()).toBe(true);

      const content = projectsDropdownButton.find('[data-testid="recent-items-content"]');
      expect(content.exists()).toBe(true);
      expect(content.findAllComponents(GlDropdownItem)).toHaveLength(
        mockFrequentlyUsedProjects.length,
      );

      removeLocalstorageFrequentItems();
    });

    it('renders recent items from the group when localStorage has recent items with mixed groups', async () => {
      setLocalstorageFrequentItems(mockMixedFrequentlyUsedProjects);

      wrapper.vm.setRecentItems();

      await nextTick();

      const projectsDropdownButton = wrapper.findComponent(GlDropdown);

      expect(
        projectsDropdownButton
          .find('[data-testid="recent-items-content"]')
          .findAllComponents(GlDropdownItem),
      ).toHaveLength(mockMixedFrequentlyUsedProjects.length - 1);

      removeLocalstorageFrequentItems();
    });

    it('renders Projects dropdown contents containing only matching project when searchKey is provided', async () => {
      const searchKey = 'Underscore';
      const filteredMockProjects = mockProjects.filter((project) => project.name === searchKey);
      jest.spyOn(wrapper.vm, 'fetchProjects').mockImplementation(jest.fn());

      wrapper.findComponent(GlDropdown).trigger('click');

      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        searchKey,
      });

      await nextTick();
      await wrapper.vm.$store.dispatch('receiveProjectsSuccess', filteredMockProjects);
      expect(wrapper.findAllComponents(GlDropdownItem)).toHaveLength(1);
    });

    it('renders Projects dropdown contents containing string string "No matches found" when searchKey provided does not match any project', async () => {
      const searchKey = "this-project-shouldn't exist";
      const filteredMockProjects = mockProjects.filter((project) => project.name === searchKey);
      jest.spyOn(wrapper.vm, 'fetchProjects').mockImplementation(jest.fn());

      wrapper.findComponent(GlDropdown).trigger('click');

      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        searchKey,
      });

      await nextTick();
      await wrapper.vm.$store.dispatch('receiveProjectsSuccess', filteredMockProjects);
      expect(wrapper.find('.dropdown-contents').text()).toContain('No matches found');
    });

    it('renders `Create issue` button', () => {
      const createIssueButton = wrapper.findAllComponents(GlButton).at(0);

      expect(createIssueButton.exists()).toBe(true);
      expect(createIssueButton.text()).toBe('Create issue');
    });

    it('renders loading icon within `Create issue` button when `itemCreateInProgress` is true', async () => {
      wrapper.vm.$store.dispatch('requestCreateItem');

      await nextTick();
      const createIssueButton = wrapper.findAllComponents(GlButton).at(0);

      expect(createIssueButton.exists()).toBe(true);
      expect(createIssueButton.props('disabled')).toBe(true);
      expect(createIssueButton.props('loading')).toBe(true);
    });

    it('renders loading icon within `Create issue` button when `recentItemFetchInProgress` is true', async () => {
      wrapper.vm.recentItemFetchInProgress = true;

      await nextTick();
      const createIssueButton = wrapper.findAllComponents(GlButton).at(0);

      expect(createIssueButton.exists()).toBe(true);
      expect(createIssueButton.props()).toMatchObject({
        disabled: true,
        loading: true,
      });
    });

    it('renders `Cancel` button', () => {
      const cancelButton = wrapper.findAllComponents(GlButton).at(1);

      expect(cancelButton.exists()).toBe(true);
      expect(cancelButton.text()).toBe('Cancel');
    });
  });
});
