import { sprintf, s__ } from '~/locale';

const I18N_VSD_DORA_METRICS_PANEL_TITLE = s__('DORA4Metrics|Metrics comparison for %{name}');

const generatePanelTitle = ({ namespace: { name } }) => {
  return sprintf(I18N_VSD_DORA_METRICS_PANEL_TITLE, { name });
};

export const fetch = ({ title, namespace, query, queryOverrides = {} }) => {
  return {
    namespace,
    title: title || generatePanelTitle({ namespace }),
    ...query,
    ...queryOverrides,
  };
};
