import { GlBadge } from '@gitlab/ui';
import IssueHealthStatus from 'ee/related_items_tree/components/issue_health_status.vue';
import {
  issueHealthStatus,
  issueHealthStatusVariantMapping,
} from 'ee/related_items_tree/constants';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockIssue1 } from '../mock_data';

describe('IssueHealthStatus', () => {
  const { healthStatus } = mockIssue1;
  let wrapper;

  const createComponent = () =>
    shallowMountExtended(IssueHealthStatus, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      propsData: {
        healthStatus,
      },
    });

  const findHealthStatus = () => wrapper.findComponent(GlBadge);

  beforeEach(() => {
    wrapper = createComponent();
  });

  it('renders health status text', () => {
    const expectedValue = issueHealthStatus[healthStatus];

    expect(findHealthStatus().text()).toBe(expectedValue);
  });

  it('applies correct health status class', () => {
    expect(findHealthStatus().attributes('variant')).toBe(
      issueHealthStatusVariantMapping[healthStatus],
    );
  });

  it('contains health status tooltip', () => {
    expect(getBinding(findHealthStatus().element, 'gl-tooltip')).not.toBeUndefined();
    expect(findHealthStatus().attributes('title')).toBe('Health status');
  });
});
