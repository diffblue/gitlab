import axios from '~/lib/utils/axios_utils';
import { buildApiUrl } from '~/api/api_utils';

const USERNAME_PLACEHOLDER = ':username';
const ENDPOINT = `/api/:version/users/${USERNAME_PLACEHOLDER}/captcha_check`;

export const needsArkoseLabsChallenge = (username = '') =>
  axios.get(buildApiUrl(ENDPOINT).replace(USERNAME_PLACEHOLDER, encodeURIComponent(username)));
