import { METRIC_TYPE_SUMMARY } from '~/api/analytics_api';
import { buildApiUrl } from '~/api/api_utils';
import axios from '~/lib/utils/axios_utils';
import { joinPaths } from '~/lib/utils/url_utility';

const GROUP_VSA_BASE = '/groups/:id/-/analytics/value_stream_analytics';
const GROUP_VSA_STAGE_BASE = `${GROUP_VSA_BASE}/value_streams/:value_stream_id/stages/:stage_id`;

const buildGroupValueStreamPath = ({ groupId }) =>
  buildApiUrl(GROUP_VSA_BASE).replace(':id', groupId);

const buildGroupValueStreamStagePath = ({ groupId, valueStreamId = null, stageId = null }) =>
  buildApiUrl(GROUP_VSA_STAGE_BASE)
    .replace(':id', groupId)
    .replace(':value_stream_id', valueStreamId)
    .replace(':stage_id', stageId);

export const getGroupValueStreamStageMedian = (
  { groupId, valueStreamId, stageId },
  params = {},
) => {
  const stageBase = buildGroupValueStreamStagePath({ groupId, valueStreamId, stageId });
  return axios.get(`${stageBase}/median`, { params });
};

export const getGroupValueStreamMetrics = ({
  endpoint = METRIC_TYPE_SUMMARY,
  requestPath: groupId,
  params = {},
}) => axios.get(joinPaths(buildGroupValueStreamPath({ groupId }), endpoint), { params });
