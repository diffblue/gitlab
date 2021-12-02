import { parseGetProjectStorageResults } from 'ee/usage_quotas/storage/utils';
import {
  projectData,
  mockGetProjectStorageStatisticsGraphQLResponse,
  defaultProjectProvideValues,
} from './mock_data';

describe('parseGetProjectStorageResults', () => {
  it('parses project statistics correctly', () => {
    expect(
      parseGetProjectStorageResults(
        mockGetProjectStorageStatisticsGraphQLResponse.data,
        defaultProjectProvideValues.helpLinks,
      ),
    ).toMatchObject(projectData);
  });

  it('includes storage type with size of 0 in returned value', () => {
    const mockedResponse = mockGetProjectStorageStatisticsGraphQLResponse.data;
    // ensuring a specific storage type item has size of 0
    mockedResponse.project.statistics.repositorySize = 0;

    const response = parseGetProjectStorageResults(
      mockedResponse,
      defaultProjectProvideValues.helpLinks,
    );

    expect(response.storage.storageTypes).toEqual(
      expect.arrayContaining([
        {
          storageType: expect.any(Object),
          value: 0,
        },
      ]),
    );
  });
});
