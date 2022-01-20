import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { escape } from 'lodash';
import AncestorsTree from 'ee/sidebar/components/ancestors_tree/ancestors_tree.vue';

describe('AncestorsTreeContainer', () => {
  let wrapper;
  const ancestors = [
    { id: 1, url: '', title: 'A', state: 'open' },
    { id: 2, url: '', title: 'B', state: 'open' },
  ];

  const defaultProps = {
    ancestors,
    isFetching: false,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(AncestorsTree, {
      propsData: { ...defaultProps, ...props },
    });
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  const findTooltip = () => wrapper.find('.collapse-truncated-title');
  const containsTimeline = () => wrapper.find('.vertical-timeline').exists();
  const containsValue = () => wrapper.find('.value').exists();

  it('renders all ancestors rows', () => {
    createComponent();

    expect(wrapper.findAll('.vertical-timeline-row')).toHaveLength(ancestors.length);
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
});
