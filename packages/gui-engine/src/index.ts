import { invoke } from '@tauri-apps/api/tauri';
import { listen } from '@tauri-apps/api/event';
import { type ProgramManifest, type UserSettings, type DotfileManifest } from '@dotfiles/schema';

export interface LogEntry {
  message: string;
  is_error: boolean;
}

export interface DiskItem {
  path: string;
  size_bytes: number;
  modified_at: number | null;
}

export interface DiskCategory {
  id: string;
  label: string;
  icon: string;
  group: string;
  size_bytes: number;
  item_count: number;
  safe: boolean;
  items: DiskItem[];
}

export interface ScanProgress {
  current: string;
  step: number;
  total: number;
}

export interface CleanEvent {
  id: string;
  freed_bytes: number;
  error: string | null;
  done: boolean;
  step: number;
  total: number;
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
  elapsed_secs: number;
  status: string;
  user: string;
}

export interface GitRepoSummary {
  path: string;
  name: string;
  current_branch: string;
  is_dirty: boolean;
  ahead: number;
  behind: number;
  last_commit_msg: string;
  last_commit_ts: number;
  stash_count: number;
}

export interface GitBranch {
  name: string;
  is_remote: boolean;
  is_current: boolean;
  ahead: number | null;
  behind: number | null;
  last_commit_hash: string;
  last_commit_msg: string;
}

export interface GitCommit {
  short_hash: string;
  full_hash: string;
  message: string;
  author: string;
  ts: number;
}

export interface GitRemote {
  name: string;
  url: string;
}

export interface GitStash {
  index: number;
  message: string;
  ts: number;
}

export interface GitRepoDetail {
  summary: GitRepoSummary;
  branches: GitBranch[];
  commits: GitCommit[];
  remotes: GitRemote[];
  stashes: GitStash[];
  tags: string[];
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

  scanDisk: async (
    onCategory?: (cat: DiskCategory) => void,
    onProgress?: (prog: ScanProgress) => void,
  ): Promise<void> => {
    return new Promise(async (resolve, reject) => {
      const unlisteners: Array<() => void> = [];

      if (onCategory) {
        const ul = await listen<DiskCategory>('scan-category', (e) => onCategory(e.payload));
        unlisteners.push(ul);
      }
      if (onProgress) {
        const ul = await listen<ScanProgress>('scan-progress', (e) => onProgress(e.payload));
        unlisteners.push(ul);
      }

      const cleanup = () => unlisteners.forEach(fn => fn());

      const doneUl = await listen<null>('scan-done', () => {
        cleanup();
        doneUl();
        resolve();
      });

      invoke('scan_disk_usage').catch((err) => {
        cleanup();
        doneUl();
        reject(err);
      });
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

      const doneUl = await listen<null>('clean-done', () => {
        cleanup();
        doneUl();
        resolve();
      });

      invoke('clean_items', { ids }).catch((err) => {
        cleanup();
        doneUl();
        reject(err);
      });
    });
  },

  scanLargeFiles: async (): Promise<LargeFile[]> => {
    return new Promise(async (resolve) => {
      const ul = await listen<LargeFile[]>('large-files-done', (e) => {
        ul();
        resolve(e.payload);
      });
      invoke('scan_large_files').catch(() => {
        ul();
        resolve([]);
      });
    });
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

  scanGitRepos: async (
    roots: string[],
    onRepo?: (repo: GitRepoSummary) => void,
    onCount?: (count: number) => void,
  ): Promise<void> => {
    return new Promise(async (resolve, reject) => {
      const unlisteners: Array<() => void> = [];

      if (onRepo) {
        const ul = await listen<GitRepoSummary>('git-repo-found', (e) => onRepo(e.payload));
        unlisteners.push(ul);
      }
      if (onCount) {
        const ul = await listen<number>('git-scan-count', (e) => onCount(e.payload));
        unlisteners.push(ul);
      }

      const cleanup = () => unlisteners.forEach(fn => fn());

      const doneUl = await listen<null>('git-scan-done', () => {
        cleanup();
        doneUl();
        resolve();
      });

      invoke('scan_git_repos', { roots }).catch((err) => {
        cleanup();
        doneUl();
        reject(err);
      });
    });
  },

  getRepoDetail: async (path: string): Promise<GitRepoDetail> => {
    return invoke<GitRepoDetail>('get_repo_detail', { path });
  },

  gitAction: async (path: string, actionType: string, params: Record<string, unknown> = {}): Promise<string> => {
    return invoke<string>('git_action', { path, action_type: actionType, params });
  },
};
