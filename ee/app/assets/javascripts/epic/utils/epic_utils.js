import $ from 'jquery';
import { getCookie, setCookie, parseBoolean } from '~/lib/utils/common_utils';

import createGqClient, { fetchPolicies } from '~/lib/graphql';

const gqClient = createGqClient(
  {},
  {
    fetchPolicy: fetchPolicies.NO_CACHE,
  },
);

const triggerDocumentEvent = (eventName, eventParam) => {
  $(document).trigger(eventName, eventParam);
};

const bindDocumentEvent = (eventName, callback) => {
  $(document).on(eventName, callback);
};

const toggleContainerClass = (className) => {
  const containerEl = document.querySelector('.page-with-contextual-sidebar');

  if (containerEl) {
    containerEl.classList.toggle(className);
  }
};

const getCollapsedGutter = () => parseBoolean(getCookie('collapsed_gutter'));

const setCollapsedGutter = (value) => setCookie('collapsed_gutter', value);

const epicUtils = {
  gqClient,
  triggerDocumentEvent,
  bindDocumentEvent,
  toggleContainerClass,
  getCollapsedGutter,
  setCollapsedGutter,
};

export default epicUtils;
