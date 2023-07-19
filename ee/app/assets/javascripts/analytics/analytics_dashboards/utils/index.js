import cloneDeep from 'lodash/cloneDeep';
import { humanize } from '~/lib/utils/text_utility';

export const createNewVisualizationPanel = (visualization) => ({
  title: humanize(visualization.slug),
  gridAttributes: {
    width: 4,
    height: 3,
  },
  queryOverrides: {},
  options: {},
  visualization: cloneDeep(visualization),
});
