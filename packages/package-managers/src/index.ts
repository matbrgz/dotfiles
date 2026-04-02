import { exec } from 'node:child_process';
import { promisify } from 'node:util';
import { detectOS } from '@dotfiles/core';

const execAsync = promisify(exec);

export type PackageManagerName = 'apt' | 'pacman' | 'dnf' | 'zypper' | 'brew' | 'choco' | 'unknown';

export abstract class PackageManager {
  abstract name: PackageManagerName;
  abstract isInstalled(packageName: string): Promise<boolean>;
  abstract install(packageName: string): Promise<{ success: boolean; stdout?: string; stderr?: string }>;
}

export class AptManager extends PackageManager {
  name: PackageManagerName = 'apt';
  async isInstalled(packageName: string): Promise<boolean> {
    try {
      await execAsync(`dpkg -l | grep -qw ${packageName}`);
      return true;
    } catch {
      return false;
    }
  }
  async install(packageName: string) {
    try {
      const { stdout, stderr } = await execAsync(`sudo apt install -y ${packageName}`);
      return { success: true, stdout, stderr };
    } catch (e: any) {
      return { success: false, stderr: e.message };
    }
  }
}

export class ChocoManager extends PackageManager {
  name: PackageManagerName = 'choco';
  async isInstalled(packageName: string): Promise<boolean> {
    try {
      await execAsync(`choco list --local-only ${packageName} | findstr /i ${packageName}`);
      return true;
    } catch {
      return false;
    }
  }
  async install(packageName: string) {
    try {
      const { stdout, stderr } = await execAsync(`choco install -y ${packageName}`);
      return { success: true, stdout, stderr };
    } catch (e: any) {
      return { success: false, stderr: e.message };
    }
  }
}

export class BrewManager extends PackageManager {
  name: PackageManagerName = 'brew';
  async isInstalled(packageName: string): Promise<boolean> {
    try {
      await execAsync(`brew list --formula | grep -qx ${packageName}`);
      return true;
    } catch {
      // Check for cask if formula fails
      try {
        await execAsync(`brew list --cask | grep -qx ${packageName}`);
        return true;
      } catch {
        return false;
      }
    }
  }
  async install(packageName: string) {
    try {
      const { stdout, stderr } = await execAsync(`brew install ${packageName}`);
      return { success: true, stdout, stderr };
    } catch (e: any) {
      return { success: false, stderr: e.message };
    }
  }
}

export function getNativeManager(): PackageManager | null {
  const os = detectOS();
  if (os === 'linux' || os === 'wsl') return new AptManager();
  if (os === 'windows') return new ChocoManager();
  if (os === 'macos') return new BrewManager();
  return null;
}
