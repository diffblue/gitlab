import { GlButton, GlIcon, GlLoadingIcon } from '@gitlab/ui';

import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import TestCaseSidebar from 'ee/test_case_show/components/test_case_sidebar.vue';
import { mockCurrentUserTodo, mockLabels } from 'jest/vue_shared/issuable/list/mock_data';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import ProjectSelect from '~/sidebar/components/move/issuable_move_dropdown.vue';
import LabelsSelectWidget from '~/sidebar/components/labels/labels_select_widget/labels_select_root.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import projectTestCase from 'ee/test_case_show/queries/project_test_case.query.graphql';

import { TYPE_TEST_CASE, WORKSPACE_PROJECT } from '~/issues/constants';
import waitForPromises from 'helpers/wait_for_promises';
import { mockProvide, mockTaskCompletionResponse } from '../mock_data';

Vue.use(VueApollo);

describe('TestCaseSidebar', () => {
  let wrapper;

  const createComponent = ({
    provide = {},
    sidebarExpanded = true,
    todo = mockCurrentUserTodo,
    selectedLabels = mockLabels,
    moved = false,
  } = {}) => {
    const apolloProvider = createMockApollo([[projectTestCase, mockTaskCompletionResponse]]);

    wrapper = shallowMountExtended(TestCaseSidebar, {
      provide: {
        ...mockProvide,
        ...provide,
      },
      apolloProvider,
      propsData: {
        sidebarExpanded,
        todo,
        selectedLabels,
        moved,
      },
    });
  };

  const findLabelsSelectWidget = () => wrapper.findComponent(LabelsSelectWidget);
  const findProjectSelect = () => wrapper.findComponent(ProjectSelect);
  const findCollapsedTodoButton = () => wrapper.findByTestId('collapsed-button');
  const findExpandedTodoEl = () => wrapper.findByTestId('todo');

  beforeEach(() => {
    setHTMLFixture('<aside class="right-sidebar"></aside>');
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('To Do section', () => {
    it('does not render', () => {
      createComponent({
        provide: {
          canEditTestCase: false,
        },
      });

      expect(findExpandedTodoEl().exists()).toBe(false);
      expect(findCollapsedTodoButton().exists()).toBe(false);
    });

    describe('when expanded', () => {
      it('renders expanded todo button', () => {
        createComponent();

        const todoEl = findExpandedTodoEl();

        expect(todoEl.text()).toContain('To Do');
        expect(todoEl.findComponent(GlButton).text()).toBe('Add a to do');
      });
    });

    describe('when collapsed', () => {
      it('renders collapsed todo button', async () => {
        createComponent({
          sidebarExpanded: false,
        });
        await waitForPromises();

        const todoButton = findCollapsedTodoButton();

        expect(todoButton.attributes('title')).toBe('Add a to do');
        expect(todoButton.findComponent(GlIcon).exists()).toBe(true);
      });

      it('display loading icon', () => {
        createComponent({
          sidebarExpanded: false,
        });

        expect(findCollapsedTodoButton().findComponent(GlLoadingIcon).exists()).toBe(true);
      });
    });
  });

  describe('Label select widget', () => {
    it('renders label-select', () => {
      createComponent();

      const { testCaseId, canEditTestCase, projectFullPath, testCasesPath } = mockProvide;
      const labelSelectEl = findLabelsSelectWidget();

      expect(labelSelectEl.props()).toMatchObject({
        iid: testCaseId,
        fullPath: projectFullPath,
        allowLabelRemove: canEditTestCase,
        allowMultiselect: true,
        issuableType: TYPE_TEST_CASE,
        attrWorkspacePath: projectFullPath,
        workspaceType: 'project',
        variant: 'sidebar',
        labelCreateType: WORKSPACE_PROJECT,
        labelsFilterBasePath: testCasesPath,
      });
      expect(labelSelectEl.text()).toBe('None');
    });

    it('emits "sidebar-toggle" events on click', () => {
      createComponent({
        sidebarExpanded: false,
      });

      expect(wrapper.emitted('sidebar-toggle')).toBeUndefined();

      findLabelsSelectWidget().vm.$emit('toggleCollapse');

      expect(wrapper.emitted('sidebar-toggle')).toHaveLength(1);
    });
  });

  describe('Project select', () => {
    it('renders project-select', () => {
      createComponent();

      const { projectsFetchPath } = mockProvide;
      const projectSelectEl = findProjectSelect();

      expect(projectSelectEl.props()).toMatchObject({
        projectsFetchPath,
        dropdownButtonTitle: 'Move test case',
        dropdownHeaderTitle: 'Move test case',
        moveInProgress: false,
      });
    });

    it('does not render project-select', () => {
      createComponent({
        provide: {
          canMoveTestCase: false,
        },
        sidebarExpanded: false,
      });

      expect(findProjectSelect().exists()).toBe(false);
    });

    it('emits "sidebar-toggle" on dropdown-close when the sidebar has been expanded by click', () => {
      createComponent({
        sidebarExpanded: false,
      });

      expect(wrapper.emitted('sidebar-toggle')).toBeUndefined();

      findLabelsSelectWidget().vm.$emit('toggleCollapse');

      expect(wrapper.emitted('sidebar-toggle')).toHaveLength(1);

      findProjectSelect().vm.$emit('dropdown-close');

      expect(wrapper.emitted('sidebar-toggle')).toHaveLength(2);
    });

    it('dispatches click event on move test case button', async () => {
      setHTMLFixture(`
        <aside class="right-sidebar"></aside>
        <div class="js-issuable-move-block">
          <button class="js-sidebar-dropdown-toggle"></button>
        </div>
      `);

      createComponent({
        sidebarExpanded: false,
      });

      const buttonEl = document.querySelector('.js-sidebar-dropdown-toggle');
      const sidebarEl = document.querySelector('aside.right-sidebar');
      jest.spyOn(buttonEl, 'dispatchEvent');

      findProjectSelect().vm.$emit('toggle-collapse');
      await nextTick();
      sidebarEl.dispatchEvent(new Event('transitionend'));

      expect(buttonEl.dispatchEvent).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'click',
          bubbles: true,
          cancelable: false,
        }),
      );

      resetHTMLFixture();
    });
  });
});
