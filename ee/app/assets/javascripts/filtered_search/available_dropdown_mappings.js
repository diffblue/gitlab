import AvailableDropdownMappingsCE from '~/filtered_search/available_dropdown_mappings';
import DropdownAjaxFilter from '~/filtered_search/dropdown_ajax_filter';
import DropdownNonUser from '~/filtered_search/dropdown_non_user';
import DropdownUser from '~/filtered_search/dropdown_user';
import { sortMilestonesByDueDate } from '~/milestones/utils';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import DropdownWeight from './dropdown_weight';

export default class AvailableDropdownMappings {
  constructor({
    container,
    labelsEndpoint,
    milestonesEndpoint,
    iterationsEndpoint,
    epicsEndpoint,
    releasesEndpoint,
    environmentsEndpoint,
    groupsOnly,
    includeAncestorGroups,
    includeDescendantGroups,
  }) {
    this.container = container;
    this.labelsEndpoint = labelsEndpoint;
    this.milestonesEndpoint = milestonesEndpoint;
    this.iterationsEndpoint = iterationsEndpoint;
    this.epicsEndpoint = epicsEndpoint;
    this.releasesEndpoint = releasesEndpoint;
    this.environmentsEndpoint = environmentsEndpoint;
    this.groupsOnly = groupsOnly;
    this.includeAncestorGroups = includeAncestorGroups;
    this.includeDescendantGroups = includeDescendantGroups;

    this.ceAvailableMappings = new AvailableDropdownMappingsCE({ ...this });
  }

  getAllowedMappings(supportedTokens) {
    const ceMappings = this.ceAvailableMappings.getMappings();

    ceMappings.milestone = {
      reference: null,
      gl: DropdownNonUser,
      extraArguments: {
        endpoint: this.getMilestoneEndpoint(),
        symbol: '%',
        preprocessing: (milestones) => milestones.sort(sortMilestonesByDueDate),
      },
      element: this.container.querySelector('#js-dropdown-milestone'),
    };

    ceMappings.approver = {
      reference: null,
      gl: DropdownUser,
      element: this.container.querySelector('#js-dropdown-approver'),
    };

    ceMappings.weight = {
      reference: null,
      gl: DropdownWeight,
      element: this.container.querySelector('#js-dropdown-weight'),
    };

    ceMappings.epic = {
      reference: null,
      gl: DropdownNonUser,
      extraArguments: {
        endpoint: this.getEpicEndpoint(),
        symbol: '&',
      },
      element: this.container.querySelector('#js-dropdown-epic'),
    };

    ceMappings.iteration = {
      reference: null,
      gl: DropdownAjaxFilter,
      extraArguments: {
        endpoint: this.iterationsEndpoint,
        symbol: '',
      },
      element: this.container.querySelector('#js-dropdown-iteration'),
    };

    return this.ceAvailableMappings.buildMappings(supportedTokens, ceMappings);
  }

  getMilestoneEndpoint() {
    let endpoint = `${this.milestonesEndpoint}.json`;

    if (this.groupsOnly) {
      endpoint = `${endpoint}?only_group_milestones=true`;
    }

    return endpoint;
  }

  getEpicEndpoint() {
    return mergeUrlParams(
      { include_ancestor_groups: true, include_descendant_groups: true },
      this.epicsEndpoint,
    );
  }
}
