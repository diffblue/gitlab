import axios from '~/lib/utils/axios_utils';

export const fetchIssue = (issuePath) => {
  return axios.get(issuePath).then(({ data }) => {
    return data;
  });
};
