import { GlAvatarLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import Approvers from 'ee/compliance_dashboard/components/merge_requests/approvers.vue';
import { PRESENTABLE_APPROVERS_LIMIT } from 'ee/compliance_dashboard/constants';
import { createApprovers } from '../../mock_data';

describe('MergeRequest component', () => {
  let wrapper;

  const findMessage = () => wrapper.find('[data-testid="approvers"]');
  const findCounter = () => wrapper.find('.avatar-counter');
  const findAvatarLinks = () => wrapper.findAllComponents(GlAvatarLink);

  const createComponent = (approvers = []) => {
    return shallowMount(Approvers, {
      propsData: {
        approvers,
      },
      stubs: {
        GlAvatarLink,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when there are no approvers', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('displays the "no approvers" message', () => {
      expect(findMessage().text()).toEqual('no approvers');
    });
  });

  describe('when there are approvers', () => {
    beforeEach(() => {
      wrapper = createComponent(createApprovers(1));
    });

    it('matches snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('when the amount of approvers matches the presentable limit', () => {
    const approvers = createApprovers(PRESENTABLE_APPROVERS_LIMIT);

    beforeEach(() => {
      wrapper = createComponent(approvers);
    });

    it('does not display the additional approvers count', () => {
      expect(findCounter().exists()).toEqual(false);
    });

    it(`displays ${PRESENTABLE_APPROVERS_LIMIT} user avatar links`, () => {
      expect(findAvatarLinks().length).toEqual(PRESENTABLE_APPROVERS_LIMIT);
    });
  });

  describe('when the amount of approvers is over the presentable limit', () => {
    const additional = 1;

    beforeEach(() => {
      wrapper = createComponent(createApprovers(PRESENTABLE_APPROVERS_LIMIT + additional));
    });

    it(`displays only ${PRESENTABLE_APPROVERS_LIMIT} user avatar links`, () => {
      expect(findAvatarLinks().length).toEqual(PRESENTABLE_APPROVERS_LIMIT);
    });

    it('displays additional approvers count', () => {
      expect(findCounter().exists()).toEqual(true);
      expect(findCounter().text()).toEqual(`+ ${additional}`);
    });
  });
});
