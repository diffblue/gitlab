import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';

import { GlBadge, GlLink, GlLoadingIcon, GlSprintf, GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import TestCaseShowRoot from 'ee/test_case_show/components/test_case_show_root.vue';
import TestCaseSidebar from 'ee/test_case_show/components/test_case_sidebar.vue';
import projectTestCase from 'ee/test_case_show/queries/project_test_case.query.graphql';
import projectTestCaseTaskList from 'ee/test_case_show/queries/test_case_tasklist.query.graphql';
import { mockCurrentUserTodo } from 'jest/vue_shared/issuable/list/mock_data';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import IssuableBody from '~/vue_shared/issuable/show/components/issuable_body.vue';
import IssuableEditForm from '~/vue_shared/issuable/show/components/issuable_edit_form.vue';
import IssuableHeader from '~/vue_shared/issuable/show/components/issuable_header.vue';
import IssuableShow from '~/vue_shared/issuable/show/components/issuable_show_root.vue';
import IssuableEventHub from '~/vue_shared/issuable/show/event_hub';
import IssuableSidebar from '~/vue_shared/issuable/sidebar/components/issuable_sidebar_root.vue';

import {
  mockProvide,
  mockTestCase,
  mockTestCaseResponse,
  mockTaskCompletionResponse,
} from '../mock_data';

jest.mock('~/vue_shared/issuable/show/event_hub');

Vue.use(VueApollo);

describe('TestCaseShowRoot', () => {
  let wrapper;
  let mockApollo;
  const taskCompletionMock = jest.fn();

  const findBadge = () => wrapper.findComponent(GlBadge);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findIssuableShow = () => wrapper.findComponent(IssuableShow);
  const findTestCaseSidebar = () => wrapper.findComponent(TestCaseSidebar);

  const createComponent = ({
    testCaseHandler = jest.fn().mockResolvedValue(mockTestCaseResponse()),
    taskCompletionHandler = taskCompletionMock.mockResolvedValue(mockTaskCompletionResponse),
  } = {}) => {
    mockApollo = createMockApollo([
      [projectTestCase, testCaseHandler],
      [projectTestCaseTaskList, taskCompletionHandler],
    ]);

    wrapper = shallowMount(TestCaseShowRoot, {
      apolloProvider: mockApollo,
      provide: {
        ...mockProvide,
      },
      stubs: {
        GlSprintf,
        IssuableShow,
        IssuableHeader,
        IssuableBody,
        IssuableEditForm,
        IssuableSidebar,
      },
    });
  };

  afterEach(() => {
    mockApollo = null;
  });

  describe('computed', () => {
    describe.each`
      state       | isTestCaseOpen | statusIcon              | statusBadgeText | testCaseActionTitle
      ${'opened'} | ${true}        | ${'issue-open-m'}       | ${'Open'}       | ${'Archive test case'}
      ${'closed'} | ${false}       | ${'mobile-issue-close'} | ${'Archived'}   | ${'Reopen test case'}
    `(
      'when `testCase.state` is $state',
      ({ state, isTestCaseOpen, statusIcon, statusBadgeText, testCaseActionTitle }) => {
        beforeEach(async () => {
          createComponent({
            testCaseHandler: jest.fn().mockResolvedValue(
              mockTestCaseResponse({
                ...mockTestCase,
                state,
              }),
            ),
          });

          await waitForPromises();
        });

        it.each`
          propName                 | propValue
          ${'isTestCaseOpen'}      | ${isTestCaseOpen}
          ${'statusIcon'}          | ${statusIcon}
          ${'statusBadgeText'}     | ${statusBadgeText}
          ${'testCaseActionTitle'} | ${testCaseActionTitle}
        `('computed prop $propName returns $propValue', ({ propName, propValue }) => {
          expect(wrapper.vm[propName]).toBe(propValue);
        });
      },
    );

    describe('selectedLabels', () => {
      it('returns `testCase.labels.nodes` array with GraphQL IDs converted to numeric IDs', () => {
        mockTestCase.labels.nodes.forEach((label, index) => {
          expect(label.id.endsWith(`${wrapper.vm.selectedLabels[index].id}`)).toBe(true);
        });
      });
    });
  });

  describe('methods', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
    });

    describe('handleTestCaseStateChange', () => {
      const updateTestCase = {
        ...mockTestCase,
        state: 'closed',
      };

      beforeEach(() => {
        jest.spyOn(wrapper.vm, 'updateTestCase').mockResolvedValue(updateTestCase);
      });

      it('sets `testCaseStateChangeInProgress` prop to true', () => {
        wrapper.vm.handleTestCaseStateChange();

        expect(wrapper.vm.testCaseStateChangeInProgress).toBe(true);
      });

      it('calls `wrapper.vm.updateTestCase` with variable `stateEvent` and errorMessage string', () => {
        wrapper.vm.handleTestCaseStateChange();

        expect(wrapper.vm.updateTestCase).toHaveBeenCalledWith({
          variables: {
            stateEvent: 'CLOSE',
          },
          errorMessage: 'Something went wrong while updating the test case.',
        });
      });

      it('sets `testCase` prop with updated test case received in response', () => {
        return wrapper.vm.handleTestCaseStateChange().then(() => {
          expect(wrapper.vm.testCase).toBe(updateTestCase);
        });
      });

      it('sets `testCaseStateChangeInProgress` prop to false', () => {
        return wrapper.vm.handleTestCaseStateChange().then(() => {
          expect(wrapper.vm.testCaseStateChangeInProgress).toBe(false);
        });
      });
    });

    describe('handleEditTestCase', () => {
      it('sets `editTestCaseFormVisible` prop to true', () => {
        wrapper.vm.handleEditTestCase();

        expect(wrapper.vm.editTestCaseFormVisible).toBe(true);
      });
    });

    describe('handleSaveTestCase', () => {
      const updateTestCase = {
        ...mockTestCase,
        title: 'Foo',
        description: 'Bar',
      };

      beforeEach(() => {
        jest.spyOn(wrapper.vm, 'updateTestCase').mockResolvedValue(updateTestCase);
      });

      it('sets `testCaseSaveInProgress` prop to true', () => {
        wrapper.vm.handleSaveTestCase({
          issuableTitle: 'Foo',
          issuableDescription: 'Bar',
        });

        expect(wrapper.vm.testCaseSaveInProgress).toBe(true);
      });

      it('calls `wrapper.vm.updateTestCase` with variables `title` & `description` and errorMessage string', () => {
        wrapper.vm.handleSaveTestCase({
          issuableTitle: 'Foo',
          issuableDescription: 'Bar',
        });

        expect(wrapper.vm.updateTestCase).toHaveBeenCalledWith({
          variables: {
            title: 'Foo',
            description: 'Bar',
          },
          errorMessage: 'Something went wrong while updating the test case.',
        });
      });

      it('sets `testCase` prop with updated test case received in response and emits "update.issuable" on IssuableEventHub', () => {
        return wrapper.vm
          .handleSaveTestCase({
            issuableTitle: 'Foo',
            issuableDescription: 'Bar',
          })
          .then(() => {
            expect(wrapper.vm.testCase).toBe(updateTestCase);
            expect(wrapper.vm.editTestCaseFormVisible).toBe(false);
            expect(IssuableEventHub.$emit).toHaveBeenCalledWith('update.issuable');
          });
      });

      it('sets `testCaseSaveInProgress` prop to false', () => {
        return wrapper.vm
          .handleSaveTestCase({
            issuableTitle: 'Foo',
            issuableDescription: 'Bar',
          })
          .then(() => {
            expect(wrapper.vm.testCaseSaveInProgress).toBe(false);
          });
      });
    });

    describe('handleCancelClick', () => {
      it('sets `editTestCaseFormVisible` prop to false and emits "close.form" event in IssuableEventHub', async () => {
        findIssuableShow().vm.$emit('edit-issuable');

        await nextTick();

        wrapper.vm.handleCancelClick();

        expect(wrapper.vm.editTestCaseFormVisible).toBe(false);
        expect(IssuableEventHub.$emit).toHaveBeenCalledWith('close.form');
      });
    });

    describe('handleTestCaseUpdated', () => {
      it('assigns value of provided testCase param to `testCase` prop', () => {
        const updatedTestCase = {
          ...mockTestCase,
          title: 'Foo',
        };

        wrapper.vm.handleTestCaseUpdated(updatedTestCase);

        expect(wrapper.vm.testCase).toBe(updatedTestCase);
      });
    });
  });

  describe('template', () => {
    it('renders loading icon', () => {
      createComponent();

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findIssuableShow().exists()).toBe(false);
    });

    describe('when query is successful', () => {
      beforeEach(async () => {
        createComponent();

        await waitForPromises();
      });

      it('renders IssuableShow', () => {
        const {
          canEditTestCase,
          descriptionPreviewPath,
          descriptionHelpPath,
          updatePath,
          lockVersion,
        } = mockProvide;
        const issuableShowEl = findIssuableShow();

        expect(findLoadingIcon().exists()).toBe(false);
        expect(issuableShowEl.exists()).toBe(true);
        expect(issuableShowEl.props()).toMatchObject({
          descriptionPreviewPath,
          descriptionHelpPath,
          enableAutocomplete: true,
          enableTaskList: true,
          issuable: mockTestCase,
          enableEdit: canEditTestCase,
          taskCompletionStatus: {},
          taskListUpdatePath: updatePath,
          taskListLockVersion: lockVersion,
        });
      });

      describe('when IssuableShow emits `edit-issuable`', () => {
        beforeEach(() => {
          findIssuableShow().vm.$emit('edit-issuable');
        });

        it('renders edit-form-actions slot contents', () => {
          expect(wrapper.find('[data-testid="save-test-case"]').exists()).toBe(true);
          expect(wrapper.find('[data-testid="cancel-test-case-edit"]').exists()).toBe(true);
        });
      });

      describe('when IssuableShow emits `task-list-update-failure`', () => {
        beforeEach(() => {
          findIssuableShow().vm.$emit('task-list-update-failure');
        });

        it('renders alert', () => {
          const alert = wrapper.findComponent(GlAlert);

          expect(alert.exists()).toBe(true);
          expect(alert.text()).toBe(
            'Someone edited this test case at the same time you did. The description has been updated and you will need to make your changes again.',
          );
        });
      });

      describe('when IssuableShow emits `task-list-update-success`', () => {
        beforeEach(() => {
          findIssuableShow().vm.$emit('task-list-update-success');
        });

        it('refetches taskCompletionStatus', () => {
          expect(taskCompletionMock).toHaveBeenCalledTimes(2);
        });
      });

      it('renders status-badge slot contents', () => {
        expect(findBadge().text()).toContain('Open');
      });

      it('renders status-badge slot contents with updated test case URL when testCase.moved is true', async () => {
        const movedTestCase = {
          ...mockTestCase,
          status: 'closed',
          moved: true,
          movedTo: {
            id: 'gid://gitlab/Issue/2',
            webUrl: 'http://0.0.0.0:3000/gitlab-org/gitlab-test/-/issues/30',
          },
        };

        createComponent({
          testCaseHandler: jest.fn().mockResolvedValue(mockTestCaseResponse(movedTestCase)),
        });

        await waitForPromises();

        const statusEl = findBadge();

        expect(statusEl.text()).toContain('Archived');
        expect(statusEl.findComponent(GlLink).attributes('href')).toBe(
          movedTestCase.movedTo.webUrl,
        );
      });

      it('renders header-actions slot contents', () => {
        expect(wrapper.find('[data-testid="actions-dropdown"]').exists()).toBe(true);
        expect(wrapper.find('[data-testid="archive-test-case"]').exists()).toBe(true);
        expect(wrapper.find('[data-testid="new-test-case"]').exists()).toBe(true);
      });

      it('renders test-case-sidebar', () => {
        expect(findTestCaseSidebar().exists()).toBe(true);
        expect(findTestCaseSidebar().props('todo')).toEqual(mockCurrentUserTodo);
      });

      it('updates `sidebarExpanded` prop on `sidebar-toggle` event', async () => {
        const testCaseSidebar = findTestCaseSidebar();
        expect(testCaseSidebar.props('sidebarExpanded')).toBe(true);

        testCaseSidebar.vm.$emit('sidebar-toggle');
        await nextTick();

        expect(testCaseSidebar.props('sidebarExpanded')).toBe(false);
      });
    });

    it('does not render IssuableShow when query fails', async () => {
      createComponent({
        testCaseHandler: jest.fn().mockRejectedValue({ error: 'hello' }),
      });

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(findIssuableShow().exists()).toBe(false);
    });
  });
});
