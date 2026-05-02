import React, { useState } from 'react';
import { type GitRepoDetail } from '@dotfiles/gui-engine';
import { useTranslation } from 'react-i18next';
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from '@/components/ui/accordion';
import { ScrollArea } from '@/components/ui/scroll-area';

export function relativeTime(ts: number): string {
  if (!ts) return '';
  const diff = Math.floor(Date.now() / 1000) - ts;
  if (diff < 60) return `${diff}s ago`;
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
  if (diff < 86400 * 30) return `${Math.floor(diff / 86400)}d ago`;
  return new Date(ts * 1000).toLocaleDateString();
}

function ActionBtn({ label, type, params, danger = false, inProgress, onAction }: {
  label: string;
  type: string;
  params?: Record<string, unknown>;
  danger?: boolean;
  inProgress: string | null;
  onAction: (type: string, params?: Record<string, unknown>) => Promise<void>;
}) {
  return (
    <button
      onClick={() => onAction(type, params)}
      disabled={!!inProgress}
      className={`text-xs px-3 py-1.5 rounded-md border transition-colors disabled:opacity-50 disabled:cursor-not-allowed ${
        danger
          ? 'border-red-400/30 text-red-400 hover:bg-red-500/10'
          : 'border-border text-muted-foreground hover:text-foreground hover:bg-accent'
      }`}
    >
      {inProgress === type ? '…' : label}
    </button>
  );
}

export interface RepoDetailProps {
  detail: GitRepoDetail;
  onAction: (type: string, params?: Record<string, unknown>) => Promise<void>;
  inProgress: string | null;
  actionError: string | null;
  onClearError: () => void;
  confirmDelete: string | null;
  setConfirmDelete: (v: string | null) => void;
}

