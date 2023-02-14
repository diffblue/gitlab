import { GlFilteredSearchToken } from '@gitlab/ui';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';
import { DATE_RANGES, PRESET_TYPES } from 'ee/roadmap/constants';

import { dateFromString } from 'helpers/datetime_helpers';
import {
  OPERATORS_IS,
  OPERATORS_IS_NOT,
  TOKEN_TITLE_AUTHOR,
  TOKEN_TITLE_CONFIDENTIAL,
  TOKEN_TITLE_LABEL,
  TOKEN_TITLE_MILESTONE,
  TOKEN_TITLE_MY_REACTION,
  TOKEN_TITLE_GROUP,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_EPIC,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_GROUP,
} from '~/vue_shared/components/filtered_search_bar/constants';

import UserToken from '~/vue_shared/components/filtered_search_bar/tokens/user_token.vue';
import EmojiToken from '~/vue_shared/components/filtered_search_bar/tokens/emoji_token.vue';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';
import MilestoneToken from '~/vue_shared/components/filtered_search_bar/tokens/milestone_token.vue';
import { TOKEN_TITLE_EPIC } from 'ee/vue_shared/components/filtered_search_bar/constants';
import EpicToken from 'ee/vue_shared/components/filtered_search_bar/tokens/epic_token.vue';
import GroupToken from 'ee/vue_shared/components/filtered_search_bar/tokens/group_token.vue';

export const mockScrollBarSize = 15;

export const mockGroupId = 1;

const mockGroup1 = {
  id: `gid://gitlab/Group/${mockGroupId}`,
  name: 'Gitlab Org',
  fullName: 'Gitlab Org',
  fullPath: '/groups/gitlab-org/',
  __typename: 'Group',
};

const mockGroup2 = {
  id: 'gid://gitlab/Group/2',
  name: 'Marketing',
  fullName: 'Gitlab Org / Marketing',
  fullPath: '/groups/gitlab-org/marketing/',
  __typename: 'Group',
};

export const mockShellWidth = 2000;

export const mockItemWidth = 180;

export const mockSortedBy = 'start_date_asc';

export const basePath = '/groups/gitlab-org/-/epics.json';

export const mockNewEpicEndpoint = '/groups/gitlab-org/-/epics';

export const mockSvgPath = '/foo/bar.svg';

export const mockTimeframeInitialDate = new Date(2018, 0, 1);

const defaultDescendantCounts = {
  openedEpics: 0,
  closedEpics: 0,
};

export const mockTimeframeQuartersPrepend = [
  {
    year: 2016,
    quarterSequence: 4,
    range: [new Date(2016, 9, 1), new Date(2016, 10, 1), new Date(2016, 11, 31)],
  },
  {
    year: 2017,
    quarterSequence: 1,
    range: [new Date(2017, 0, 1), new Date(2017, 1, 1), new Date(2017, 2, 31)],
  },
  {
    year: 2017,
    quarterSequence: 2,
    range: [new Date(2017, 3, 1), new Date(2017, 4, 1), new Date(2017, 5, 30)],
  },
];
export const mockTimeframeQuartersAppend = [
  {
    year: 2019,
    quarterSequence: 2,
    range: [new Date(2019, 3, 1), new Date(2019, 4, 1), new Date(2019, 5, 30)],
  },
  {
    year: 2019,
    quarterSequence: 3,
    range: [new Date(2019, 6, 1), new Date(2019, 7, 1), new Date(2019, 8, 30)],
  },
  {
    year: 2019,
    quarterSequence: 4,
    range: [new Date(2019, 9, 1), new Date(2019, 10, 1), new Date(2019, 11, 31)],
  },
];

export const mockTimeframeMonthsPrepend = [
  new Date(2017, 2, 1),
  new Date(2017, 3, 1),
  new Date(2017, 4, 1),
  new Date(2017, 5, 1),
  new Date(2017, 6, 1),
  new Date(2017, 7, 1),
  new Date(2017, 8, 1),
  new Date(2017, 9, 1),
];
export const mockTimeframeMonthsAppend = [
  new Date(2018, 6, 1),
  new Date(2018, 7, 1),
  new Date(2018, 8, 1),
  new Date(2018, 9, 1),
  new Date(2018, 10, 1),
  new Date(2018, 11, 31),
];

