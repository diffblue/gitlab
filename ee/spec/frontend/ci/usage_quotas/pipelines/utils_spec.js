import { formatDate } from '~/lib/utils/datetime_utility';
import { getProjectMinutesUsage } from 'ee/ci/usage_quotas/pipelines/utils';
import { mockGetNamespaceProjectsInfo, mockGetCiMinutesUsageNamespace } from './mock_data';

describe('getProjectMinutesUsage', () => {
  it('returns the correct ci minutes for the current month', () => {
    expect(
      getProjectMinutesUsage(
        mockGetNamespaceProjectsInfo.data.namespace.projects.nodes[0],
        mockGetCiMinutesUsageNamespace.data.ciMinutesUsage.nodes.map((node) => ({
          ...node,
          monthIso8601: formatDate(Date.now(), 'yyyy-mm-dd'),
        })),
      ),
    ).toBe(35);
  });

  it('returns 0 ci minutes if no usage in the current month', () => {
    expect(
      getProjectMinutesUsage(
        mockGetNamespaceProjectsInfo.data.namespace.projects.nodes[0],
        mockGetCiMinutesUsageNamespace.data.ciMinutesUsage.nodes,
      ),
    ).toBe(0);
  });
});
