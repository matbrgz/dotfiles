import { useState, useEffect, useRef } from 'react';
import { guiCommands, type LogEntry } from '@dotfiles/gui-engine';
import { type ProgramManifest, type UserSettings, type DotfileManifest } from '@dotfiles/schema';
import { Sidebar } from './components/Sidebar';
import { Header } from './components/Header';
import { TerminalPanel } from './components/TerminalPanel';
import { InventoryTab } from './components/InventoryTab';
import { EnvironmentTab } from './components/EnvironmentTab';
import { SettingsTab } from './components/SettingsTab';
import { ProfileTab } from './components/ProfileTab';
import { 
  Package, 
  Settings, 
  User, 
  FileCode
} from 'lucide-react';

export default function App() {
  const [registry, setRegistry] = useState<Record<string, ProgramManifest>>({});
  const [dotfiles, setDotfiles] = useState<Record<string, DotfileManifest>>({});
  const [settings, setSettings] = useState<UserSettings | null>(null);
  const [loading, setLoading] = useState(true);
  const [osInfo, setOsInfo] = useState({ os: 'unknown', platform: '' });
  const [installing, setInstalling] = useState<Record<string, boolean>>({});
  const [installedStatus, setInstalledStatus] = useState<Record<string, boolean>>({});
  const [logs, setLogs] = useState<string[]>(["SYSTEM_INITIALIZED", "READY_FOR_INPUT"]);
  const [activeTab, setActiveTab] = useState('inventory');
  const [searchQuery, setSearchQuery] = useState('');
  const [isApplying, setIsApplying] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);

  const TABS = [
    { id: 'inventory', label: 'Inv', icon: Package },
    { id: 'environment', label: 'Env', icon: FileCode },
    { id: 'settings', label: 'Cfg', icon: Settings },
    { id: 'profile', label: 'Usr', icon: User },
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
        addLog(`CORE_READY: ${Object.keys(data).length} MODULES DETECTED`);
        
        // Initial check for all programs
        checkAllInstallations(data);
      } catch (err) {
        addLog(`ERROR: FAILED_TO_INITIALIZE_CORE: ${err}`, true);
      } finally {
        setLoading(false);
      }
    }
    init();
  }, []);

  const checkAllInstallations = async (data: Record<string, ProgramManifest>) => {
    addLog("SCANNING_LOCAL_SYSTEM_FOR_INSTALLED_MODULES...");
    for (const id of Object.keys(data)) {
      const isInstalled = await guiCommands.checkInstallation(id);
      setInstalledStatus(prev => ({ ...prev, [id]: isInstalled }));
    }
    addLog("SYSTEM_SCAN_COMPLETE");
  };

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [logs]);

  const addLog = (msg: string, isError = false) => {
    const timestamp = new Date().toLocaleTimeString('en-GB', { hour12: false });
    const prefix = isError ? "!! ERROR: " : "";
    setLogs(prev => [...prev, `[${timestamp}] ${prefix}${msg}`]);
  };

  const handleInstall = async (id: string) => {
    setInstalling(prev => ({ ...prev, [id]: true }));
    addLog(`INITIATING_INSTALL: MODULE_${id.toUpperCase()}`);
    try {
      await guiCommands.runCommand('install', id, (log: LogEntry) => {
        addLog(log.message, log.is_error);
      });
      addLog(`SUCCESS: ${id.toUpperCase()}_DEPLOY_COMPLETE`);
      // Update status after install
      const isInstalled = await guiCommands.checkInstallation(id);
      setInstalledStatus(prev => ({ ...prev, [id]: isInstalled }));
    } catch (err) {
      addLog(`CRITICAL_FAILURE: ${id.toUpperCase()}_ABORTED: ${err}`, true);
    } finally {
      setInstalling(prev => ({ ...prev, [id]: false }));
    }
  };

  const handleApplyDotfiles = async () => {
    if (isApplying) return;
    setIsApplying(true);
    addLog("INITIATING_DOTFILES_SYNC...");
    try {
      await guiCommands.runCommand('apply', undefined, (log: LogEntry) => {
        addLog(log.message, log.is_error);
      });
      addLog("SUCCESS: DOTFILES_SYNC_COMPLETE");
    } catch (err) {
      addLog(`ERROR: DOTFILES_SYNC_FAILED: ${err}`, true);
    } finally {
      setIsApplying(false);
    }
  };

  const handleSaveSettings = async () => {
    if (!settings || isSaving) return;
    setIsSaving(true);
    addLog("PERSISTING_USER_DATA...");
    try {
      await guiCommands.saveUserSettings(settings);
      addLog("SUCCESS: CONFIGURATIONS_SAVED");
    } catch (err) {
      addLog(`ERROR: FAILED_TO_SAVE_SETTINGS: ${err}`, true);
    } finally {
      setIsSaving(false);
    }
  };

  if (loading) return (
    <div className="flex h-screen items-center justify-center bg-blueprint-bg font-mono">
      <div className="text-cyan-500 animate-pulse text-sm tracking-[0.5em] uppercase text-center text-white">Establishing Link...</div>
    </div>
  );

  return (
    <div className="flex h-screen bg-blueprint-bg text-zinc-300 font-mono select-none overflow-hidden">
      <Sidebar activeTab={activeTab} onTabChange={setActiveTab} tabs={TABS} />
      
      <main className="flex-1 flex flex-col relative overflow-hidden">
        <Header 
          osInfo={osInfo} 
          isApplying={isApplying} 
          onApplyDotfiles={handleApplyDotfiles}
          searchQuery={searchQuery}
          onSearchChange={setSearchQuery}
          activeTab={activeTab}
        />

        {activeTab === 'inventory' && (
          <InventoryTab 
            registry={registry} 
            searchQuery={searchQuery} 
            installing={installing} 
            onInstall={handleInstall} 
            installedStatus={installedStatus}
          />
        )}

        {activeTab === 'environment' && (
          <EnvironmentTab dotfiles={dotfiles} onApply={handleApplyDotfiles} />
        )}

        {activeTab === 'settings' && settings && (
          <SettingsTab settings={settings} setSettings={setSettings} onSave={handleSaveSettings} isSaving={isSaving} />
        )}

        {activeTab === 'profile' && settings && (
          <ProfileTab settings={settings} registry={registry} dotfiles={dotfiles} osInfo={osInfo} />
        )}

        <TerminalPanel logs={logs} scrollRef={scrollRef} />
      </main>
    </div>
  );
}
