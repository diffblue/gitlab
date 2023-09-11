import { cloneWithoutReferences } from '~/lib/utils/common_utils';
import { humanize } from '~/lib/utils/text_utility';
import { getUniquePanelId } from 'ee/vue_shared/components/customizable_dashboard/utils';

export const createNewVisualizationPanel = (visualization) => ({
  id: getUniquePanelId(),
  title: humanize(visualization.slug),
  gridAttributes: {
    width: 4,
    height: 3,
  },
  queryOverrides: {},
  options: {},
  visualization: cloneWithoutReferences({ ...visualization, errors: null }),
});
