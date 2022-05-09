import {
  initMergeOptionSettings,
  ERROR_LOADING_MERGE_OPTION_SETTINGS,
} from 'ee/pages/projects/edit/merge_options';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import createFlash from '~/flash';
import * as createDefaultClient from '~/lib/graphql';

jest.mock('~/flash');

describe('MergOptions', () => {
  beforeEach(() => {
    setHTMLFixture(`
      <div id="project-merge-options"></div/>
    `);

    createDefaultClient.default = jest.fn(() => ({
      query: jest.fn().mockRejectedValue('Error'),
    }));
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('shows flash message on network error', async () => {
    await initMergeOptionSettings();

    expect(createFlash).toHaveBeenCalledWith({
      message: ERROR_LOADING_MERGE_OPTION_SETTINGS,
      error: 'Error',
      captureError: true,
    });
  });
});
