import { GlDrawer } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RoadmapSettings from 'ee/roadmap/components/roadmap_settings.vue';

describe('RoadmapSettings', () => {
  let wrapper;

  const createComponent = ({ isOpen = false } = {}) => {
    wrapper = shallowMountExtended(RoadmapSettings, {
      propsData: { isOpen },
    });
  };

  const findSettingsDrawer = () => wrapper.findComponent(GlDrawer);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    it('render drawer and title', () => {
      expect(findSettingsDrawer().exists()).toBe(true);
      expect(findSettingsDrawer().text()).toContain('Roadmap settings');
    });
  });
});
