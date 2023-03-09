import { GlDrawer } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RoadmapSettings from 'ee/roadmap/components/roadmap_settings.vue';
import RoadmapDaterange from 'ee/roadmap/components/roadmap_daterange.vue';
import RoadmapEpicsState from 'ee/roadmap/components/roadmap_epics_state.vue';
import RoadmapMilestones from 'ee/roadmap/components/roadmap_milestones.vue';
import RoadmapProgressTracking from 'ee/roadmap/components/roadmap_progress_tracking.vue';
import RoadmapToggleLabels from 'ee/roadmap/components/roadmap_toggle_labels.vue';

describe('RoadmapSettings', () => {
  let wrapper;

  const createComponent = ({ isOpen = false } = {}) => {
    wrapper = shallowMountExtended(RoadmapSettings, {
      propsData: { isOpen, timeframeRangeType: 'CURRENT_QUARTER' },
    });
  };

  const findSettingsDrawer = () => wrapper.findComponent(GlDrawer);
  const findDaterange = () => wrapper.findComponent(RoadmapDaterange);
  const findMilestones = () => wrapper.findComponent(RoadmapMilestones);
  const findEpicsSate = () => wrapper.findComponent(RoadmapEpicsState);
  const findProgressTracking = () => wrapper.findComponent(RoadmapProgressTracking);
  const findToggleLabels = () => wrapper.findComponent(RoadmapToggleLabels);

  beforeEach(() => {
    createComponent();
  });

  describe('template', () => {
    it('renders drawer and title', () => {
      expect(findSettingsDrawer().exists()).toBe(true);
      expect(findSettingsDrawer().text()).toContain('Roadmap settings');
    });

    it('renders roadmap daterange component', () => {
      expect(findDaterange().exists()).toBe(true);
    });

    it('renders roadmap milestones component', () => {
      expect(findMilestones().exists()).toBe(true);
    });

    it('renders roadmap epics state component', () => {
      expect(findEpicsSate().exists()).toBe(true);
    });

    it('renders roadmap progress tracking component', () => {
      expect(findProgressTracking().exists()).toBe(true);
    });

    it('renders roadmap toggle labels', () => {
      expect(findToggleLabels().exists()).toBe(true);
    });
  });
});