export const mockTimeframeWeeksPrepend = [
  new Date(2017, 10, 5),
  new Date(2017, 10, 12),
  new Date(2017, 10, 19),
  new Date(2017, 10, 26),
  new Date(2017, 11, 3),
  new Date(2017, 11, 10),
];
export const mockTimeframeWeeksAppend = [
  new Date(2018, 0, 28),
  new Date(2018, 1, 4),
  new Date(2018, 1, 11),
  new Date(2018, 1, 18),
  new Date(2018, 1, 25),
  new Date(2018, 2, 4),
];

const OCT_11_2020 = dateFromString('Oct 11 2020');
export const mockWeekly = {
  currentDate: OCT_11_2020,
  /*
    Each item in timeframe is a Date object.

    timeframe = [ Sep 27 2020, Oct  4 2020, Oct 11 2020, <- current week or currentIndex == 2
                  Oct 18 2020, Oct 25 2020, Nov  1 2020,
                  Nov  8 2020 ]
  */
  timeframe: getTimeframeForRangeType({
    timeframeRangeType: DATE_RANGES.CURRENT_QUARTER,
    presetType: PRESET_TYPES.WEEKS,
    initialDate: OCT_11_2020,
  }),
};

const DEC_1_2020 = dateFromString('Dec 1 2020');
export const mockMonthly = {
  currentDate: DEC_1_2020,
  /*
    Each item in timeframe is a Date object.

    timeframe = [ Oct 1 2020, Nov 1 2020, Dec 1 2020, <- current month == index 2
                  Jan 1 2021, Feb 1 2021, Mar 1 2021,
                  Apr 1 2021, May 31 2021 ]
  */
  timeframe: getTimeframeForRangeType({
    timeframeRangeType: DATE_RANGES.CURRENT_YEAR,
    presetType: PRESET_TYPES.MONTHS,
    initialDate: DEC_1_2020,
  }),
};

const DEC_25_2020 = dateFromString('Dec 25 2020');
export const mockQuarterly = {
  currentDate: DEC_25_2020,
  /*
    The format of quarterly timeframes differs from that of the monthly and weekly ones.

    For quarterly, each item in timeframe has the following shape:
      { quarterSequence: number, range: array<Dates>, year: number }

      Each item in range is a Date object.

      E.g., { 2020 Q2 } = { quarterSequence: 2, range: [ Apr 1 2020, May 1 2020, Jun 30 2020], year 2020 }

    timeframe = [ { 2020 Q2 }, { 2020 Q3 }, { 2020 Q4 }, <- current quarter == index 2
                  { 2021 Q1 }, { 2021 Q2 }, { 2021 Q3 },
                  { 2021 Q4 } ]
  */
  timeframe: getTimeframeForRangeType({
    timeframeRangeType: DATE_RANGES.THREE_YEARS,
    presetType: PRESET_TYPES.QUARTERS,
    initialDate: DEC_25_2020,
  }),
};

export const mockEpic = {
  id: 1,
  iid: 1,
  description:
    'Explicabo et soluta minus praesentium minima ab et voluptatem. Quas architecto vero corrupti voluptatibus labore accusantium consectetur. Aliquam aut impedit voluptates illum molestias aut harum. Aut non odio praesentium aut.\n\nQuo asperiores aliquid sed nobis. Omnis sint iste provident numquam. Qui voluptatem tempore aut aut voluptas dolorem qui.\n\nEst est nemo quod est. Odit modi eos natus cum illo aut. Expedita nostrum ea est omnis magnam ut eveniet maxime. Itaque ipsam provident minima et occaecati ut. Dicta est perferendis sequi perspiciatis rerum voluptatum deserunt.',
  title:
    'Cupiditate exercitationem unde harum reprehenderit maxime eius velit recusandae incidunt quia.',
  group: mockGroup1,
  startDate: new Date('2017-11-10'),
  originalStartDate: new Date('2017-11-10'),
  endDate: new Date('2018-06-02'),
  webUrl: '/groups/gitlab-org/-/epics/1',
  descendantCounts: {
    openedEpics: 3,
    closedEpics: 2,
  },
};

