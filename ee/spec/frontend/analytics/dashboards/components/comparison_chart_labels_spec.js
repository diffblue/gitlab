import { GlLabel, GlButton, GlPopover } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ComparisonChartLabels from 'ee/analytics/dashboards/components/comparison_chart_labels.vue';
import { MOCK_LABELS } from '../mock_data';

describe('Comparison chart labels', () => {
  const webUrl = 'gdk.test/groups/group';

  let wrapper;

  const createWrapper = (props = {}) => {
    wrapper = mountExtended(ComparisonChartLabels, {
      propsData: {
        labels: MOCK_LABELS,
        webUrl,
        ...props,
      },
    });
  };

  const expectLabel = ({ title, color }) =>
    expect.objectContaining({
      title,
      backgroundColor: color,
      target: `${webUrl}/-/labels?search=${title}`,
    });

  const findPrimaryLabels = () => wrapper.findByTestId('primary-labels').findAllComponents(GlLabel);
  const findSeeMoreButton = () => wrapper.findComponent(GlButton);
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findPopoverLabels = () => findPopover().findAllComponents(GlLabel);

  describe('labels', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders a maximum of 2 labels on the page', () => {
      expect(findPrimaryLabels().length).toBe(2);
      [0, 1].forEach((index) =>
        expect(findPrimaryLabels().at(index).props()).toEqual(expectLabel(MOCK_LABELS[index])),
      );
    });

    it('renders all labels in the popover', () => {
      expect(findPopoverLabels().length).toBe(3);
      [0, 1, 2].forEach((index) =>
        expect(findPopoverLabels().at(index).props()).toEqual(expectLabel(MOCK_LABELS[index])),
      );
    });
  });

  describe('see more button', () => {
    it('does not render for < 3 labels', () => {
      createWrapper({ labels: [MOCK_LABELS[0]] });

      expect(findSeeMoreButton().exists()).toBe(false);
      expect(findPopover().exists()).toBe(false);
    });

    it('renders for >= 3 labels', () => {
      createWrapper();

      expect(findSeeMoreButton().exists()).toBe(true);
      expect(findPopover().exists()).toBe(true);
      expect(findPopover().props('target')).toBe(findSeeMoreButton().attributes('id'));
    });
  });
});
