import { isEqual, pick } from 'lodash';
import { convertObjectPropsToSnakeCase } from '~/lib/utils/common_utils';
import { isStartEvent, getAllowedEndEvents, eventToOption, eventsByIdentifier } from '../../utils';
import {
  i18n,
  ERRORS,
  defaultErrors,
  defaultFields,
  NAME_MAX_LENGTH,
  formFieldKeys,
  editableFormFieldKeys,
} from './constants';

/**
 * @typedef {Object} CustomStageEvents
 * @property {String} canBeStartEvent - Title of the metric measured
 * @property {String} name - Friendly name for the event
 * @property {String} identifier - snakeized name for the event
 *
 * @typedef {Object} DropdownData
 * @property {String} text - Friendly name for the event
 * @property {String} value - Value to be submitted for the dropdown
 */

/**
 * Takes an array of custom stage events to return only the
 * events where `canBeStartEvent` is true and converts them
 * to { value, text } pairs for use in dropdowns
 *
 * @param {CustomStageEvents[]} events
 * @returns {DropdownData[]} array of start events formatted for dropdowns
 */
export const startEventOptions = (eventsList) => [
  { value: null, text: i18n.SELECT_START_EVENT },
  ...eventsList.filter(isStartEvent).map(eventToOption),
];

/**
 * Takes an array of custom stage events to return only the
 * events where `canBeStartEvent` is false and converts them
 * to { value, text } pairs for use in dropdowns
 *
 * @param {CustomStageEvents[]} events
 * @returns {DropdownData[]} array end events formatted for dropdowns
 */
export const endEventOptions = (eventsList, startEventIdentifier) => {
  const endEvents = getAllowedEndEvents(eventsList, startEventIdentifier);
  return [
    { value: null, text: i18n.SELECT_END_EVENT },
    ...eventsByIdentifier(eventsList, endEvents).map(eventToOption),
  ];
};

/**
 * @typedef {Object} CustomStageFormData
 * @property {Object.<String, String>} fields - form field values
 * @property {Object.<String, Array>} errors - form field errors
 */

/**
 * Initializes the fields and errors for the custom stages form
 * providing defaults for any missing keys
 *
 * @param {CustomStageFormData} data
 * @returns {CustomStageFormData} the updated initial data with all defaults
 */
export const initializeFormData = ({ fields, errors }) => {
  const initErrors = fields?.endEventIdentifier
    ? defaultErrors
    : {
        ...defaultErrors,
        endEventIdentifier: !fields?.startEventIdentifier ? [ERRORS.START_EVENT_REQUIRED] : [],
      };
  return {
    fields: {
      ...defaultFields,
      ...fields,
    },
    errors: {
      ...initErrors,
      ...errors,
    },
  };
};

/**
 * Validates the form fields for the custom stages form
 * Any errors will be returned in a object where the key is
 * the name of the field.g
 *
 * @param {Object} fields key value pair of form field values
 * @param {Object} defaultStageNames array of lower case default value stream names
 * @returns {Object} key value pair of form fields with an array of errors
 */
export const validateStage = (fields, defaultStageNames = []) => {
  const newErrors = {};

  if (fields?.name) {
    if (fields.name.length > NAME_MAX_LENGTH) {
      newErrors.name = [ERRORS.MAX_LENGTH];
    }
    if (fields?.custom && defaultStageNames.includes(fields.name.toLowerCase())) {
      newErrors.name = [ERRORS.STAGE_NAME_EXISTS];
    }
  } else {
    newErrors.name = [ERRORS.STAGE_NAME_MIN_LENGTH];
  }

  if (fields?.startEventIdentifier) {
    if (!fields?.endEventIdentifier) {
      newErrors.endEventIdentifier = [ERRORS.END_EVENT_REQUIRED];
    }
  } else {
    newErrors.endEventIdentifier = [ERRORS.START_EVENT_REQUIRED];
  }
  return newErrors;
};

/**
 * Validates the name of a value stream Any errors will be
 * returned as an array in a object with key`name`
 *
 * @param {Object} fields key value pair of form field values
 * @returns {Array} an array of errors
 */
export const validateValueStreamName = ({ name = '' }) => {
  const errors = [];
  if (name.length > NAME_MAX_LENGTH) {
    errors.push(ERRORS.MAX_LENGTH);
  }
  if (!name.length) {
    errors.push(ERRORS.VALUE_STREAM_NAME_MIN_LENGTH);
  }
  return errors;
};