export const mockRawEpic = {
  __typename: 'Epic',
  parent: null,
  id: 'gid://gitlab/Epic/41',
  iid: '2',
  title: 'Another marketing',
  description: '',
  state: 'opened',
  startDate: '2017-06-26',
  dueDate: '2018-03-10',
  webUrl: 'http://gdk.test:3000/groups/gitlab-org/marketing/-/epics/1',
  hasChildren: false,
  hasParent: false,
  confidential: false,
  descendantWeightSum: {
    closedIssues: 3,
    openedIssues: 2,
    __typename: 'EpicDescendantWeights',
  },
  descendantCounts: {
    openedEpics: 3,
    closedEpics: 2,
    closedIssues: 3,
    openedIssues: 2,
    __typename: 'EpicDescendantCount',
  },
  group: mockGroup1,
  labels: {
    nodes: [
      {
        id: 'gid://gitlab/GroupLabel/12',
        title: 'Aquanix',
        color: '#e65431',
        textColor: '#FFFFFF',
        __typename: 'Label',
      },
    ],
  },
};

export const mockRawEpic2 = {
  ...mockRawEpic,
  startDate: '2017-12-31',
  dueDate: '2018-02-15',
};

export const mockFormattedChildEpic1 = {
  id: 50,
  iid: 52,
  description: null,
  title: 'Marketing child epic 1',
  group: mockGroup1,
  startDate: new Date(2017, 10, 1),
  originalStartDate: new Date(2017, 5, 26),
  endDate: new Date(2018, 2, 10),
  originalEndDate: new Date(2018, 2, 10),
  startDateOutOfRange: true,
  endDateOutOfRange: false,
  webUrl: '/groups/gitlab-org/marketing/-/epics/5',
  newEpic: undefined,
  descendantWeightSum: {
    closedIssues: 3,
    openedIssues: 2,
  },
  descendantCounts: defaultDescendantCounts,
  isChildEpic: true,
};

export const mockFormattedChildEpic2 = {
  id: 51,
  iid: 53,
  description: null,
  title: 'Marketing child epic 2',
  group: mockGroup1,
  startDate: new Date(2017, 10, 1),
  originalStartDate: new Date(2017, 5, 26),
  endDate: new Date(2018, 2, 10),
  originalEndDate: new Date(2018, 2, 10),
  startDateOutOfRange: true,
  endDateOutOfRange: false,
  webUrl: '/groups/gitlab-org/marketing/-/epics/6',
  newEpic: undefined,
  descendantWeightSum: {
    closedIssues: 3,
    openedIssues: 2,
  },
  isChildEpic: true,
};

export const mockFormattedEpic = {
  ...mockRawEpic,
  startDate: new Date(2018, 0, 1),
  originalStartDate: new Date(2017, 5, 26),
  endDate: new Date(2018, 2, 10),
  originalEndDate: new Date(2018, 2, 10),
  startDateOutOfRange: true,
  endDateOutOfRange: false,
  confidential: false,
  isChildEpic: false,
};

export const mockFormattedEpic2 = {
  ...mockRawEpic2,
  isChildEpic: false,
  newEpic: undefined,
  startDateOutOfRange: true,
  endDateOutOfRange: false,
  startDate: new Date(2018, 0, 1),
  originalStartDate: new Date(2017, 11, 31),
  endDate: new Date(2018, 1, 15),
  originalEndDate: new Date(2018, 1, 15),
};

