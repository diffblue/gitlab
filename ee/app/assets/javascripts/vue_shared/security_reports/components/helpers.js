import { EMPTY_BODY_MESSAGE } from './constants';

/**
 * A helper function which validates the passed
 * in body string.
 *
 * It returns an empty string if the body has explicitly
 * been passed in as an empty string, a fallback
 * message if the body is null / undefined, else
 * it will return the original body string.
 *
 * @param {String} body the body message
 *
 * @return {String} the validated body message
 */
export const bodyWithFallBack = (body) => (body === '' ? '' : body || EMPTY_BODY_MESSAGE);

/**
 * Returns a string representation of the HTTP request
 *
 * @param {Object} httpData
 * @param {String} httpData.body
 * @param {String} httpData.method
 * @param {String} httpData.url
 * @param {{name: String, value: String}[]} httpData.headers
 *
 * @returns {String}
 */
export const getHttpString = (httpData) => {
  if (!httpData) {
    return '';
  }

  const { body, headers, method, url, statusCode, reasonPhrase } = httpData;
  const methodOrStatusCode = method || statusCode;
  const urlOrReasonPhrase = url || reasonPhrase;
  const headerString = headers.map(({ name, value }) => `${name}: ${value}`).join('\n');

  return `${methodOrStatusCode} ${urlOrReasonPhrase}\n${headerString}\n\n${bodyWithFallBack(body)}`;
};

export const getCreatedIssueForVulnerability = (vulnerability) =>
  vulnerability.issue_links?.find((link) => link.link_type === 'created');

export const getDismissalTransitionForVulnerability = (vulnerability) => {
  const latestTransition = vulnerability.state_transitions?.at(-1);
  return latestTransition?.to_state.toLowerCase() === 'dismissed' ? latestTransition : null;
};
