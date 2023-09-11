export const mockJobLog = [
  { offset: 0, content: [{ text: 'Running with gitlab-runner 15.0.0 (febb2a09)' }], lineNumber: 0 },
  { offset: 54, content: [{ text: '  on colima-docker EwM9WzgD' }], lineNumber: 1 },
  {
    isClosed: false,
    isHeader: true,
    line: {
      offset: 91,
      content: [{ text: 'Resolving secrets', style: 'term-fg-l-cyan term-bold' }],
      section: 'resolve-secrets',
      section_header: true,
      lineNumber: 2,
      section_duration: '00:00',
    },
    lines: [],
  },
  {
    isClosed: false,
    isHeader: true,
    line: {
      offset: 218,
      content: [{ text: 'Preparing the "docker" executor', style: 'term-fg-l-cyan term-bold' }],
      section: 'prepare-executor',
      section_header: true,
      lineNumber: 4,
      section_duration: '00:01',
    },
    lines: [
      {
        offset: 317,
        content: [{ text: 'Using Docker executor with image ruby:2.7 ...' }],
        section: 'prepare-executor',
        lineNumber: 5,
      },
      {
        offset: 372,
        content: [{ text: 'Pulling docker image ruby:2.7 ...' }],
        section: 'prepare-executor',
        lineNumber: 6,
      },
      {
        offset: 415,
        content: [
          {
            text:
              'Using docker image sha256:55106bf6ba7f452c38d01ea760affc6ceb67d4b60068ffadab98d1b7b007668c for ruby:2.7 with digest ruby@sha256:23d08a4bae1a12ee3fce017f83204fcf9a02243443e4a516e65e5ff73810a449 ...',
          },
        ],
        section: 'prepare-executor',
        lineNumber: 7,
      },
    ],
  },
  {
    isClosed: false,
    isHeader: true,
    line: {
      offset: 665,
      content: [{ text: 'Preparing environment', style: 'term-fg-l-cyan term-bold' }],
      section: 'prepare-script',
      section_header: true,
      lineNumber: 9,
      section_duration: '00:01',
    },
    lines: [
      {
        offset: 752,
        content: [
          { text: 'Running on runner-ewm9wzgd-project-20-concurrent-0 via 8ea689ec6969...' },
        ],
        section: 'prepare-script',
        lineNumber: 10,
      },
    ],
  },
  {
    offset: 1605,
    content: [{ text: 'Job succeeded', style: 'term-fg-l-green term-bold' }],
    lineNumber: 23,
  },
];
