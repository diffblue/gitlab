import { GlDrawer } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RoadmapSettings from 'ee/roadmap/components/roadmap_settings.vue';
import RoadmapDaterange from 'ee/roadmap/components/roadmap_daterange.vue';

describe('RoadmapSettings', () => {
  let wrapper;

  const createComponent = ({ isOpen = false } = {}) => {
    wrapper = shallowMountExtended(RoadmapSettings, {
      propsData: { isOpen, timeframeRangeType: 'CURRENT_QUARTER' },
    });
  };

  const findSettingsDrawer = () => wrapper.findComponent(GlDrawer);
  const findDaterange = () => wrapper.findComponent(RoadmapDaterange);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    it('renders drawer and title', () => {
      expect(findSettingsDrawer().exists()).toBe(true);
      expect(findSettingsDrawer().text()).toContain('Roadmap settings');
    });

    it('renders roadmap daterange component', () => {
      expect(findDaterange().exists()).toBe(true);
    });
  });
});
