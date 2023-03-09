import { GlFriendlyWrap, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Url from 'ee/vulnerabilities/components/generic_report/types/url.vue';

const TEST_DATA = {
  href: 'http://gitlab.com',
};

describe('ee/vulnerabilities/components/generic_report/types/url.vue', () => {
  let wrapper;

  const createWrapper = () => {
    return shallowMount(Url, {
      propsData: {
        ...TEST_DATA,
      },
    });
  };

  const findLink = () => wrapper.findComponent(GlLink);

  beforeEach(() => {
    wrapper = createWrapper();
  });

  it('renders a link', () => {
    expect(findLink().exists()).toBe(true);
  });

  it('passes the href to the link', () => {
    expect(findLink().attributes('href')).toBe(TEST_DATA.href);
  });

  it('shows the href as the link-text and makes it wrap if needed', () => {
    // `GlFriendlyWrap` is a functional component, so we have to use `attributes` instead of `props`
    expect(findLink().findComponent(GlFriendlyWrap).attributes('text')).toBe(TEST_DATA.href);
  });
});
