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
      jest.spyOn(axios, 'get');
      axiosMock.onGet().reply(200);
    });

    it.each`
      username        | expectedUrlFragment
      ${undefined}    | ${''}
      ${''}           | ${''}
      ${'foo'}        | ${'foo'}
      ${'éøà'}        | ${'%C3%A9%C3%B8%C3%A0'}
      ${'dot.slash/'} | ${'dot.slash%2F'}
    `(
      'calls the API with $expectedUrlFragment in the URL when given $username as the username',
      ({ username, expectedUrlFragment }) => {
        arkoseLabsApi.needsArkoseLabsChallenge(username);

        expect(axios.get).toHaveBeenCalledWith(
          `/api/v4/users/${expectedUrlFragment}/captcha_check`,
        );
      },
    );
  });
});
