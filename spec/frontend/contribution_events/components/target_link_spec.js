import { GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TargetLink from '~/contribution_events/components/target_link.vue';
import { eventApproved, eventJoined } from '../utils';

describe('TargetLink', () => {
  let wrapper;

  const defaultPropsData = {
    event: eventApproved(),
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(TargetLink, {
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
    });
  };

  describe('when target is defined', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders link', () => {
      const link = wrapper.findComponent(GlLink);
      const { web_url: webUrl, title, reference_link_text } = defaultPropsData.event.target;

      expect(link.attributes()).toMatchObject({
        href: webUrl,
        title,
      });
      expect(link.text()).toBe(reference_link_text);
    });
  });

  describe('when target is not defined', () => {
    beforeEach(() => {
      createComponent({ propsData: { event: eventJoined() } });
    });

    it('renders nothing', () => {
      expect(wrapper.html()).toBe('');
    });
  });
});
