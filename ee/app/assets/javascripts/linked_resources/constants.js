import { s__ } from '~/locale';

export const resourceLinksI18n = Object.freeze({
  headerText: s__('LinkedResources|Linked resources'),
  helpText: s__(
    'LinkedResources|Use this space to add links to the resources your team needs as they work to resolve the incident.',
  ),
  addButtonText: s__('LinkedResources|Add a resource link'),
  fetchingLinkedResourcesText: s__('LinkedResources|Fetching linked resources'),
  fetchError: s__(
    'LinkedResources|Something went wrong while fetching linked resources for the incident.',
  ),
  deleteError: s__('LinkedResources|Error deleting the linked resource for the incident: %{error}'),
  deleteErrorGeneric: s__(
    'LinkedResources|Something went wrong while deleting the linked resource for the incident.',
  ),
  createError: s__('LinkedResources|Error creating resource link for the incident: %{error}'),
  createErrorGeneric: s__(
    'LinkedResources|Something went wrong while creating the resource link for the incident.',
  ),
});

export const resourceLinksFormI18n = Object.freeze({
  linkTextLabel: s__('LinkedResources|Text (Optional)'),
  linkValueLabel: s__('LinkedResources|Link'),
  submitButtonText: s__('LinkedResources|Add'),
  cancelButtonText: s__('LinkedResources|Cancel'),
});

export const resourceLinksListI18n = Object.freeze({
  linkRemoveText: s__('LinkedResources|Remove'),
});
