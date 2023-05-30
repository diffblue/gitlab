import { merge } from 'lodash';
import { createAppOptions as createAppOptionsCE } from '~/ci/pipeline_editor/options';
import { parseBoolean } from '~/lib/utils/common_utils';

export const createAppOptions = (el) => {
  if (!el) return null;

  const appOptionsCE = createAppOptionsCE(el);

  const { dataset } = el;

  const { ciCatalogPath, canViewNamespaceCatalog } = dataset;

  return merge({}, appOptionsCE, {
    provide: {
      ciCatalogPath,
      canViewNamespaceCatalog: parseBoolean(canViewNamespaceCatalog),
    },
  });
};
