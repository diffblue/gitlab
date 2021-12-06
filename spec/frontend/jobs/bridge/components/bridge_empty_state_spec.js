import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import BridgeEmptyState from '~/jobs/bridge/components/empty_state.vue';
import { MOCK_EMPTY_ILLUSTRATION_PATH, MOCK_PATH_TO_DOWNSTREAM } from '../mock_data';

describe('Bridge Empty State', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(BridgeEmptyState, {
      provide: {
        downstreamPipelinePath: MOCK_PATH_TO_DOWNSTREAM,
        emptyStateIllustrationPath: MOCK_EMPTY_ILLUSTRATION_PATH,
      },
    });
  };

  const findSvg = () => wrapper.find('img');
  const findTitle = () => wrapper.find('h1');
  const findLinkBtn = () => wrapper.findComponent(GlButton);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders illustration', () => {
      expect(findSvg().exists()).toBe(true);
    });

    it('renders title', () => {
      expect(findTitle().exists()).toBe(true);
      expect(findTitle().text()).toBe(wrapper.vm.$options.i18n.title);
    });

    it('renders CTA button', () => {
      expect(findLinkBtn().exists()).toBe(true);
      expect(findLinkBtn().text()).toBe(wrapper.vm.$options.i18n.linkBtnText);
      expect(findLinkBtn().attributes('href')).toBe(MOCK_PATH_TO_DOWNSTREAM);
    });
  });
});