/**
 * Formats the value stream stages for submission, ensures that the
 * 'custom' property is set when we are editing, we include the `id` if its
 * set and all fields are converted to snake case
 *
 * @param {Array} stages array of value stream stages
 * @param {Boolean} isEditing flag to indicate if we are editing a value stream or creating
 * @returns {Array} the array prepared to be submitted for persistence
 */
export const formatStageDataForSubmission = (stages, isEditing = false) => {
  return stages.map(({ id = null, custom = false, name, ...rest }) => {
    let editProps = { custom };
    if (isEditing) {
      // We can add a new stage to the value stream when either creating, or editing
      // If a new stage has been added then at this point, the `id` won't exist
      // The new stage is still `custom` but wont have an id until the form submits and its persisted to the DB
      editProps = id ? { id, custom: true } : { custom: true };
    }
    const editableFields = pick(rest, editableFormFieldKeys);
    // While we work on https://gitlab.com/gitlab-org/gitlab/-/issues/321959 we should not allow editing default
    return custom
      ? convertObjectPropsToSnakeCase({ ...editableFields, ...editProps, name })
      : convertObjectPropsToSnakeCase({ ...editProps, name, custom: false });
  });
};

/**
 * Checks an array of value stream stages to see if there are
 * any differences in the values they contain
 *
 * @param {Array} stages array of value stream stages
 * @param {Array} stages array of value stream stages
 * @returns {Boolean} returns true if there is a difference in the 2 arrays
 */
export const hasDirtyStage = (currentStages, originalStages) => {
  const cs = currentStages.map((s) => pick(s, formFieldKeys));
  const os = originalStages.map((s) => pick(s, formFieldKeys));
  return !isEqual(cs, os);
};

/**
 * Checks if the target name matches the name of any of the value
 * stream stages passed in
 *
 * @param {Array} stages array of value stream stages
 * @param {String} targetName name we are searching for
 * @returns {Object} returns the found object or null
 */
const findStageByName = (stages, targetName = '') =>
  stages.find(({ name }) => name.toLowerCase().trim() === targetName.toLowerCase().trim());

/**
 * Returns a valid custom value stream stage
 *
 * @param {Object} stage a raw value stream stage retrieved from the vuex store
 * @returns {Object} the same stage with fields adjusted for the value stream form
 */
const prepareCustomStage = ({ startEventLabel = {}, endEventLabel = {}, ...rest }) => ({
  ...rest,
  startEventLabel,
  endEventLabel,
  startEventLabelId: startEventLabel?.id || null,
  endEventLabelId: endEventLabel?.id || null,
  isDefault: false,
});

/**
 * Returns a valid default value stream stage
 *
 * @param {Object} stage a raw value stream stage retrieved from the vuex store
 * @returns {Object} the same stage with fields adjusted for the value stream form
 */
const prepareDefaultStage = (defaultStageConfig, { name, ...rest }) => {
  // default stages currently dont have any label based events
  const stage = findStageByName(defaultStageConfig, name) || null;
  if (!stage) return {};
  const { startEventIdentifier = null, endEventIdentifier = null } = stage;
  return {
    ...rest,
    name,
    startEventIdentifier,
    endEventIdentifier,
    isDefault: true,
  };
};

const generateHiddenDefaultStages = (defaultStageConfig, stageNames) => {
  // We use the stage name to check for any default stages that might be hidden
  // Currently the default stages can't be renamed
  return defaultStageConfig
    .filter(({ name }) => !stageNames.includes(name.toLowerCase()))
    .map((data) => ({ ...data, hidden: true }));
};

/**
 * Returns a valid array of value stream stages for
 * use in the value stream form
 *
 * @param {Array} defaultStageConfig an array of the default value stream stages retrieved from the backend
 * @param {Array} selectedValueStreamStages an array of raw value stream stages retrieved from the vuex store
 * @returns {Object} the same stage with fields adjusted for the value stream form
 */
export const generateInitialStageData = (defaultStageConfig, selectedValueStreamStages) => {
  const hiddenDefaultStages = generateHiddenDefaultStages(
    defaultStageConfig,
    selectedValueStreamStages.map((s) => s.name.toLowerCase()),
  );
  const combinedStages = [...selectedValueStreamStages, ...hiddenDefaultStages];
  return combinedStages.map(
    ({ startEventIdentifier = null, endEventIdentifier = null, custom = false, ...rest }) => {
      const stageData =
        custom && startEventIdentifier && endEventIdentifier
          ? prepareCustomStage({ ...rest, startEventIdentifier, endEventIdentifier })
          : prepareDefaultStage(defaultStageConfig, rest);

      if (stageData?.name) {
        return {
          ...stageData,
          custom,
        };
      }
      return {};
    },
  );
};
