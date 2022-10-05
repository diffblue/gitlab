import { roundOffFloat } from '~/lib/utils/common_utils';
import dateformat from '~/lib/dateformat';
import { DEPLOYMENT_FREQUENCY_METRIC_TYPE, CHANGE_FAILURE_RATE } from 'ee/api/dora_api';
import { DORA_METRIC_IDENTIFIERS } from './constants';

export const extractDoraMetrics = (metrics = []) =>
  metrics
    .filter(({ identifier }) => DORA_METRIC_IDENTIFIERS.includes(identifier))
    .reduce((acc, curr) => {
      const { identifier, ...rest } = curr;
      return {
        ...acc,
        [identifier]: {
          ...rest,
          identifier,
        },
      };
    }, {});

export const formatPercentChange = (current, previous) =>
  `${roundOffFloat(((current - previous) / previous) * 100, 2)}%`;

export const formatMetricString = ({ identifier, value, unit }) =>
  [DEPLOYMENT_FREQUENCY_METRIC_TYPE, CHANGE_FAILURE_RATE].includes(identifier)
    ? `${value}${unit}`
    : `${value} ${unit}`;

export const generateComparison = ({ current, previous }) => {
  return DORA_METRIC_IDENTIFIERS.map((identifier) => {
    const c = current[identifier];
    const p = previous[identifier];
    return {
      metric: c.label,
      current: formatMetricString(c),
      previous: formatMetricString(p),
      change: formatPercentChange(c.value, p.value),
    };
  });
};

export const toUtcYMD = (d) => dateformat(d, 'UTC:yyyy-mm-dd');
