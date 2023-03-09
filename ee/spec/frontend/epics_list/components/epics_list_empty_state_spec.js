import { GlEmptyState } from '@gitlab/ui';
import { mount } from '@vue/test-utils';

import { nextTick } from 'vue';
import EpicsListEmptyState from 'ee/epics_list/components/epics_list_empty_state.vue';

const createComponent = (props = {}) =>
  mount(EpicsListEmptyState, {
    provide: {
      emptyStatePath: '/assets/illustrations/empty-state/epics.svg',
    },
    propsData: {
      currentState: 'opened',
      epicsCount: {
        opened: 0,
        closed: 0,
        all: 0,
      },
      ...props,
    },
  });

describe('EpicsListEmptyState', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('template', () => {
    it('renders gl-empty-state component', () => {
      const emptyStateEl = wrapper.findComponent(GlEmptyState);

      expect(emptyStateEl.exists()).toBe(true);
      expect(emptyStateEl.props('svgPath')).toBe('/assets/illustrations/empty-state/epics.svg');
    });

    it('returns string "There are no open epics" when value of `currentState` prop is "opened" and group has some epics', async () => {
      wrapper.setProps({
        epicsCount: {
          opened: 0,
          closed: 2,
          all: 2,
        },
      });

      await nextTick();

      expect(wrapper.find('h1').text()).toBe('There are no open epics');
    });

    it('returns string "There are no archived epics" when value of `currenState` prop is "closed" and group has some epics', async () => {
      wrapper.setProps({
        currentState: 'closed',
        epicsCount: {
          opened: 2,
          closed: 0,
          all: 2,
        },
      });

      await nextTick();

      expect(wrapper.find('h1').text()).toBe('There are no closed epics');
    });

    it('returns a generic string when group has no epics', () => {
      expect(wrapper.find('h1').text()).toBe(
        'Epics let you manage your portfolio of projects more efficiently and with less effort',
      );
    });

    it('renders empty state description with default description when all epics count is not zero', async () => {
      wrapper.setProps({
        epicsCount: {
          opened: 0,
          closed: 0,
          all: 0,
        },
      });

      await nextTick();

      expect(wrapper.find('p').exists()).toBe(true);
      expect(wrapper.find('p').text()).toContain(
        'Track groups of issues that share a theme, across projects and milestones',
      );
    });

    it('does not render empty state description when all epics count is zero', async () => {
      wrapper.setProps({
        epicsCount: {
          opened: 1,
          closed: 0,
          all: 1,
        },
      });

      await nextTick();

      expect(wrapper.find('p').exists()).toBe(false);
    });
  });
});
