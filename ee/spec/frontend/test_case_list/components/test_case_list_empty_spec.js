import { GlEmptyState, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import { nextTick } from 'vue';
import TestCaseListEmptyState from 'ee/test_case_list/components/test_case_list_empty_state.vue';

const createComponent = (props = {}) =>
  shallowMount(TestCaseListEmptyState, {
    provide: {
      canCreateTestCase: true,
      testCaseNewPath: '/gitlab-org/gitlab-test/-/quality/test_cases/new',
      emptyStatePath: '/assets/illustrations/empty-state/test-cases.svg',
    },
    propsData: {
      currentState: 'opened',
      testCasesCount: {
        opened: 0,
        closed: 0,
        all: 0,
      },
      ...props,
    },
    stubs: { GlEmptyState },
  });

describe('TestCaseListEmptyState', () => {
  let wrapper;

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('computed', () => {
    describe('emptyStateTitle', () => {
      it('returns string "There are no open test cases" when value of `currentState` prop is "opened" and project has some test cases', async () => {
        wrapper.setProps({
          testCasesCount: {
            opened: 0,
            closed: 2,
            all: 2,
          },
        });

        await nextTick();

        expect(wrapper.vm.emptyStateTitle).toBe('There are no open test cases');
      });

      it('returns string "There are no archived test cases" when value of `currenState` prop is "closed" and project has some test cases', async () => {
        wrapper.setProps({
          currentState: 'closed',
          testCasesCount: {
            opened: 2,
            closed: 0,
            all: 2,
          },
        });

        await nextTick();

        expect(wrapper.vm.emptyStateTitle).toBe('There are no archived test cases');
      });

      it('returns a generic string when project has no test cases', () => {
        expect(wrapper.vm.emptyStateTitle).toBe('Improve quality with test cases');
      });
    });

    describe('showDescription', () => {
      it.each`
        allCount | returnValue
        ${0}     | ${true}
        ${1}     | ${false}
      `(
        'returns $returnValue when count of total test cases in project is $allCount',
        async ({ allCount, returnValue }) => {
          wrapper.setProps({
            testCasesCount: {
              opened: allCount,
              closed: 0,
              all: allCount,
            },
          });

          await nextTick();

          expect(wrapper.vm.showDescription).toBe(returnValue);
        },
      );
    });
  });

  describe('template', () => {
    it('renders gl-empty-state component', () => {
      expect(findEmptyState().exists()).toBe(true);
    });

    it('renders empty state description', () => {
      expect(findEmptyState().exists()).toBe(true);
      expect(findEmptyState().text()).toContain(
        'Create testing scenarios by defining project conditions in your development platform.',
      );
    });

    it('renders "New test cases" button', () => {
      const buttonEl = wrapper.findComponent(GlButton);

      expect(buttonEl.exists()).toBe(true);
      expect(buttonEl.attributes('href')).toBe('/gitlab-org/gitlab-test/-/quality/test_cases/new');
      expect(buttonEl.text()).toBe('New test case');
    });
  });
});