export const rawEpics = [
  {
    id: 41,
    iid: 2,
    description: null,
    title: 'Another marketing',
    startDate: '2017-12-26',
    endDate: '2018-03-10',
    webUrl: '/groups/gitlab-org/marketing/-/epics/2',
    descendantCounts: defaultDescendantCounts,
    hasParent: true,
    parent: {
      id: '40',
    },
    group: mockGroup2,
  },
  {
    id: 40,
    iid: 1,
    description: null,
    title: 'Marketing epic',
    startDate: '2017-12-25',
    endDate: '2018-03-09',
    webUrl: '/groups/gitlab-org/marketing/-/epics/1',
    descendantCounts: defaultDescendantCounts,
    hasParent: false,
    group: mockGroup2,
  },
  {
    id: 39,
    iid: 12,
    description: null,
    title: 'Epic with end in first timeframe month',
    group: mockGroup1,
    startDate: '2017-04-02',
    endDate: '2017-11-30',
    webUrl: '/groups/gitlab-org/-/epics/12',
    descendantCounts: defaultDescendantCounts,
    hasParent: false,
  },
  {
    id: 38,
    iid: 11,
    description: null,
    title: 'Epic with end date out of range',
    group: mockGroup2,
    startDate: '2018-01-15',
    endDate: '2020-01-03',
    webUrl: '/groups/gitlab-org/-/epics/11',
    descendantCounts: defaultDescendantCounts,
    hasParent: false,
  },
  {
    id: 37,
    iid: 10,
    description: null,
    title: 'Epic with timeline in same month',
    group: mockGroup2,
    startDate: '2018-01-01',
    endDate: '2018-01-31',
    webUrl: '/groups/gitlab-org/-/epics/10',
    descendantCounts: defaultDescendantCounts,
    hasParent: false,
  },
  {
    id: 35,
    iid: 8,
    description: null,
    title: 'Epic with out of range start & null end',
    group: mockGroup1,
    startDate: '2017-09-04',
    endDate: null,
    webUrl: '/groups/gitlab-org/-/epics/8',
    descendantCounts: defaultDescendantCounts,
    hasParent: false,
  },
  {
    id: 33,
    iid: 6,
    description: null,
    title: 'Epic with only start date',
    group: mockGroup1,
    startDate: '2017-11-27',
    endDate: null,
    webUrl: '/groups/gitlab-org/-/epics/6',
    descendantCounts: defaultDescendantCounts,
    hasParent: false,
  },
  {
    id: 4,
    iid: 4,
    description:
      'Animi dolorem error ipsam assumenda. Dolor reprehenderit sit soluta molestias id. Explicabo vel dolores numquam earum ut aliquid. Quisquam aliquam a totam laborum quia.\n\nEt voluptatem reiciendis qui cum. Labore ratione delectus minus et voluptates. Dolor voluptatem nisi neque fugiat ut ullam dicta odit. Aut quaerat provident ducimus aut molestiae hic esse.\n\nSuscipit non repellat laudantium quaerat. Voluptatum dolor explicabo vel illo earum. Laborum vero occaecati qui autem cumque dolorem autem. Enim voluptatibus a dolorem et.',
    title: 'Et repellendus quo et laboriosam corrupti ex nisi qui.',
    group: mockGroup1,
    startDate: '2018-01-01',
    endDate: '2018-02-02',
    webUrl: '/groups/gitlab-org/-/epics/4',
    descendantCounts: defaultDescendantCounts,
    hasParent: false,
  },
  {
    id: 3,
    iid: 3,
    description:
      'Magnam placeat ut esse aut vel. Et sit ab soluta ut eos et et. Nesciunt expedita sit et optio maiores quas facilis. Provident ut aut et nihil. Nesciunt ipsum fuga labore dolor quia.\n\nSit suscipit impedit aut dolore non provident. Nesciunt nemo excepturi voluptatem natus veritatis. Vel ut possimus reiciendis dolorem et. Recusandae voluptatem voluptatum aut iure. Sapiente quia est iste similique quidem quia omnis et.\n\nId aut assumenda beatae iusto est dicta consequatur. Tempora voluptatem pariatur ab velit vero ut reprehenderit fuga. Dolor modi aspernatur eos atque eveniet harum sed voluptatem. Dolore iusto voluptas dolor enim labore dolorum consequatur dolores.',
    title: 'Nostrum ut nisi fugiat accusantium qui velit dignissimos.',
    group: mockGroup1,
    startDate: '2017-12-01',
    endDate: '2018-03-26',
    webUrl: '/groups/gitlab-org/-/epics/3',
    descendantCounts: defaultDescendantCounts,
    hasParent: true,
    parent: {
      id: '40',
    },
  },
  {
    id: 2,
    iid: 2,
    description:
      'Deleniti id facere numquam cum consectetur sint ipsum consequatur. Odit nihil harum consequuntur est nemo adipisci. Incidunt suscipit voluptatem et culpa at voluptatem consequuntur. Rerum aliquam earum quia consequatur ipsam quae ut.\n\nQuod molestias ducimus quia ratione nostrum ut adipisci. Fugiat officiis reiciendis repellendus quia ut ipsa. Voluptatum ut dolor perferendis nostrum. Porro a ducimus sequi qui quos ea. Earum velit architecto necessitatibus at dicta.\n\nModi aut non fugiat autem doloribus nobis ea. Sit quam corrupti blanditiis nihil tempora ratione enim ex. Aliquam quia ut impedit ut velit reprehenderit quae amet. Unde quod at dolorum eligendi in ducimus perspiciatis accusamus.',
    title: 'Sit beatae amet quaerat consequatur non repudiandae qui.',
    group: mockGroup1,
    startDate: '2017-11-26',
    endDate: '2018-03-22',
    webUrl: '/groups/gitlab-org/-/epics/2',
    descendantCounts: defaultDescendantCounts,
    hasParent: false,
  },
  {
    id: 1,
    iid: 1,
    description:
      'Explicabo et soluta minus praesentium minima ab et voluptatem. Quas architecto vero corrupti voluptatibus labore accusantium consectetur. Aliquam aut impedit voluptates illum molestias aut harum. Aut non odio praesentium aut.\n\nQuo asperiores aliquid sed nobis. Omnis sint iste provident numquam. Qui voluptatem tempore aut aut voluptas dolorem qui.\n\nEst est nemo quod est. Odit modi eos natus cum illo aut. Expedita nostrum ea est omnis magnam ut eveniet maxime. Itaque ipsam provident minima et occaecati ut. Dicta est perferendis sequi perspiciatis rerum voluptatum deserunt.',
    title:
      'Cupiditate exercitationem unde harum reprehenderit maxime eius velit recusandae incidunt quia.',
    group: mockGroup1,
    startDate: '2017-07-10',
    endDate: '2018-06-02',
    webUrl: '/groups/gitlab-org/-/epics/1',
    descendantCounts: defaultDescendantCounts,
    hasParent: false,
  },
  {
    id: 22,
    iid: 2,
    description: null,
    title: 'Epic with invalid dates',
    group: mockGroup2,
    startDate: '2018-12-26',
    endDate: '2018-03-10',
    webUrl: '/groups/gitlab-org/marketing/-/epics/22',
    descendantCounts: defaultDescendantCounts,
    hasParent: false,
  },
];

