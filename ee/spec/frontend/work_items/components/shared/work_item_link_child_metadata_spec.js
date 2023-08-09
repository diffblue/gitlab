import { GlIcon, GlBadge, GlTooltip } from '@gitlab/ui';
import { __ } from '~/locale';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { formatDate } from '~/lib/utils/datetime_utility';
import WorkItemLinkChildMetadata from 'ee/work_items/components/shared/work_item_link_child_metadata.vue';
import { healthStatusTextMap } from 'ee/sidebar/constants';
import { issueHealthStatusVariantMapping } from 'ee/related_items_tree/constants';

import { workItemObjectiveMetadataWidgets } from 'jest/work_items/mock_data';

describe('WorkItemLinkChildMetadataEE', () => {
  const { PROGRESS, HEALTH_STATUS } = workItemObjectiveMetadataWidgets;
  let wrapper;

  const createComponent = ({ metadataWidgets = workItemObjectiveMetadataWidgets } = {}) => {
    wrapper = shallowMountExtended(WorkItemLinkChildMetadata, {
      propsData: {
        metadataWidgets,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders item progress icon and percentage completion', () => {
    const progressEl = wrapper.findByTestId('item-progress');

    expect(progressEl.exists()).toBe(true);
    expect(progressEl.findComponent(GlIcon).props('name')).toBe('progress');
    expect(wrapper.findByTestId('progressValue').text().trim()).toBe(`${PROGRESS.progress}%`);
  });

  describe('progress tooltip', () => {
    it('renders gl-tooltip', () => {
      const progressEl = wrapper.findByTestId('item-progress');

      expect(progressEl.findComponent(GlTooltip).isVisible()).toBe(true);
    });

    it('renders progressTitle in bold', () => {
      expect(wrapper.findByTestId('progressTitle').text().trim()).toBe(__('Progress'));
    });

    it('renders progressText in bold', () => {
      expect(wrapper.findByTestId('progressText').text().trim()).toBe(__('Last updated'));
    });

    it('renders lastUpdatedInWords', () => {
      expect(wrapper.findByTestId('lastUpdatedInWords').text().trim()).toContain('just now');
    });

    it('renders lastUpdatedTimestamp in muted', () => {
      expect(wrapper.findByTestId('lastUpdatedTimestamp').text().trim()).toContain(
        formatDate(PROGRESS.updatedAt).toString(),
      );
    });
  });

  it('renders health status badge', () => {
    const { healthStatus } = HEALTH_STATUS;
    const healthStatusEl = wrapper.findComponent(GlBadge);

    expect(healthStatusEl.exists()).toBe(true);
    expect(healthStatusEl.props('variant')).toBe(issueHealthStatusVariantMapping[healthStatus]);
    expect(healthStatusEl.attributes('title')).toBe('Health status');
    expect(healthStatusEl.text().trim()).toBe(healthStatusTextMap[healthStatus]);
  });
});
