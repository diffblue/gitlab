import { GlEmptyState, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import {
  EMPTY_STATE_DESCRIPTION,
  NO_ENVIRONMENT_TITLE,
} from 'ee/threat_monitoring/components/constants';
import NoEnvironmentEmptyState from 'ee/threat_monitoring/components/no_environment_empty_state.vue';

const documentationPath = '/docs';
const emptyStateSvgPath = '/svgs';

describe('NoEnvironmentEmptyState component', () => {
  let wrapper;

  const findGlEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findGlSprintf = () => wrapper.findComponent(GlSprintf);

  const factory = () => {
    wrapper = shallowMount(NoEnvironmentEmptyState, {
      provide: {
        documentationPath,
        emptyStateSvgPath,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('default state', () => {
    beforeEach(() => {
      factory();
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('shows the GlEmptyState component', () => {
      expect(findGlEmptyState().exists()).toBe(true);
      expect(findGlEmptyState().attributes()).toMatchObject({
        title: NO_ENVIRONMENT_TITLE,
        svgpath: emptyStateSvgPath,
      });
    });

    it('shows the message', () => {
      expect(findGlSprintf().exists()).toBe(true);
      expect(findGlSprintf().attributes('message')).toBe(EMPTY_STATE_DESCRIPTION);
    });
  });
});
