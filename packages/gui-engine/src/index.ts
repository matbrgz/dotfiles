import { invoke } from '@tauri-apps/api/tauri';
import { listen } from '@tauri-apps/api/event';
import { type ProgramManifest, type UserSettings, type DotfileManifest } from '@dotfiles/schema';

export interface LogEntry {
  message: string;
  is_error: boolean;
}

/**
 * Tauri Commands Wrapper (Bridge to Rust Backend)
 */
export const guiCommands = {
  getSystemInfo: async () => {
    try {
      return await invoke<{ os: string; platform: string }>('get_system_info');
    } catch (e) {
      return { os: 'browser-dev', platform: window.navigator.platform };
    }
  },

  getRegistryData: async () => {
    try {
      return await invoke<Record<string, ProgramManifest>>('get_registry_data');
    } catch (e) {
      console.warn('Tauri not detected or failed to load registry:', e);
      return {};
    }
  },

  getDotfilesData: async () => {
    try {
      return await invoke<Record<string, DotfileManifest>>('get_dotfiles_data');
    } catch (e) {
      console.warn('Failed to load dotfiles:', e);
      return {};
    }
  },

  getUserSettings: async () => {
    try {
      return await invoke<UserSettings>('get_user_settings');
    } catch (e) {
      throw new Error(`Failed to load settings: ${e}`);
    }
  },

  saveUserSettings: async (settings: UserSettings) => {
    try {
      await invoke('save_user_settings', { settings });
    } catch (e) {
      throw new Error(`Failed to save settings: ${e}`);
    }
  },

  checkInstallation: async (name: string): Promise<boolean> => {
    try {
      return await invoke<boolean>('check_installation', { name });
    } catch (e) {
      return false;
    }
  },

  /**
   * Runs a CLI command and sets up a callback for real-time logs
   */
  runCommand: async (command: string, name?: string, onLog?: (log: LogEntry) => void) => {
    let unlisten: (() => void) | null = null;
    
    if (onLog) {
      unlisten = await listen<LogEntry>('cli-log', (event) => {
        onLog(event.payload);
      });
    }

    try {
      await invoke('run_cli_command', { command, name });
    } finally {
      if (unlisten) unlisten();
    }
  }
};
