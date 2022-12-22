import { GlIcon, GlBadge } from '@gitlab/ui';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import WorkItemLinkChildMetadata from 'ee/work_items/components/work_item_links/work_item_link_child_metadata.vue';
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
    expect(progressEl.attributes('title')).toBe('Progress');
    expect(progressEl.text().trim()).toBe(`${PROGRESS.progress}%`);
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
