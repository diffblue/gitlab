import { provide } from 'ee/ci/runner/admin_runners/provide';

import {
  onlineContactTimeoutSecs,
  staleTimeoutSecs,
  runnerInstallHelpPage,
} from 'jest/ci/runner/mock_data';
import { runnerDashboardPath } from 'ee_jest/ci/runner/mock_data';

const mockDataset = {
  runnerInstallHelpPage,
  onlineContactTimeoutSecs,
  staleTimeoutSecs,
  runnerDashboardPath,
};

describe('ee admin runners provide', () => {
  it('returns runnerDashboardPath', () => {
    expect(provide(mockDataset)).toMatchObject({
      runnerDashboardPath,
    });
  });
});
