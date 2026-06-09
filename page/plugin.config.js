const translations = {
  en: {
    displayName: 'Nethogs Network Monitor for MOS',
    description: 'Real-time network traffic monitoring tool',
    commands: {
      install: 'Install Nethogs and network monitoring tools',
    },
  },
  de: {
    displayName: 'Nethogs Netzwerk-Monitor fuer MOS',
    description: 'Echtzeit-Netzwerküberwachungstool',
    commands: {
      install: 'Nethogs und Netzwerk-Überwachungstools installieren',
    },
  },
};

export default {
  name: 'mos-nethogs',
  displayName: translations.en.displayName,
  description: translations.en.description,
  version: '0.0.1',
  icon: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/network-topology.png',
  category: ['Network'],
  architecture: ['amd64'],
  driver: false,
  author: 'MOS Community',
  homepage: 'https://github.com/netoptimizer/nethogs',
  repository: 'https://github.com/netoptimizer/nethogs',
  support: 'https://github.com/netoptimizer/nethogs/issues',
  translations,
  commands: [
    {
      name: 'mos-nethogs-install',
      executable: '/usr/bin/plugins/mos-nethogs-install',
      description: translations.en.commands.install,
    },
  ],
};
