import Api from 'ee/api';
import axios from '~/lib/utils/axios_utils';

export function mrStatusCheckRetry({ projectId, mergeRequestId, externalStatusCheckId }) {
  const url = Api.buildUrl(Api.mrStatusCheckRetryPath)
    .replace(':id', encodeURIComponent(projectId))
    .replace(':merge_request_iid', encodeURIComponent(mergeRequestId))
    .replace(':external_status_check_id', encodeURIComponent(externalStatusCheckId));

  return axios.post(url);
}
