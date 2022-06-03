import MockAdapter from 'axios-mock-adapter';
import * as arkoseLabsApi from 'ee/api/arkose_labs_api';
import axios from '~/lib/utils/axios_utils';

describe('ArkoseLabs API', () => {
  let axiosMock;

  beforeEach(() => {
    window.gon = { api_version: 'v4' };
    axiosMock = new MockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('needsArkoseLabsChallenge', () => {
    beforeEach(() => {
      jest.spyOn(axios, 'post');
      axiosMock.onPost().reply(200);
    });

    it.each`
      username     | expectedParam
      ${undefined} | ${''}
      ${''}        | ${''}
      ${'foo'}     | ${'foo'}
    `(
      'calls the API with $expectedUrlFragment in the URL when given $username as the username',
      ({ username, expectedParam }) => {
        arkoseLabsApi.needsArkoseLabsChallenge(username);

        expect(axios.post).toHaveBeenCalledWith(`/api/v4/users/captcha_check`, {
          username: expectedParam,
        });
      },
    );
  });
});
