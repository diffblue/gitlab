import { GlEmptyState, GlSprintf, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

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

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
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

        await wrapper.vm.$nextTick();

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

        await wrapper.vm.$nextTick();

        expect(wrapper.vm.emptyStateTitle).toBe('There are no archived test cases');
      });

      it('returns a generic string when project has no test cases', () => {
        expect(wrapper.vm.emptyStateTitle).toBe(
          'With test cases, you can define conditions for your project to meet in determining quality',
        );
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

          await wrapper.vm.$nextTick();

          expect(wrapper.vm.showDescription).toBe(returnValue);
        },
      );
    });
  });

  describe('template', () => {
    it('renders gl-empty-state component', () => {
      expect(wrapper.findComponent(GlEmptyState).exists()).toBe(true);
    });

    it('renders empty state description', () => {
      const descriptionEl = wrapper.findComponent(GlSprintf);

      expect(descriptionEl.exists()).toBe(true);
      expect(descriptionEl.attributes('message')).toBe(
        'You can group test cases using labels. To learn about the future direction of this feature, visit %{linkStart}Quality Management direction page%{linkEnd}.',
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
