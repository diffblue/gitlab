import { GlFormCheckbox } from '@gitlab/ui';
import mockGetJobArtifactsResponse from 'test_fixtures/graphql/ci/artifacts/graphql/queries/get_job_artifacts.query.graphql.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import JobCheckbox from '~/ci/artifacts/components/job_checkbox.vue';
import { I18N_BULK_DELETE_MAX_SELECTED } from '~/ci/artifacts/constants';

describe('JobCheckbox component', () => {
  let wrapper;

  const mockArtifactNodes = mockGetJobArtifactsResponse.data.project.jobs.nodes[0].artifacts.nodes;
  const mockSelectedArtifacts = [mockArtifactNodes[0], mockArtifactNodes[1]];
  const mockUnselectedArtifacts = [mockArtifactNodes[2]];

  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);

  const createComponent = ({
    hasArtifacts = true,
    selectedArtifacts = mockSelectedArtifacts,
    unselectedArtifacts = mockUnselectedArtifacts,
    isSelectedArtifactsLimitReached = false,
  } = {}) => {
    wrapper = shallowMountExtended(JobCheckbox, {
      propsData: {
        hasArtifacts,
        selectedArtifacts,
        unselectedArtifacts,
        isSelectedArtifactsLimitReached,
      },
      mocks: { GlFormCheckbox },
    });
  };

  it('is disabled when the job has no artifacts', () => {
    createComponent({ hasArtifacts: false });

    expect(findCheckbox().attributes('disabled')).toBe('true');
  });

  describe('when some artifacts are selected', () => {
    beforeEach(() => {
      createComponent();
    });

    it('is indeterminate', () => {
      expect(findCheckbox().attributes('indeterminate')).toBe('true');
      expect(findCheckbox().attributes('checked')).toBeUndefined();
    });

    it('selects the unselected artifacts on click', () => {
      findCheckbox().vm.$emit('input', true);

      expect(wrapper.emitted('selectArtifact')).toMatchObject([[mockUnselectedArtifacts[0], true]]);
    });
  });

  describe('when all artifacts are selected', () => {
    beforeEach(() => {
      createComponent({ unselectedArtifacts: [] });
    });

    it('is checked', () => {
      expect(findCheckbox().attributes('checked')).toBe('true');
    });

    it('deselects the selected artifacts on click', () => {
      findCheckbox().vm.$emit('input', false);

      expect(wrapper.emitted('selectArtifact')).toMatchObject([
        [mockSelectedArtifacts[0], false],
        [mockSelectedArtifacts[1], false],
      ]);
    });
  });

  describe('when no artifacts are selected', () => {
    beforeEach(() => {
      createComponent({ selectedArtifacts: [] });
    });

    it('is enabled and not checked', () => {
      expect(findCheckbox().attributes('checked')).toBeUndefined();
      expect(findCheckbox().attributes('disabled')).toBeUndefined();
      expect(findCheckbox().attributes('title')).toBe('');
    });

    it('selects the artifacts on click', () => {
      findCheckbox().vm.$emit('input', true);

      expect(wrapper.emitted('selectArtifact')).toMatchObject([[mockUnselectedArtifacts[0], true]]);
    });

    it('is disabled when the selected artifacts limit has been reached', () => {
      createComponent({ selectedArtifacts: [], isSelectedArtifactsLimitReached: true });

      expect(findCheckbox().attributes('disabled')).toBe('true');
      expect(findCheckbox().attributes('title')).toBe(I18N_BULK_DELETE_MAX_SELECTED);
    });
  });
});
