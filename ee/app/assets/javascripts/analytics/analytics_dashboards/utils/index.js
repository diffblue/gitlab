import cloneDeep from 'lodash/cloneDeep';
import { humanize } from '~/lib/utils/text_utility';

export const isValidConfigFileName = (fileName) =>
  fileName.split('.')[0] !== '' &&
  (fileName.endsWith('.json') || fileName.endsWith('.yml') || fileName.endsWith('.yaml'));

export const configFileNameToID = (fileName) => fileName.replace(/(\.json|\.ya?ml)$/, '');

export const getNextPanelId = (panels) => {
  if (!panels?.length) {
    return 1;
  }

  const currentId = panels.map(({ id }) => id).reduce((acc, id) => Math.max(acc, id), 0);

  // If none of the panel IDs are a number then start with a new number ID.
  if (Number.isNaN(currentId)) {
    return 1;
  }

  return currentId + 1;
};

export const createNewVisualizationPanel = (panelId, visualization) => ({
  id: panelId,
  title: humanize(visualization.slug),
  gridAttributes: {
    width: 4,
    height: 3,
  },
  queryOverrides: {},
  options: {},
  visualization: cloneDeep(visualization),
});