export const mockUnsortedEpics = [
  {
    title: 'Nov 10 2013 ~ Jun 01 2014; actual start date is Feb 1 2013',
    originalStartDate: dateFromString('Feb 1 2013'),
    startDate: dateFromString('Nov 10 2013'),
    endDate: dateFromString('Jun 1, 2014'),
  },
  {
    title: 'Oct 01 2013 ~ Nov 01 2013; actual due date is Nov 1 2014',
    startDate: dateFromString('Oct 1 2013'),
    originalEndDate: dateFromString('Nov 1 2014'),
    endDate: dateFromString('Nov 1, 2013'),
  },
  {
    title: 'Jan 01 2020 ~ Dec 01 2020; no fixed start date',
    startDateUndefined: true,
    startDate: dateFromString('Jan 1 2020'),
    endDate: dateFromString('Dec 1 2020'),
  },
  {
    title: 'Mar 01 2013 ~ Dec 01 2013; no fixed due date',
    startDate: dateFromString('Mar 1 2013'),
    endDateUndefined: true,
    endDate: dateFromString('Dec 1 2013'),
  },
  {
    title: 'Mar 12 2017 ~ Aug 20 2017',
    startDate: new Date(2017, 2, 12),
    endDate: new Date(2017, 7, 20),
  },
  {
    title: 'Jun 08 2015 ~ Apr 01 2016',
    startDate: new Date(2015, 5, 8),
    endDate: new Date(2016, 3, 1),
  },
  {
    title: 'Apr 12 2019 ~ Aug 30 2019',
    startDate: new Date(2019, 4, 12),
    endDate: new Date(2019, 7, 30),
  },
  {
    title: 'Mar 17 2014 ~ Aug 15 2015',
    startDate: new Date(2014, 3, 17),
    endDate: new Date(2015, 7, 15),
  },
];

export const mockEpicNode1 = {
  __typename: 'Epic',
  parent: null,
  id: 'gid://gitlab/Epic/40',
  iid: '2',
  title: 'Marketing epic',
  description: 'Mock epic description',
  state: 'opened',
  startDate: '2017-12-25',
  dueDate: '2018-02-15',
  webUrl: 'http://gdk.test:3000/groups/gitlab-org/marketing/-/epics/1',
  hasChildren: false,
  hasParent: false,
  confidential: false,
  descendantWeightSum: {
    closedIssues: 3,
    openedIssues: 2,
    __typename: 'EpicDescendantWeights',
  },
  descendantCounts: {
    openedEpics: 3,
    closedEpics: 2,
    __typename: 'EpicDescendantCount',
  },
  group: mockGroup1,
};

