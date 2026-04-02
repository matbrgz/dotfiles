import { Command } from 'commander';
import pc from 'picocolors';
import path from 'node:path';
import fs from 'node:fs/promises';
import { detectOS, runScript, createSymlink, injectTemplate } from '@dotfiles/core';
import { loadRegistry, loadSettings, loadDotfiles } from '@dotfiles/registry';
import { getNativeManager } from '@dotfiles/package-managers';
import { logger } from '@dotfiles/logger';
import { formatTable } from '@dotfiles/shared-utils';

export async function createCli(rootDir: string) {
  const registryDir = path.join(rootDir, 'packages/registry');
  const program = new Command();

  program
    .name('dotfiles')
    .description('Universal System Setup & Configuration Tool')
    .version('1.0.0');

  program
    .command('info')
    .description('Display system information')
    .action(async () => {
      const os = detectOS();
      logger.info(`${pc.blue('System OS:')} ${pc.bold(os)}`);
      try {
        const settings = await loadSettings(path.join(registryDir, 'settings.json'));
        logger.info(`${pc.blue('User:')} ${pc.bold(settings.personal.name)} (${pc.cyan(settings.personal.email)})`);
      } catch (e) {
        logger.error('Settings not found or invalid.');
      }
    });

  program
    .command('list')
    .description('List available programs')
    .action(async () => {
      const registry = await loadRegistry(registryDir);
      const entries = Object.entries(registry);
      const rows = entries.map(([id, p]) => [pc.bold(id), p.name, pc.dim(p.description), pc.magenta(p.category)]);
      console.log(formatTable([['ID', 'NAME', 'DESCRIPTION', 'CATEGORY'], ...rows]));
    });

  program
    .command('apply')
    .description('Apply dotfiles')
    .action(async () => {
      const os = detectOS();
      const settings = await loadSettings(path.join(registryDir, 'settings.json'));
      const dotfiles = await loadDotfiles(registryDir);
      logger.step('Applying dotfiles...');
      for (const [id, config] of Object.entries(dotfiles)) {
        logger.info(`Applying ${pc.bold(config.name)}...`);
        const sourcePath = path.resolve(rootDir, config.source);
        if (config.type === 'link' && config.target) {
          await createSymlink(sourcePath, config.target);
        } else if (config.type === 'template' && config.target) {
          const vars = { name: settings.personal.name, email: settings.personal.email, githubuser: settings.personal.githubuser };
          await injectTemplate(sourcePath, config.target, vars);
        } else if (config.type === 'script') {
          await runScript(sourcePath, os);
        }
      }
      logger.success('Dotfiles applied!');
    });

  program
    .command('create')
    .description('Scaffold a new program in the registry')
    .argument('<id>', 'Unique ID for the program')
    .option('-n, --name <name>', 'Display name')
    .option('-c, --category <cat>', 'Category', 'other')
    .option('-d, --description <desc>', 'Description', '')
    .action(async (id, options) => {
      const catFile = path.join(registryDir, 'data', `${options.category}.json`);
      let categoryData: any = {};
      try {
        const content = await fs.readFile(catFile, 'utf-8');
        categoryData = JSON.parse(content);
      } catch (e) {}
      categoryData[id] = {
        name: options.name || id,
        description: options.description,
        category: options.category,
        enabled: true,
        default: false,
        platforms: {
          linux: { script: `packages/os-linux/scripts/${id}.sh` },
          windows: { script: `packages/os-windows/scripts/${id}.ps1` },
          macos: { script: `packages/os-macos/scripts/${id}.sh` }
        }
      };
      await fs.writeFile(catFile, JSON.stringify(categoryData, null, 2));
      const platforms = ['linux', 'windows', 'macos'];
      for (const p of platforms) {
        const ext = p === 'windows' ? 'ps1' : 'sh';
        const scriptPath = path.join(rootDir, `packages/os-${p}/scripts/${id}.${ext}`);
        await fs.mkdir(path.dirname(scriptPath), { recursive: true });
        if (!(await fs.access(scriptPath).then(() => true).catch(() => false))) {
          await fs.writeFile(scriptPath, p === 'windows' ? '# PowerShell' : '#!/bin/bash');
        }
      }
      logger.success(`Program ${id} created!`);
    });

  program
    .command('check')
    .description('Check if a program is installed')
    .argument('<name>', 'Program name')
    .action(async (name) => {
      const pm = getNativeManager();
      if (!pm) {
        process.exit(1);
      }
      const installed = await pm.isInstalled(name);
      process.exit(installed ? 0 : 1);
    });

  program
    .command('install')
    .description('Install a program')
    .argument('<name>', 'Program name')
    .option('--force', 'Force install')
    .action(async (name, options) => {
      const os = detectOS();
      const registry = await loadRegistry(registryDir);
      const prog = registry[name];
      if (!prog) return logger.error(`Program ${name} not found.`);
      
      const platformKey = os === 'wsl' ? 'linux' : os;
      const config = prog.platforms[platformKey as keyof typeof prog.platforms];
      if (!config) return logger.error(`${prog.name} not supported on ${os}.`);

      const pm = getNativeManager();
      if (pm && !options.force && await pm.isInstalled(name)) {
        return logger.success(`${prog.name} is already installed.`);
      }

      logger.step(`Installing ${prog.name}...`);
      const result = await runScript(path.resolve(rootDir, config.script), os);
      if (result.success) logger.success(`${prog.name} installed!`);
      else logger.error(`Failed: ${result.error}`);
    });

  return program;
}
