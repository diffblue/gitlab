import { GlEmptyState, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import RequirementsEmptyState from 'ee/requirements/components/requirements_empty_state.vue';
import { filterState } from 'ee/requirements/constants';

const createComponent = (props = {}) =>
  shallowMount(RequirementsEmptyState, {
    propsData: {
      filterBy: filterState.opened,
      emptyStatePath: '/assets/illustrations/empty-state/requirements.svg',
      requirementsCount: {
        OPENED: 0,
        ARCHIVED: 0,
        ALL: 0,
      },
      canCreateRequirement: true,
      ...props,
    },
    stubs: { GlEmptyState },
  });

describe('RequirementsEmptyState', () => {
  let wrapper;

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findNewRequirementButton = () => wrapper.findComponent(GlButton);

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('template', () => {
    describe('when project has no requirements', () => {
      it('renders empty state', () => {
        expect(findEmptyState().props()).toMatchObject({
          svgPath: '/assets/illustrations/empty-state/requirements.svg',
          title: 'With requirements, you can set criteria to check your products against.',
          description:
            'Requirements can be based on users, stakeholders, system, software, or anything else you find important to capture.',
        });
      });

      it('renders new requirement button', () => {
        expect(findNewRequirementButton().text()).toBe('New requirement');
      });
    });

    describe('when project has some "OPENED" requirements', () => {
      beforeEach(() => {
        wrapper = createComponent({
          requirementsCount: {
            OPENED: 2,
            ARCHIVED: 0,
            ALL: 2,
          },
        });
      });

      it('does not render new requirement button', () => {
        expect(findNewRequirementButton().exists()).toBe(false);
      });

      describe('when value of `filterBy` prop is "ARCHIVED"', () => {
        beforeEach(() => {
          wrapper = createComponent({
            filterBy: filterState.archived,
            requirementsCount: {
              OPENED: 2,
              ARCHIVED: 0,
              ALL: 2,
            },
          });
        });

        it('renders empty state', () => {
          expect(findEmptyState().props()).toMatchObject({
            title: 'There are no archived requirements',
            description: null,
          });
        });
      });
    });

    describe('when project has some "ARCHIVED" requirements', () => {
      describe('when value of `filterBy` prop is "OPENED"', () => {
        beforeEach(() => {
          wrapper = createComponent({
            requirementsCount: {
              OPENED: 0,
              ARCHIVED: 2,
              ALL: 2,
            },
          });
        });

        it('renders empty state', () => {
          expect(findEmptyState().props()).toMatchObject({
            title: 'There are no open requirements',
            description: null,
          });
        });
      });
    });

    describe('when user is not authorized', () => {
      beforeEach(() => {
        wrapper = createComponent({
          canCreateRequirement: false,
        });
      });

      it('does not render new requirement button', () => {
        expect(findNewRequirementButton().exists()).toBe(false);
      });
    });
  });
});
