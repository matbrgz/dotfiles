import fs from 'node:fs/promises';
import path from 'node:path';
import { 
  ProgramManifestSchema, type ProgramManifest, 
  UserSettingsSchema, type UserSettings,
  DotfileManifestSchema, type DotfileManifest
} from '@dotfiles/schema';

export async function loadSettings(settingsPath: string): Promise<UserSettings> {
  const content = await fs.readFile(settingsPath, 'utf-8');
  const data = JSON.parse(content);
  return UserSettingsSchema.parse(data);
}

export async function loadRegistry(registryDir: string): Promise<Record<string, ProgramManifest>> {
  const registry: Record<string, ProgramManifest> = {};
  const dataDir = path.join(registryDir, 'data');

  try {
    const files = await fs.readdir(dataDir);
    for (const file of files) {
      if (file.endsWith('.json') && file !== 'dotfiles.json') {
        const filePath = path.join(dataDir, file);
        const content = await fs.readFile(filePath, 'utf-8');
        const data = JSON.parse(content);

        for (const [id, config] of Object.entries(data)) {
          try {
            registry[id] = ProgramManifestSchema.parse(config);
          } catch (error) {
            console.error(`Invalid manifest for program ${id} in ${file}:`, error);
          }
        }
      }
    }
  } catch (error) {
    console.error('Error loading registry data:', error);
  }
  return registry;
}

export async function loadDotfiles(registryDir: string): Promise<Record<string, DotfileManifest>> {
  const filePath = path.join(registryDir, 'data/dotfiles.json');
  try {
    const content = await fs.readFile(filePath, 'utf-8');
    const data = JSON.parse(content);
    const dotfiles: Record<string, DotfileManifest> = {};
    for (const [id, config] of Object.entries(data)) {
      dotfiles[id] = DotfileManifestSchema.parse(config);
    }
    return dotfiles;
  } catch (error) {
    console.error('Error loading dotfiles:', error);
    return {};
  }
}
