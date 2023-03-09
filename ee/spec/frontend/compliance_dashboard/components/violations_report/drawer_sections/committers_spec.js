import { shallowMount } from '@vue/test-utils';
import Committers from 'ee/compliance_dashboard/components/violations_report/drawer_sections/committers.vue';
import DrawerAvatarsList from 'ee/compliance_dashboard/components/violations_report/shared/drawer_avatars_list.vue';
import DrawerSectionHeader from 'ee/compliance_dashboard/components/violations_report/shared/drawer_section_header.vue';
import { createApprovers } from '../../../mock_data';

describe('Committers component', () => {
  let wrapper;

  const findSectionHeader = () => wrapper.findComponent(DrawerSectionHeader);
  const findCommitters = () => wrapper.findComponent(DrawerAvatarsList);

  const createComponent = (committers) => {
    return shallowMount(Committers, {
      propsData: { committers },
    });
  };

  describe('rendering', () => {
    const committersList = createApprovers(2);

    beforeEach(() => {
      wrapper = createComponent(committersList);
    });

    it('renders the header', () => {
      expect(findSectionHeader().text()).toBe('Change made by');
    });

    it('renders the committers list', () => {
      expect(findCommitters().props()).toMatchObject({
        avatars: committersList,
      });
    });
  });

  describe.each`
    number | header                | emptyHeader
    ${1}   | ${'1 commit author'}  | ${'No committers'}
    ${3}   | ${'3 commit authors'} | ${'No committers'}
  `('with $number committers', ({ number, header, emptyHeader }) => {
    beforeEach(() => {
      wrapper = createComponent(createApprovers(number));
    });

    it('renders the committers list with the correct header', () => {
      expect(findCommitters().props()).toMatchObject({
        header,
        emptyHeader,
      });
    });
  });
});
