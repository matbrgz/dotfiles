import { useState, useEffect, useRef } from 'react';
import { guiCommands, type LogEntry } from '@dotfiles/gui-engine';
import { type ProgramManifest, type UserSettings, type DotfileManifest } from '@dotfiles/schema';
import { useTranslation } from 'react-i18next';
import { Sidebar } from './components/Sidebar';
import { Header } from './components/Header';
import { TerminalPanel } from './components/TerminalPanel';
import { InventoryTab } from './components/InventoryTab';
import { EnvironmentTab } from './components/EnvironmentTab';
import { SettingsTab } from './components/SettingsTab';
import { ProfileTab } from './components/ProfileTab';
import { DiskCleanerTab } from './components/DiskCleanerTab';
import { MemoryTab } from './components/MemoryTab';
import { GitReposTab } from './components/GitReposTab';
import { Package, Settings, User, FileCode, HardDrive, Cpu, GitBranch } from 'lucide-react';

export default function App() {
  const { t } = useTranslation('layout');
  const { t: tCommon } = useTranslation('common');
  const [registry, setRegistry] = useState<Record<string, ProgramManifest>>({});
  const [dotfiles, setDotfiles] = useState<Record<string, DotfileManifest>>({});
  const [settings, setSettings] = useState<UserSettings | null>(null);
  const [loading, setLoading] = useState(true);
  const [osInfo, setOsInfo] = useState({ os: 'unknown', platform: '' });
  const [installing, setInstalling] = useState<Record<string, boolean>>({});
  const [installedStatus, setInstalledStatus] = useState<Record<string, boolean>>({});
  const [dotfileStatus, setDotfileStatus] = useState<Record<string, boolean>>({});
  const [logs, setLogs] = useState<string[]>(['System initialized', 'Ready']);
  const [activeTab, setActiveTab] = useState('inventory');
  const [searchQuery, setSearchQuery] = useState('');
  const [isApplying, setIsApplying] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [scanningDone, setScanningDone] = useState(false);
  const [terminalCollapsed, setTerminalCollapsed] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);

  const TABS = [
    { id: 'inventory',    label: t('tabPackages'),    icon: Package },
    { id: 'environment',  label: t('tabDotfiles'),    icon: FileCode },
    { id: 'settings',     label: t('tabSettings'),    icon: Settings },
    { id: 'profile',      label: t('tabProfile'),     icon: User },
    { id: 'disk-cleaner', label: t('tabDiskCleaner'), icon: HardDrive },
    { id: 'memory',       label: t('tabMemory'),      icon: Cpu },
    { id: 'git-repos',    label: t('tabGitRepos'),    icon: GitBranch },
  ];

  useEffect(() => {
    async function init() {
      try {
        const info = await guiCommands.getSystemInfo();
        setOsInfo(info);
        const data = await guiCommands.getRegistryData();
        setRegistry(data);
        const dotData = await guiCommands.getDotfilesData();
        setDotfiles(dotData);
        const userSettings = await guiCommands.getUserSettings();
        setSettings(userSettings);
        addLog(`Loaded ${Object.keys(data).length} packages, ${Object.keys(dotData).length} dotfiles`);
        scanInstallations(data);
        scanDotfiles(dotData);
      } catch (err) {
        addLog(`Init error: ${err}`, true);
      } finally {
        setLoading(false);
      }
    }
    init();
  }, []);

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [logs]);

  const scanInstallations = async (data: Record<string, ProgramManifest>) => {
    addLog('Scanning installed packages...');
    const results: Record<string, boolean> = {};
    for (const [id, prog] of Object.entries(data)) {
      const mac = (prog.platforms as any)?.macos;
      if (!mac) { results[id] = false; continue; }
      const pkg = mac.formula || mac.cask || id;
      const method = mac.method || 'which';
      results[id] = await guiCommands.checkBrewPackage(method, pkg);
      setInstalledStatus(prev => ({ ...prev, [id]: results[id] }));
    }
    setScanningDone(true);
    const installed = Object.values(results).filter(Boolean).length;
    addLog(`Scan complete — ${installed}/${Object.keys(data).length} packages installed`);
  };

  const scanDotfiles = async (dots: Record<string, DotfileManifest>) => {
    for (const [id, dot] of Object.entries(dots)) {
      if ((dot as any).target) {
        const exists = await guiCommands.checkDotfileExists((dot as any).target);
        setDotfileStatus(prev => ({ ...prev, [id]: exists }));
      }
    }
  };

  const addLog = (msg: string, isError = false) => {
    const ts = new Date().toLocaleTimeString('en-GB', { hour12: false });
    const prefix = isError ? '[ERR] ' : '';
    setLogs(prev => [...prev, `${ts}  ${prefix}${msg}`]);
  };

  const handleInstall = async (id: string) => {
    setInstalling(prev => ({ ...prev, [id]: true }));
    addLog(`Installing ${id}...`);
    try {
      await guiCommands.runCommand('install', id, (log: LogEntry) => {
        addLog(log.message, log.is_error);
      });
      addLog(`${id} installed`);
      // Re-check status after install
      const prog = registry[id];
      const mac = (prog?.platforms as any)?.macos;
      if (mac) {
        const isInstalled = await guiCommands.checkBrewPackage(mac.method || 'which', mac.formula || mac.cask || id);
        setInstalledStatus(prev => ({ ...prev, [id]: isInstalled }));
      }
    } catch (err) {
      addLog(`Failed to install ${id}: ${err}`, true);
    } finally {
      setInstalling(prev => ({ ...prev, [id]: false }));
    }
  };

  const handleApplyDotfiles = async () => {
    if (isApplying) return;
    setIsApplying(true);
    addLog('Syncing dotfiles...');
    try {
      await guiCommands.runCommand('apply', undefined, (log: LogEntry) => {
        addLog(log.message, log.is_error);
      });
      addLog('Dotfiles synced');
      scanDotfiles(dotfiles);
    } catch (err) {
      addLog(`Sync failed: ${err}`, true);
    } finally {
      setIsApplying(false);
    }
  };

  const handleSaveSettings = async () => {
    if (!settings || isSaving) return;
    setIsSaving(true);
    addLog('Saving settings...');
    try {
      await guiCommands.saveUserSettings(settings);
      addLog('Settings saved');
    } catch (err) {
      addLog(`Save failed: ${err}`, true);
    } finally {
      setIsSaving(false);
    }
  };

  if (loading) return (
    <div className="flex h-screen items-center justify-center" style={{ background: 'var(--color-bg)' }}>
      <div style={{ color: 'var(--color-green)', fontFamily: 'var(--font-mono)' }} className="text-xs tracking-widest animate-pulse">
        {tCommon('loading')}
      </div>
    </div>
  );

  const installedCount = Object.values(installedStatus).filter(Boolean).length;
  const syncedCount = Object.values(dotfileStatus).filter(Boolean).length;

  return (
    <div className="flex h-screen overflow-hidden" style={{ background: 'var(--color-bg)', fontFamily: 'var(--font-mono)' }}>
      <Sidebar activeTab={activeTab} onTabChange={setActiveTab} tabs={TABS} />

      <main className="flex-1 flex flex-col overflow-hidden">
        <Header
          osInfo={osInfo}
          isApplying={isApplying}
          onApplyDotfiles={handleApplyDotfiles}
          searchQuery={searchQuery}
          onSearchChange={setSearchQuery}
          activeTab={activeTab}
          installedCount={installedCount}
          totalCount={Object.keys(registry).length}
          syncedCount={syncedCount}
          totalDotfiles={Object.keys(dotfiles).length}
          scanning={!scanningDone}
        />

        <div style={{ position: 'relative', flex: 1, overflow: 'hidden' }}>
          <div style={{
            position: 'absolute', top: 0, left: 0, right: 0,
            bottom: terminalCollapsed ? 36 : 140,
            overflowY: 'auto',
          }}>
            {activeTab === 'inventory' && (
              <InventoryTab
                registry={registry}
                searchQuery={searchQuery}
                installing={installing}
                onInstall={handleInstall}
                installedStatus={installedStatus}
                scanning={!scanningDone}
              />
            )}
            {activeTab === 'environment' && (
              <EnvironmentTab
                dotfiles={dotfiles}
                dotfileStatus={dotfileStatus}
                onApply={handleApplyDotfiles}
                isApplying={isApplying}
              />
            )}
            {activeTab === 'settings' && settings && (
              <SettingsTab settings={settings} setSettings={setSettings} onSave={handleSaveSettings} isSaving={isSaving} />
            )}
            {activeTab === 'profile' && settings && (
              <ProfileTab settings={settings} registry={registry} dotfiles={dotfiles} osInfo={osInfo} />
            )}
            {activeTab === 'disk-cleaner' && <DiskCleanerTab />}
            {activeTab === 'memory' && <MemoryTab />}
            {activeTab === 'git-repos' && <GitReposTab />}
          </div>

          <TerminalPanel logs={logs} scrollRef={scrollRef} onCollapseChange={setTerminalCollapsed} />
        </div>
      </main>
    </div>
  );
}
