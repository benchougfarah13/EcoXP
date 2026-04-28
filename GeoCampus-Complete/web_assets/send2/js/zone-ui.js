/**
 * Smart Zone System — UI dynamique (même barre, panneau quêtes, modal activité).
 * Flux mini-jeu : Start → Play → Result → Reward
 */
const ZoneUI = (() => {
  let _currentContent = null;
  let _playState = null;

  function init() {
    document.getElementById('btn-zone-activity-close')?.addEventListener('click', closeActivityModal);
    document.getElementById('btn-zone-phase-start')?.addEventListener('click', () => _goPhase('play'));
    document.getElementById('zone-activity-modal')?.addEventListener('click', (e) => {
      if (e.target.id === 'zone-activity-modal') closeActivityModal();
    });
  }

  function setZoneIndicator(zone) {
    const pill = document.getElementById('zone-indicator');
    const label = document.getElementById('zone-indicator-label');
    if (!pill || !label) return;
    if (!zone) {
      pill.classList.add('hidden');
      label.textContent = '';
      return;
    }
    pill.classList.remove('hidden');
    label.textContent = zone.name;
    pill.dataset.zoneType = zone.type || '';
  }

  function showZoneEntryBanner(zone) {
    const msg = zone.enterMessage || `Entrée : ${zone.name}`;
    UIController.showToast('success', msg, 'Nouvelles activités disponibles dans l’onglet Quêtes.');
  }

  function closeActivityModal() {
    document.getElementById('zone-activity-modal')?.classList.add('hidden');
    _currentContent = null;
    _playState = null;
  }

  function openActivity(content) {
    if (GameState.isZoneContentCompleted(content.id)) {
      UIController.showToast('info', 'Déjà complété', 'Cette activité a déjà été récompensée.');
      return;
    }
    _currentContent = content;
    const modal = document.getElementById('zone-activity-modal');
    const title = document.getElementById('zone-activity-title');
    const typeEl = document.getElementById('zone-activity-type');
    if (!modal || !title) return;

    title.textContent = content.title;
    const typeLabels = { mission: 'Mission', quiz: 'Quiz', game: 'Mini-jeu' };
    if (typeEl) typeEl.textContent = typeLabels[content.content_type] || content.content_type;

    _goPhase('start');
    modal.classList.remove('hidden');
  }

  function _goPhase(phase) {
    const startEl = document.getElementById('zone-phase-start');
    const playEl = document.getElementById('zone-phase-play');
    const resultEl = document.getElementById('zone-phase-result');
    const rewardEl = document.getElementById('zone-phase-reward');
    [startEl, playEl, resultEl, rewardEl].forEach(el => el?.classList.add('hidden'));

    if (phase === 'start') {
      startEl?.classList.remove('hidden');
      const desc = document.getElementById('zone-activity-desc');
      if (desc) desc.textContent = _currentContent.description || '';
    } else if (phase === 'play') {
      playEl?.classList.remove('hidden');
      _renderPlayArea();
    } else if (phase === 'result') {
      resultEl?.classList.remove('hidden');
    } else if (phase === 'reward') {
      rewardEl?.classList.remove('hidden');
    }
  }

  function _renderPlayArea() {
    const host = document.getElementById('zone-play-host');
    if (!host || !_currentContent) return;
    host.innerHTML = '';
    const p = _currentContent.play_payload || { kind: 'mission_ack' };
    _playState = { success: false };

    if (p.kind === 'mission_ack') {
      host.innerHTML = `<p class="zone-play-text">${_escapeHtml(_currentContent.description)}</p>
        <button type="button" class="btn-primary zone-play-action" id="zone-mission-ok">Valider la mission</button>`;
      document.getElementById('zone-mission-ok')?.addEventListener('click', () => {
        _playState.success = true;
        _finishPlay();
      });
      return;
    }

    if (p.kind === 'quiz') {
      host.innerHTML = `<p class="zone-play-question">${_escapeHtml(p.question)}</p><div class="zone-quiz-choices" id="zone-quiz-choices"></div>`;
      const box = document.getElementById('zone-quiz-choices');
      p.choices.forEach((c, i) => {
        const b = document.createElement('button');
        b.type = 'button';
        b.className = 'btn-secondary zone-choice-btn';
        b.textContent = c;
        b.addEventListener('click', () => {
          _playState.success = i === p.answerIndex;
          _finishPlay();
        });
        box.appendChild(b);
      });
      return;
    }

    if (p.kind === 'sequence') {
      _playState.step = 0;
      _playState.success = false;
      _playState.input = [];
      const seq = p.sequence || [0, 1];
      host.innerHTML = `<p class="zone-play-text">Mémorisez la séquence, puis reproduisez-la.</p>
        <div class="zone-seq-preview" id="zone-seq-preview"></div>
        <div class="zone-seq-pad" id="zone-seq-pad"></div>
        <p class="zone-seq-hint" id="zone-seq-hint">Regardez…</p>`;
      const preview = document.getElementById('zone-seq-preview');
      const pad = document.getElementById('zone-seq-pad');
      const hint = document.getElementById('zone-seq-hint');
      seq.forEach((idx, step) => {
        setTimeout(() => {
          if (preview) preview.textContent = (p.labels && p.labels[idx]) || String(idx + 1);
        }, step * 650);
      });
      setTimeout(() => {
        if (preview) preview.textContent = '…';
        if (hint) hint.textContent = 'À vous !';
        (p.labels || ['A', 'B', 'C']).forEach((label, idx) => {
          const b = document.createElement('button');
          b.type = 'button';
          b.className = 'btn-secondary zone-choice-btn';
          b.textContent = label;
          b.addEventListener('click', () => {
            _playState.input.push(idx);
            if (_playState.input.length === seq.length) {
              _playState.success = seq.every((v, j) => _playState.input[j] === v);
              _finishPlay();
            }
          });
          pad.appendChild(b);
        });
      }, seq.length * 650 + 400);
      return;
    }

    if (p.kind === 'logic_series') {
      const arr = [...(p.series || [])];
      const miss = p.missingIndex ?? 0;
      const hidden = arr[miss];
      arr[miss] = '?';
      host.innerHTML = `<p class="zone-play-text">Série : <strong>${arr.join(', ')}</strong></p>
        <div class="zone-quiz-choices" id="zone-logic-choices"></div>`;
      const box = document.getElementById('zone-logic-choices');
      (p.options || []).forEach((n, i) => {
        const b = document.createElement('button');
        b.type = 'button';
        b.className = 'btn-secondary zone-choice-btn';
        b.textContent = String(n);
        b.addEventListener('click', () => {
          _playState.success = n === hidden;
          _finishPlay();
        });
        box.appendChild(b);
      });
      return;
    }

    if (p.kind === 'decision') {
      host.innerHTML = `<p class="zone-play-question">${_escapeHtml(p.prompt)}</p><div class="zone-quiz-choices" id="zone-decision-choices"></div>`;
      const box = document.getElementById('zone-decision-choices');
      p.choices.forEach((c, i) => {
        const b = document.createElement('button');
        b.type = 'button';
        b.className = 'btn-secondary zone-choice-btn';
        b.textContent = c;
        b.addEventListener('click', () => {
          _playState.success = i === p.correctIndex;
          _finishPlay();
        });
        box.appendChild(b);
      });
      return;
    }

    host.innerHTML = '<p class="zone-play-text">Activité non reconnue.</p>';
  }

  function _escapeHtml(s) {
    const d = document.createElement('div');
    d.textContent = s;
    return d.innerHTML;
  }

  function _finishPlay() {
    const ok = !!_playState?.success;
    document.getElementById('zone-phase-play')?.classList.add('hidden');
    const resultEl = document.getElementById('zone-phase-result');
    resultEl?.classList.remove('hidden');
    const resTitle = document.getElementById('zone-result-title');
    const resMsg = document.getElementById('zone-result-msg');
    if (resTitle) resTitle.textContent = ok ? 'Réussi !' : 'Pas tout à fait…';
    if (resMsg) {
      resMsg.textContent = ok
        ? 'Bravo — récompense ajoutée à votre progression unifiée.'
        : 'Réessayez plus tard ou choisissez une autre activité de zone.';
    }

    const btnNext = document.getElementById('btn-zone-result-next');
    if (btnNext) btnNext.textContent = ok ? 'Voir la récompense' : 'Fermer';
    const clone = btnNext?.cloneNode(true);
    if (btnNext && clone) {
      btnNext.replaceWith(clone);
      clone.textContent = ok ? 'Voir la récompense' : 'Fermer';
      clone.addEventListener('click', () => {
        if (ok) _applyRewardAndShow();
        else closeActivityModal();
      });
    }
  }

  function _applyRewardAndShow() {
    if (!_currentContent) return;
    const r = GameState.completeZoneContent({
      contentId: _currentContent.id,
      xp: _currentContent.reward_xp,
      coins: _currentContent.reward_coins,
      badgeId: _currentContent.badge_id,
    });
    if (!r.ok) {
      UIController.showToast('warning', 'Récompense', 'Cette activité était déjà validée.');
      closeActivityModal();
      return;
    }

    document.getElementById('zone-phase-result')?.classList.add('hidden');
    const rewardEl = document.getElementById('zone-phase-reward');
    rewardEl?.classList.remove('hidden');

    const xpLine = document.getElementById('zone-reward-xp');
    const coinLine = document.getElementById('zone-reward-coins');
    const badgeLine = document.getElementById('zone-reward-badge');
    const lbLine = document.getElementById('zone-reward-lb');

    if (xpLine) xpLine.textContent = `+${_currentContent.reward_xp} XP`;
    if (coinLine) coinLine.textContent = `+${_currentContent.reward_coins} pièces`;
    if (badgeLine) {
      badgeLine.textContent = _currentContent.badge_id ? `Badge : ${_currentContent.badge_id}` : 'Aucun badge supplémentaire';
    }
    if (lbLine) lbLine.textContent = `Score classement (local) : ${GameState.getLeaderboardScore()}`;

    UIController.refreshPlayerBar?.();

    const btnClose = document.getElementById('btn-zone-reward-close');
    const c2 = btnClose?.cloneNode(true);
    if (btnClose && c2) {
      btnClose.replaceWith(c2);
      c2.addEventListener('click', () => {
        closeActivityModal();
        UIController.showToast('success', 'Progression enregistrée', 'XP, pièces et classement mis à jour.');
      });
    }
  }

  return {
    init,
    setZoneIndicator,
    showZoneEntryBanner,
    openActivity,
    closeActivityModal,
  };
})();
