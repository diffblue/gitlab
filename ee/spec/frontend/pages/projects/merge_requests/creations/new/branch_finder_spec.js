import MockAdapter from 'axios-mock-adapter';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import axios from '~/lib/utils/axios_utils';
import { findTargetBranch } from 'ee/pages/projects/merge_requests/creations/new/branch_finder';

let mock;

describe('Merge request find target branch', () => {
  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet('/target_branch').reply(200, { target_branch: 'main' });
  });

  afterEach(() => {
    resetHTMLFixture();
    mock.restore();
  });

  describe('element does not exist', () => {
    it('returns null', async () => {
      expect(await findTargetBranch()).toBe(null);
    });
  });

  describe('element exists', () => {
    beforeEach(() => {
      setHTMLFixture(
        '<div class="js-merge-request-new-compare" data-target-branch-finder-path="/target_branch"></div>',
      );
    });

    it('returns target branch', async () => {
      expect(await findTargetBranch()).toBe('main');
    });
  });
});
