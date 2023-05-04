import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { escape } from 'lodash';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { __ } from '~/locale';
import AncestorsTree from 'ee/sidebar/components/ancestors_tree/ancestors_tree.vue';

describe('AncestorsTreeContainer', () => {
  let wrapper;
  const ancestors = [
    {
      id: 1,
      url: 'http://example.com/groups/gitlab-org/-/epics/90',
      title: 'A',
      state: 'open',
      hasParent: false,
    },
    {
      id: 2,
      url: 'http://example.com/groups/gitlab-org/-/epics/91',
      title: 'B',
      state: 'open',
      hasParent: true,
    },
  ];

  const defaultProps = {
    ancestors,
    isFetching: false,
  };

  const createComponent = (props = {}) => {
    wrapper = extendedWrapper(
      shallowMount(AncestorsTree, {
        propsData: { ...defaultProps, ...props },
      }),
    );
  };

  const findTooltip = () => wrapper.find('.collapse-truncated-title');
  const containsTimeline = () => wrapper.find('.vertical-timeline').exists();
  const containsValue = () => wrapper.find('.value').exists();
  const findParentWarning = () => wrapper.findByTestId('ancestor-parent-warning');

  it('renders all ancestors rows', () => {
    createComponent();

    expect(wrapper.findAll('.vertical-timeline-row')).toHaveLength(ancestors.length);
    expect(findParentWarning().exists()).toBe(false);
  });

  it('renders tooltip with the immediate parent', () => {
    createComponent();

    expect(findTooltip().text()).toBe(ancestors.slice(-1)[0].title);
  });

  it('does not render timeline when fetching', () => {
    createComponent({
      isFetching: true,
    });

    expect(containsTimeline()).toBe(false);
    expect(containsValue()).toBe(false);
  });

  it('render `None` when ancestors is an empty array', () => {
    createComponent({
      ancestors: [],
    });

    expect(containsTimeline()).toBe(false);
    expect(containsValue()).not.toBe(false);
  });

  it('render loading icon when isFetching is true', () => {
    createComponent({
      isFetching: true,
    });

    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
  });

  it('escapes html in the tooltip', () => {
    const title = '<script>alert(1);</script>';
    const escapedTitle = escape(title);

    createComponent({
      ancestors: [{ id: 1, url: '', title, state: 'open' }],
    });

    expect(findTooltip().text()).toBe(escapedTitle);
  });

  it('renders warning when not all ancestors can be viewed', () => {
    const ancestors2 = [
      {
        id: 1,
        url: 'http://example.com/groups/gitlab-org/-/epics/90',
        title: 'A',
        state: 'open',
        hasParent: true,
      },
      {
        id: 2,
        url: 'http://example.com/groups/gitlab-org/-/epics/91',
        title: 'B',
        state: 'open',
        hasParent: true,
      },
    ];

    createComponent({ ancestors: ancestors2 });

    expect(wrapper.findAll('.vertical-timeline-row')).toHaveLength(ancestors2.length + 1);
    expect(findParentWarning().exists()).toBe(true);
    expect(findParentWarning().text()).toBe(__("You don't have permission to view this epic"));
  });
});
