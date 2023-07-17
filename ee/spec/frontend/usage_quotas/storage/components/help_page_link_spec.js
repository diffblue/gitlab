import { shallowMount, Wrapper } from '@vue/test-utils'; // eslint-disable-line no-unused-vars
import { GlLink } from '@gitlab/ui';
import HelpPageLink from 'ee/usage_quotas/storage/components/help_page_link.vue';
import { helpPagePath } from '~/helpers/help_page_helper';

/** @type { Wrapper } */
let wrapper;

const createComponent = (props = {}) => {
  wrapper = shallowMount(HelpPageLink, {
    propsData: {
      ...props,
    },
    stubs: {
      GlLink: true,
    },
  });
};

const findGlLink = () => wrapper.findComponent(GlLink);

describe('HelpPageLink', () => {
  it('renders a link', () => {
    const path = 'the/turtle/cross';
    createComponent({ path });

    const link = findGlLink();
    const expectedHref = helpPagePath(path, { anchor: null });
    expect(link.attributes().href).toBe(expectedHref);
  });

  it('adds the anchor', () => {
    const path = 'the/turtle/cross';
    const anchor = '#and-be-quick';
    createComponent({ path, anchor });

    const link = findGlLink();
    const expectedHref = helpPagePath(path, { anchor });
    expect(link.attributes().href).toBe(expectedHref);
  });
});
