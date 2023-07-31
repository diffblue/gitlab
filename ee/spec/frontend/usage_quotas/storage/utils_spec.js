import { parseGetStorageResults } from 'ee/usage_quotas/storage/utils';
import { mockGetNamespaceStorageStatisticsGraphQLResponse } from './mock_data';

describe('parseGetStorageResults', () => {
  it('returns the object keys we use', () => {
    const objectKeys = Object.keys(
      parseGetStorageResults(mockGetNamespaceStorageStatisticsGraphQLResponse.data),
    );
    expect(objectKeys).toEqual([
      'projects',
      'additionalPurchasedStorageSize',
      'actualRepositorySizeLimit',
      'containsLockedProjects',
      'repositorySizeExcessProjectCount',
      'totalRepositorySize',
      'totalRepositorySizeExcess',
      'totalUsage',
      'rootStorageStatistics',
      'limit',
    ]);
  });
});