export function RepoDetail({ detail, onAction, inProgress, actionError, onClearError, confirmDelete, setConfirmDelete }: RepoDetailProps) {
  const { t } = useTranslation('git');
  const { summary, branches, commits, remotes, stashes, tags } = detail;
  const localBranches = branches.filter(b => !b.is_remote);
  const remoteBranches = branches.filter(b => b.is_remote);
  const [newBranchName, setNewBranchName] = useState('');
  const [showNewBranch, setShowNewBranch] = useState(false);
  const [stashMsg, setStashMsg] = useState('');
  const [showStashInput, setShowStashInput] = useState(false);
  const defaultRemote = remotes[0]?.name ?? 'origin';

  return (
    <div className="flex flex-col h-full overflow-hidden">
      {/* Header */}
      <div className="px-5 py-4 border-b border-border bg-card/50 shrink-0">
        <div className="flex items-start justify-between gap-3 mb-3">
          <div className="min-w-0">
            <h2 className="text-sm font-bold text-foreground">{summary.name}</h2>
            <p className="text-[10px] text-muted-foreground font-mono truncate mt-0.5">{summary.path}</p>
          </div>
          <div className="flex items-center gap-2 shrink-0">
            <span className="text-[10px] font-mono text-primary bg-primary/10 px-2 py-1 rounded-md border border-primary/20">{summary.current_branch}</span>
            <span className={`text-[10px] px-2 py-1 rounded-md border ${summary.is_dirty ? 'text-amber-400 bg-amber-500/10 border-amber-400/20' : 'text-emerald-400 bg-emerald-500/10 border-emerald-400/20'}`}>
              {summary.is_dirty ? '● dirty' : '✓ clean'}
            </span>
          </div>
        </div>

        {/* Action bar */}
        <div className="flex items-center gap-2 flex-wrap">
          <ActionBtn label={t('actionFetch')} type="fetch" params={{ remote: defaultRemote }} inProgress={inProgress} onAction={onAction} />
          <ActionBtn label={t('actionPull')} type="pull" params={{ remote: defaultRemote, branch: summary.current_branch }} inProgress={inProgress} onAction={onAction} />
          <ActionBtn label={t('actionPush')} type="push" params={{ remote: defaultRemote, branch: summary.current_branch }} inProgress={inProgress} onAction={onAction} />
          <div className="w-px h-4 bg-border mx-1" />
          <ActionBtn label={t('actionTerminal')} type="open_terminal" inProgress={inProgress} onAction={onAction} />
          <ActionBtn label={t('actionVscode')} type="open_vscode" inProgress={inProgress} onAction={onAction} />
        </div>

        {actionError && (
          <div className="mt-2 px-3 py-2 rounded-md bg-red-500/10 border border-red-400/30 text-xs text-red-400 flex items-start justify-between gap-2">
            <span className="font-mono break-all">{actionError}</span>
            <button onClick={onClearError} className="shrink-0 hover:opacity-70 text-sm leading-none">×</button>
          </div>
        )}
      </div>

      {/* Accordion sections */}
      <ScrollArea className="flex-1">
        <Accordion type="multiple" defaultValue={['branches', 'commits']} className="px-4 py-2">

          {/* Branches */}
          <AccordionItem value="branches">
            <AccordionTrigger className="text-xs font-semibold py-3">
              {t('sectionBranches')}
              <span className="text-muted-foreground font-normal ml-1.5">
                {t('branchesCount', { local: localBranches.length, remote: remoteBranches.length > 0 ? `, ${remoteBranches.length} remote` : '' })}
              </span>
            </AccordionTrigger>
            <AccordionContent className="space-y-1 pb-3">
              {localBranches.map(b => (
                <div key={b.name} className={`flex items-center justify-between gap-2 px-2.5 py-2 rounded-md ${b.is_current ? 'bg-primary/10 border border-primary/20' : 'hover:bg-muted/30'}`}>
                  <div className="flex items-center gap-2 min-w-0">
                    {b.is_current && <span className="text-primary text-[10px] shrink-0">●</span>}
                    <span className="text-xs font-mono text-foreground truncate">{b.name}</span>
                    {b.ahead != null && b.ahead > 0 && <span className="text-[9px] text-emerald-400 shrink-0">↑{b.ahead}</span>}
                    {b.behind != null && b.behind > 0 && <span className="text-[9px] text-blue-400 shrink-0">↓{b.behind}</span>}
                  </div>
                  {!b.is_current && (
                    <div className="flex items-center gap-1 shrink-0">
                      <button
                        onClick={() => onAction('checkout', { branch: b.name })}
                        disabled={!!inProgress}
                        className="text-[10px] px-2 py-0.5 rounded border border-border text-muted-foreground hover:text-foreground hover:bg-accent disabled:opacity-50"
                      >
                        {t('btnCheckout')}
                      </button>
                      <button
                        onClick={() => {
                          if (confirmDelete === b.name) {
                            onAction('delete_branch', { name: b.name, force: false });
                            setConfirmDelete(null);
                          } else {
                            setConfirmDelete(b.name);
                            setTimeout(() => setConfirmDelete(null), 3000);
                          }
                        }}
                        disabled={!!inProgress}
                        className={`text-[10px] px-2 py-0.5 rounded border disabled:opacity-50 transition-colors ${
                          confirmDelete === b.name
                            ? 'border-red-400/50 bg-red-500/10 text-red-400'
                            : 'border-border text-muted-foreground hover:text-red-400'
                        }`}
                      >
                        {confirmDelete === b.name ? t('btnDeleteBranchConfirm') : t('btnDeleteBranch')}
                      </button>
                    </div>
                  )}
                </div>
              ))}

              {remoteBranches.length > 0 && (
                <div className="mt-3 space-y-1">
                  <p className="text-[9px] text-muted-foreground uppercase tracking-widest px-1 mb-1.5">{t('sectionRemoteBranches')}</p>
                  {remoteBranches.map(b => (
                    <div key={b.name} className="flex items-center justify-between gap-2 px-2.5 py-1.5 rounded-md hover:bg-muted/20">
                      <span className="text-[10px] font-mono text-muted-foreground truncate">{b.name}</span>
                      <button
                        onClick={() => onAction('checkout', { branch: b.name.replace(/^origin\//, '') })}
                        disabled={!!inProgress}
                        className="text-[10px] px-2 py-0.5 rounded border border-border text-muted-foreground hover:text-foreground hover:bg-accent disabled:opacity-50"
                      >
                        {t('btnCheckout')}
                      </button>
                    </div>
                  ))}
                </div>
              )}

              <div className="mt-3">
                {showNewBranch ? (
                  <div className="flex gap-1.5">
                    <input
                      value={newBranchName}
                      onChange={e => setNewBranchName(e.target.value)}
                      onKeyDown={e => {
                        if (e.key === 'Enter' && newBranchName.trim()) {
                          onAction('create_branch', { name: newBranchName.trim(), from: 'HEAD' });
                          setNewBranchName('');
                          setShowNewBranch(false);
                        }
                      }}
                      placeholder={t('placeholderBranchName')}
                      className="flex-1 text-xs bg-background border border-border rounded-md px-2 py-1.5 text-foreground placeholder:text-muted-foreground outline-none focus:border-primary"
                      autoFocus
                    />
                    <button
                      onClick={() => { if (newBranchName.trim()) { onAction('create_branch', { name: newBranchName.trim(), from: 'HEAD' }); setNewBranchName(''); setShowNewBranch(false); } }}
                      className="text-xs px-3 py-1.5 rounded-md bg-primary text-primary-foreground"
                    >
                      {t('btnCreate')}
                    </button>
                    <button onClick={() => setShowNewBranch(false)} className="text-xs px-2 py-1.5 rounded-md border border-border text-muted-foreground">{t('btnCancel')}</button>
                  </div>
                ) : (
                  <button onClick={() => setShowNewBranch(true)} className="text-xs text-primary hover:opacity-80">{t('btnNewBranch')}</button>
                )}
              </div>
            </AccordionContent>
          </AccordionItem>

          {/* Commits */}
          <AccordionItem value="commits">
            <AccordionTrigger className="text-xs font-semibold py-3">
              {t('sectionCommits')} <span className="text-muted-foreground font-normal ml-1.5">({commits.length})</span>
            </AccordionTrigger>
            <AccordionContent className="space-y-0.5 pb-3">
              {commits.map(c => (
                <div key={c.full_hash} className="flex items-start gap-3 px-2 py-2 rounded-md hover:bg-muted/20">
                  <span className="text-[10px] font-mono text-primary shrink-0 mt-0.5">{c.short_hash}</span>
                  <div className="min-w-0 flex-1">
                    <p className="text-xs text-foreground truncate">{c.message}</p>
                    <p className="text-[9px] text-muted-foreground mt-0.5">{c.author} · {relativeTime(c.ts)}</p>
                  </div>
                </div>
              ))}
            </AccordionContent>
          </AccordionItem>

          {/* Remotes */}
          <AccordionItem value="remotes">
            <AccordionTrigger className="text-xs font-semibold py-3">
              {t('sectionRemotes')} <span className="text-muted-foreground font-normal ml-1.5">({remotes.length})</span>
            </AccordionTrigger>
            <AccordionContent className="pb-3">
              {remotes.length === 0 ? (
                <p className="text-xs text-muted-foreground px-2">{t('emptyRemotes')}</p>
              ) : (
                <div className="space-y-1">
                  {remotes.map(r => (
                    <div key={r.name} className="flex items-center justify-between gap-3 px-2.5 py-2.5 rounded-md bg-muted/20">
                      <div className="min-w-0">
                        <p className="text-xs font-semibold text-foreground">{r.name}</p>
                        <p className="text-[10px] font-mono text-muted-foreground truncate">{r.url}</p>
                      </div>
                      <button
                        onClick={() => navigator.clipboard.writeText(r.url)}
                        className="text-[10px] text-muted-foreground hover:text-foreground shrink-0 px-2 py-0.5 rounded border border-border hover:bg-accent transition-colors"
                      >
                        Copy
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </AccordionContent>
          </AccordionItem>

          {/* Stashes */}
          <AccordionItem value="stashes">
            <AccordionTrigger className="text-xs font-semibold py-3">
              {t('sectionStashes')} <span className="text-muted-foreground font-normal ml-1.5">({stashes.length})</span>
            </AccordionTrigger>
            <AccordionContent className="pb-3">
              <div className="mb-2">
                {showStashInput ? (
                  <div className="flex gap-1.5">
                    <input
                      value={stashMsg}
                      onChange={e => setStashMsg(e.target.value)}
                      onKeyDown={e => {
                        if (e.key === 'Enter') {
                          onAction('stash_push', { message: stashMsg.trim() || null });
                          setStashMsg('');
                          setShowStashInput(false);
                        }
                      }}
                      placeholder={t('placeholderStashMessage')}
                      className="flex-1 text-xs bg-background border border-border rounded-md px-2 py-1.5 text-foreground placeholder:text-muted-foreground outline-none focus:border-primary"
                      autoFocus
                    />
                    <button
                      onClick={() => { onAction('stash_push', { message: stashMsg.trim() || null }); setStashMsg(''); setShowStashInput(false); }}
                      className="text-xs px-3 py-1.5 rounded-md bg-primary text-primary-foreground"
                    >
                      {t('btnStash')}
                    </button>
                    <button onClick={() => setShowStashInput(false)} className="text-xs px-2 py-1.5 rounded-md border border-border text-muted-foreground">{t('btnCancel')}</button>
                  </div>
                ) : (
                  <button onClick={() => setShowStashInput(true)} className="text-xs text-primary hover:opacity-80">{t('btnStashChanges')}</button>
                )}
              </div>
              {stashes.length === 0 ? (
                <p className="text-xs text-muted-foreground px-2">{t('emptyStashes')}</p>
              ) : (
                <div className="space-y-1">
                  {stashes.map(s => (
                    <div key={s.index} className="flex items-center justify-between gap-2 px-2.5 py-2 rounded-md bg-muted/20">
                      <div className="min-w-0">
                        <p className="text-xs text-foreground truncate">{s.message}</p>
                        {s.ts > 0 && <p className="text-[9px] text-muted-foreground">{relativeTime(s.ts)}</p>}
                      </div>
                      <div className="flex gap-1 shrink-0">
                        <button onClick={() => onAction('stash_pop', { index: s.index })} disabled={!!inProgress} className="text-[10px] px-2 py-0.5 rounded border border-border text-muted-foreground hover:text-foreground hover:bg-accent disabled:opacity-50">{t('btnStashPop')}</button>
                        <button onClick={() => onAction('stash_drop', { index: s.index })} disabled={!!inProgress} className="text-[10px] px-2 py-0.5 rounded border border-red-400/30 text-red-400 hover:bg-red-500/10 disabled:opacity-50">{t('btnStashDrop')}</button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </AccordionContent>
          </AccordionItem>

          {/* Git tags (only shown when present) */}
          {tags.length > 0 && (
            <AccordionItem value="tags">
              <AccordionTrigger className="text-xs font-semibold py-3">
                {t('sectionTags')} <span className="text-muted-foreground font-normal ml-1.5">({tags.length})</span>
              </AccordionTrigger>
              <AccordionContent className="pb-3">
                <div className="flex flex-wrap gap-1.5">
                  {tags.map(tag => (
                    <span key={tag} className="text-[10px] font-mono px-2 py-0.5 rounded-md bg-muted/40 border border-border text-muted-foreground">
                      {tag}
                    </span>
                  ))}
                </div>
              </AccordionContent>
            </AccordionItem>
          )}

        </Accordion>
      </ScrollArea>
    </div>
  );
}
