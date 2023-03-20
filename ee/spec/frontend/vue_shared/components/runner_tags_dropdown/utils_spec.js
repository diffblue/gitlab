import { getUniqueTagListFromEdges } from 'ee/vue_shared/components/runner_tags_dropdown/utils';
import { RUNNER_TAG_LIST_MOCK } from './mocks/mocks';

describe('getUniqueTagListFromEdges', () => {
  it('should join tagLists on node and return unique list of tags', () => {
    expect(getUniqueTagListFromEdges(RUNNER_TAG_LIST_MOCK)).toEqual([
      'macos',
      'linux',
      'docker',
      'backup',
      'development',
    ]);
  });
});
