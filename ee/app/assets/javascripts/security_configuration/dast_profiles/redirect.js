import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import {
  redirectTo, // eslint-disable-line import/no-deprecated
  setUrlParams,
  relativePathToAbsolute,
  getBaseURL,
} from '~/lib/utils/url_utility';

const getReferrerPath = (referrer) => {
  if (!referrer) return '';
  return new URL(referrer).pathname;
};

export const returnToPreviousPageFactory = ({
  allowedPaths,
  profilesLibraryPath,
  urlParamKey,
}) => ({ id } = {}) => {
  const referrerPath = getReferrerPath(document.referrer);
  const redirectPath = allowedPaths.find((allowedPath) => referrerPath === allowedPath);

  // when previous page is not an allowed path
  if (!redirectPath) return redirectTo(profilesLibraryPath); // eslint-disable-line import/no-deprecated

  // otherwise redirect to the previous page along
  // with the given profile id
  const redirectPathWithId = id
    ? setUrlParams(
        { [urlParamKey]: getIdFromGraphQLId(id) },
        relativePathToAbsolute(redirectPath, getBaseURL()),
      )
    : redirectPath;

  return redirectTo(redirectPathWithId); // eslint-disable-line import/no-deprecated
};
