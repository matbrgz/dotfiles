import { z } from 'zod';

export const ProgramPlatformConfigSchema = z.object({
  script: z.string(),
  method: z.string().optional(),
  dependencies: z.array(z.string()).optional(),
  version: z.string().optional(),
});

export const ProgramManifestSchema = z.object({
  name: z.string(),
  description: z.string(),
  category: z.string(),
  enabled: z.boolean(),
  default: z.boolean(),
  platforms: z.object({
    linux: ProgramPlatformConfigSchema.optional(),
    windows: ProgramPlatformConfigSchema.optional(),
    macos: ProgramPlatformConfigSchema.optional(),
    wsl: ProgramPlatformConfigSchema.optional(),
  }),
  post_install: z.array(z.string()).optional(),
  config_file: z.string().nullable().optional(),
});

export const DotfileManifestSchema = z.object({
  name: z.string(),
  type: z.enum(['link', 'script', 'template']),
  source: z.string(),
  target: z.string().optional(),
  description: z.string().optional(),
});

export const UserSettingsSchema = z.object({
  personal: z.object({
    name: z.string(),
    email: z.string().email(),
    githubuser: z.string(),
    defaultfolder: z.record(z.string()),
  }),
  system: z.object({
    behavior: z.object({
      debug_mode: z.boolean(),
      purge_mode: z.boolean(),
      backup_configs: z.boolean(),
    }),
  }),
});

export type ProgramPlatformConfig = z.infer<typeof ProgramPlatformConfigSchema>;
export type ProgramManifest = z.infer<typeof ProgramManifestSchema>;
export type UserSettings = z.infer<typeof UserSettingsSchema>;
export type DotfileManifest = z.infer<typeof DotfileManifestSchema>;
