import { GlButton, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import { nextTick } from 'vue';
import TestCaseSidebar from 'ee/test_case_show/components/test_case_sidebar.vue';
import { mockCurrentUserTodo, mockLabels } from 'jest/vue_shared/issuable/list/mock_data';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import ProjectSelect from '~/sidebar/components/move/issuable_move_dropdown.vue';
import LabelsSelectWidget from '~/sidebar/components/labels/labels_select_widget/labels_select_root.vue';

import { TYPE_TEST_CASE, WORKSPACE_PROJECT } from '~/issues/constants';
import { mockProvide, mockTestCase } from '../mock_data';

const createComponent = ({
  sidebarExpanded = true,
  todo = mockCurrentUserTodo,
  selectedLabels = mockLabels,
  testCaseLoading = false,
} = {}) =>
  shallowMount(TestCaseSidebar, {
    provide: {
      ...mockProvide,
    },
    propsData: {
      sidebarExpanded,
      todo,
      selectedLabels,
    },
    mocks: {
      $apollo: {
        queries: {
          testCase: {
            loading: testCaseLoading,
          },
        },
      },
    },
  });

describe('TestCaseSidebar', () => {
  let wrapper;

  beforeEach(() => {
    setHTMLFixture('<aside class="right-sidebar"></aside>');
    wrapper = createComponent();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('computed', () => {
    describe.each`
      state        | isTodoPending | todoActionText    | todoIcon
      ${'pending'} | ${true}       | ${'Mark as done'} | ${'todo-done'}
      ${'done'}    | ${false}      | ${'Add a to do'}  | ${'todo-add'}
    `('when `todo.state` is "$state"', ({ state, isTodoPending, todoActionText, todoIcon }) => {
      beforeEach(async () => {
        wrapper.setProps({
          todo: {
            ...mockCurrentUserTodo,
            state,
          },
        });

        await nextTick();
      });

      it.each`
        propName            | propValue
        ${'isTodoPending'}  | ${isTodoPending}
        ${'todoActionText'} | ${todoActionText}
        ${'todoIcon'}       | ${todoIcon}
      `('computed prop `$propName` returns $propValue', ({ propName, propValue }) => {
        expect(wrapper.vm[propName]).toBe(propValue);
      });
    });

    describe('selectProjectDropdownButtonTitle', () => {
      it.each`
        testCaseMoveInProgress | returnValue
        ${true}                | ${'Moving test case'}
        ${false}               | ${'Move test case'}
      `(
        'returns $returnValue when testCaseMoveInProgress is $testCaseMoveInProgress',
        async ({ testCaseMoveInProgress, returnValue }) => {
          // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
          // eslint-disable-next-line no-restricted-syntax
          wrapper.setData({
            testCaseMoveInProgress,
          });

          await nextTick();

          expect(wrapper.vm.selectProjectDropdownButtonTitle).toBe(returnValue);
        },
      );
    });
  });

  describe('methods', () => {
    describe('handleTodoButtonClick', () => {
      it.each`
        state        | methodToCall
        ${'pending'} | ${'markTestCaseTodoDone'}
        ${'done'}    | ${'addTestCaseAsTodo'}
      `(
        'calls `wrapper.vm.$methodToCall` when `todo.state` is "$state"',
        async ({ state, methodToCall }) => {
          jest.spyOn(wrapper.vm, methodToCall).mockImplementation(jest.fn());
          wrapper.setProps({
            todo: {
              ...mockCurrentUserTodo,
              state,
            },
          });

          await nextTick();

          wrapper.vm.handleTodoButtonClick();

          expect(wrapper.vm[methodToCall]).toHaveBeenCalled();
        },
      );
    });

    describe('toggleSidebar', () => {
      beforeEach(() => {
        setHTMLFixture('<button class="js-toggle-right-sidebar-button"></button>');
      });

      afterEach(() => {
        resetHTMLFixture();
      });

      it('dispatches click event on sidebar toggle button', () => {
        wrapper.vm.toggleSidebar();

        expect(wrapper.emitted('sidebar-toggle')).toBeDefined();
      });
    });

    describe('expandSidebarAndOpenDropdown', () => {
      beforeEach(() => {
        setHTMLFixture(`
          <div class="js-issuable-move-block">
            <button class="js-sidebar-dropdown-toggle"></button>
          </div>
        `);
      });

      afterEach(() => {
        resetHTMLFixture();
      });

      it('calls `toggleSidebar` method and sets `sidebarExpandedOnClick` to true when `sidebarExpanded` prop is false', async () => {
        jest.spyOn(wrapper.vm, 'toggleSidebar').mockImplementation(jest.fn());
        wrapper.setProps({
          sidebarExpanded: false,
        });

        await nextTick();

        wrapper.vm.expandSidebarAndOpenDropdown(
          '.js-issuable-move-block .js-sidebar-dropdown-toggle',
        );

        expect(wrapper.vm.toggleSidebar).toHaveBeenCalled();
        expect(wrapper.vm.sidebarExpandedOnClick).toBe(true);
      });

      it('dispatches click event on move test case button', async () => {
        const buttonEl = document.querySelector('.js-sidebar-dropdown-toggle');
        jest.spyOn(wrapper.vm, 'toggleSidebar').mockImplementation(jest.fn());
        jest.spyOn(buttonEl, 'dispatchEvent');
        wrapper.setProps({
          sidebarExpanded: false,
        });

        await nextTick();

        wrapper.vm.expandSidebarAndOpenDropdown(
          '.js-issuable-move-block .js-sidebar-dropdown-toggle',
        );

        await nextTick();

        wrapper.vm.sidebarEl.dispatchEvent(new Event('transitionend'));

        expect(buttonEl.dispatchEvent).toHaveBeenCalledWith(
          expect.objectContaining({
            type: 'click',
            bubbles: true,
            cancelable: false,
          }),
        );
      });
    });

    describe('handleSidebarDropdownClose', () => {
      it('sets `sidebarExpandedOnClick` to false and calls `toggleSidebar` method when `sidebarExpandedOnClick` is true', async () => {
        jest.spyOn(wrapper.vm, 'toggleSidebar').mockImplementation(jest.fn());
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          sidebarExpandedOnClick: true,
        });

        await nextTick();

        wrapper.vm.handleSidebarDropdownClose();

        expect(wrapper.vm.sidebarExpandedOnClick).toBe(false);
        expect(wrapper.vm.toggleSidebar).toHaveBeenCalled();
      });
    });

    describe('handleUpdateSelectedLabels', () => {
      const updatedLabels = [
        {
          ...mockLabels[0],
          set: false,
        },
      ];

      it('sets `testCaseLabelsSelectInProgress` to true when provided labels param includes any of the additions or removals', () => {
        jest.spyOn(wrapper.vm, 'updateTestCase').mockResolvedValue(mockTestCase);

        wrapper.vm.handleUpdateSelectedLabels(updatedLabels);

        expect(wrapper.vm.testCaseLabelsSelectInProgress).toBe(true);
      });

      it('calls `updateTestCase` method with variables `addLabelIds` & `removeLabelIds` and erroMessage when provided labels param includes any of the additions or removals', () => {
        jest.spyOn(wrapper.vm, 'updateTestCase').mockResolvedValue(mockTestCase);

        wrapper.vm.handleUpdateSelectedLabels(updatedLabels);

        expect(wrapper.vm.updateTestCase).toHaveBeenCalledWith({
          variables: {
            addLabelIds: [],
            removeLabelIds: [updatedLabels[0].id],
          },
          errorMessage: 'Something went wrong while updating the test case labels.',
        });
      });

      it('emits "test-case-updated" event on component upon promise resolve', () => {
        jest.spyOn(wrapper.vm, 'updateTestCase').mockResolvedValue(mockTestCase);
        jest.spyOn(wrapper.vm, '$emit');

        return wrapper.vm.handleUpdateSelectedLabels(updatedLabels).then(() => {
          expect(wrapper.vm.$emit).toHaveBeenCalledWith('test-case-updated', mockTestCase);
        });
      });

      it('sets `testCaseLabelsSelectInProgress` to false', () => {
        jest.spyOn(wrapper.vm, 'updateTestCase').mockResolvedValue(mockTestCase);

        return wrapper.vm.handleUpdateSelectedLabels(updatedLabels).finally(() => {
          expect(wrapper.vm.testCaseLabelsSelectInProgress).toBe(false);
        });
      });
    });
  });

  describe('template', () => {
    it('renders todo button', async () => {
      let todoEl = wrapper.find('[data-testid="todo"]');

      expect(todoEl.exists()).toBe(true);
      expect(todoEl.text()).toContain('To Do');
      expect(todoEl.findComponent(GlButton).exists()).toBe(true);
      expect(todoEl.findComponent(GlButton).text()).toBe('Add a to do');

      wrapper.setProps({
        sidebarExpanded: false,
      });

      await nextTick();

      todoEl = wrapper.findComponent(GlButton);

      expect(todoEl.exists()).toBe(true);
      expect(todoEl.attributes('title')).toBe('Add a to do');
      expect(todoEl.findComponent(GlIcon).exists()).toBe(true);
    });

    it('renders label-select', () => {
      const { testCaseId, canEditTestCase, projectFullPath, testCasesPath } = mockProvide;
      const labelSelectEl = wrapper.findComponent(LabelsSelectWidget);

      expect(labelSelectEl.exists()).toBe(true);
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

    it('renders project-select', () => {
      const { selectProjectDropdownButtonTitle, testCaseMoveInProgress } = wrapper.vm;
      const { projectsFetchPath } = mockProvide;
      const projectSelectEl = wrapper.findComponent(ProjectSelect);

      expect(projectSelectEl.exists()).toBe(true);
      expect(projectSelectEl.props()).toMatchObject({
        projectsFetchPath,
        dropdownButtonTitle: selectProjectDropdownButtonTitle,
        dropdownHeaderTitle: 'Move test case',
        moveInProgress: testCaseMoveInProgress,
      });
    });
  });
});
