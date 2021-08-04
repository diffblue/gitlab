import { buildApiUrl } from '~/api/api_utils';
import axios from '~/lib/utils/axios_utils';

const GROUP_VSA_PATH_BASE =
  '/groups/:id/-/analytics/value_stream_analytics/value_streams/:value_stream_id/stages/:stage_id';

const buildGroupValueStreamPath = ({ groupId, valueStreamId = null, stageId = null }) =>
  buildApiUrl(GROUP_VSA_PATH_BASE)
    .replace(':id', groupId)
    .replace(':value_stream_id', valueStreamId)
    .replace(':stage_id', stageId);

export const getGroupValueStreamStageMedian = (
  { groupId, valueStreamId, stageId },
  params = {},
) => {
  const stageBase = buildGroupValueStreamPath({ groupId, valueStreamId, stageId });
  return axios.get(`${stageBase}/median`, { params });
};