export const mockEpicNode2 = {
  __typename: 'Epic',
  parent: null,
  id: 'gid://gitlab/Epic/41',
  iid: '3',
  title: 'Another marketing',
  startDate: '2017-12-26',
  dueDate: '2018-03-10',
  state: 'opened',
  webUrl: 'http://gdk.test:3000/groups/gitlab-org/marketing/-/epics/2',
  descendantWeightSum: {
    closedIssues: 0,
    openedIssues: 1,
    __typename: 'EpicDescendantWeights',
  },
  descendantCounts: {
    openedEpics: 0,
    closedEpics: 0,
    __typename: 'EpicDescendantCount',
  },
  group: mockGroup1,
};

export const mockGroupEpics = [mockEpicNode1, mockEpicNode2];

export const mockPageInfo = {
  endCursor: 'eyJzdGFydF9kYXRlIjoiMjAyMC0wOS0wMSIsImlkIjoiMzExIn0',
  hasNextPage: true,
  hasPreviousPage: true,
  startCursor: 'eyJzdGFydF9kYXRlIjoiMjAyMC0wNC0xOCIsImlkIjoiMjQ1In0',
  __typename: 'PageInfo',
};

export const mockGroupEpicsQueryResponse = {
  data: {
    group: {
      id: 'gid://gitlab/Group/1',
      name: 'Gitlab Org',
      epics: {
        edges: [
          {
            node: {
              ...mockEpicNode1,
            },
            __typename: 'EpicEdge',
          },
          {
            node: {
              ...mockEpicNode2,
            },
            __typename: 'EpicEdge',
          },
        ],
        pageInfo: {
          ...mockPageInfo,
        },
        __typename: 'EpicConnection',
      },
      __typename: 'Group',
    },
  },
};

export const mockChildEpicNode1 = {
  __typename: 'Epic',
  id: 'gid://gitlab/Epic/70',
  iid: '10',
  title: 'child epic title',
  description: null,
  state: 'opened',
  webUrl: 'http://gdk.test:3000/groups/gitlab-org/-/epics/10',
  startDate: null,
  dueDate: null,
  hasChildren: false,
  hasParent: true,
  confidential: false,
  descendantWeightSum: {
    closedIssues: 0,
    openedIssues: 0,
    __typename: 'EpicDescendantWeights',
  },
  descendantCounts: {
    openedEpics: 0,
    closedEpics: 0,
    __typename: 'EpicDescendantCount',
  },
  group: {
    name: 'Gitlab Org',
    fullName: 'Gitlab Org',
    fullPath: 'gitlab-org',
    __typename: 'Group',
  },
  color: null,
  textColor: null,
};

export const mockEpicChildEpicsQueryResponse = {
  data: {
    group: {
      id: 'gid://gitlab/Group/2',
      name: 'Gitlab Org',
      epic: {
        id: 'gid://gitlab/Epic/1',
        title: 'Error omnis quos consequatur',
        hasChildren: true,
        children: {
          edges: [
            {
              node: {
                ...mockChildEpicNode1,
              },
              __typename: 'EpicEdge',
            },
          ],
          __typename: 'EpicConnection',
        },
        __typename: 'Epic',
      },
      __typename: 'Group',
    },
  },
};

export const mockEpicChildEpicsWithColorQueryResponse = {
  data: {
    group: {
      id: 'gid://gitlab/Group/2',
      name: 'Gitlab Org',
      epic: {
        id: 'gid://gitlab/Epic/1',
        title: 'Error omnis quos consequatur',
        hasChildren: true,
        children: {
          edges: [
            {
              node: {
                ...mockChildEpicNode1,
                color: '#1068bf',
                textColor: '#ffffff',
              },
              __typename: 'EpicEdge',
            },
          ],
          __typename: 'EpicConnection',
        },
        __typename: 'Epic',
      },
      __typename: 'Group',
    },
  },
};

