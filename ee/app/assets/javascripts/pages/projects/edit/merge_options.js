import { gql } from '@apollo/client/core';
import { createAlert } from '~/alert';
import createDefaultClient from '~/lib/graphql';
import { s__ } from '~/locale';

export const ERROR_LOADING_MERGE_OPTION_SETTINGS = s__(
  'Settings|Unable to load the merge request options settings. Try reloading the page.',
);
const mergePipelinesCheckbox = document.querySelector('.js-merge-options-merge-pipelines');
const mergeTrainsCheckbox = document.querySelector('.js-merge-options-merge-trains');

const getCiCdSettingsQuery = (projectFullPath) =>
  gql`
    query {
      project(fullPath:"${projectFullPath}") {
        id,
        ciCdSettings {
          mergePipelinesEnabled,
          mergeTrainsEnabled,
        }
      }
    }
  `;

const initMergeOptions = (mergePipelinesEnabled, mergeTrainsEnabled) => {
  if (!mergePipelinesCheckbox) {
    return;
  }

  mergePipelinesCheckbox.disabled = false;
  mergePipelinesCheckbox.checked = mergePipelinesEnabled;

  if (mergeTrainsCheckbox) {
    mergeTrainsCheckbox.disabled = !mergePipelinesEnabled;
    mergeTrainsCheckbox.checked = mergeTrainsEnabled;

    mergePipelinesCheckbox.addEventListener('change', () => {
      if (!mergePipelinesCheckbox.checked) {
        mergeTrainsCheckbox.checked = false;
      }
      mergeTrainsCheckbox.disabled = !mergePipelinesCheckbox.checked;
    });
  }
};

const fetchMergeOptions = () => {
  const containerEl = document.querySelector('#project-merge-options');
  const { projectFullPath } = containerEl.dataset;

  const defaultClient = createDefaultClient();

  return defaultClient
    .query({
      query: getCiCdSettingsQuery(projectFullPath),
    })
    .then((result) => {
      const { mergePipelinesEnabled, mergeTrainsEnabled } = result.data.project.ciCdSettings;

      return { mergePipelinesEnabled, mergeTrainsEnabled };
    });
};

export const initMergeOptionSettings = () => {
  return fetchMergeOptions()
    .then(({ mergePipelinesEnabled, mergeTrainsEnabled }) => {
      initMergeOptions(mergePipelinesEnabled, mergeTrainsEnabled);
    })
    .catch((error) => {
      createAlert({ message: ERROR_LOADING_MERGE_OPTION_SETTINGS, error, captureError: true });
    });
};
