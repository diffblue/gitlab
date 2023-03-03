import {
  initMergeOptionSettings,
  ERROR_LOADING_MERGE_OPTION_SETTINGS,
} from 'ee/pages/projects/edit/merge_options';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { createAlert } from '~/alert';
import * as createDefaultClient from '~/lib/graphql';

jest.mock('~/alert');

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

  it('shows alert message on network error', async () => {
    await initMergeOptionSettings();

    expect(createAlert).toHaveBeenCalledWith({
      message: ERROR_LOADING_MERGE_OPTION_SETTINGS,
      error: 'Error',
      captureError: true,
    });
  });
});