export const mockMilestone = {
  id: 1,
  state: 'active',
  description:
    'Explicabo et soluta minus praesentium minima ab et voluptatem. Quas architecto vero corrupti voluptatibus labore accusantium consectetur. Aliquam aut impedit voluptates illum molestias aut harum. Aut non odio praesentium aut.\n\nQuo asperiores aliquid sed nobis. Omnis sint iste provident numquam. Qui voluptatem tempore aut aut voluptas dolorem qui.\n\nEst est nemo quod est. Odit modi eos natus cum illo aut. Expedita nostrum ea est omnis magnam ut eveniet maxime. Itaque ipsam provident minima et occaecati ut. Dicta est perferendis sequi perspiciatis rerum voluptatum deserunt.',
  title:
    'Cupiditate exercitationem unde harum reprehenderit maxime eius velit recusandae incidunt quia.',
  groupId: 2,
  groupName: 'Gitlab Org',
  groupFullName: 'Gitlab Org',
  startDate: new Date('2017-07-10'),
  endDate: new Date('2018-06-02'),
  webPath: '/groups/gitlab-org/-/milestones/1',
};

export const mockMilestone2 = {
  id: 2,
  state: 'active',
  description:
    'Explicabo et soluta minus praesentium minima ab et voluptatem. Quas architecto vero corrupti voluptatibus labore accusantium consectetur. Aliquam aut impedit voluptates illum molestias aut harum. Aut non odio praesentium aut.\n\nQuo asperiores aliquid sed nobis. Omnis sint iste provident numquam. Qui voluptatem tempore aut aut voluptas dolorem qui.\n\nEst est nemo quod est. Odit modi eos natus cum illo aut. Expedita nostrum ea est omnis magnam ut eveniet maxime. Itaque ipsam provident minima et occaecati ut. Dicta est perferendis sequi perspiciatis rerum voluptatum deserunt.',
  title: 'Milestone 2',
  groupId: 2,
  groupName: 'Gitlab Org',
  groupFullName: 'Gitlab Org',
  startDate: new Date('2017-11-10'),
  endDate: new Date('2018-07-02'),
  webPath: '/groups/gitlab-org/-/milestones/1',
};

export const mockFormattedMilestone = {
  id: 1,
  state: 'active',
  title:
    'Cupiditate exercitationem unde harum reprehenderit maxime eius velit recusandae incidunt quia.',
  description:
    'Explicabo et soluta minus praesentium minima ab et voluptatem. Quas architecto vero corrupti voluptatibus labore accusantium consectetur. Aliquam aut impedit voluptates illum molestias aut harum. Aut non odio praesentium aut.\n\nQuo asperiores aliquid sed nobis. Omnis sint iste provident numquam. Qui voluptatem tempore aut aut voluptas dolorem qui.\n\nEst est nemo quod est. Odit modi eos natus cum illo aut. Expedita nostrum ea est omnis magnam ut eveniet maxime. Itaque ipsam provident minima et occaecati ut. Dicta est perferendis sequi perspiciatis rerum voluptatum deserunt.',
  groupId: 2,
  groupName: 'Gitlab Org',
  groupFullName: 'Gitlab Org',
  startDate: new Date(2017, 10, 1),
  originalStartDate: new Date(2017, 5, 26),
  endDate: new Date(2018, 2, 10),
  originalEndDate: new Date(2018, 2, 10),
  startDateOutOfRange: true,
  endDateOutOfRange: false,
  webPath: '/groups/gitlab-org/-/milestones/1',
  newMilestone: undefined,
};

export const mockGroupMilestoneNode1 = {
  id: 'gid://gitlab/Milestone/40',
  title: 'Sprint - Tempore voluptatibus et aut consequatur similique animi dolores veritatis.',
  description: '',
  state: 'active',
  startDate: '2017-12-25',
  dueDate: '2018-03-09',
  webPath: '/gitlab-org/gitlab-org/-/milestones/1',
  projectMilestone: false,
  groupMilestone: true,
  subgroupMilestone: false,
  __typename: 'Milestone',
};

export const mockGroupMilestoneNode2 = {
  id: 'gid://gitlab/Milestone/41',
  description: 'Maiores dolor vel nihil non nam commodi.',
  title: 'Milestone 2',
  state: 'active',
  startDate: '2017-12-26',
  dueDate: '2018-03-10',
  webPath: '/gitlab-org/gitlab-test/-/milestones/2',
  projectMilestone: false,
  groupMilestone: true,
  subgroupMilestone: false,
  __typename: 'Milestone',
};

