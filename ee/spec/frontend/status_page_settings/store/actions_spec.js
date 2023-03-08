import MockAdapter from 'axios-mock-adapter';
import * as actions from 'ee/status_page_settings/store/actions';
import * as types from 'ee/status_page_settings/store/mutation_types';
import testAction from 'helpers/vuex_action_helper';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { refreshCurrentPage } from '~/lib/utils/url_utility';

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility');

let mock;

describe('Status Page actions', () => {
  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  const state = {
    enabled: true,
    bucketName: 'test-bucket',
    region: 'us-west',
  };

  it.each`
    mutation                         | action                            | value                 | key
    ${types.SET_STATUS_PAGE_ENABLED} | ${'setStatusPageEnabled'}         | ${true}               | ${'enabled'}
    ${types.SET_STATUS_PAGE_URL}     | ${'setStatusPageUrl'}             | ${'http://status.io'} | ${'url'}
    ${types.SET_BUCKET_NAME}         | ${'setStatusPageBucketName'}      | ${'my-bucket'}        | ${'bucketName'}
    ${types.SET_REGION}              | ${'setStatusPageRegion'}          | ${'us-west'}          | ${'region'}
    ${types.SET_ACCESS_KEY_ID}       | ${'setStatusPageAccessKey'}       | ${'key-id'}           | ${'awsAccessKey'}
    ${types.SET_SECRET_ACCESS_KEY}   | ${'setStatusPageSecretAccessKey'} | ${'secret'}           | ${'awsSecretKey'}
  `('$action will commit $mutation with $value', ({ mutation, action, value, key }) => {
    testAction(
      actions[action],
      { [key]: value },
      null,
      [
        {
          type: mutation,
          payload: value,
        },
      ],
      [],
    );
  });

  describe('updateStatusPageSettings', () => {
    it('should handle successful status update', () => {
      mock.onPatch().reply(HTTP_STATUS_OK, {});
      testAction(
        actions.updateStatusPageSettings,
        null,
        state,
        [
          {
            payload: true,
            type: types.LOADING,
          },
          {
            payload: false,
            type: types.LOADING,
          },
        ],
        [{ type: 'receiveStatusPageSettingsUpdateSuccess' }],
      );
    });

    it('should handle unsuccessful status update', () => {
      mock.onPatch().reply(HTTP_STATUS_BAD_REQUEST, {});
      testAction(
        actions.updateStatusPageSettings,
        null,
        state,
        [
          {
            payload: true,
            type: types.LOADING,
          },
          {
            payload: false,
            type: types.LOADING,
          },
        ],
        [
          {
            payload: expect.any(Object),
            type: 'receiveStatusPageSettingsUpdateError',
          },
        ],
      );
    });
  });

  describe('receiveStatusPageSettingsUpdateSuccess', () => {
    it('should handle successful settings update', async () => {
      await testAction(actions.receiveStatusPageSettingsUpdateSuccess, null, null, [], []);

      expect(refreshCurrentPage).toHaveBeenCalledTimes(1);
    });
  });

  describe('receiveStatusPageSettingsUpdateError', () => {
    const error = { response: { data: { message: 'Update error' } } };
    it('should handle error update', async () => {
      await testAction(actions.receiveStatusPageSettingsUpdateError, error, null, [], []);

      expect(createAlert).toHaveBeenCalledWith({
        message: `There was an error saving your changes. ${error.response.data.message}`,
      });
    });
  });
});
