#!/usr/bin/env zsh
# ~/.zsh_cleanup.zsh — Limpeza e atualizações do terminal
# Sourced pelo ~/.zshrc

# ─────────────────────────────────────────────
# HELPERS DE PRINT
# ─────────────────────────────────────────────
_divider() { print -P "%F{242}────────────────────────────────────────────%f"; }
_title()   { print -P "\n%F{yellow}$1%f\n"; }
_ok()      { print -P "  %F{green}✓%f $1"; }
_skip()    { print -P "  %F{242}· $1%f"; }
_warn()    { print -P "  %F{red}⚠%f  $1"; }
_ask()     { print -Pn "  %F{white}$1%f (s/N) "; read -r _ans; [[ "$_ans" =~ ^[sS]$ ]]; }

# ─────────────────────────────────────────────
# HELPERS DE TAMANHO (KB, via awk — sem aritmética shell)
# ─────────────────────────────────────────────

# Soma KB de uma lista de paths (stdin, um por linha)
_du_sum_kb() {
  local paths=()
  while IFS= read -r p; do
    [[ -n "$p" && -e "$p" ]] && paths+=("$p")
  done
  (( ${#paths[@]} == 0 )) && { echo 0; return; }
  du -sk "${paths[@]}" 2>/dev/null | awk '{t+=$1} END{printf "%d", (t>0?t:0)}'
}

# KB de um único path
_du_kb1() {
  [[ -d "$1" || -f "$1" ]] || { echo 0; return; }
  du -sk "$1" 2>/dev/null \
    | awk 'NR==1{printf "%d", ($1>0?$1:0); exit} END{if(NR==0) print 0}'
}

# Formata KB → legível (GB/MB/KB) — aritmética no awk
_fmt_kb() {
  awk -v kb="$1" 'BEGIN{
    if      (kb >= 1048576) printf "%.1f GB", kb/1048576
    else if (kb >= 1024)    printf "%.1f MB", kb/1024
    else                    printf "%d KB",   kb
  }'
}

# ─────────────────────────────────────────────
# ATUALIZAÇÕES
# ─────────────────────────────────────────────
_startup_updates() {
  _divider
  _title "ATUALIZAÇÕES"

  # ── Homebrew ──
  if _ask "🍺 Atualizar o Homebrew?"; then
    print -P "\n  %F{242}Verificando fórmulas desatualizadas...%f"
    local outdated
    outdated=$(brew outdated 2>/dev/null)
    if [[ -n "$outdated" ]]; then
      print -P "  %F{yellow}Desatualizados:%f"
      echo "$outdated" | sed 's/^/    /'
    else
      print -P "  %F{green}Tudo atualizado.%f"
    fi
    echo ""

    brew update
    brew upgrade
    brew upgrade --cask 2>/dev/null

    if _ask "  🧹 Rodar brew cleanup --prune=all?"; then
      brew cleanup --prune=all
    fi

    if _ask "  🍃 Rodar brew autoremove? (remove dependências não usadas)"; then
      brew autoremove
    fi

    if _ask "  🩺 Rodar brew doctor?"; then
      brew doctor
    fi

    _ok "Homebrew atualizado!"
  else
    _skip "Homebrew ignorado"
  fi

  # ── macOS ──
  if _ask "🍎 Verificar atualizações do macOS?"; then
    softwareupdate --list
    if _ask "   Instalar todas as atualizações?"; then
      sudo softwareupdate --install --all
      _ok "macOS atualizado!"
    fi
  else
    _skip "macOS ignorado"
  fi

  _divider
  echo ""
}

# ─────────────────────────────────────────────
# LIMPEZA
# ─────────────────────────────────────────────
_startup_cleanup() {
  _divider
  _title "🔍 Escaneando caches e lixo..."

  # ── Coleta de paths ──
  local nm_dirs build_dirs next_dirs ds_files venv_dirs pip_cache_dir gocache

  nm_dirs=$(find ~/dev -name "node_modules" -type d -prune 2>/dev/null)

  # build genérico (sem .next — separado para destacar)
  build_dirs=$(find ~/dev -maxdepth 5 \
    \( -name "dist" -o -name "build" -o -name ".cache" \
       -o -name ".turbo" -o -name ".svelte-kit" -o -name ".nuxt" \
       -o -name "out" -o -name ".output" \) \
    -type d -prune 2>/dev/null)

  # .next separado
  next_dirs=$(find ~/dev -maxdepth 5 -name ".next" -type d -prune 2>/dev/null)

  ds_files=$(find ~/dev -name ".DS_Store" 2>/dev/null)

  venv_dirs=$(find ~/dev -maxdepth 5 \
    \( -name "venv" -o -name ".venv" -o -name "env" \) \
    -type d -prune 2>/dev/null \
    | while IFS= read -r d; do [[ -f "$d/bin/activate" ]] && echo "$d"; done)

  pip_cache_dir=$(python3 -m pip cache dir 2>/dev/null || echo "$HOME/Library/Caches/pip")
  gocache=$(go env GOCACHE 2>/dev/null)

  # Brew cache
  local brew_cache_dir
  brew_cache_dir=$(brew --cache 2>/dev/null || echo "$HOME/Library/Caches/Homebrew")

  # ── Tamanhos (todos em KB) ──
  local nm_size=0 build_size=0 next_size=0 ds_size=0
  local npm_size=0 yarn_size=0 pnpm_size=0
  local gradle_size=0 go_size=0 maven_size=0
  local venv_size=0 pip_size=0
  local cargo_size=0 ruby_size=0 bundler_size=0
  local composer_size=0 hex_size=0
  local cocoapods_size=0 spm_size=0
  local brew_cache_size=0 brew_logs_size=0
  local docker_size=0 trash_size=0 libcache_size=0
  local codex_log_size=0 codex_sessions_size=0 codex_app_cache_size=0
  local downloads_size=0 zsh_sessions_size=0

  [[ -n "$nm_dirs" ]]    && nm_size=$(echo    "$nm_dirs"    | _du_sum_kb)
  [[ -n "$build_dirs" ]] && build_size=$(echo "$build_dirs" | _du_sum_kb)
  [[ -n "$next_dirs" ]]  && next_size=$(echo  "$next_dirs"  | _du_sum_kb)
  [[ -n "$ds_files" ]]   && ds_size=$(echo    "$ds_files"   | _du_sum_kb)
  [[ -n "$venv_dirs" ]]  && venv_size=$(echo  "$venv_dirs"  | _du_sum_kb)

  [[ -d "$HOME/.npm/_cacache" ]]                    && npm_size=$(_du_kb1 "$HOME/.npm/_cacache")
  [[ -d "$HOME/Library/Caches/Yarn/v6" ]]           && yarn_size=$(_du_kb1 "$HOME/Library/Caches/Yarn/v6")
  [[ -d "$HOME/Library/pnpm/store" ]]               && pnpm_size=$(_du_kb1 "$HOME/Library/pnpm/store")
  [[ -d "$HOME/.gradle/caches" ]]                   && gradle_size=$(_du_kb1 "$HOME/.gradle/caches")
  [[ -d "$HOME/.m2/repository" ]]                   && maven_size=$(_du_kb1 "$HOME/.m2/repository")
  [[ -n "$gocache" && -d "$gocache" ]]              && go_size=$(_du_kb1 "$gocache")
  [[ -n "$pip_cache_dir" && -d "$pip_cache_dir" ]]  && pip_size=$(_du_kb1 "$pip_cache_dir")

  cargo_size=$(du -sk \
    "$HOME/.cargo/registry" "$HOME/.cargo/git" 2>/dev/null \
    | awk '{t+=$1} END{printf "%d", (t>0?t:0)}')

  [[ -d "$HOME/.gem" ]]                             && ruby_size=$(_du_kb1 "$HOME/.gem")
  [[ -d "$HOME/.bundle" ]]                          && bundler_size=$(_du_kb1 "$HOME/.bundle")
  [[ -d "$HOME/.composer/cache" ]]                  && composer_size=$(_du_kb1 "$HOME/.composer/cache")
  [[ -d "$HOME/.hex" ]]                             && hex_size=$(_du_kb1 "$HOME/.hex")
  [[ -d "$HOME/Library/Caches/CocoaPods" ]]         && cocoapods_size=$(_du_kb1 "$HOME/Library/Caches/CocoaPods")
  [[ -d "$HOME/Library/Caches/org.swift.swiftpm" ]] && spm_size=$(_du_kb1 "$HOME/Library/Caches/org.swift.swiftpm")

  # Brew
  [[ -d "$brew_cache_dir" ]] && brew_cache_size=$(_du_kb1 "$brew_cache_dir")
  [[ -d "$HOME/Library/Logs/Homebrew" ]] && brew_logs_size=$(_du_kb1 "$HOME/Library/Logs/Homebrew")

  # Xcode / Simuladores iOS
  local xcode_derived_size=0 xcode_archives_size=0 ios_sim_size=0
  [[ -d "$HOME/Library/Developer/Xcode/DerivedData" ]]  && xcode_derived_size=$(_du_kb1 "$HOME/Library/Developer/Xcode/DerivedData")
  [[ -d "$HOME/Library/Developer/Xcode/Archives" ]]     && xcode_archives_size=$(_du_kb1 "$HOME/Library/Developer/Xcode/Archives")
  [[ -d "$HOME/Library/Developer/CoreSimulator/Devices" ]] && ios_sim_size=$(_du_kb1 "$HOME/Library/Developer/CoreSimulator/Devices")

  # Docker
  if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
    docker_size=$(docker system df --format '{{.Reclaimable}}' 2>/dev/null \
      | grep -oE '[0-9]+\.?[0-9]*(GB|MB|kB|B)' \
      | awk '{
          v=$0+0
          if($0~/GB$/) t+=v*1048576
          else if($0~/MB$/) t+=v*1024
          else if($0~/kB$/) t+=v
          else t+=v/1024
        } END{printf "%d", (t>0?t:0)}')
    docker_size=${docker_size:-0}
  fi

  [[ -d "$HOME/.Trash" ]]         && trash_size=$(_du_kb1 "$HOME/.Trash")
  [[ -d "$HOME/Library/Caches" ]] && libcache_size=$(_du_kb1 "$HOME/Library/Caches")

  # IA / MCP / Ferramentas dev
  local ai_gemini_size=0 ai_claude_size=0 ai_claude_hist_size=0
  local fly_logs_size=0 npm_logs_size=0

  # Codex
  [[ -d "$HOME/.codex/log" ]]              && codex_log_size=$(_du_kb1 "$HOME/.codex/log")
  [[ -d "$HOME/.codex/sessions" ]]         && codex_sessions_size=$(_du_kb1 "$HOME/.codex/sessions")
  codex_app_cache_size=$(du -sk \
      "$HOME/Library/Application Support/Codex/Cache" \
      "$HOME/Library/Application Support/Codex/Code Cache" \
      "$HOME/Library/Application Support/Codex/GPUCache" \
      "$HOME/Library/Application Support/Codex/DawnGraphiteCache" \
      "$HOME/Library/Application Support/Codex/DawnWebGPUCache" \
      2>/dev/null | awk '{t+=$1} END{printf "%d",(t>0?t:0)}')

  # Sistema / outros
  [[ -d "$HOME/Downloads" ]]               && downloads_size=$(_du_kb1 "$HOME/Downloads")
  [[ -d "$HOME/.zsh_sessions" ]]           && zsh_sessions_size=$(_du_kb1 "$HOME/.zsh_sessions")

  [[ -d "$HOME/.gemini/tmp" ]]             && ai_gemini_size=$(_du_kb1 "$HOME/.gemini/tmp")
  # Claude Code: cache + paste-cache + shell-snapshots (sessions e projects são dados do user)
  ai_claude_size=$(du -sk \
      "$HOME/.claude/cache" \
      "$HOME/.claude/paste-cache" \
      "$HOME/.claude/shell-snapshots" \
      "$HOME/.claude/telemetry" \
      2>/dev/null | awk '{t+=$1} END{printf "%d",(t>0?t:0)}')
  [[ -d "$HOME/.claude/file-history" ]]    && ai_claude_hist_size=$(_du_kb1 "$HOME/.claude/file-history")
  fly_logs_size=$(du -sk \
      "$HOME/.fly/agent-logs" \
      "$HOME/.fly/logs" \
      2>/dev/null | awk '{t+=$1} END{printf "%d",(t>0?t:0)}')
  [[ -d "$HOME/.npm/_logs" ]]              && npm_logs_size=$(_du_kb1 "$HOME/.npm/_logs")

  # Total via awk (sem overflow de shell)
  local total
  total=$(awk \
    -v a="$nm_size"    -v b="$build_size"    -v b2="$next_size"   -v c="$ds_size" \
    -v d="$npm_size"   -v e="$yarn_size"     -v f="$pnpm_size" \
    -v g="$gradle_size" -v h="$go_size"      -v i="$maven_size" \
    -v j="$venv_size"  -v k="$pip_size"      -v l="$cargo_size" \
    -v m="$ruby_size"  -v n="$bundler_size"  -v o="$composer_size" \
    -v p="$hex_size"   -v q="$cocoapods_size" -v r="$spm_size" \
    -v s="$brew_cache_size" -v s2="$brew_logs_size" \
    -v t2="$docker_size" -v u="$trash_size"  -v v="$libcache_size" \
    -v w="$xcode_derived_size" -v x="$xcode_archives_size" -v y="$ios_sim_size" \
    -v z1="$ai_gemini_size" -v z2="$ai_claude_size" -v z3="$ai_claude_hist_size" \
    -v z4="$fly_logs_size"   -v z5="$npm_logs_size" \
    -v z6="$codex_log_size" -v z7="$codex_sessions_size" -v z8="$codex_app_cache_size" \
    -v z9="$downloads_size" -v z10="$zsh_sessions_size" \
    'BEGIN{printf "%d", a+b+b2+c+d+e+f+g+h+i+j+k+l+m+n+o+p+q+r+s+s2+t2+u+v+w+x+y+z1+z2+z3+z4+z5+z6+z7+z8+z9+z10}')

  # ── Tabela ──
  echo ""
  print -P "  %F{white}Cache / Lixo encontrado:%f\n"
  printf "  %b%-34s  %s%b\n" "\033[0;90m" "Item" "Tamanho" "\033[0m"
  print -P "  %F{242}  ─────────────────────────────────────────%f"

  local _idx=0
  typeset -a _clean_keys _clean_sizes
  _clean_keys=(); _clean_sizes=()

  _row() {
    local key="$1" icon="$2" label="$3" size=$4
    (( size > 0 )) || return
    _idx=$(( _idx + 1 ))
    _clean_keys+=("$key")
    _clean_sizes+=($size)
    printf "  \033[0;37m[%2d]\033[0m  %-32s  %s\n" \
      $_idx "$icon $label" "$(_fmt_kb $size)"
  }

  # Projetos
  _row "nm"        "📦" "node_modules (~/dev)"         $nm_size
  _row "build"     "🗂 " "dist / build / out / etc"     $build_size
  _row "next"      "▲ " ".next (~/dev)"                 $next_size
  _row "ds"        "🫧 " ".DS_Store (~/dev)"             $ds_size
  # Node
  _row "npm"       "📦" "npm cache"                    $npm_size
  _row "yarn"      "🧶" "Yarn cache"                   $yarn_size
  _row "pnpm"      "⚡" "pnpm store"                   $pnpm_size
  # JVM
  _row "gradle"    "🐘" "Gradle cache"                 $gradle_size
  _row "maven"     "☕" "Maven cache"                  $maven_size
  # Go
  _row "go"        "🐹" "Go cache"                     $go_size
  # Python
  _row "venv"      "🐍" "Python venv (~/dev)"          $venv_size
  _row "pip"       "🐍" "pip cache"                    $pip_size
  # Rust
  _row "cargo"     "🦀" "Rust cargo cache"             $cargo_size
  # Ruby
  _row "ruby"      "💎" "Ruby gems (~/.gem)"           $ruby_size
  _row "bundler"   "💎" "Bundler cache"                $bundler_size
  # PHP / Elixir / Apple
  _row "composer"  "🐘" "Composer cache"               $composer_size
  _row "hex"       "💧" "Elixir Hex cache"             $hex_size
  _row "pods"      "🍫" "CocoaPods cache"              $cocoapods_size
  _row "spm"       "🍎" "Swift PM cache"               $spm_size
  # Brew
  _row "brew_cache"  "🍺" "Homebrew download cache"       $brew_cache_size
  _row "brew_logs"   "🍺" "Homebrew logs"                 $brew_logs_size
  # Xcode / iOS
  _row "xcode_der"   "🔨" "Xcode DerivedData"             $xcode_derived_size
  _row "xcode_arc"   "🔨" "Xcode Archives"                $xcode_archives_size
  _row "ios_sim"     "📱" "iOS Simuladores (unavailable)" $ios_sim_size
  # Codex
  _row "codex_log"     "🤖" "Codex logs (~/.codex/log)"          $codex_log_size
  _row "codex_sess"    "🤖" "Codex sessions (~/.codex/sessions)"  $codex_sessions_size
  _row "codex_app"     "🤖" "Codex app cache (Electron)"         $codex_app_cache_size
  # IA / MCP / Logs
  _row "ai_gemini"     "🤖" "Gemini CLI temp (~/.gemini/tmp)"    $ai_gemini_size
  _row "ai_claude"     "🤖" "Claude Code cache/snapshots"        $ai_claude_size
  _row "ai_claude_hist" "🤖" "Claude Code file-history"          $ai_claude_hist_size
  _row "fly_logs"      "🪰" "Fly.io logs"                        $fly_logs_size
  _row "npm_logs"      "📋" "npm logs"                           $npm_logs_size
  # Docker / Sistema
  _row "docker"       "🐳" "Docker (reclaimable)"         $docker_size
  _row "downloads"    "📥" "~/Downloads"                  $downloads_size
  _row "zsh_sessions" "🐚" "~/.zsh_sessions"              $zsh_sessions_size
  _row "trash"        "🗑 " "Lixeira do Mac"               $trash_size
  _row "libcache"     "📂" "~/Library/Caches"             $libcache_size

  echo ""
  print -P "  %F{yellow}Total estimado: $(_fmt_kb $total)%f\n"

  if (( _idx == 0 )); then
    print -P "  %F{green}✓ Nada para limpar!%f"
    _divider; echo ""; return
  fi

  # ── Escolha ──
  print -P "  %F{white}O que limpar?%f"
  print -P "  %F{white}[t]%f       Tudo"
  print -P "  %F{white}[1,3,5]%f   Números separados por vírgula"
  print -P "  %F{242}[Enter]    Cancelar%f"
  print -Pn "\n  %F{white}Opção:%f "
  read -r _choice
  echo ""

  [[ -z "$_choice" ]] && { _skip "Limpeza cancelada"; _divider; echo ""; return; }

  local _selected=()
  if [[ "$_choice" =~ ^[tT]$ ]]; then
    for (( i=1; i<=_idx; i++ )); do _selected+=($i); done
  else
    IFS=',' read -rA _selected <<< "$_choice"
  fi

  # ── Execução ──
  _do_clean() {
    case "$1" in
      nm)
        echo "$nm_dirs" | while IFS= read -r d; do [[ -n "$d" ]] && rm -rf "$d"; done
        _ok "node_modules removidos" ;;
      build)
        echo "$build_dirs" | while IFS= read -r d; do [[ -n "$d" ]] && rm -rf "$d"; done
        _ok "Pastas de build removidas" ;;
      next)
        echo "$next_dirs" | while IFS= read -r d; do [[ -n "$d" ]] && rm -rf "$d"; done
        _ok ".next removidos" ;;
      ds)
        find ~/dev -name ".DS_Store" -delete 2>/dev/null
        _ok ".DS_Store removidos" ;;
      npm)
        npm cache clean --force 2>/dev/null; _ok "npm cache limpo" ;;
      yarn)
        yarn cache clean 2>/dev/null; _ok "Yarn cache limpo" ;;
      pnpm)
        pnpm store prune 2>/dev/null; _ok "pnpm store limpo" ;;
      gradle)
        rm -rf "$HOME/.gradle/caches"; _ok "Gradle cache limpo" ;;
      maven)
        rm -rf "$HOME/.m2/repository"; _ok "Maven cache limpo" ;;
      go)
        go clean -cache -testcache -modcache 2>/dev/null; _ok "Go cache limpo" ;;
      venv)
        echo "$venv_dirs" | while IFS= read -r d; do [[ -n "$d" ]] && rm -rf "$d"; done
        _ok "Python venvs removidos" ;;
      pip)
        python3 -m pip cache purge 2>/dev/null; _ok "pip cache limpo" ;;
      cargo)
        rm -rf "$HOME/.cargo/registry/cache" "$HOME/.cargo/git/db" 2>/dev/null
        _ok "Rust cargo cache limpo" ;;
      ruby)
        gem cleanup 2>/dev/null; _ok "Ruby gems limpos" ;;
      bundler)
        rm -rf "$HOME/.bundle/cache" 2>/dev/null; _ok "Bundler cache limpo" ;;
      composer)
        composer clearcache 2>/dev/null || rm -rf "$HOME/.composer/cache" 2>/dev/null
        _ok "Composer cache limpo" ;;
      hex)
        rm -rf "$HOME/.hex/packages" 2>/dev/null; _ok "Elixir Hex cache limpo" ;;
      pods)
        rm -rf "$HOME/Library/Caches/CocoaPods"; _ok "CocoaPods cache limpo" ;;
      spm)
        rm -rf "$HOME/Library/Caches/org.swift.swiftpm"; _ok "Swift PM cache limpo" ;;
      brew_cache)
        brew cleanup --prune=all 2>/dev/null; _ok "Homebrew download cache limpo" ;;
      brew_logs)
        rm -rf "$HOME/Library/Logs/Homebrew/"* 2>/dev/null; _ok "Homebrew logs limpos" ;;
      xcode_der)
        rm -rf "$HOME/Library/Developer/Xcode/DerivedData/"* 2>/dev/null
        _ok "Xcode DerivedData limpo" ;;
      xcode_arc)
        rm -rf "$HOME/Library/Developer/Xcode/Archives/"* 2>/dev/null
        _ok "Xcode Archives limpos" ;;
      ios_sim)
        xcrun simctl delete unavailable 2>/dev/null
        _ok "iOS Simulators indisponíveis removidos" ;;
      ai_gemini)
        rm -rf "$HOME/.gemini/tmp/"* 2>/dev/null
        _ok "Gemini CLI temp limpo" ;;
      ai_claude)
        rm -rf "$HOME/.claude/cache/"* \
               "$HOME/.claude/paste-cache/"* \
               "$HOME/.claude/shell-snapshots/"* \
               "$HOME/.claude/telemetry/"* 2>/dev/null
        _ok "Claude Code cache/snapshots limpos" ;;
      ai_claude_hist)
        rm -rf "$HOME/.claude/file-history/"* 2>/dev/null
        _ok "Claude Code file-history limpo" ;;
      fly_logs)
        rm -rf "$HOME/.fly/agent-logs/"* "$HOME/.fly/logs/"* 2>/dev/null
        _ok "Fly.io logs limpos" ;;
      npm_logs)
        rm -rf "$HOME/.npm/_logs/"* 2>/dev/null
        _ok "npm logs limpos" ;;
      codex_log)
        rm -rf "$HOME/.codex/log/"* 2>/dev/null
        _ok "Codex logs limpos" ;;
      codex_sess)
        rm -rf "$HOME/.codex/sessions/"* 2>/dev/null
        _ok "Codex sessions limpas" ;;
      codex_app)
        rm -rf \
          "$HOME/Library/Application Support/Codex/Cache/"* \
          "$HOME/Library/Application Support/Codex/Code Cache/"* \
          "$HOME/Library/Application Support/Codex/GPUCache/"* \
          "$HOME/Library/Application Support/Codex/DawnGraphiteCache/"* \
          "$HOME/Library/Application Support/Codex/DawnWebGPUCache/"* \
          2>/dev/null
        _ok "Codex app cache limpo" ;;
      downloads)
        _warn "Isso vai apagar TODO o conteúdo de ~/Downloads!"
        print -Pn "  %F{red}Confirmar?%f (sim/N) "; read -r _confirm
        if [[ "$_confirm" == "sim" ]]; then
          rm -rf "$HOME/Downloads/"* 2>/dev/null
          _ok "~/Downloads limpo"
        else
          _skip "Downloads mantidos"
        fi ;;
      zsh_sessions)
        rm -rf "$HOME/.zsh_sessions/"* 2>/dev/null
        _ok "zsh sessions limpas" ;;
      docker)
        _warn "Containers e volumes ativos não serão removidos"
        docker image prune -f 2>/dev/null
        docker builder prune -f 2>/dev/null
        docker network prune -f 2>/dev/null
        _ok "Docker limpo" ;;
      trash)
        rm -rf "$HOME/.Trash/"* 2>/dev/null; _ok "Lixeira esvaziada" ;;
      libcache)
        rm -rf "$HOME/Library/Caches/"* 2>/dev/null; _ok "~/Library/Caches limpo" ;;
    esac
  }

  for n in "${_selected[@]}"; do
    n="${n// /}"
    if (( n >= 1 && n <= _idx )); then
      _do_clean "${_clean_keys[$n]}"
    fi
  done

  _divider
  echo ""
}

# ─────────────────────────────────────────────
# MENU INICIAL
# ─────────────────────────────────────────────
startup_menu() {
  _divider
  print -P "\n  %F{yellow}O que deseja fazer agora?%f"
  print -P "  %F{white}[1]%f  Atualizações + Limpeza"
  print -P "  %F{white}[2]%f  Só Atualizações"
  print -P "  %F{white}[3]%f  Só Limpeza"
  print -P "  %F{white}[0]%f  Reiniciar o Mac"
  print -P "  %F{white}[-1]%f Desligar o Mac"
  print -P "  %F{242}[Enter] Usar o terminal%f"
  print -Pn "\n  %F{white}Opção:%f "
  read -r _startup_choice
  echo ""
  case "$_startup_choice" in
    1) _startup_updates; _startup_cleanup ;;
    2) _startup_updates ;;
    3) _startup_cleanup ;;
    0) _warn "Reiniciando o Mac..."; sudo shutdown -r now ;;
    -1) _warn "Desligando o Mac..."; sudo shutdown -h now ;;
    *) _divider; echo "" ;;
  esac
}
