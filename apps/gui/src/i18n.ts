import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';

// common
import enCommon from './locales/en/common.json';
import ptBRCommon from './locales/pt-BR/common.json';
import esCommon from './locales/es/common.json';
// layout
import enLayout from './locales/en/layout.json';
import ptBRLayout from './locales/pt-BR/layout.json';
import esLayout from './locales/es/layout.json';
// inventory
import enInventory from './locales/en/inventory.json';
import ptBRInventory from './locales/pt-BR/inventory.json';
import esInventory from './locales/es/inventory.json';
// environment
import enEnvironment from './locales/en/environment.json';
import ptBREnvironment from './locales/pt-BR/environment.json';
import esEnvironment from './locales/es/environment.json';
// settings
import enSettings from './locales/en/settings.json';
import ptBRSettings from './locales/pt-BR/settings.json';
import esSettings from './locales/es/settings.json';
// profile
import enProfile from './locales/en/profile.json';
import ptBRProfile from './locales/pt-BR/profile.json';
import esProfile from './locales/es/profile.json';
// disk
import enDisk from './locales/en/disk.json';
import ptBRDisk from './locales/pt-BR/disk.json';
import esDisk from './locales/es/disk.json';
// memory
import enMemory from './locales/en/memory.json';
import ptBRMemory from './locales/pt-BR/memory.json';
import esMemory from './locales/es/memory.json';
// git
import enGit from './locales/en/git.json';
import ptBRGit from './locales/pt-BR/git.json';
import esGit from './locales/es/git.json';

i18n.use(initReactI18next).init({
  resources: {
    en: {
      common: enCommon,
      layout: enLayout,
      inventory: enInventory,
      environment: enEnvironment,
      settings: enSettings,
      profile: enProfile,
      disk: enDisk,
      memory: enMemory,
      git: enGit,
    },
    'pt-BR': {
      common: ptBRCommon,
      layout: ptBRLayout,
      inventory: ptBRInventory,
      environment: ptBREnvironment,
      settings: ptBRSettings,
      profile: ptBRProfile,
      disk: ptBRDisk,
      memory: ptBRMemory,
      git: ptBRGit,
    },
    es: {
      common: esCommon,
      layout: esLayout,
      inventory: esInventory,
      environment: esEnvironment,
      settings: esSettings,
      profile: esProfile,
      disk: esDisk,
      memory: esMemory,
      git: esGit,
    },
  },
  lng: (() => {
    try { return localStorage.getItem('dotfiles-lang') ?? 'en'; } catch { return 'en'; }
  })(),
  fallbackLng: 'en',
  defaultNS: 'common',
  interpolation: { escapeValue: false },
});

export default i18n;
