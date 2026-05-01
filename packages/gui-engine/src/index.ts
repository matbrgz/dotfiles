import { invoke } from '@tauri-apps/api/tauri';
import { listen } from '@tauri-apps/api/event';
import { type ProgramManifest, type UserSettings, type DotfileManifest } from '@dotfiles/schema';

export interface LogEntry {
  message: string;
  is_error: boolean;
}

export interface DiskCategory {
  id: string;
  label: string;
  icon: string;
  group: string;
  size_bytes: number;
  item_count: number;
  safe: boolean;
}

export interface CleanEvent {
  id: string;
  freed_bytes: number;
  error: string | null;
  done: boolean;
}

export interface LargeFile {
  path: string;
  size_bytes: number;
}

export interface MemoryInfo {
  total_mb: number;
  used_mb: number;
  available_mb: number;
  inactive_mb: number;
  wired_mb: number;
}

export interface ProcInfo {
  pid: number;
  name: string;
  memory_mb: number;
  cpu_pct: number;
}

export const guiCommands = {
  getSystemInfo: async () => {
    try {
      return await invoke<{ os: string; platform: string }>('get_system_info');
    } catch {
      return { os: 'browser-dev', platform: window.navigator.platform };
    }
  },

  getRuntimeInfo: async (): Promise<{ node: string; tauri: string }> => {
    try {
      return await invoke<{ node: string; tauri: string }>('get_runtime_info');
    } catch {
      return { node: 'n/a', tauri: 'n/a' };
    }
  },

  checkBrewPackage: async (method: string, package_name: string): Promise<boolean> => {
    try {
      return await invoke<boolean>('check_brew_package', { method, package: package_name });
    } catch {
      return false;
    }
  },

  checkDotfileExists: async (target: string): Promise<boolean> => {
    try {
      return await invoke<boolean>('check_dotfile_exists', { target });
    } catch {
      return false;
    }
  },

  getRegistryData: async () => {
    try {
      return await invoke<Record<string, ProgramManifest>>('get_registry_data');
    } catch (e) {
      console.warn('Failed to load registry:', e);
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

  runCommand: async (command: string, name?: string, onLog?: (log: LogEntry) => void): Promise<void> => {
    return new Promise(async (resolve, reject) => {
      const unlisteners: Array<() => void> = [];

      if (onLog) {
        const unlisten = await listen<LogEntry>('cli-log', (event) => {
          onLog(event.payload);
        });
        unlisteners.push(unlisten);
      }

      const cleanup = () => unlisteners.forEach(fn => fn());

      const finishUnlisten = await listen<boolean>('cli-finished', (event) => {
        cleanup();
        finishUnlisten();
        event.payload ? resolve() : reject(new Error('Command failed'));
      });

      invoke('run_cli_command', { command, name }).catch((err) => {
        cleanup();
        finishUnlisten();
        reject(err);
      });
    });
  },

  scanDisk: async (onCategory?: (cat: DiskCategory) => void): Promise<DiskCategory[]> => {
    return new Promise(async (resolve, reject) => {
      const results: DiskCategory[] = [];
      let unlisten: (() => void) | null = null;
      if (onCategory) {
        unlisten = await listen<DiskCategory>('scan-category', (e) => {
          results.push(e.payload);
          onCategory(e.payload);
        });
      }
      try {
        const cats = await invoke<DiskCategory[]>('scan_disk_usage');
        resolve(cats);
      } catch (e) {
        reject(e);
      } finally {
        if (unlisten) unlisten();
      }
    });
  },

  cleanItems: async (ids: string[], onProgress?: (e: CleanEvent) => void): Promise<void> => {
    return new Promise(async (resolve, reject) => {
      const unlisteners: Array<() => void> = [];
      if (onProgress) {
        const ul = await listen<CleanEvent>('clean-progress', (e) => onProgress(e.payload));
        unlisteners.push(ul);
      }
      const cleanup = () => unlisteners.forEach(fn => fn());
      try {
        await invoke('clean_items', { ids });
        cleanup();
        resolve();
      } catch (e) {
        cleanup();
        reject(e);
      }
    });
  },

  scanLargeFiles: async (): Promise<LargeFile[]> => {
    try {
      return await invoke<LargeFile[]>('scan_large_files');
    } catch {
      return [];
    }
  },

  getMemoryInfo: async (): Promise<MemoryInfo> => {
    return invoke<MemoryInfo>('get_memory_info');
  },

  getTopProcesses: async (limit: number): Promise<ProcInfo[]> => {
    try {
      return await invoke<ProcInfo[]>('get_top_processes', { limit });
    } catch {
      return [];
    }
  },

  killProcess: async (pid: number): Promise<void> => {
    await invoke('kill_process', { pid });
  },
};