export const mockGroupMilestones = [mockGroupMilestoneNode1, mockGroupMilestoneNode2];

export const mockGroupMilestonesQueryResponse = {
  data: {
    group: {
      id: 'gid://gitlab/Group/2',
      name: 'Gitlab Org',
      milestones: {
        edges: [
          {
            node: {
              ...mockGroupMilestoneNode1,
            },
            __typename: 'MilestoneEdge',
          },
          {
            node: {
              ...mockGroupMilestoneNode2,
            },
            __typename: 'MilestoneEdge',
          },
        ],
        __typename: 'MilestoneConnection',
      },
      __typename: 'Group',
    },
  },
};

export const mockEpicsWithParents = [
  {
    id: 'gid://gitlab-org/subgroup/Epic/1',
    hasParent: true,
    parent: {
      id: 'gid://gitlab-org/Epic/1',
    },
  },
  {
    id: 'gid://gitlab-org/subgroup/Epic/2',
    hasParent: true,
    parent: {
      id: 'gid://gitlab-org/subgroup/Epic/1',
    },
  },
  {
    id: 'gid://gitlab-org/subgroup/Epic/3',
    hasParent: true,
    parent: {
      id: 'gid://gitlab-org/subgroup/Epic/1',
    },
  },
  {
    id: 'gid://gitlab-org/subgroup/Epic/4',
    hasParent: true,
    parent: {
      id: 'gid://gitlab-org/subgroup/Epic/1',
    },
  },
];

export const mockAuthorTokenConfig = {
  type: TOKEN_TYPE_AUTHOR,
  icon: 'user',
  title: TOKEN_TITLE_AUTHOR,
  unique: true,
  symbol: '@',
  token: UserToken,
  operators: OPERATORS_IS_NOT,
  recentSuggestionsStorageKey: 'gitlab-org-epics-recent-tokens-author_username',
  fetchUsers: expect.any(Function),
  preloadedUsers: [],
  defaultUsers: [],
};

export const mockLabelTokenConfig = {
  type: TOKEN_TYPE_LABEL,
  icon: 'labels',
  title: TOKEN_TITLE_LABEL,
  unique: false,
  symbol: '~',
  token: LabelToken,
  operators: OPERATORS_IS_NOT,
  recentSuggestionsStorageKey: 'gitlab-org-epics-recent-tokens-label_name',
  fetchLabels: expect.any(Function),
};

export const mockMilestoneTokenConfig = {
  type: TOKEN_TYPE_MILESTONE,
  icon: 'clock',
  title: TOKEN_TITLE_MILESTONE,
  unique: true,
  symbol: '%',
  token: MilestoneToken,
  operators: OPERATORS_IS,
  fetchMilestones: expect.any(Function),
  defaultMilestones: [],
};

export const mockConfidentialTokenConfig = {
  type: TOKEN_TYPE_CONFIDENTIAL,
  icon: 'eye-slash',
  title: TOKEN_TITLE_CONFIDENTIAL,
  unique: true,
  token: GlFilteredSearchToken,
  operators: OPERATORS_IS,
  options: [
    { icon: 'eye-slash', value: true, title: 'Yes' },
    { icon: 'eye', value: false, title: 'No' },
  ],
};

export const mockEpicTokenConfig = {
  type: TOKEN_TYPE_EPIC,
  icon: 'epic',
  title: TOKEN_TITLE_EPIC,
  unique: true,
  symbol: '&',
  token: EpicToken,
  operators: OPERATORS_IS,
  idProperty: 'iid',
  useIdValue: true,
  recentSuggestionsStorageKey: 'gitlab-org-epics-recent-tokens-epic_iid',
  fullPath: 'gitlab-org',
};

export const mockReactionEmojiTokenConfig = {
  type: TOKEN_TYPE_MY_REACTION,
  icon: 'thumb-up',
  title: TOKEN_TITLE_MY_REACTION,
  unique: true,
  token: EmojiToken,
  operators: OPERATORS_IS_NOT,
  fetchEmojis: expect.any(Function),
};

export const mockGroupTokenConfig = {
  type: TOKEN_TYPE_GROUP,
  icon: 'group',
  title: TOKEN_TITLE_GROUP,
  unique: true,
  token: GroupToken,
  operators: OPERATORS_IS,
  fullPath: 'gitlab-org',
};
