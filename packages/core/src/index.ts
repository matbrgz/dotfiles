import { exec } from 'node:child_process';
import { promisify } from 'node:util';
import os from 'node:os';
import fs from 'node:fs/promises';
import path from 'node:path';

const execAsync = promisify(exec);

export type OSType = 'linux' | 'windows' | 'macos' | 'wsl' | 'unknown';

export function detectOS(): OSType {
  const platform = os.platform();
  
  if (platform === 'win32') return 'windows';
  if (platform === 'darwin') return 'macos';
  if (platform === 'linux') {
    if (os.release().toLowerCase().includes('microsoft')) {
      return 'wsl';
    }
    return 'linux';
  }
  
  return 'unknown';
}

export async function runScript(scriptPath: string, osType: OSType) {
  const command = osType === 'windows' 
    ? `powershell.exe -ExecutionPolicy Bypass -File ${scriptPath}`
    : `bash ${scriptPath}`;

  try {
    const { stdout, stderr } = await execAsync(command);
    return { success: true, stdout, stderr };
  } catch (error: any) {
    return { success: false, error: error.message, stdout: error.stdout, stderr: error.stderr };
  }
}

export async function createSymlink(source: string, target: string) {
  const resolvedTarget = target.replace(/^~/, os.homedir());
  
  try {
    // Ensure target directory exists
    await fs.mkdir(path.dirname(resolvedTarget), { recursive: true });
    
    // Check if target already exists
    try {
      const stats = await fs.lstat(resolvedTarget);
      if (stats.isSymbolicLink() || stats.isFile()) {
        await fs.unlink(resolvedTarget); // Remove existing link/file
      }
    } catch (e) {
      // Target doesn't exist, which is fine
    }

    await fs.symlink(source, resolvedTarget);
    return { success: true };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}

export async function injectTemplate(source: string, target: string, variables: Record<string, string>) {
  const resolvedTarget = target.replace(/^~/, os.homedir());
  
  try {
    let content = await fs.readFile(source, 'utf-8');
    
    for (const [key, value] of Object.entries(variables)) {
      const regex = new RegExp(`{{${key}}}`, 'g');
      content = content.replace(regex, value);
    }
    
    await fs.mkdir(path.dirname(resolvedTarget), { recursive: true });
    await fs.writeFile(resolvedTarget, content);
    return { success: true };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}
