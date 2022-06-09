import axios from '~/lib/utils/axios_utils';
import { buildApiUrl } from '~/api/api_utils';

const ENDPOINT = `/api/:version/users/captcha_check`;

export const needsArkoseLabsChallenge = (username = '') =>
  axios.post(buildApiUrl(ENDPOINT), {
    username,
  });
