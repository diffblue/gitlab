import { getBaseURL, joinPaths } from '~/lib/utils/url_utility';

export const getSourceUrl = (fullPath) => {
  return joinPaths(getBaseURL(), fullPath);
};

export const isPolicyInherited = (source) => {
  if (source?.inherited === true) {
    return true;
  }

  return false;
};
